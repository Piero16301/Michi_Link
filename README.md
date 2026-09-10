# Michi Link
Directo, cercano y muy natural en español. Conecta el término cariñoso ("michi") con el concepto del enlace de radiofrecuencia (RF Link) punto a punto y la conexión constante hacia la nube mediante MQTT.

## Diagrama de Arquitectura Global

```mermaid
flowchart TB
    %% CAPA FÍSICA / IOT
    subgraph IOT ["📡 CAPA IOT / HARDWARE"]
        direction LR
        subgraph COLLAR ["COLLAR (Gato)"]
            direction TB
            C1["nRF52840 + GPS"]
            C2["Envía paquete LoRa P2P\n(915 MHz)"]
            C1 --> C2
        end

        subgraph BASE ["ESTACIÓN BASE (Tu Casa)"]
            direction TB
            B1["Heltec WiFi LoRa 32 V3\n(ESP32-S3)"]
            B2["Recibe LoRa, desencripta y\ncalcula distancia / RSSI"]
            B3["Conectado al WiFi de casa"]
            B1 --> B2 --> B3
        end

        C2 -->|"Radiofrecuencia LoRa\n(~200m - 1km)"| B1
    end

    %% BROKER MQTT
    subgraph BROKER_ZONE ["☁️ MENSAJERÍA CLOUD"]
        BROKER["BROKER MQTT (HiveMQ)\nTópico: mascotas/gato01/telemetria"]
    end

    %% BACKEND GCP
    subgraph BACKEND ["⚙️ BACKEND (GCP e2-micro)"]
        direction TB
        BE_GO["Suscriptor MQTT Continuo (Go)\n• Ingesta y validación de telemetría\n• Motor de Geofencing (si dist > 150m)"]
    end

    %% PERSISTENCIA Y NOTIFICACIONES
    subgraph GOOGLE_SERVICES ["🔥 FIREBASE / GOOGLE CLOUD"]
        direction LR
        DB[("Cloud Firestore\nHistórico y última posición")]
        FCM["Firebase Notifications (FCM)\nPush Notifications de Alerta"]
    end

    %% CLIENTES FINALES
    subgraph CLIENTES ["👥 CLIENTES FINALES (Ecosistema Flutter & WearOS)"]
        direction LR
        CLI_APP["📱 App Móvil\n(Flutter + Google Maps)\n• Stream en vivo (Firestore)\n• Notificaciones Push"]
        CLI_WEB["💻 Dashboard Web\n(Flutter + OpenStreetMap)\n• Monitoreo en mapa en tiempo real"]
        CLI_WEAR["⌚ App WearOS\n(Smartwatch + Google Maps)\n• Mapa, telemetría rápida y alertas"]
    end

    %% CONEXIONES ENTRE CAPAS
    B3 -->|"Publica JSON vía MQTT/TLS"| BROKER
    BROKER -->|"Suscripción MQTT"| BE_GO

    BE_GO -->|"Escribe última posición / historial"| DB
    BE_GO -->|"Dispara alerta si dist > 150m"| FCM

    DB -.->|"Stream reactivo en tiempo real"| CLI_APP
    DB -.->|"Stream / Consulta de datos"| CLI_WEB
    DB -.->|"Sincronización de estado"| CLI_WEAR

    FCM -->|"Push Notifications"| CLI_APP
    FCM -->|"Notificaciones al reloj"| CLI_WEAR
```

## Formato en el Aire: Estructura Binaria en C++ (Collar)

```cpp
// Estructura binaria compacta: 17 BYTES EN TOTAL
struct __attribute__((packed)) MinimalCollarPacket {
    uint16_t collar_id;   // 2 B: ID estático aleatorio
    uint16_t seq;         // 2 B: Secuencia incremental (0 a 65535)
    int32_t  lat_scaled;  // 4 B: Latitud * 10,000,000 (~1 cm precisión)
    int32_t  lon_scaled;  // 4 B: Longitud * 10,000,000
    int16_t  alt_m;       // 2 B: Altitud entera en metros (-32,768m a +32,767m)
    uint16_t battery_mv;  // 2 B: Voltaje en milivoltios (ej. 4150 mV)
    uint8_t  gps_flags;   // 1 B: Bit 7 = GPS Fix (1/0), Bits 0..6 = Satélites
};
```

## Envío de datos ESP32-S3 a MQTT

### Estructura de Payload JSON

```json
{
    "device_id": "gato_01",
    "timestamp": 1772635200,
    "seq": 142,
    "coords": {
        "lat": -12.046374,
        "lon": -77.042793,
        "alt_m": 2.5
    },
    "status": {
        "gps_fix": true,
        "sats": 8,
        "battery_v": 3.98,
        "battery_pct": 88
    },
    "radio": {
        "rssi": -68,
        "snr": 9.5,
        "distance_home_m": 48.2
    }
}
```

### Base de datos Cloud Firestore

Consumo 100% dentro de la Capa Gratuita (Spark Plan):

- Transmitiendo 1 paquete cada 60 segundos:
  - 60 paquetes/hora × 24 = 1,440 escrituras al día.
  - La capa gratuita de Firestore incluye 20,000 escrituras al día (solo usarás el 7.2% del límite gratuito).
  - El peso de 10,000 puntos en 7 días es de unos ~3 a 4 MB (la capa gratuita incluye 1 GB de almacenamiento).

### Estructura de Datos Optimizada en Firestore

```text
collars/ (Colección)
  └── collar_01 (Documento: Último estado en vivo)
        ├── device_id: "gato_01"
        ├── last_seen: Timestamp
        ├── seq: number
        ├── coords: { lat: -12.0463, lon: -77.0427, alt: 2.5 }
        ├── status: { battery_v: 3.98, battery_pct: 88, gps_fix: true }
        ├── radio: { rssi: -68, snr: 9.5, distance_m: 48.2 }
        │
        └── history/ (Subcolección: Registro de puntos)
              └── auto_id_document
                    ├── timestamp: Timestamp
                    ├── expireAt: Timestamp  <-- [TTL activo aquí (ahora + 7 días)]
                    ├── coords: { lat: -12.0463, lon: -77.0427, alt: 2.5 }
                    ├── status: { battery_v: 3.98, gps_fix: true }
                    └── radio: { rssi: -68, distance_m: 48.2 }
```

### Tipos de Datos para el Historial en Firestore

| Campo | Tipo de Dato en Go / Firestore | Descripción |
| :--- | :--- | :--- |
| `timestamp` | `time.Time` → `Timestamp` | Fecha y hora exacta de captura del paquete. |
| `expire_at` | `time.Time` → `Timestamp` | Objetivo del TTL: timestamp + 7 días. |
| `seq` | `uint32` → `Integer` | Contador incremental del paquete. |
| `coords.lat` | `float64` → `Number (Float)` | Latitud decimal. |
| `coords.lon` | `float64` → `Number (Float)` | Longitud decimal. |
| `coords.alt_m` | `float64` → `Number (Float)` | Altura sobre el nivel del mar en metros. |
| `status.gps_fix` | `bool` → `Boolean` | `true` si hay satélites válidos, `false` para modo baliza. |
| `status.sats` | `int` → `Integer` | Cantidad de satélites enganchados. |
| `status.bat_v` | `float64` → `Number (Float)` | Voltaje medido (ej. 3.98). |
| `status.bat_pct` | `int` → `Integer` | Porcentaje estimado (0–100%). |
| `radio.rssi` | `int` → `Integer` | Potencia RF recibida (ej. -68). |
| `radio.snr` | `float64` → `Number (Float)` | Relación señal/ruido en dB (ej. 9.5). |
| `radio.dist_m` | `float64` → `Number (Float)` | Distancia calculada a casa por Haversine. |

## Resumen del Flujo de Datos

```mermaid
flowchart TD
    %% ETAPA 1: SENSORES
    subgraph E1 ["1. CAPTURA EN EL COLLAR"]
        direction LR
        S_GPS["Sensor GPS\n(NMEA: Latitud, Longitud, Altitud)"]
        S_BAT["Sensor ADC\n(Voltaje de Batería)"]
    end

    %% ETAPA 2: PAQUETE BINARIO
    subgraph E2 ["2. EMPAQUETADO BINARIO LORA (17 Bytes en el aire - 915 MHz)"]
        direction LR
        P_ID["Identificación y Secuencia\n• collar_id: 2B\n• seq: 2B"]
        P_GEO["Posicionamiento Global\n• lat: 4B\n• lon: 4B\n• alt_m: 2B"]
        P_EST["Energía y Flags\n• vbat_mv: 2B\n• flags: 1B"]
    end

    %% ETAPA 3: RECEPTOR BASE
    subgraph E3 ["3. ESTACIÓN BASE ESP32-S3 (Tu Casa)"]
        direction LR
        B_RX["Receptor LoRa 915 MHz\nDesempaqueta binario"]
        B_ENRICH["Enriquecimiento de Telemetría:\n• Timestamp NTP de internet\n• Señal RF (RSSI y SNR)\n• Distancia calculada por Haversine"]
        B_RX --> B_ENRICH
    end

    %% ETAPA 4: BROKER MQTT
    subgraph E4 ["4. MENSAJERÍA MQTT (Cloud)"]
        direction LR
        M_JSON["Generador JSON\nPayload estructurado"]
        M_BROKER["Broker HiveMQ\nTópico: mascotas/collar_01/telemetria"]
        M_JSON -->|"Publica sobre TCP/TLS"| M_BROKER
    end

    %% ETAPA 5: BACKEND Y BASE DE DATOS
    subgraph E5 ["5. PROCESAMIENTO & PERSISTENCIA"]
        direction TB
        G_SUB["Worker en Go (GCP e2-micro)\nSuscriptor MQTT continuo"]
        
        subgraph E5_DB ["Cloud Firestore"]
            direction LR
            DB_DOC[("Documento Vivo\nÚltimo estado en tiempo real")]
            DB_HIST[("Subcolección History\nRegistro histórico con TTL de 7 días")]
        end
        
        G_SUB --> DB_DOC
        G_SUB --> DB_HIST
    end

    %% FLUJO ENTRE ETAPAS
    S_GPS --> P_GEO
    S_BAT --> P_EST
    P_GEO -->|"Radiofrecuencia LoRa P2P (~200m - 1km)"| B_RX
    B_ENRICH --> M_JSON
    M_BROKER -->|"Consumo continuo"| G_SUB
```

## Tópicos a MQTT a Usar

| Tópico | Dirección del Flujo | Frecuencia / Cuándo se usa | Función Principal |
| :--- | :--- | :--- | :--- |
| `mascotas/{pet_id}/telemetria` | Base (Casa) → Broker | Periódica (ej. cada 60s) | Telemetría habitual: Envía el JSON completo con coordenadas GPS, altitud, satélites, voltaje/porcentaje de batería, RSSI, SNR y distancia a casa. |
| `mascotas/{pet_id}/alertas` | Base (Casa) → Broker | Inmediata (por evento) | Eventos críticos: Disparado al instante sin esperar el ciclo normal si ocurre algo urgente (salida de la zona segura/geovalla >150 m, batería crítica <15%, o activación de modo radiobaliza por pérdida de señal GPS). |
| `mascotas/{pet_id}/status` | Base (Casa) → Broker | Al conectar / Al caerse | Presencia y disponibilidad (LWT - Last Will & Testament): Publica `online` cuando la base en casa se conecta y `offline` automáticamente si la base pierde conexión a internet o energía. |
| `mascotas/{pet_id}/comandos` | App / Web → Base | Bajo demanda | (A futuro): Envío de instrucciones remotas hacia la base o collar (por ejemplo, activar un "Modo Búsqueda" para que la base ordene al collar transmitir cada 15 segundos en vez de cada 60). |

## Flujo de Ejecución en el ESP32

```mermaid
flowchart TD
    %% RECEPCIÓN
    RX(["📦 Paquete LoRa de 17B Recibido\n(915 MHz)"])

    %% ETAPA 1: DESEMPAQUETAR Y CALCULAR
    subgraph E1 ["1. DESEMPAQUETAR Y CALCULAR"]
        direction TB
        CALC["Procesamiento de Métricas:\n• Distancia a casa (Haversine)\n• Estado y nivel de batería\n• Métricas RF (RSSI y SNR)"]
    end

    %% ETAPA 2: PUBLICAR TELEMETRÍA
    subgraph E2 ["2. PUBLICAR TELEMETRÍA (SIEMPRE SE ENVÍA)"]
        direction LR
        PUB_TEL["Publicar Telemetría Habitual\n(Payload JSON completo)"]
        TOP_TEL["☁️ Tópico:\nmascotas/collar_01/telemetria"]
        PUB_TEL --> TOP_TEL
    end

    %% ETAPA 3: EVALUAR REGLAS
    subgraph E3 ["3. EVALUAR REGLAS EN BASE"]
        direction TB
        CHECK{"¿Cumple Condición Crítica?\n• ¿Distancia > 150m?\n• ¿Batería < 15%?\n• ¿GPS perdió el fix?"}
    end

    %% ETAPA 4: PUBLICAR ALERTA
    subgraph E4 ["4. DISPARO DE ALERTAS (POR EVENTO)"]
        direction LR
        PUB_ALT["Publicar Alerta Inmediata\n(Sin esperar ciclo habitual)"]
        TOP_ALT["🚨 Tópico:\nmascotas/collar_01/alertas"]
        PUB_ALT --> TOP_ALT
    end

    FIN(["Fin del Ciclo\n(Ignorar y esperar próximo paquete)"])

    %% CONEXIONES DEL FLUJO
    RX --> CALC
    CALC --> PUB_TEL
    PUB_TEL --> CHECK

    CHECK -->|"SÍ (Evento crítico)"| PUB_ALT
    CHECK -->|"NO (Valores normales)"| FIN
    PUB_ALT --> FIN
```
