package models

import "time"

// Constantes de Severidad estandarizadas en mayúsculas
const (
	SeverityCritical = "CRITICAL"
	SeverityWarning  = "WARNING"
	SeverityInfo     = "INFO"
)

type CoordsData struct {
	Lat  float64 `json:"lat" firestore:"lat"`
	Lon  float64 `json:"lon" firestore:"lon"`
	AltM float64 `json:"alt_m" firestore:"alt_m"`
}

type StatusData struct {
	GpsFix     bool    `json:"gps_fix" firestore:"gps_fix"`
	Sats       int     `json:"sats" firestore:"sats"`
	BatteryV   float64 `json:"battery_v" firestore:"battery_v"`
	BatteryPct int     `json:"battery_pct" firestore:"battery_pct"`
}

type RadioData struct {
	RSSI          int     `json:"rssi" firestore:"rssi"`
	SNR           float64 `json:"snr" firestore:"snr"`
	DistanceHomeM float64 `json:"distance_home_m" firestore:"distance_home_m"`
}

type TelemetryPayload struct {
	DeviceID string     `json:"device_id"`
	PetName  string     `json:"pet_name,omitempty"`
	Seq      uint32     `json:"seq"`
	Coords   CoordsData `json:"coords"`
	Status   StatusData `json:"status"`
	Radio    RadioData  `json:"radio"`
}

type StatusPayload struct {
	DeviceID string `json:"device_id"`
	Status   string `json:"status"`
}

type HistoryRecord struct {
	Timestamp time.Time  `firestore:"timestamp"`
	ExpireAt  time.Time  `firestore:"expire_at"`
	Seq       uint32     `firestore:"seq"`
	Coords    CoordsData `firestore:"coords"`
	Status    StatusData `firestore:"status"`
	Radio     RadioData  `firestore:"radio"`
}

type AlertPayload struct {
	DeviceID  string    `json:"device_id"`
	Type      string    `json:"type"`
	Severity  string    `json:"severity"` // models.SeverityInfo, models.SeverityWarning, models.SeverityCritical
	Value     float64   `json:"value,omitempty"`
	Timestamp time.Time `json:"timestamp"`
}

type LastAlertInfo struct {
	Type      string    `firestore:"type"`
	Severity  string    `firestore:"severity"`
	Value     float64   `firestore:"value,omitempty"`
	Timestamp time.Time `firestore:"timestamp"`
}

type AlertRecord struct {
	Timestamp time.Time `firestore:"timestamp"`
	ExpireAt  time.Time `firestore:"expire_at"`
	Type      string    `firestore:"type"`
	Severity  string    `firestore:"severity"`
	Value     float64   `firestore:"value,omitempty"`
}

type CollarConfig struct {
	MaxDistanceM  float64 `firestore:"max_distance_m" json:"max_dist_m"`
	MinBatteryPct int     `firestore:"min_battery_pct" json:"min_bat_pct"`
	RequireGpsFix bool    `firestore:"require_gps_fix" json:"require_gps_fix"`
}
