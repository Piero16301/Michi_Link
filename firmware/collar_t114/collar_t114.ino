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

// Sentencias válidas de bajo consumo para Quectel L76K / AT6558R
// $PCAS11,1*1C: Stop Mode nativo CASIC (~15 uA en SRAM)
// $PCAS11,2*1F: Standby Mode CASIC
// $PMTK161,0*28: Standby Mode protocolo MTK (compatibilidad de firmware Quectel)
const char *CASIC_STOP_CMD    = "$PCAS11,1*1C\r\n";
const char *CASIC_STANDBY_CMD = "$PCAS11,2*1F\r\n";
const char *PMTK_STANDBY_CMD  = "$PMTK161,0*28\r\n";

// ========================================================
// CONTROL DE ENERGÍA GNSS (COMANDOS CASIC REALES)
// ========================================================

void wakeGps() {
  // Transmitir bytes en el bus UART despierta al AT6558R del Stop Mode
  Serial2.write(0xFF);
  Serial2.print("\r\n");
  Serial2.flush();
  delay(25);
}

void sleepGps() {
  // 1. Drenar búfer de recepción previo
  while (Serial2.available() > 0) {
    Serial2.read();
  }

  // 2. Enviar Stop Mode nativo CASIC (Zhongke Micro AT6558R)
  Serial2.print(CASIC_STOP_CMD);
  Serial2.flush();
  delay(15);

  // 3. Enviar sentencias de respaldo para variantes de firmware L76K
  Serial2.print(CASIC_STANDBY_CMD);
  Serial2.flush();
  delay(15);
  Serial2.print(PMTK_STANDBY_CMD);
  Serial2.flush();
  delay(15);

  // 4. Vaciar las últimas tramas NMEA que estuvieran en tránsito de transmisión
  unsigned long drainStart = millis();
  while (millis() - drainStart < 80) {
    while (Serial2.available() > 0) {
      Serial2.read();
    }
  }
}

// ========================================================
// MEDICIÓN DE BATERÍA POR DIVISOR CON COMPUERTA
// ========================================================

uint16_t readBatteryMilliVolts() {
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
// INICIALIZACIÓN DEL SISTEMA
// ========================================================

void setup() {
  // 1. Habilitar reguladores conmutados DC-DC internos del nRF52840 (REG1 y REG0)
  // Reduce el consumo del microcontrolador de ~4.5 mA a ~2.3 mA
  NRF_POWER->DCDCEN = 1;
  NRF_POWER->DCDCEN0 = 1;

#if ENABLE_SERIAL_DEBUG
  Serial.begin(115200);
  delay(1000);
  DBG_PRINTLN("\n=== MICHIN LINK - CASIC POWER FIX ===");
#endif

  // 2. Aislar compuerta ADC desde el arranque
  pinMode(PIN_BAT_ADC_CTL, OUTPUT);
  digitalWrite(PIN_BAT_ADC_CTL, HIGH);

  // 3. Energizar módulo GNSS
  pinMode(GPS_POWER_PIN, OUTPUT);
  digitalWrite(GPS_POWER_PIN, HIGH);
  pinMode(GPS_RESET_PIN, OUTPUT);
  digitalWrite(GPS_RESET_PIN, LOW);
  delay(15);
  digitalWrite(GPS_RESET_PIN, HIGH);
  delay(150);

  Serial2.begin(GPS_BAUDRATE);

  // 4. Inicializar transceptor LoRa SX1262
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

  // 5. Cold Start inicial para bajar efemérides (hasta 40s)
  unsigned long startBootGps = millis();
  while (millis() - startBootGps < 40000) {
    while (Serial2.available() > 0) {
      if (gps.encode(Serial2.read())) {
        if (gps.location.isValid()) break;
      }
    }
    if (gps.location.isValid()) break;
  }

  // Poner el GPS en Stop Mode conservando efemérides en SRAM
  sleepGps();
}

// ========================================================
// CICLO PRINCIPAL (60 SEGUNDOS)
// ========================================================

void loop() {
  uint32_t cycleStart = millis();

  // 1. Medir tensión de celda en reposo
  uint16_t batMv = readBatteryMilliVolts();

  // 2. Despertar GPS (Hot Start)
  wakeGps();

  unsigned long startGpsTime = millis();
  bool gotFreshFix = false;

  // Timeout dinámico de 5s (Hot Start fija en < 2s; previene drenaje en interiores)
  while (millis() - startGpsTime < 5000) {
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

  // 3. Empaquetar datos binarios (23 bytes)
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

  // 4. Suspender GPS a modo Stop (~15 uA en RAM)
  sleepGps();

  // 5. Transmitir paquete por LoRa a +22 dBm y suspender radio
  radio.transmit((uint8_t *)&packet, sizeof(MinimalCollarPacket));
  radio.sleep();

  // 6. Reposo del procesador nRF52840 durante el resto de los 60 segundos
  uint32_t elapsed = millis() - cycleStart;
  if (elapsed < INTERVAL_MS) {
    delay(INTERVAL_MS - elapsed);
  }
}
