#include <Arduino.h>
#include <RadioLib.h>
#include <SPI.h>
#include <TinyGPSPlus.h>

#include "config.h"
#include "packet.h"

#define ENABLE_SERIAL_DEBUG 0

#if ENABLE_SERIAL_DEBUG
  #define DBG_PRINTLN(x) Serial.println(x)
  #define DBG_PRINTF(...) Serial.printf(__VA_ARGS__)
#else
  #define DBG_PRINTLN(x)
  #define DBG_PRINTF(...)
#endif

SX1262 radio =
    new Module(PIN_LORA_NSS, PIN_LORA_DIO1, PIN_LORA_RESET, PIN_LORA_BUSY);
TinyGPSPlus gps;
uint16_t packetSeq = 1;

// Solo GGA + RMC (lo único que necesita TinyGPSPlus). Menos tráfico UART = menos CPU despierta.
// Nota: $PCAS11 es el modelo dinámico de navegación (NO un comando de energía) y
// $PMTK161 es MTK (el L76K/AT6558R lo ignora). El reposo se controla por el pin STANDBY.
static const char *CASIC_NMEA_GGA_RMC = "$PCAS03,1,0,0,0,1,0,0,0,0,0,,,0,0*02\r\n";
// GPS + BeiDou + GLONASS: más satélites candidatos = readquisición más rápida con señal débil
static const char *CASIC_GNSS_GPS_BDS_GLO = "$PCAS04,7*1E\r\n";

static uint32_t lastTtffMs = 0;

static bool     gpsUartOn          = false;
static uint8_t  gpsMissStreak      = 0;
static uint16_t cyclesSinceRefresh = 0xFFFF;
static uint16_t refreshCooldown    = GPS_REFRESH_COOLDOWN_MIN;
static uint16_t cyclesSinceMaint   = 0;
static uint8_t  lowBatCount        = 0;

// ========================================================
// UART GPS: SUSPENSIÓN SIN FLANCO DE BAJADA EN EL RX DEL L76K
// ========================================================

void gpsUartResume() {
  if (gpsUartOn) return;
  Serial2.begin(GPS_BAUDRATE);
  gpsUartOn = true;
}

void gpsUartSuspend() {
  if (!gpsUartOn) return;
  Serial2.flush();
  // Precargar el latch GPIO en ALTO ANTES de soltar el pin: mientras la UARTE
  // está habilitada ella controla el pin; al deshabilitarla, el pin vuelve al
  // GPIO, que ya está en OUTPUT/HIGH (idle UART). Así no hay flanco de bajada.
  pinMode(GPS_UART_TX_PIN, OUTPUT);
  digitalWrite(GPS_UART_TX_PIN, HIGH);
  Serial2.end();                    // Libera el HFCLK (~1 mA)
  pinMode(GPS_UART_RX_PIN, INPUT);  // El L76K mantiene su TX en idle-high
  gpsUartOn = false;
}

// ========================================================
// CONTROL DE ENERGÍA GNSS (PIN STANDBY P1.02)
// ========================================================

void gpsWake() {
  digitalWrite(GPS_STANDBY_PIN, HIGH);  // Forzar activo
  gpsUartResume();
}

void gpsSleep() {
  digitalWrite(GPS_STANDBY_PIN, LOW);   // Standby: RF off, SRAM + RTC vivos (~0.4 mA)
  gpsUartSuspend();
}

// Alimenta TinyGPS durante 'ms' sin busy-wait
void gpsFeedFor(uint32_t ms) {
  uint32_t t0 = millis();
  while (millis() - t0 < ms) {
    while (Serial2.available() > 0) {
      gps.encode(Serial2.read());
    }
    delay(10);
  }
}

// Espera un fix NUEVO y de calidad aceptable, o agota la ventana
bool gpsWaitFreshFix(uint32_t windowMs) {
  uint32_t t0 = millis();
  while (millis() - t0 < windowMs) {
    while (Serial2.available() > 0) {
      if (gps.encode(Serial2.read()) &&
          gps.location.isValid() && gps.location.age() < 1500 &&
          gps.hdop.isValid() && gps.hdop.hdop() <= GPS_MAX_HDOP) {
        lastTtffMs = millis() - t0;
        DBG_PRINTF("TTFF %lu ms\n", lastTtffMs);
        return true;
      }
    }
    delay(10);  // Deja a FreeRTOS entrar en idle (WFE) entre ráfagas NMEA
  }
  return false;
}

// ========================================================
// MEDICIÓN DE BATERÍA POR DIVISOR CON COMPUERTA
// ========================================================

uint16_t readBatteryMilliVolts() {
  // NOTA: Meshtastic define ADC_CTRL_ENABLED = HIGH para el T114. Verificar polaridad.
  digitalWrite(PIN_BAT_ADC_CTL, LOW); // Habilitar divisor
  delay(5);

  analogReadResolution(12);
  analogReference(AR_DEFAULT);

  analogRead(PIN_BAT_ADC); // Muestra de descarte

  uint32_t sum = 0;
  const uint8_t SAMPLES = 16;
  for (uint8_t i = 0; i < SAMPLES; i++) {
    sum += analogRead(PIN_BAT_ADC);
    delayMicroseconds(100);
  }

  digitalWrite(PIN_BAT_ADC_CTL, HIGH); // Aislar divisor para suprimir corriente de fuga

  float rawAvg = (float)sum / (float)SAMPLES;
  float voltage = (rawAvg * 3.6f / 4096.0f) * BAT_AMPLIFY;
  return (uint16_t)(voltage * 1000.0f);
}

// ========================================================
// PROTECCIÓN DE CELDA: SYSTEM OFF POR DEBAJO DEL UMBRAL CRÍTICO
// ========================================================

void shutdownLowBattery() {
  DBG_PRINTLN("Bateria critica -> System OFF");
  gpsSleep();
  // Evitar phantom powering del GPS a través de su pin RX al cortar Vext
  pinMode(GPS_UART_TX_PIN, INPUT);
  pinMode(GPS_STANDBY_PIN, INPUT);
  digitalWrite(GPS_POWER_PIN, LOW);  // Cortar Vext
  radio.sleep(false);                // Cold sleep SX1262
  systemOff(USER_BUTTON_PIN, LOW);   // nRF52 System OFF; despierta con el botón
}

// ========================================================
// INICIALIZACIÓN DEL SISTEMA
// ========================================================

void setup() {
  // 1. Habilitar reguladores conmutados DC-DC internos del nRF52840 (REG1 y REG0)
  NRF_POWER->DCDCEN = 1;
  NRF_POWER->DCDCEN0 = 1;

#if ENABLE_SERIAL_DEBUG
  Serial.begin(115200);
  delay(1000);
  DBG_PRINTLN("\n=== MICHIN LINK - STANDBY PIN FIX ===");
#endif

  // 2. Aislar compuerta ADC desde el arranque
  pinMode(PIN_BAT_ADC_CTL, OUTPUT);
  digitalWrite(PIN_BAT_ADC_CTL, HIGH);

  // 3. Energizar módulo GNSS: STANDBY en alto (activo), Vext ON, reset > 100 ms
  pinMode(GPS_STANDBY_PIN, OUTPUT);
  digitalWrite(GPS_STANDBY_PIN, HIGH);
  pinMode(GPS_POWER_PIN, OUTPUT);
  digitalWrite(GPS_POWER_PIN, HIGH);
  pinMode(GPS_RESET_PIN, OUTPUT);
  digitalWrite(GPS_RESET_PIN, LOW);
  delay(120);
  digitalWrite(GPS_RESET_PIN, HIGH);
  delay(300);

  gpsUartResume();
  Serial2.print(CASIC_GNSS_GPS_BDS_GLO);
  Serial2.flush();
  delay(250);
  Serial2.print(CASIC_NMEA_GGA_RMC);
  Serial2.flush();
  delay(250);

  // 4. Inicializar transceptor LoRa SX1262 (TCXO 1.8 V; sync word por defecto = el mismo de antes)
  SPI.begin();
  int state = radio.begin(LORA_FREQ, LORA_BANDWIDTH_KHZ, LORA_SPREADING_FACT,
                          LORA_CODING_RATE, RADIOLIB_SX126X_SYNC_WORD_PRIVATE,
                          LORA_TX_POWER_DBM, 8, LORA_TCXO_VOLTAGE);
  if (state == RADIOLIB_ERR_NONE) {
    radio.setDio2AsRfSwitch(true);
    radio.sleep();
  } else {
    DBG_PRINTF("radio.begin error %d\n", state);
  }

  // 5. Cold start inicial + asentamiento para bajar efemérides de más satélites
  if (gpsWaitFreshFix(GPS_BOOT_TIMEOUT_MS)) {
    gpsFeedFor(GPS_BOOT_SETTLE_MS);
  }

  // Poner el GPS en standby conservando efemérides en SRAM
  gpsSleep();
}

// ========================================================
// CICLO PRINCIPAL (60 SEGUNDOS)
// ========================================================

void loop() {
  uint32_t cycleStart = millis();

  // 1. Medir tensión de celda en reposo (GPS dormido) + corte crítico con histéresis
  uint16_t batMv = readBatteryMilliVolts();
  if (batMv < BAT_CRITICAL_MV) {
    if (++lowBatCount >= 3) shutdownLowBattery();
  } else {
    lowBatCount = 0;
  }

  // 2. Ventana GPS adaptativa (normal / larga para recuperar efemérides)
  uint32_t window = GPS_WINDOW_MS;
  bool refreshing = false;
  if (gpsMissStreak >= GPS_MISSES_BEFORE_REFRESH &&
      cyclesSinceRefresh >= refreshCooldown) {
    window = GPS_REFRESH_WINDOW_MS;
    refreshing = true;
    cyclesSinceRefresh = 0;
  } else if (cyclesSinceRefresh < 0xFFFF) {
    cyclesSinceRefresh++;
  }

  // 3. Despertar GPS (Hot Start)
  gpsWake();
  bool gotFreshFix = gpsWaitFreshFix(window);

  if (gotFreshFix) {
    gpsMissStreak = 0;
    refreshCooldown = GPS_REFRESH_COOLDOWN_MIN;
    // Mantenimiento de efemérides: cada ~2 h, 30 s extra con cielo visible
    if (++cyclesSinceMaint >= GPS_EPH_MAINT_CYCLES) {
      gpsFeedFor(GPS_EPH_MAINT_EXTRA_MS);
      cyclesSinceMaint = 0;
    }
  } else {
    if (gpsMissStreak < 255) gpsMissStreak++;
    // Backoff en interiores: no quemar 40 s cada 10 min si no hay cielo
    if (refreshing && refreshCooldown < GPS_REFRESH_COOLDOWN_MAX) {
      refreshCooldown *= 2;
      if (refreshCooldown > GPS_REFRESH_COOLDOWN_MAX) {
        refreshCooldown = GPS_REFRESH_COOLDOWN_MAX;
      }
    }
  }

  // 4. Empaquetar datos binarios (23 bytes, formato sin cambios)
  MinimalCollarPacket packet;
  packet.collar_id = COLLAR_ID;
  packet.seq = packetSeq++;
  packet.battery_mv = batMv;

  uint8_t sats = (uint8_t)(gps.satellites.value() & GPS_FLAG_SATS_MASK);
  bool freshLocation =
      gotFreshFix || (gps.location.isValid() && gps.location.age() < 2000);

  if (gps.location.isValid()) {
    // Con fix fresco: bit FIX = 1. Sin fix fresco: se envía la ÚLTIMA posición
    // conocida con bit FIX = 0, para que el backend la muestre como "última ubicación".
    packet.lat_scaled = (int32_t)(gps.location.lat() * 10000000.0);
    packet.lon_scaled = (int32_t)(gps.location.lng() * 10000000.0);
    packet.alt_m = (int16_t)gps.altitude.meters();
    packet.gps_flags = freshLocation ? (GPS_FLAG_FIX_MASK | sats) : sats;
  } else {
    packet.lat_scaled = 0;
    packet.lon_scaled = 0;
    packet.alt_m = 0;
    packet.gps_flags = sats;
  }

  DBG_PRINTF("seq=%u win=%lu fix=%d ttff=%lu sats=%u hdop=%.1f miss=%u\n",
             packet.seq, window, gotFreshFix, gotFreshFix ? lastTtffMs : 0,
             sats, gps.hdop.hdop(), gpsMissStreak);

  // 5. GPS a standby + UARTE suspendida (libera HFCLK)
  gpsSleep();

  // 6. Transmitir paquete por LoRa a +22 dBm y suspender radio
  radio.transmit((uint8_t *)&packet, sizeof(MinimalCollarPacket));
  radio.sleep();

  // 7. Reposo del nRF52840 el resto de los 60 s (delay -> vTaskDelay -> tickless idle / WFE)
  uint32_t elapsed = millis() - cycleStart;
  if (elapsed < INTERVAL_MS) {
    delay(INTERVAL_MS - elapsed);
  }
}
