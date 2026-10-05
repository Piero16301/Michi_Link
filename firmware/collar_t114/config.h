#ifndef CONFIG_H
#define CONFIG_H

#include <stdint.h>

// ==========================================
// IDENTIFICACIÓN DEL NODO Y TEMPORIZACIÓN
// ==========================================
constexpr uint64_t COLLAR_ID = 0x9E2B4A1F8C3D2E5AULL;
constexpr uint32_t INTERVAL_MS = 60000; // 60 segundos de intervalo entre envíos

// ==========================================
// PARÁMETROS DE RADIOENLACE LORA SX1262
// ==========================================
constexpr float LORA_FREQ = 915.0;          // MHz (Banda ISM 915)
constexpr float LORA_BANDWIDTH_KHZ = 125.0; // kHz
constexpr uint8_t LORA_SPREADING_FACT = 7;  // SF7
constexpr uint8_t LORA_CODING_RATE = 5;     // CR 4/5
constexpr int8_t LORA_TX_POWER_DBM = 22;    // Potencia máxima (+22 dBm)
constexpr float LORA_TCXO_VOLTAGE = 1.8f;   // TCXO del SX1262 en el T114 (DIO3)

// ==========================================
// PINES DE HARDWARE HELTEC T114
// ==========================================
// Transceptor LoRa SX1262
constexpr uint8_t PIN_LORA_NSS = 24;
constexpr uint8_t PIN_LORA_DIO1 = 20;
constexpr uint8_t PIN_LORA_RESET = 18;
constexpr uint8_t PIN_LORA_BUSY = 17;

// GPS Quectel L76K
constexpr uint8_t GPS_POWER_PIN = 21; // Riel Vext (HIGH para habilitar)
constexpr uint8_t GPS_RESET_PIN = 38; // Reset físico por hardware (activo LOW, > 100 ms)
constexpr uint32_t GPS_BAUDRATE = 9600;

// Control de energía L76K (según variant.h de Meshtastic para el T114)
constexpr uint8_t GPS_STANDBY_PIN = 34; // P1.02: LOW = standby, HIGH = activo
constexpr uint8_t GPS_UART_TX_PIN = 37; // P1.05: nRF -> GPS (debe coincidir con PIN_SERIAL2_TX)
constexpr uint8_t GPS_UART_RX_PIN = 39; // P1.07: GPS -> nRF (debe coincidir con PIN_SERIAL2_RX)

// Ventanas de adquisición GNSS
constexpr uint32_t GPS_BOOT_TIMEOUT_MS = 90000;      // Cold start inicial
constexpr uint32_t GPS_BOOT_SETTLE_MS = 30000;       // Rastreo extra tras 1er fix (más efemérides)
// Ventana normal: sale en cuanto hay fix. Con señal débil (interiores/urbano) la
// readquisición tras 60 s de standby puede tardar más, ampliamos a 25 s.
constexpr uint32_t GPS_WINDOW_MS = 25000;
constexpr uint32_t GPS_REFRESH_WINDOW_MS = 75000;    // Ventana larga para recuperar efemérides
constexpr uint8_t GPS_MISSES_BEFORE_REFRESH = 2;     // Fallos seguidos antes de ventana larga (reducido)
constexpr uint16_t GPS_REFRESH_COOLDOWN_MIN = 5;     // Ciclos mínimos entre ventanas largas (reducido)
constexpr uint16_t GPS_REFRESH_COOLDOWN_MAX = 15;    // Backoff máximo en interiores (reducido)
constexpr uint16_t GPS_EPH_MAINT_CYCLES = 60;        // Mantenimiento cada ~1 h (reducido)
constexpr uint32_t GPS_EPH_MAINT_EXTRA_MS = 45000;   // 45 s extra para asegurar descarga completa
constexpr float GPS_MAX_HDOP = 10.0f;                // Umbral relajado para aceptar fixes en interiores

// Botón de usuario (despertar desde System OFF)
constexpr uint8_t USER_BUTTON_PIN = 42; // P1.10

// ==========================================
// MEDICIÓN DE BATERÍA
// ==========================================
#ifndef PIN_BAT_ADC
#define PIN_BAT_ADC 4
#endif

#ifndef PIN_BAT_ADC_CTL
#define PIN_BAT_ADC_CTL 6
#endif

#ifdef BAT_AMPLIFY
#undef BAT_AMPLIFY
#endif
#define BAT_AMPLIFY 5.10f

// Corte de protección de la celda LiPo (3 lecturas seguidas por debajo)
constexpr uint16_t BAT_CRITICAL_MV = 3350;

#endif // CONFIG_H
