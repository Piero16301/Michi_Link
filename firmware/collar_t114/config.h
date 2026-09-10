#ifndef CONFIG_H
#define CONFIG_H

#include <stdint.h>

// ==========================================
// IDENTIFICACIÓN DEL NODO Y TEMPORIZACIÓN
// ==========================================
constexpr uint16_t COLLAR_ID   = 0x9E2B;
constexpr uint32_t INTERVAL_MS = 10000; // Intervalo entre transmisiones (ms)

// ==========================================
// PARÁMETROS DE RADIOENLACE LORA SX1262
// ==========================================
constexpr float   LORA_FREQ           = 915.0; // MHz (Banda ISM 915)
constexpr float   LORA_BANDWIDTH_KHZ  = 125.0; // kHz
constexpr uint8_t LORA_SPREADING_FACT = 7;     // SF7
constexpr uint8_t LORA_CODING_RATE    = 5;     // CR 4/5
constexpr int8_t  LORA_TX_POWER_DBM   = 22;    // Potencia máxima (+22 dBm)

// ==========================================
// PINES DE HARDWARE HELTEC T114 (board-config.h)
// ==========================================
// Transceptor LoRa SX1262
constexpr uint8_t PIN_LORA_NSS   = 24;
constexpr uint8_t PIN_LORA_DIO1  = 20;
constexpr uint8_t PIN_LORA_RESET = 18;
constexpr uint8_t PIN_LORA_BUSY  = 17;

// GPS Quectel L76K
constexpr uint8_t  GPS_POWER_PIN  = 21; // Vext (HIGH para habilitar)
constexpr uint8_t  GPS_RESET_PIN  = 38; // Reset físico por hardware
constexpr uint32_t GPS_BAUDRATE   = 9600;

// ==========================================
// MEDICIÓN DE BATERÍA (Nativo de variant.h)
// ==========================================
// Se usan macros de respaldo para evitar colisiones con el núcleo Heltec
#ifndef PIN_BAT_ADC
#define PIN_BAT_ADC     4
#endif

#ifndef PIN_BAT_ADC_CTL
#define PIN_BAT_ADC_CTL 6
#endif

#ifndef BAT_AMPLIFY
#define BAT_AMPLIFY     4.9f
#endif

#endif // CONFIG_H
