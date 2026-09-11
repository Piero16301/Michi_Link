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

// Coordenadas base del hogar
const double HOME_LAT = -8.066663;
const double HOME_LON = -79.062807;

// ==========================================
// 2. PINES HELTEC WIFI LORA 32 (V3)
// ==========================================
#define VEXT_PIN 36 // Control energía OLED y LoRa (LOW = ON)
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

// ==========================================
// 3. ESTRUCTURAS, CONFIGURACIÓN Y PÉRDIDAS
// ==========================================
struct CollarLimits {
  float max_dist_m = 500.0;
  int min_bat_pct = 20;
  bool require_gps_fix = true;
};

// Mapa que asocia cada device_id con su configuración independiente
std::map<String, CollarLimits> collarConfigs;

// Auditoría de pérdida de paquetes por dispositivo
std::map<String, uint16_t> lastCollarSeq;
uint32_t totalPacketsRx = 0;
uint32_t totalPacketsLost = 0;

// Instancias de hardware y red
Adafruit_SSD1306 display(128, 64, &Wire, OLED_RST);
SX1262 radio = new Module(LORA_NSS, LORA_DIO1, LORA_RESET, LORA_BUSY);

WiFiClientSecure netClient;
PubSubClient mqttClient(netClient);

volatile bool packetReceived = false;

#if defined(ESP8266) || defined(ESP32)
ICACHE_RAM_ATTR
#endif
void setFlag(void) { packetReceived = true; }

double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const double R = 6371000.0;
  double dLat = (lat2 - lat1) * DEG_TO_RAD;
  double dLon = (lon2 - lon1) * DEG_TO_RAD;
  double a = sin(dLat / 2.0) * sin(dLat / 2.0) +
             cos(lat1 * DEG_TO_RAD) * cos(lat2 * DEG_TO_RAD) * sin(dLon / 2.0) *
                 sin(dLon / 2.0);
  double c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a));
  return R * c;
}

int batteryMvToPct(uint16_t mv) {
  if (mv >= 4200)
    return 100;
  if (mv <= 3300)
    return 0;
  return (int)((mv - 3300) * 100 / (4200 - 3300));
}

// ==========================================
// 4. GESTIÓN DEL DISPLAY OLED
// ==========================================
void updateOLED(const char *status, const MinimalCollarPacket *pkt = nullptr,
                float dist = 0, float rssi = 0, uint16_t gap = 0) {
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);

  // Fila 0: Estado de conexiones WiFi y MQTT
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.printf("WiFi:%s | MQTT:%s", WiFi.isConnected() ? "OK" : "NO",
                 mqttClient.connected() ? "OK" : "NO");
  display.drawLine(0, 9, 128, 9, SSD1306_WHITE);

  if (pkt != nullptr) {
    bool fix = (pkt->gps_flags & GPS_FLAG_FIX_MASK);
    uint8_t sats = (pkt->gps_flags & GPS_FLAG_SATS_MASK);

    // Fila 1: Identificador y secuencia recibida
    display.setCursor(0, 13);
    display.printf("ID:0x%04X #%u", pkt->collar_id, pkt->seq);
    if (gap > 0) {
      display.printf(" (-%u)",
                     gap); // Muestra paquetes perdidos en el último salto
    }

    // Fila 2: Fix y distancia calculada a casa
    display.setCursor(0, 24);
    if (fix) {
      display.printf("Fix:SI (%uS) Dist:%0.0fm", sats, dist);
      display.setCursor(0, 35);
      display.printf("%.5f, %.5f", pkt->lat_scaled / 10000000.0,
                     pkt->lon_scaled / 10000000.0);
    } else {
      display.printf("Fix:NO (%u Sats)", sats);
      display.setCursor(0, 35);
      display.print("Buscando satelites...");
    }

    // Fila 4: Batería
    display.setCursor(0, 46);
    display.printf("Bat:%u%% (%umV)", batteryMvToPct(pkt->battery_mv),
                   pkt->battery_mv);

    // Fila 5: Métricas de RF y paquetes recibidos vs perdidos
    display.setCursor(0, 56);
    display.printf("R:%.0fdB RX:%lu L:%lu", rssi, totalPacketsRx,
                   totalPacketsLost);
  } else {
    display.setCursor(0, 22);
    display.setTextSize(1);
    display.print(status);
    display.setCursor(0, 38);
    display.printf("Collares activos: %u", (unsigned int)collarConfigs.size());
    display.setCursor(0, 52);
    display.printf("RX:%lu | Perdidos:%lu", totalPacketsRx, totalPacketsLost);
  }

  display.display();
}

// ==========================================
// 5. MQTT: CALLBACK MULTICOLLAR Y CONEXIÓN
// ==========================================
void handleMqttCallback(char *topic, byte *payload, unsigned int length) {
  String message;
  for (unsigned int i = 0; i < length; i++)
    message += (char)payload[i];
  Serial.printf("[MQTT RX] Topico: %s | Msg: %s\n", topic, message.c_str());

  String topStr = String(topic);
  int firstSlash = topStr.indexOf('/');
  int secondSlash = topStr.indexOf('/', firstSlash + 1);

  if (firstSlash != -1 && secondSlash != -1 && topStr.endsWith("/config")) {
    String deviceID = topStr.substring(firstSlash + 1, secondSlash);

    StaticJsonDocument<256> doc;
    if (deserializeJson(doc, message) == DeserializationError::Ok) {
      CollarLimits limits;
      if (collarConfigs.find(deviceID) != collarConfigs.end()) {
        limits = collarConfigs[deviceID];
      }

      if (doc.containsKey("max_dist_m"))
        limits.max_dist_m = doc["max_dist_m"];
      if (doc.containsKey("min_bat_pct"))
        limits.min_bat_pct = doc["min_bat_pct"];
      if (doc.containsKey("require_gps_fix"))
        limits.require_gps_fix = doc["require_gps_fix"];

      collarConfigs[deviceID] = limits;

      Serial.printf("⚙️ [CONFIG GUARDADA] ID: %s | MaxDist: %.1fm | MinBat: "
                    "%d%% | ReqFix: %d\n",
                    deviceID.c_str(), limits.max_dist_m, limits.min_bat_pct,
                    limits.require_gps_fix);
      updateOLED("Config actualizada");
    }
  }
}

void reconnectMQTT() {
  while (!mqttClient.connected()) {
    Serial.print("[MQTT] Conectando a HiveMQ Cloud... ");
    String clientId = "ESP32Base-" + String(random(0xffff), HEX);
    if (mqttClient.connect(clientId.c_str(), MQTT_USER, MQTT_PASS)) {
      Serial.println("¡CONECTADO CON ÉXITO!");

      mqttClient.subscribe("mascotas/+/config", 1);
      mqttClient.publish("mascotas/base_station/status",
                         "{\"status\":\"online\"}", true);

      // Refrescar OLED inmediatamente para mostrar WiFi:OK | MQTT:OK
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
// 6. SETUP & LOOP
// ==========================================
void setup() {
  Serial.begin(115200);
  delay(1000);

  // 1. Encender periféricos (OLED y LoRa)
  pinMode(VEXT_PIN, OUTPUT);
  digitalWrite(VEXT_PIN, LOW);
  delay(100);

  // 2. Iniciar pantalla OLED
  Wire.begin(OLED_SDA, OLED_SCL);
  if (display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(10, 25);
    display.println("Iniciando Base...");
    display.display();
  }

  // 3. Iniciar módem LoRa SX1262
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

  // 4. Iniciar Wi-Fi y MQTT con TLS
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
  mqttClient.setCallback(handleMqttCallback);
  mqttClient.setBufferSize(512);

  updateOLED("Conectando MQTT...");
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    if (!mqttClient.connected()) {
      reconnectMQTT();
    }
    mqttClient.loop();
  }

  // Procesar tramas LoRa recibidas
  if (packetReceived) {
    packetReceived = false;

    MinimalCollarPacket packet;
    int state = radio.readData((uint8_t *)&packet, sizeof(MinimalCollarPacket));

    if (state == RADIOLIB_ERR_NONE) {
      totalPacketsRx++;
      float rssi = radio.getRSSI();
      float snr = radio.getSNR();

      char devIdStr[20];
      snprintf(devIdStr, sizeof(devIdStr), "COLLAR_%04X", packet.collar_id);
      String currentDevID = String(devIdStr);

      // Detección de saltos de secuencia (pérdida de paquetes)
      uint16_t lostInThisGap = 0;
      if (lastCollarSeq.find(currentDevID) != lastCollarSeq.end()) {
        uint16_t prevSeq = lastCollarSeq[currentDevID];
        if (packet.seq > prevSeq + 1) {
          lostInThisGap = packet.seq - prevSeq - 1;
          totalPacketsLost += lostInThisGap;
        } else if (prevSeq > 65000 && packet.seq < 500) {
          // Compensación por desbordamiento uint16 (65535 -> 1)
          lostInThisGap = (65535 - prevSeq) + packet.seq - 1;
          totalPacketsLost += lostInThisGap;
        }
      }
      lastCollarSeq[currentDevID] = packet.seq;

      bool hasFix = (packet.gps_flags & GPS_FLAG_FIX_MASK);
      uint8_t sats = (packet.gps_flags & GPS_FLAG_SATS_MASK);
      double lat = packet.lat_scaled / 10000000.0;
      double lon = packet.lon_scaled / 10000000.0;
      double distM =
          hasFix ? haversineDistance(HOME_LAT, HOME_LON, lat, lon) : 0.0;
      int batPct = batteryMvToPct(packet.battery_mv);

      Serial.printf("\n[LORA RX #%lu] %s (#%u) | Perdidos: %u (Tot: %lu) | "
                    "Dist: %.1fm | Bat: %d%% | RSSI: %.1fdBm\n",
                    totalPacketsRx, devIdStr, packet.seq, lostInThisGap,
                    totalPacketsLost, distM, batPct, rssi);

      CollarLimits limits;
      if (collarConfigs.find(currentDevID) != collarConfigs.end()) {
        limits = collarConfigs[currentDevID];
      }

      // Construcción del JSON de telemetría hacia HiveMQ
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
      radioObj["distance_home_m"] = round(distM * 10.0) / 10.0;
      radioObj["packets_lost_gap"] = lostInThisGap;

      char jsonBuffer[512];
      serializeJson(doc, jsonBuffer);

      String telemTopic = "mascotas/" + currentDevID + "/telemetria";
      mqttClient.publish(telemTopic.c_str(), jsonBuffer);

      // Evaluación de geovalla local
      if (hasFix && distM > limits.max_dist_m) {
        StaticJsonDocument<256> alertDoc;
        alertDoc["device_id"] = currentDevID;
        alertDoc["type"] = "GEOFENCE_BREACH";
        alertDoc["severity"] = "CRITICAL";
        alertDoc["value"] = distM;
        char alertBuf[256];
        serializeJson(alertDoc, alertBuf);
        mqttClient.publish(("mascotas/" + currentDevID + "/alertas").c_str(),
                           alertBuf);
      }

      // Evaluación de batería local
      if (batPct <= limits.min_bat_pct) {
        StaticJsonDocument<256> alertDoc;
        alertDoc["device_id"] = currentDevID;
        alertDoc["type"] = "LOW_BATTERY";
        alertDoc["severity"] = "WARNING";
        alertDoc["value"] = batPct;
        char alertBuf[256];
        serializeJson(alertDoc, alertBuf);
        mqttClient.publish(("mascotas/" + currentDevID + "/alertas").c_str(),
                           alertBuf);
      }

      // Actualizar pantalla con el paquete actual y la métrica de pérdidas
      updateOLED(nullptr, &packet, distM, rssi, lostInThisGap);
    }

    radio.startReceive();
  }
}
