#ifndef PACKET_H
#define PACKET_H

#include <stdint.h>

// Máscaras de bits para el campo gps_flags
#define GPS_FLAG_FIX_MASK 0x80  // Bit 7: Fix válido (1) o no válido (0)
#define GPS_FLAG_SATS_MASK 0x7F // Bits 0..6: Cantidad de satélites visibles

// Estructura binaria compacta de exactamente 17 bytes transmitida por LoRa
struct __attribute__((packed)) MinimalCollarPacket {
  uint16_t
      collar_id; // 2 bytes: Identificador único del dispositivo (ej. 0x9E2B)
  uint16_t seq;  // 2 bytes: Contador secuencial incremental
  int32_t lat_scaled;  // 4 bytes: Latitud escalada (* 10,000,000)
  int32_t lon_scaled;  // 4 bytes: Longitud escalada (* 10,000,000)
  int16_t alt_m;       // 2 bytes: Altitud sobre el nivel del mar en metros
  uint16_t battery_mv; // 2 bytes: Tensión de batería en milivoltios
  uint8_t gps_flags;   // 1 byte:  Bit 7 = GPS Fix | Bits 0..6 = Satélites
};

#endif // PACKET_H
