#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Arduino.h>
#include <ArduinoJson.h>
#include <PubSubClient.h>
#include <RadioLib.h>
#include <SPI.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <Wire.h>
#include <map>

#include "packet.h"

// ==========================================
// 1. CREDENCIALES Y AJUSTES DE RED
// ==========================================
const char *WIFI_SSID = "ENGOMOHE-2.4G";
const char *WIFI_PASSWORD = "0178691930";

const char *MQTT_BROKER = "4a3d7cdffc0943709189065b2b48eece.s1.eu.hivemq.cloud";
const int MQTT_PORT = 8883;
const char *MQTT_USER = "michi-link";
const char *MQTT_PASS = "Aj7dpWB5M!asBrz";

// ==========================================
// 2. PINES HELTEC WIFI LORA 32 (V3)
// ==========================================
#define VEXT_PIN 36
#define OLED_SDA 17
#define OLED_SCL 18
#define OLED_RST 21

#define LORA_NSS 8
#define LORA_SCK 9
#define LORA_MOSI 10
#define LORA_MISO 11
#define LORA_RESET 12
#define LORA_BUSY 13
#define LORA_DIO1 14

#define LED_PIN 35 // LED blanco de usuario en la V3

// ==========================================
// 3. ESTADOS Y OBJETOS GLOBALES
// ==========================================
std::map<String, uint16_t> lastCollarSeq;

uint32_t totalPacketsRx = 0;
uint32_t totalPacketsLost = 0;

Adafruit_SSD1306 display(128, 64, &Wire, OLED_RST);
SX1262 radio = new Module(LORA_NSS, LORA_DIO1, LORA_RESET, LORA_BUSY);

WiFiClientSecure netClient;
PubSubClient mqttClient(netClient);

volatile bool packetReceived = false;

#if defined(ESP8266) || defined(ESP32)
IRAM_ATTR
#endif
void setFlag(void) { packetReceived = true; }

int batteryMvToPct(uint16_t mv) {
  if (mv >= 4160) return 100;
  if (mv >= 4050) return 90 + (mv - 4050) * 10 / 110;  // 4050 a 4160 mV -> 90% a 100%
  if (mv >= 3920) return 75 + (mv - 3920) * 15 / 130;  // 3920 a 4050 mV -> 75% a 90%
  if (mv >= 3800) return 50 + (mv - 3800) * 25 / 120;  // 3800 a 3920 mV -> 50% a 75%
  if (mv >= 3700) return 25 + (mv - 3700) * 25 / 100;  // 3700 a 3800 mV -> 25% a 50%
  if (mv >= 3550) return 10 + (mv - 3550) * 15 / 150;  // 3550 a 3700 mV -> 10% a 25%
  if (mv >= 3350) return 3  + (mv - 3350) * 7  / 200;  // 3350 a 3550 mV -> 3% a 10%
  if (mv >= 3000) return 1;                            // Reserva crítica antes de corte
  return 0;                                            // Corte (< 3.0V)
}

// ==========================================
// 4. GESTIÓN DEL DISPLAY OLED (128x64)
// ==========================================
void updateOLED(const char *status, const MinimalCollarPacket *pkt = nullptr,
                float rssi = 0, float snr = 0, uint16_t gap = 0) {
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);

  // Línea 1 (y=0): Estado de conectividad de red
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.printf("WiFi:%s | MQTT:%s", WiFi.isConnected() ? "OK" : "NO",
                 mqttClient.connected() ? "OK" : "NO");
  display.drawLine(0, 9, 128, 9, SSD1306_WHITE);

  if (pkt != nullptr) {
    bool fix = (pkt->gps_flags & GPS_FLAG_FIX_MASK);
    uint8_t sats = (pkt->gps_flags & GPS_FLAG_SATS_MASK);

    // Línea 2 (y=13): ID del collar y secuencia
    display.setCursor(0, 13);
    display.printf("ID:...%03llX #%u", (pkt->collar_id & 0xFFFULL), pkt->seq);
    if (gap > 0) {
      display.printf(" (-%u)", gap);
    }

    // Línea 3 (y=24): Fix, satélites y RSSI recibido (reemplaza la distancia)
    display.setCursor(0, 24);
    if (fix) {
      display.printf("Fix:SI (%uS) R:%.0fdBm", sats, rssi);
      display.setCursor(0, 35);
      display.printf("%.5f, %.5f", pkt->lat_scaled / 10000000.0,
                     pkt->lon_scaled / 10000000.0);
    } else {
      display.printf("Fix:NO (%uS) R:%.0fdBm", sats, rssi);
      display.setCursor(0, 35);
      display.print("Buscando satelites...");
    }

    // Línea 4 (y=46): Nivel de batería
    display.setCursor(0, 46);
    display.printf("Bat:%u%% (%umV)", batteryMvToPct(pkt->battery_mv),
                   pkt->battery_mv);

    // Línea 5 (y=56): Métricas de radio y paquetes acumulados
    display.setCursor(0, 56);
    display.printf("SNR:%.1fdB RX:%lu L:%lu", snr, totalPacketsRx,
                   totalPacketsLost);
  } else {
    display.setCursor(0, 22);
    display.print(status);
    display.setCursor(0, 38);
    display.print("Gateway LoRa Activo");
    display.setCursor(0, 52);
    display.printf("RX:%lu | Perdidos:%lu", totalPacketsRx, totalPacketsLost);
  }

  display.display();
}

// ==========================================
// 5. MQTT: CONEXIÓN Y HEARTBEAT
// ==========================================
void reconnectMQTT() {
  while (!mqttClient.connected()) {
    Serial.print("[MQTT] Conectando a HiveMQ Cloud... ");
    String clientId = "ESP32Base-" + String(random(0xffff), HEX);
    if (mqttClient.connect(clientId.c_str(), MQTT_USER, MQTT_PASS)) {
      Serial.println("¡CONECTADO CON ÉXITO!");

      // Estado de la estación base retenido en el broker
      mqttClient.publish("mascotas/base_station/status",
                         "{\"status\":\"online\"}", true);

      updateOLED("MQTT Conectado");
    } else {
      Serial.printf("Fallo de conexion (rc=%d). Reintentando en 3s...\n",
                    mqttClient.state());
      updateOLED("Error en MQTT");
      delay(3000);
    }
  }
}

// ==========================================
// 6. SETUP
// ==========================================
void setup() {
  Serial.begin(115200);
  delay(1000);

  pinMode(VEXT_PIN, OUTPUT);
  digitalWrite(VEXT_PIN, LOW); // Enciende riel Vext en Heltec V3
  delay(100);

  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  Wire.begin(OLED_SDA, OLED_SCL);
  if (display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(10, 25);
    display.println("Iniciando Gateway...");
    display.display();
  }

  SPI.begin(LORA_SCK, LORA_MISO, LORA_MOSI, LORA_NSS);
  Serial.print("[LoRa Base] Configurando SX1262... ");
  int state = radio.begin(915.0, 125.0, 7, 5, 0x12, 22, 8, 1.6, false);
  if (state == RADIOLIB_ERR_NONE) {
    radio.setDio2AsRfSwitch(true);
    radio.setPacketReceivedAction(setFlag);
    radio.startReceive();
    Serial.println("OK (Modo Escucha Activo)");
  } else {
    Serial.printf("Error LoRa: %d\n", state);
  }

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("[WiFi] Conectando");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.printf("\n[WiFi] Conectado IP: %s\n",
                WiFi.localIP().toString().c_str());

  netClient.setInsecure();
  mqttClient.setServer(MQTT_BROKER, MQTT_PORT);
  mqttClient.setBufferSize(512);

  updateOLED("Conectando MQTT...");
}

// ==========================================
// 7. LOOP PRINCIPAL
// ==========================================
void loop() {
  bool wifiConnected = (WiFi.status() == WL_CONNECTED);
  bool mqttConnected = mqttClient.connected();

  // LED de estado: parpadea si se pierde WiFi o MQTT
  static unsigned long lastBlinkTime = 0;
  static bool ledState = false;

  if (!wifiConnected || !mqttConnected) {
    if (millis() - lastBlinkTime > 500) {
      lastBlinkTime = millis();
      ledState = !ledState;
      digitalWrite(LED_PIN, ledState ? HIGH : LOW);
    }
  } else {
    if (ledState) {
      ledState = false;
      digitalWrite(LED_PIN, LOW);
    }
  }

  if (wifiConnected) {
    if (!mqttConnected) {
      reconnectMQTT();
    }
    mqttClient.loop();
  }

  // Procesamiento del paquete LoRa entrante
  if (packetReceived) {
    packetReceived = false;

    MinimalCollarPacket packet;
    int state = radio.readData((uint8_t *)&packet, sizeof(MinimalCollarPacket));

    if (state == RADIOLIB_ERR_NONE) {
      totalPacketsRx++;
      float rssi = radio.getRSSI();
      float snr = radio.getSNR();

      char devIdStr[32];
      snprintf(devIdStr, sizeof(devIdStr), "COLLAR_%016llX", packet.collar_id);
      String currentDevID = String(devIdStr);

      // Auditoría de saltos de secuencia
      uint16_t lostInThisGap = 0;
      if (lastCollarSeq.find(currentDevID) != lastCollarSeq.end()) {
        uint16_t prevSeq = lastCollarSeq[currentDevID];
        if (packet.seq > prevSeq + 1) {
          lostInThisGap = packet.seq - prevSeq - 1;
          totalPacketsLost += lostInThisGap;
        } else if (prevSeq > 65000 && packet.seq < 500) {
          lostInThisGap = (65535 - prevSeq) + packet.seq - 1;
          totalPacketsLost += lostInThisGap;
        }
      }
      lastCollarSeq[currentDevID] = packet.seq;

      bool hasFix = (packet.gps_flags & GPS_FLAG_FIX_MASK);
      uint8_t sats = (packet.gps_flags & GPS_FLAG_SATS_MASK);
      double lat = packet.lat_scaled / 10000000.0;
      double lon = packet.lon_scaled / 10000000.0;
      int batPct = batteryMvToPct(packet.battery_mv);

      Serial.printf("\n[LORA RX #%lu] %s (#%u) | Perdidos: %u | Bat: %d%% | RSSI: %.1fdBm | SNR: %.1fdB\n",
                    totalPacketsRx, devIdStr, packet.seq, lostInThisGap,
                    batPct, rssi, snr);

      // Estructuración del JSON de telemetría hacia HiveMQ
      StaticJsonDocument<512> doc;
      doc["device_id"] = currentDevID;
      doc["seq"] = packet.seq;

      JsonObject coords = doc.createNestedObject("coords");
      coords["lat"] = lat;
      coords["lon"] = lon;
      coords["alt_m"] = packet.alt_m;

      JsonObject status = doc.createNestedObject("status");
      status["gps_fix"] = hasFix;
      status["sats"] = sats;
      status["battery_v"] = round((packet.battery_mv / 1000.0) * 100.0) / 100.0;
      status["battery_pct"] = batPct;

      JsonObject radioObj = doc.createNestedObject("radio");
      radioObj["rssi"] = (int)rssi;
      radioObj["snr"] = round(snr * 10.0) / 10.0;
      radioObj["packets_lost_gap"] = lostInThisGap;

      char jsonBuffer[512];
      serializeJson(doc, jsonBuffer);

      String telemTopic = "mascotas/" + currentDevID + "/telemetria";
      mqttClient.publish(telemTopic.c_str(), jsonBuffer);

      // Actualizar display OLED con métricas de radiofrecuencia
      updateOLED(nullptr, &packet, rssi, snr, lostInThisGap);
    }

    radio.startReceive();
  }
}
