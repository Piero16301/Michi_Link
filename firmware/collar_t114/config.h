#ifndef CONFIG_H
#define CONFIG_H

#include <stdint.h>

// ==========================================
// IDENTIFICACIÓN DEL NODO Y TEMPORIZACIÓN
// ==========================================
constexpr uint64_t COLLAR_ID = 0x9E2B4A1F8C3D2E5AULL;

// Configurado a 75 segundos (1m 15s) para asegurar > 3 días holgados (> 75 horas).
// Si requieres 60 segundos exactos, cambia a: 60000 (brinda ~71.4h útiles / 79h totales).
constexpr uint32_t INTERVAL_MS = 60000;

// ==========================================
// PARÁMETROS DE RADIOENLACE LORA SX1262
// ==========================================
constexpr float LORA_FREQ = 915.0;          // MHz (Banda ISM 915)
constexpr float LORA_BANDWIDTH_KHZ = 125.0; // kHz
constexpr uint8_t LORA_SPREADING_FACT = 7;  // SF7
constexpr uint8_t LORA_CODING_RATE = 5;     // CR 4/5
constexpr int8_t LORA_TX_POWER_DBM = 22;    // Potencia máxima (+22 dBm)

// ==========================================
// PINES DE HARDWARE HELTEC T114
// ==========================================
// Transceptor LoRa SX1262
constexpr uint8_t PIN_LORA_NSS = 24;
constexpr uint8_t PIN_LORA_DIO1 = 20;
constexpr uint8_t PIN_LORA_RESET = 18;
constexpr uint8_t PIN_LORA_BUSY = 17;

// GPS Quectel L76K
constexpr uint8_t GPS_POWER_PIN = 21; // Vext (HIGH para habilitar)
constexpr uint8_t GPS_RESET_PIN = 38; // Reset físico por hardware
constexpr uint32_t GPS_BAUDRATE = 9600;

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

#endif // CONFIG_H
