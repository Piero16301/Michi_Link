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

// Comando NMEA de Quectel para Standby (~7 uA manteniendo efemérides en RAM)
const char *GPS_STANDBY_CMD = "$PMTK161,0*28\r\n";

// Despertar el módulo GPS y rehabilitar la UART
void wakeGps() {
  Serial2.begin(GPS_BAUDRATE);
  delay(10);
  // Cualquier byte enviado por RX despierta al L76K del modo Standby
  Serial2.write(0xFF);
  delay(20);
}

// Dormir el GPS y apagar el periférico UART de la CPU
void sleepGps() {
  Serial2.print(GPS_STANDBY_CMD);
  Serial2.flush();
  delay(15);
  // Apagar la UART detiene el hardware EasyDMA del nRF52840,
  // permitiendo que el microcontrolador entre en sueño profundo (System ON IDLE)
  Serial2.end();
}

// Lectura de la tensión de la batería LiPo
uint16_t readBatteryMilliVolts() {
  pinMode(PIN_BAT_ADC_CTL, OUTPUT);
  digitalWrite(PIN_BAT_ADC_CTL, LOW); // Activa el divisor resistivo
  delay(10);

  analogReadResolution(12);
  analogReference(AR_DEFAULT);
  int raw = analogRead(PIN_BAT_ADC);

  digitalWrite(PIN_BAT_ADC_CTL, HIGH); // Desactiva para evitar drenaje continuo

  float voltage = (raw * 3.6f / 4096.0f) * BAT_AMPLIFY;
  return (uint16_t)(voltage * 1000.0f);
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n========================================");
  Serial.println("  MICHIN LINK - Collar Heltec T114");
  Serial.println("========================================");

  // 1. Energizar y reiniciar periféricos
  pinMode(GPS_POWER_PIN, OUTPUT);
  digitalWrite(GPS_POWER_PIN, HIGH);
  pinMode(GPS_RESET_PIN, OUTPUT);
  digitalWrite(GPS_RESET_PIN, LOW);
  delay(15);
  digitalWrite(GPS_RESET_PIN, HIGH);
  delay(150);

  // Inicializar bus SPI del módem
  SPI.begin();

  // 2. Inicializar módem LoRa SX1262 a máxima potencia urbana (+22 dBm)
  Serial.print("[LoRa] Inicializando SX1262 a 915 MHz... ");
  int state = radio.begin(LORA_FREQ);
  if (state == RADIOLIB_ERR_NONE) {
    Serial.println("OK");
    radio.setOutputPower(LORA_TX_POWER_DBM); // Máxima potencia (+22 dBm) para sortear muros
    radio.setSpreadingFactor(LORA_SPREADING_FACT);
    radio.setBandwidth(LORA_BANDWIDTH_KHZ);
    radio.setCodingRate(LORA_CODING_RATE);
    radio.setDio2AsRfSwitch(true);
    radio.sleep(); // Dormir la etapa de radio tras el inicio
  } else {
    Serial.printf("FALLÓ (Error: %d)\n", state);
  }

  // Poner el GPS en Standby hasta que inicie el loop
  Serial2.begin(GPS_BAUDRATE);
  sleepGps();
}

void loop() {
  Serial.printf("\n--- Transmisión #%u ---\n", packetSeq);

  // 1. Despertar GPS y procesar tramas NMEA durante 2.5 segundos
  wakeGps();
  unsigned long startGpsTime = millis();
  while (millis() - startGpsTime < 2500) {
    while (Serial2.available() > 0) {
      gps.encode(Serial2.read());
    }
  }

  // 2. Medir voltaje de la batería
  uint16_t batMv = readBatteryMilliVolts();

  // 3. Estructurar el paquete binario (23 bytes)
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

    Serial.printf(
        "[GPS] Fix: SI | Satélites: %u | Lat: %.6f | Lon: %.6f | Alt: %d m\n",
        sats, packet.lat_scaled / 10000000.0, packet.lon_scaled / 10000000.0,
        packet.alt_m);
  } else {
    packet.lat_scaled = 0;
    packet.lon_scaled = 0;
    packet.alt_m = 0;
    packet.gps_flags = sats;

    Serial.printf(
        "[GPS] Fix: NO | Satélites detectados: %u (esperando sincronización)\n",
        sats);
  }

  Serial.printf("[BATERÍA] %u mV\n", packet.battery_mv);

  // 4. Enviar trama por LoRa a máxima potencia (+22 dBm) y dormir la radio de inmediato
  int transmitState =
      radio.transmit((uint8_t *)&packet, sizeof(MinimalCollarPacket));
  if (transmitState == RADIOLIB_ERR_NONE) {
    Serial.println("[LoRa] -> Trama enviada con éxito.");
  } else {
    Serial.printf("[LoRa] -> Error en transmisión: %d\n", transmitState);
  }

  // Dormir el transceptor LoRa inmediatamente tras la transmisión (~1.5 uA)
  radio.sleep();

  // 5. Enviar el GPS a modo Standby (~7 uA) y apagar periférico UART EasyDMA
  sleepGps();

  // 6. Reposo del procesador
  // Con EasyDMA apagado y la radio en sleep, FreeRTOS duerme los núcleos del nRF52840
  delay(INTERVAL_MS);
}
