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

// Umbrales de enlace y batería
const int LORA_WEAK_RSSI_THRESHOLD = -115;   // dBm
const int LORA_NORMAL_RSSI_THRESHOLD = -105; // dBm (histeresis)
const int BATTERY_CRITICAL_PCT = 10;         // %

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

// ==========================================
// 3. ESTRUCTURAS, CONFIGURACIÓN Y ESTADOS
// ==========================================
struct CollarLimits {
  float max_dist_m = 500.0;
  int min_bat_pct = 20;
  bool require_gps_fix = true;
};

// Máquina de estados para evitar spam y permitir alertas de recuperación
struct CollarAlertState {
  bool inGeofenceBreach = false;
  bool inLowBattery = false;
  bool inCriticalBat = false;
  bool inNoGpsFix = false;
  bool inWeakSignal = false;
  bool initialized = false;
};

std::map<String, CollarLimits> collarConfigs;
std::map<String, CollarAlertState> collarAlertStates;
std::map<String, uint16_t> lastCollarSeq;

uint32_t totalPacketsRx = 0;
uint32_t totalPacketsLost = 0;

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

// Emisión normalizada de alertas hacia MQTT
void publishAlert(const String &devID, const char *type, const char *severity,
                  float value) {
  StaticJsonDocument<256> doc;
  doc["device_id"] = devID;
  doc["type"] = type;
  doc["severity"] = severity;
  doc["value"] = round(value * 10.0) / 10.0;

  char buffer[256];
  serializeJson(doc, buffer);
  String topic = "mascotas/" + devID + "/alertas";
  mqttClient.publish(topic.c_str(), buffer);

  Serial.printf("🚨 [ALERTA GENERADA] %s -> [%s] (%s): %.1f\n", devID.c_str(),
                type, severity, value);
}

// ==========================================
// 4. MOTOR DE EVALUACIÓN DE ALERTAS
// ==========================================
void evaluateAlerts(const String &devID, bool hasFix, uint8_t sats,
                    double distM, int batPct, float rssi,
                    const CollarLimits &limits) {
  CollarAlertState &state = collarAlertStates[devID];

  // En el primer paquete, inicializamos estado para evitar falsos positivos
  if (!state.initialized) {
    state.inGeofenceBreach = (hasFix && distM > limits.max_dist_m);
    state.inCriticalBat = (batPct <= BATTERY_CRITICAL_PCT);
    state.inLowBattery = (batPct <= limits.min_bat_pct && !state.inCriticalBat);
    state.inNoGpsFix = (!hasFix && limits.require_gps_fix);
    state.inWeakSignal = (rssi < LORA_WEAK_RSSI_THRESHOLD);
    state.initialized = true;
    return;
  }

  // --- 1. GEOVALLA ---
  if (hasFix) {
    if (distM > limits.max_dist_m && !state.inGeofenceBreach) {
      state.inGeofenceBreach = true;
      publishAlert(devID, "GEOFENCE_BREACH", "CRITICAL", distM);
    } else if (distM <= limits.max_dist_m && state.inGeofenceBreach) {
      state.inGeofenceBreach = false;
      publishAlert(devID, "GEOFENCE_RESTORED", "INFO", distM);
    }
  }

  // --- 2. BATERÍA ---
  if (batPct <= BATTERY_CRITICAL_PCT) {
    if (!state.inCriticalBat) {
      state.inCriticalBat = true;
      state.inLowBattery = true;
      publishAlert(devID, "BATTERY_CRITICAL", "CRITICAL", batPct);
    }
  } else if (batPct <= limits.min_bat_pct) {
    state.inCriticalBat = false;
    if (!state.inLowBattery) {
      state.inLowBattery = true;
      publishAlert(devID, "LOW_BATTERY", "WARNING", batPct);
    }
  } else {
    // Recuperación a nivel normal
    if (state.inLowBattery || state.inCriticalBat) {
      state.inLowBattery = false;
      state.inCriticalBat = false;
      publishAlert(devID, "BATTERY_NORMAL", "INFO", batPct);
    }
  }

  // --- 3. SATÉLITES (GPS) ---
  if (limits.require_gps_fix) {
    if (!hasFix && !state.inNoGpsFix) {
      state.inNoGpsFix = true;
      publishAlert(devID, "NO_GPS_FIX", "WARNING", 0);
    } else if (hasFix && state.inNoGpsFix) {
      state.inNoGpsFix = false;
      publishAlert(devID, "GPS_FIX_RESTORED", "INFO", sats);
    }
  }

  // --- 4. RADIOENLACE LORA ---
  if (rssi < LORA_WEAK_RSSI_THRESHOLD && !state.inWeakSignal) {
    state.inWeakSignal = true;
    publishAlert(devID, "WEAK_SIGNAL", "WARNING", rssi);
  } else if (rssi >= LORA_NORMAL_RSSI_THRESHOLD && state.inWeakSignal) {
    state.inWeakSignal = false;
    publishAlert(devID, "SIGNAL_NORMAL", "INFO", rssi);
  }
}

// ==========================================
// 5. GESTIÓN DEL DISPLAY OLED
// ==========================================
void updateOLED(const char *status, const MinimalCollarPacket *pkt = nullptr,
                float dist = 0, float rssi = 0, uint16_t gap = 0) {
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);

  display.setTextSize(1);
  display.setCursor(0, 0);
  display.printf("WiFi:%s | MQTT:%s", WiFi.isConnected() ? "OK" : "NO",
                 mqttClient.connected() ? "OK" : "NO");
  display.drawLine(0, 9, 128, 9, SSD1306_WHITE);

  if (pkt != nullptr) {
    bool fix = (pkt->gps_flags & GPS_FLAG_FIX_MASK);
    uint8_t sats = (pkt->gps_flags & GPS_FLAG_SATS_MASK);

    display.setCursor(0, 13);
    display.printf("ID:0x%04X #%u", pkt->collar_id, pkt->seq);
    if (gap > 0) {
      display.printf(" (-%u)", gap);
    }

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

    display.setCursor(0, 46);
    display.printf("Bat:%u%% (%umV)", batteryMvToPct(pkt->battery_mv),
                   pkt->battery_mv);

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
// 6. MQTT: CALLBACK Y CONEXIÓN
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
// 7. SETUP & LOOP
// ==========================================
void setup() {
  Serial.begin(115200);
  delay(1000);

  pinMode(VEXT_PIN, OUTPUT);
  digitalWrite(VEXT_PIN, LOW);
  delay(100);

  Wire.begin(OLED_SDA, OLED_SCL);
  if (display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(10, 25);
    display.println("Iniciando Base...");
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
      double distM =
          hasFix ? haversineDistance(HOME_LAT, HOME_LON, lat, lon) : 0.0;
      int batPct = batteryMvToPct(packet.battery_mv);

      Serial.printf("\n[LORA RX #%lu] %s (#%u) | Perdidos: %u | Dist: %.1fm | "
                    "Bat: %d%% | RSSI: %.1fdBm\n",
                    totalPacketsRx, devIdStr, packet.seq, lostInThisGap, distM,
                    batPct, rssi);

      CollarLimits limits;
      if (collarConfigs.find(currentDevID) != collarConfigs.end()) {
        limits = collarConfigs[currentDevID];
      }

      // Publicar Telemetría
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

      // Evaluación del catálogo completo de alertas
      evaluateAlerts(currentDevID, hasFix, sats, distM, batPct, rssi, limits);

      updateOLED(nullptr, &packet, distM, rssi, lostInThisGap);
    }

    radio.startReceive();
  }
}
