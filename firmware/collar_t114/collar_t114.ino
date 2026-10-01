#include <Arduino.h>
#include <RadioLib.h>
#include <SPI.h>
#include <TinyGPSPlus.h>

#include "config.h"
#include "packet.h"

// Poner en 0 para operar en el collar con batería (ahorra ~8 mA apagando USB)
// Poner en 1 únicamente si vas a conectar el cable USB para depurar en consola
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

const char *GPS_STANDBY_CMD = "$PMTK161,0*28\r\n";

// Despertar el GPS
void wakeGps() {
  Serial2.begin(GPS_BAUDRATE);
  delay(10);
  Serial2.write(0xFF); // Un byte cualquiera saca al L76K de Standby
  delay(20);
}

// Poner el GPS en Standby reteniendo la línea TX en HIGH
void sleepGps() {
  Serial2.print(GPS_STANDBY_CMD);
  Serial2.flush();
  delay(20);
  Serial2.end();

  // Mantener forzada la línea TX a 3.3V (HIGH) para evitar el Start Bit fantasma
  #ifdef PIN_SERIAL2_TX
    pinMode(PIN_SERIAL2_TX, OUTPUT);
    digitalWrite(PIN_SERIAL2_TX, HIGH);
  #endif
}

// Medición de batería estabilizada con sobremuestreo (16 muestras promediadas)
uint16_t readBatteryMilliVolts() {
  pinMode(PIN_BAT_ADC_CTL, OUTPUT);
  digitalWrite(PIN_BAT_ADC_CTL, LOW); // Activa el divisor
  delay(5);                           // Estabilización del condensador de filtrado

  analogReadResolution(12);
  analogReference(AR_DEFAULT);

  // Descarte de primera muestra por carga del conversor
  analogRead(PIN_BAT_ADC);

  uint32_t sum = 0;
  const uint8_t SAMPLES = 16;
  for (uint8_t i = 0; i < SAMPLES; i++) {
    sum += analogRead(PIN_BAT_ADC);
    delayMicroseconds(120);
  }

  digitalWrite(PIN_BAT_ADC_CTL, HIGH); // Apaga el divisor para evitar fugas

  float rawAvg = (float)sum / (float)SAMPLES;
  float voltage = (rawAvg * 3.6f / 4096.0f) * BAT_AMPLIFY;
  return (uint16_t)(voltage * 1000.0f);
}

void setup() {
#if ENABLE_SERIAL_DEBUG
  Serial.begin(115200);
  delay(1000);
  DBG_PRINTLN("\n=== MICHIN LINK - DEBUG MODE ===");
#endif

  // 1. Inicialización de periféricos
  pinMode(GPS_POWER_PIN, OUTPUT);
  digitalWrite(GPS_POWER_PIN, HIGH);
  pinMode(GPS_RESET_PIN, OUTPUT);
  digitalWrite(GPS_RESET_PIN, LOW);
  delay(15);
  digitalWrite(GPS_RESET_PIN, HIGH);
  delay(150);

  SPI.begin();

  // 2. Radio LoRa a máxima potencia urbana (+22 dBm)
  int state = radio.begin(LORA_FREQ);
  if (state == RADIOLIB_ERR_NONE) {
    radio.setOutputPower(LORA_TX_POWER_DBM);
    radio.setSpreadingFactor(LORA_SPREADING_FACT);
    radio.setBandwidth(LORA_BANDWIDTH_KHZ);
    radio.setCodingRate(LORA_CODING_RATE);
    radio.setDio2AsRfSwitch(true);
    radio.sleep();
  }

  // Poner el GPS en reposo inmediato hasta la primera transmisión
  Serial2.begin(GPS_BAUDRATE);
  sleepGps();
}

void loop() {
  // 1. Medir batería EN FRÍO antes de activar el consumo del GPS o la radio
  uint16_t batMv = readBatteryMilliVolts();

  // 2. Despertar GPS y capturar paquetes NMEA
  wakeGps();
  unsigned long startGpsTime = millis();
  while (millis() - startGpsTime < 2500) {
    while (Serial2.available() > 0) {
      gps.encode(Serial2.read());
    }
  }

  // 3. Estructuración del paquete binario (23 bytes)
  MinimalCollarPacket packet;
  packet.collar_id = COLLAR_ID;
  packet.seq = packetSeq++;
  packet.battery_mv = batMv;

  uint8_t sats = (uint8_t)(gps.satellites.value() & GPS_FLAG_SATS_MASK);

  if (gps.location.isValid() && gps.location.age() < 5000) {
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

  // 4. Transmisión LoRa y suspensión inmediata del módem
  radio.transmit((uint8_t *)&packet, sizeof(MinimalCollarPacket));
  radio.sleep();

  // 5. Suspensión del GPS reteniendo la línea UART
  sleepGps();

  // 6. Sueño profundo del nRF52840
  delay(INTERVAL_MS);
}
