#ifndef PACKET_H
#define PACKET_H

#include <stdint.h>

// Máscaras de bits para el campo gps_flags
#define GPS_FLAG_FIX_MASK 0x80  // Bit 7: Fix válido (1) o no válido (0)
#define GPS_FLAG_SATS_MASK 0x7F // Bits 0..6: Cantidad de satélites visibles

// Estructura binaria compacta (23 bytes totales)
struct __attribute__((packed)) MinimalCollarPacket {
  uint64_t collar_id;  // 8 bytes: Identificador de 16 caracteres hex
  uint16_t seq;        // 2 bytes: Contador secuencial
  int32_t lat_scaled;  // 4 bytes: Latitud * 10,000,000
  int32_t lon_scaled;  // 4 bytes: Longitud * 10,000,000
  int16_t alt_m;       // 2 bytes: Altitud en metros
  uint16_t battery_mv; // 2 bytes: Batería en milivoltios
  uint8_t gps_flags;   // 1 byte:  Bit 7 Fix | Bits 0..6 Satélites
};

#endif // PACKET_H
