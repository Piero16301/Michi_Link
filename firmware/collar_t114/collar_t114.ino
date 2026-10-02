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

// Calibración para que 4.20V reales en batería no se lean como 4.04V
#undef BAT_AMPLIFY
#define BAT_AMPLIFY 5.10f

SX1262 radio =
    new Module(PIN_LORA_NSS, PIN_LORA_DIO1, PIN_LORA_RESET, PIN_LORA_BUSY);
TinyGPSPlus gps;
uint16_t packetSeq = 1;

// Encender el GPS por hardware
void powerOnGps() {
  pinMode(GPS_POWER_PIN, OUTPUT);
  digitalWrite(GPS_POWER_PIN, HIGH);
  pinMode(GPS_RESET_PIN, OUTPUT);
  digitalWrite(GPS_RESET_PIN, HIGH);
  delay(35); // Tiempo de arranque del regulador
  Serial2.begin(GPS_BAUDRATE);
}

// Apagar el GPS por hardware y liberar pines para evitar fugas parásitas
void powerOffGps() {
  Serial2.end(); // Apaga EasyDMA y permite el reposo profundo de la CPU
  pinMode(GPS_RESET_PIN, INPUT);
  digitalWrite(GPS_POWER_PIN, LOW); // Corte físico total (0.0 mA)
}

// Lectura de batería con sobremuestreo
uint16_t readBatteryMilliVolts() {
  pinMode(PIN_BAT_ADC_CTL, OUTPUT);
  digitalWrite(PIN_BAT_ADC_CTL, LOW); // Activa divisor resistivo
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

  digitalWrite(PIN_BAT_ADC_CTL, HIGH); // Apaga divisor para evitar fugas

  float rawAvg = (float)sum / (float)SAMPLES;
  float voltage = (rawAvg * 3.6f / 4096.0f) * BAT_AMPLIFY;
  return (uint16_t)(voltage * 1000.0f);
}

void setup() {
#if ENABLE_SERIAL_DEBUG
  Serial.begin(115200);
  delay(1000);
  DBG_PRINTLN("\n=== MICHIN LINK - HARDWARE POWER CUT ===");
#endif

  // 1. Inicialización inicial del GPS
  pinMode(GPS_POWER_PIN, OUTPUT);
  digitalWrite(GPS_POWER_PIN, HIGH);
  pinMode(GPS_RESET_PIN, OUTPUT);
  digitalWrite(GPS_RESET_PIN, LOW);
  delay(15);
  digitalWrite(GPS_RESET_PIN, HIGH);
  delay(150);

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

  // Apagar el GPS físicamente hasta el inicio del ciclo
  powerOffGps();
}

void loop() {
  uint32_t cycleStart = millis();

  // 1. Medir batería en reposo
  uint16_t batMv = readBatteryMilliVolts();

  // 2. Encender GPS y capturar datos satelitales
  powerOnGps();

  unsigned long startGpsTime = millis();
  bool gotFreshFix = false;

  // Espera dinámica: sale apenas obtiene Fix válido, con límite de seguridad de 6 segundos
  while (millis() - startGpsTime < 6000) {
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

  // 4. Apagar físicamente el GPS de inmediato (0 mA)
  powerOffGps();

  // 5. Transmisión LoRa y suspensión del transceptor (< 2 uA)
  radio.transmit((uint8_t *)&packet, sizeof(MinimalCollarPacket));
  radio.sleep();

  // 6. Reposo del microcontrolador por el tiempo restante del ciclo de 60 segundos
  uint32_t elapsed = millis() - cycleStart;
  if (elapsed < INTERVAL_MS) {
    delay(INTERVAL_MS - elapsed);
  }
}
