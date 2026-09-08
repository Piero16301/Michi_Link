package main

import (
	"time"

	"cloud.google.com/go/firestore"
)

// CoordsData Coordenadas geográficas
type CoordsData struct {
	Lat  float64 `json:"lat" firestore:"lat"`
	Lon  float64 `json:"lon" firestore:"lon"`
	AltM float64 `json:"alt_m" firestore:"alt_m"`
}

// StatusData Estado de sensores y batería
type StatusData struct {
	GpsFix     bool    `json:"gps_fix" firestore:"gps_fix"`
	Sats       int     `json:"sats" firestore:"sats"`
	BatteryV   float64 `json:"battery_v" firestore:"battery_v"`
	BatteryPct int     `json:"battery_pct" firestore:"battery_pct"`
}

// RadioData Métricas de radioenlace y distancia
type RadioData struct {
	RSSI          int     `json:"rssi" firestore:"rssi"`
	SNR           float64 `json:"snr" firestore:"snr"`
	DistanceHomeM float64 `json:"distance_home_m" firestore:"distance_home_m"`
}

// TelemetryPayload Payload recibido en 'mascotas/+/telemetria'
type TelemetryPayload struct {
	DeviceID string     `json:"device_id"`
	PetName  string     `json:"pet_name,omitempty"`
	Seq      uint32     `json:"seq"`
	Coords   CoordsData `json:"coords"`
	Status   StatusData `json:"status"`
	Radio    RadioData  `json:"radio"`
}

// HistoryRecord Documento tipado para cada punto en la sub colección 'history'
type HistoryRecord struct {
	Timestamp time.Time  `firestore:"timestamp"`
	ExpireAt  time.Time  `firestore:"expire_at"` // Campo para TTL en Firestore
	Seq       uint32     `firestore:"seq"`
	Coords    CoordsData `firestore:"coords"`
	Status    StatusData `firestore:"status"`
	Radio     RadioData  `firestore:"radio"`
}

// StatusPayload Payload recibido en 'mascotas/+/status'
type StatusPayload struct {
	DeviceID string `json:"device_id"`
	Status   string `json:"status"` // "online" | "offline"
}

// AlertPayload Payload recibido en 'mascotas/+/alertas'
type AlertPayload struct {
	DeviceID  string    `json:"device_id"`
	Type      string    `json:"type"`     // ej: "GEOFENCE_BREACH", "LOW_BATTERY", "NO_GPS_FIX"
	Message   string    `json:"message"`  // Detalle para humanos
	Severity  string    `json:"severity"` // "warning", "critical", "info"
	Value     float64   `json:"value,omitempty"`
	Timestamp time.Time `json:"timestamp"`
}

// LastAlertInfo Estructura tipada incrustada en el documento raíz para la vista rápida
type LastAlertInfo struct {
	Type      string    `firestore:"type"`
	Message   string    `firestore:"message"`
	Severity  string    `firestore:"severity"`
	Timestamp time.Time `firestore:"timestamp"`
}

// AlertRecord Documento tipado para la sub colección 'alerts'
type AlertRecord struct {
	Timestamp time.Time `firestore:"timestamp"`
	ExpireAt  time.Time `firestore:"expire_at"` // Campo para TTL en Firestore
	Type      string    `firestore:"type"`
	Message   string    `firestore:"message"`
	Severity  string    `firestore:"severity"`
	Value     float64   `firestore:"value,omitempty"`
}

type IngestService struct {
	firestoreClient *firestore.Client
	projectID       string
}

// CollarConfig Parámetros dinámicos de geo valla y energía
type CollarConfig struct {
	MaxDistanceM  float64 `firestore:"max_distance_m" json:"max_dist_m"`
	MinBatteryPct int     `firestore:"min_battery_pct" json:"min_bat_pct"`
	RequireGpsFix bool    `firestore:"require_gps_fix" json:"require_gps_fix"`
}
