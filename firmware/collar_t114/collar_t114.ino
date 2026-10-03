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

void wakeGps() {
  // Enviar cualquier byte saca al L76K del modo Standby inmediatamente
  Serial2.write(0xFF);
  delay(15);
}

void sleepGps() {
  // Enviar SOLO el comando CASIC y vaciar el buffer
  Serial2.print(GPS_STANDBY_CMD);
  Serial2.flush();
  delay(10);
}

uint16_t readBatteryMilliVolts() {
  pinMode(PIN_BAT_ADC_CTL, OUTPUT);
  digitalWrite(PIN_BAT_ADC_CTL, LOW);
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

  digitalWrite(PIN_BAT_ADC_CTL, HIGH);

  float rawAvg = (float)sum / (float)SAMPLES;
  float voltage = (rawAvg * 3.6f / 4096.0f) * BAT_AMPLIFY;
  return (uint16_t)(voltage * 1000.0f);
}

void setup() {
#if ENABLE_SERIAL_DEBUG
  Serial.begin(115200);
  delay(1000);
  DBG_PRINTLN("\n=== MICHIN LINK - CALIBRADO ===");
#endif

  // 1. Energizar GPS
  pinMode(GPS_POWER_PIN, OUTPUT);
  digitalWrite(GPS_POWER_PIN, HIGH);
  pinMode(GPS_RESET_PIN, OUTPUT);
  digitalWrite(GPS_RESET_PIN, LOW);
  delay(15);
  digitalWrite(GPS_RESET_PIN, HIGH);
  delay(150);

  Serial2.begin(GPS_BAUDRATE);

  // 2. Inicializar módem LoRa
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

  // 3. Sincronización inicial (Cold Start): hasta 40s para descargar efemérides
  unsigned long startBootGps = millis();
  while (millis() - startBootGps < 40000) {
    while (Serial2.available() > 0) {
      if (gps.encode(Serial2.read())) {
        if (gps.location.isValid()) break;
      }
    }
    if (gps.location.isValid()) break;
  }

  // Suspender el GPS conservando las efemérides en RAM
  sleepGps();
}

void loop() {
  uint32_t cycleStart = millis();

  // 1. Medir batería en reposo
  uint16_t batMv = readBatteryMilliVolts();

  // 2. Despertar GPS (Hot Start)
  wakeGps();

  unsigned long startGpsTime = millis();
  bool gotFreshFix = false;

  // Timeout dinámico de hasta 15s; sale apenas obtiene Fix (< 2s habituales)
  while (millis() - startGpsTime < 15000) {
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

  // 3. Estructurar paquete binario
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

  // 4. Suspender el GPS conservando efemérides en RAM (~7 uA)
  sleepGps();

  // 5. Transmitir por LoRa y suspender radio
  radio.transmit((uint8_t *)&packet, sizeof(MinimalCollarPacket));
  radio.sleep();

  // 6. Dormir el resto del ciclo de 60 segundos
  uint32_t elapsed = millis() - cycleStart;
  if (elapsed < INTERVAL_MS) {
    delay(INTERVAL_MS - elapsed);
  }
}
