#include <Arduino.h>
#include <RadioLib.h>
#include <SPI.h>
#include <TinyGPSPlus.h>

#include "config.h"
#include "packet.h"

// 0 para batería en collar | 1 solo para depuración conectada a PC
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

// Comando Standby nativo de AT6558R (Quectel L76K)
const char *GPS_CASIC_STANDBY = "$PCAS12,1*1F\r\n";
const char *GPS_PMTK_STANDBY  = "$PMTK161,0*28\r\n";

void wakeGps() {
  // Enviar cualquier byte por la línea UART saca al L76K del modo Standby
  Serial2.write(0xFF);
  delay(15);
}

void sleepGps() {
  // Enviar ambos comandos para garantizar la entrada a Standby (~7 uA)
  Serial2.print(GPS_CASIC_STANDBY);
  Serial2.print(GPS_PMTK_STANDBY);
  Serial2.flush();
  delay(10);
}

// Lectura promediada en frío con descarte de muestra
uint16_t readBatteryMilliVolts() {
  pinMode(PIN_BAT_ADC_CTL, OUTPUT);
  digitalWrite(PIN_BAT_ADC_CTL, LOW); // Activa divisor resistivo
  delay(5);

  analogReadResolution(12);
  analogReference(AR_DEFAULT);

  analogRead(PIN_BAT_ADC); // Descarte de estabilización

  uint32_t sum = 0;
  const uint8_t SAMPLES = 16;
  for (uint8_t i = 0; i < SAMPLES; i++) {
    sum += analogRead(PIN_BAT_ADC);
    delayMicroseconds(100);
  }

  digitalWrite(PIN_BAT_ADC_CTL, HIGH); // Apaga divisor

  float rawAvg = (float)sum / (float)SAMPLES;
  float voltage = (rawAvg * 3.6f / 4096.0f) * BAT_AMPLIFY;
  return (uint16_t)(voltage * 1000.0f);
}

void setup() {
#if ENABLE_SERIAL_DEBUG
  Serial.begin(115200);
  delay(1000);
  DBG_PRINTLN("\n=== MICHIN LINK - DEBUG ===");
#endif

  // 1. Inicializar GPS
  pinMode(GPS_POWER_PIN, OUTPUT);
  digitalWrite(GPS_POWER_PIN, HIGH);
  pinMode(GPS_RESET_PIN, OUTPUT);
  digitalWrite(GPS_RESET_PIN, LOW);
  delay(15);
  digitalWrite(GPS_RESET_PIN, HIGH);
  delay(150);

  Serial2.begin(GPS_BAUDRATE);

  // 2. Inicializar LoRa
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

  // Poner el GPS en Standby hasta el primer ciclo
  sleepGps();
}

void loop() {
  // 1. Medir batería antes de elevar el consumo del sistema
  uint16_t batMv = readBatteryMilliVolts();

  // 2. Despertar GPS y capturar datos con salida temprana
  wakeGps();
  unsigned long startGpsTime = millis();
  bool gotFreshFix = false;

  // Espera máxima de 2.5s, pero si ya hay fix fresco, sale de inmediato
  while (millis() - startGpsTime < 2500) {
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

  // 3. Empaquetar datos binarios
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

  // 4. Transmitir por LoRa y suspender radio
  radio.transmit((uint8_t *)&packet, sizeof(MinimalCollarPacket));
  radio.sleep();

  // 5. Enviar el GPS a Standby inmediatamente
  sleepGps();

  // 6. Reposo del procesador nRF52840 (FreeRTOS IDLE)
  delay(INTERVAL_MS);
}
