#include <Arduino.h>
#include <RadioLib.h>
#include <SPI.h>
#include <TinyGPSPlus.h>

#include "config.h"
#include "packet.h"

// Instancias de hardware
SX1262 radio =
    new Module(PIN_LORA_NSS, PIN_LORA_DIO1, PIN_LORA_RESET, PIN_LORA_BUSY);
TinyGPSPlus gps;
uint16_t packetSeq = 1;

// Lectura de la tensión de la batería LiPo
uint16_t readBatteryMilliVolts() {
  pinMode(PIN_BAT_ADC_CTL, OUTPUT);
  digitalWrite(PIN_BAT_ADC_CTL, LOW); // LOW activa la lectura en el divisor
  delay(15);

  analogReadResolution(12);
  analogReference(AR_DEFAULT);
  int raw = analogRead(PIN_BAT_ADC);

  digitalWrite(PIN_BAT_ADC_CTL,
               HIGH); // HIGH desactiva para evitar descarga parásita

  float voltage = (raw * 3.6f / 4096.0f) * BAT_AMPLIFY;
  return (uint16_t)(voltage * 1000.0f);
}

void setup() {
  Serial.begin(115200);
  delay(2000);
  Serial.println("\n========================================");
  Serial.println("  MICHIN LINK - Collar Heltec T114");
  Serial.println("========================================");

  // 1. Energizar y reiniciar periféricos (GPS y sensores)
  pinMode(GPS_POWER_PIN, OUTPUT);
  digitalWrite(GPS_POWER_PIN, HIGH);
  pinMode(GPS_RESET_PIN, OUTPUT);
  digitalWrite(GPS_RESET_PIN, LOW);
  delay(15);
  digitalWrite(GPS_RESET_PIN, HIGH);
  delay(150);

  // 2. Iniciar UART del GPS (Serial2 oficial en el T114)
  Serial2.begin(GPS_BAUDRATE);

  // 3. Iniciar bus SPI oficial
  SPI.begin();

  // 4. Inicializar módem LoRa SX1262
  Serial.print("[LoRa] Inicializando SX1262 a 915 MHz... ");
  int state = radio.begin(LORA_FREQ);
  if (state == RADIOLIB_ERR_NONE) {
    Serial.println("OK");
    radio.setOutputPower(LORA_TX_POWER_DBM);
    radio.setSpreadingFactor(LORA_SPREADING_FACT);
    radio.setBandwidth(LORA_BANDWIDTH_KHZ);
    radio.setCodingRate(LORA_CODING_RATE);
    radio.setDio2AsRfSwitch(true);
  } else {
    Serial.printf("FALLÓ (Error: %d)\n", state);
  }
}

void loop() {
  Serial.printf("\n--- Transmisión #%u ---\n", packetSeq);

  // 1. Procesar tramas NMEA desde Serial2 durante 2 segundos
  unsigned long startGpsTime = millis();
  while (millis() - startGpsTime < 2000) {
    while (Serial2.available() > 0) {
      gps.encode(Serial2.read());
    }
  }

  // 2. Medir voltaje de la batería
  uint16_t batMv = readBatteryMilliVolts();

  // 3. Estructurar el paquete binario de 17 bytes
  MinimalCollarPacket packet;
  packet.collar_id = COLLAR_ID;
  packet.seq = packetSeq;
  packet.battery_mv = batMv;

  uint8_t sats = (uint8_t)(gps.satellites.value() & GPS_FLAG_SATS_MASK);

  if (gps.location.isValid() && gps.location.age() < 5000) {
    packet.lat_scaled = (int32_t)(gps.location.lat() * 10000000.0);
    packet.lon_scaled = (int32_t)(gps.location.lng() * 10000000.0);
    packet.alt_m = (int16_t)gps.altitude.meters();
    packet.gps_flags = GPS_FLAG_FIX_MASK | sats;

    Serial.printf(
        "[GPS] Fix: SI | Satélites: %u | Lat: %.6f | Lon: %.6f | Alt: %d m\n",
        sats, packet.lat_scaled / 10000000.0, packet.lon_scaled / 10000000.0,
        packet.alt_m);
  } else {
    packet.lat_scaled = 0;
    packet.lon_scaled = 0;
    packet.alt_m = 0;
    packet.gps_flags = (0 << 7) | sats;

    Serial.printf(
        "[GPS] Fix: NO | Satélites detectados: %u (esperando sincronización)\n",
        sats);
  }

  Serial.printf("[BATERÍA] %u mV\n", packet.battery_mv);

  // 4. Enviar trama por radiofrecuencia
  int transmitState =
      radio.transmit((uint8_t *)&packet, sizeof(MinimalCollarPacket));
  if (transmitState == RADIOLIB_ERR_NONE) {
    Serial.println("[LoRa] -> Trama de 23 bytes enviada con éxito.");
  } else {
    Serial.printf("[LoRa] -> Error en transmisión: %d\n", transmitState);
  }

  // 5. Entrar en modo reposo de radio entre ciclos
  radio.sleep();
  packetSeq++;

  delay(INTERVAL_MS);
}
