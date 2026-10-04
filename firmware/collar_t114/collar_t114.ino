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

// Comando Standby nativo para Quectel L76K / AT6558R (~7 uA en RAM)
const char *GPS_STANDBY_CMD = "$PCAS12,1*1F\r\n";

// ========================================================
// CONTROL DE ENERGÍA SEGURO DEL GNSS (UART SIEMPRE ESTABLE)
// ========================================================

void wakeGps() {
  // Enviar cualquier byte despierta al L76K inmediatamente de Standby
  Serial2.write(0xFF);
  delay(15);
}

void sleepGps() {
  // Transmitir comando de Standby CASIC y vaciar búfer UART.
  // NO cerramos Serial2: la línea TX permanece en nivel lógico ALTO (3.3V),
  // evitando flancos de bajada accidentales que despierten al módulo GNSS.
  Serial2.print(GPS_STANDBY_CMD);
  Serial2.flush();
  delay(10);
}

// ========================================================
// MEDICIÓN DE BATERÍA POR DIVISOR CON COMPUERTA
// ========================================================

uint16_t readBatteryMilliVolts() {
  digitalWrite(PIN_BAT_ADC_CTL, LOW); // Activa el divisor
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

  digitalWrite(PIN_BAT_ADC_CTL, HIGH); // Apaga el divisor para evitar fugas

  float rawAvg = (float)sum / (float)SAMPLES;
  float voltage = (rawAvg * 3.6f / 4096.0f) * BAT_AMPLIFY;
  return (uint16_t)(voltage * 1000.0f);
}

// ========================================================
// INICIALIZACIÓN DEL SISTEMA
// ========================================================

void setup() {
  // 1. Activar reguladores conmutados DC-DC internos del nRF52840 (REG1 y REG0)
  // Reduce el consumo de reposo de CPU y osciladores de ~4.5 mA a ~2.3 mA
  NRF_POWER->DCDCEN = 1;
  NRF_POWER->DCDCEN0 = 1;

#if ENABLE_SERIAL_DEBUG
  Serial.begin(115200);
  delay(1000);
  DBG_PRINTLN("\n=== MICHIN LINK - ESTABLE > 3 DIAS ===");
#endif

  // 2. Aislar compuerta ADC desde el inicio para evitar fugas en arranque
  pinMode(PIN_BAT_ADC_CTL, OUTPUT);
  digitalWrite(PIN_BAT_ADC_CTL, HIGH);

  // 3. Energizar GPS (Riel Vext)
  pinMode(GPS_POWER_PIN, OUTPUT);
  digitalWrite(GPS_POWER_PIN, HIGH);
  pinMode(GPS_RESET_PIN, OUTPUT);
  digitalWrite(GPS_RESET_PIN, LOW);
  delay(15);
  digitalWrite(GPS_RESET_PIN, HIGH);
  delay(150);

  // El bus UART se inicializa una sola vez y no se destruye
  Serial2.begin(GPS_BAUDRATE);

  // 4. Inicializar módem LoRa SX1262
  SPI.begin();
  int state = radio.begin(LORA_FREQ);
  if (state == RADIOLIB_ERR_NONE) {
    radio.setOutputPower(LORA_TX_POWER_DBM);
    radio.setSpreadingFactor(LORA_SPREADING_FACT);
    radio.setBandwidth(LORA_BANDWIDTH_KHZ);
    radio.setCodingRate(LORA_CODING_RATE);
    radio.setDio2AsRfSwitch(true);
    radio.sleep();
  }

  // 5. Sincronización inicial (Cold Start): hasta 40s para descargar efemérides
  unsigned long startBootGps = millis();
  while (millis() - startBootGps < 40000) {
    while (Serial2.available() > 0) {
      if (gps.encode(Serial2.read())) {
        if (gps.location.isValid()) break;
      }
    }
    if (gps.location.isValid()) break;
  }

  // Suspender el GNSS conservando efemérides en RAM interna
  sleepGps();
}

// ========================================================
// CICLO PRINCIPAL DE TELEMETRÍA
// ========================================================

void loop() {
  uint32_t cycleStart = millis();

  // 1. Medir batería en reposo
  uint16_t batMv = readBatteryMilliVolts();

  // 2. Despertar GPS (Hot Start)
  wakeGps();

  unsigned long startGpsTime = millis();
  bool gotFreshFix = false;

  // Timeout dinámico acotado a 4s (Hot Start fija en < 2s; no drena en interiores)
  while (millis() - startGpsTime < 4000) {
    while (Serial2.available() > 0) {
      if (gps.encode(Serial2.read())) {
        if (gps.location.isValid() && gps.location.age() < 2000) {
          gotFreshFix = true;
          break;
        }
      }
    }
    if (gotFreshFix) break;
  }

  // 3. Estructurar paquete binario compacto (23 bytes)
  MinimalCollarPacket packet;
  packet.collar_id = COLLAR_ID;
  packet.seq = packetSeq++;
  packet.battery_mv = batMv;

  uint8_t sats = (uint8_t)(gps.satellites.value() & GPS_FLAG_SATS_MASK);

  if (gotFreshFix || (gps.location.isValid() && gps.location.age() < 5000)) {
    packet.lat_scaled = (int32_t)(gps.location.lat() * 10000000.0);
    packet.lon_scaled = (int32_t)(gps.location.lng() * 10000000.0);
    packet.alt_m = (int16_t)gps.altitude.meters();
    packet.gps_flags = GPS_FLAG_FIX_MASK | sats;
  } else {
    packet.lat_scaled = 0;
    packet.lon_scaled = 0;
    packet.alt_m = 0;
    packet.gps_flags = sats;
  }

  // 4. Suspender el GPS conservando efemérides en RAM
  sleepGps();

  // 5. Transmitir paquete LoRa a +22 dBm y suspender radio
  radio.transmit((uint8_t *)&packet, sizeof(MinimalCollarPacket));
  radio.sleep();

  // 6. Dormir el resto del ciclo (nRF52840 en reposo con DC-DC activo)
  uint32_t elapsed = millis() - cycleStart;
  if (elapsed < INTERVAL_MS) {
    delay(INTERVAL_MS - elapsed);
  }
}
