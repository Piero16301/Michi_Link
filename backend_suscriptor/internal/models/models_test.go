package models

import (
	"encoding/json"
	"reflect"
	"strings"
	"testing"
	"time"
)

func TestSeverityConstants(t *testing.T) {
	tests := []struct {
		name     string
		got      string
		expected string
	}{
		{"SeverityCritical", SeverityCritical, "CRITICAL"},
		{"SeverityWarning", SeverityWarning, "WARNING"},
		{"SeverityInfo", SeverityInfo, "INFO"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if tt.got != tt.expected {
				t.Errorf("constante %s = %q, esperado %q", tt.name, tt.got, tt.expected)
			}
		})
	}
}

func TestTelemetryPayload_JSONSerialization(t *testing.T) {
	t.Run("con pet_name presente", func(t *testing.T) {
		payload := TelemetryPayload{
			DeviceID: "T114_001",
			PetName:  "Michin",
			Seq:      42,
			Coords: CoordsData{
				Lat:  -8.066697,
				Lon:  -79.062737,
				AltM: 92.5,
			},
			Status: StatusData{
				GpsFix:     true,
				Sats:       10,
				BatteryV:   4.02,
				BatteryPct: 82,
			},
			Radio: RadioData{
				RSSI:          -65,
				SNR:           9.5,
				DistanceHomeM: 14.2,
			},
		}

		bytes, err := json.Marshal(payload)
		if err != nil {
			t.Fatalf("error serializando TelemetryPayload: %v", err)
		}

		var decoded TelemetryPayload
		if err := json.Unmarshal(bytes, &decoded); err != nil {
			t.Fatalf("error deserializando TelemetryPayload: %v", err)
		}

		if !reflect.DeepEqual(payload, decoded) {
			t.Errorf("discrepancia en deserialización:\noriginal: %+v\nrecibido: %+v", payload, decoded)
		}
	})

	t.Run("con pet_name vacío (omitempty)", func(t *testing.T) {
		payload := TelemetryPayload{
			DeviceID: "T114_002",
			Seq:      1,
			Coords:   CoordsData{Lat: 0, Lon: 0, AltM: 0},
			Status:   StatusData{GpsFix: false, Sats: 0, BatteryV: 3.7, BatteryPct: 20},
			Radio:    RadioData{RSSI: -110, SNR: -5.0, DistanceHomeM: 0},
		}

		bytes, err := json.Marshal(payload)
		if err != nil {
			t.Fatalf("error serializando payload sin pet_name: %v", err)
		}

		jsonStr := string(bytes)
		if strings.Contains(jsonStr, `"pet_name"`) {
			t.Errorf("se esperaba omitir 'pet_name' por omitempty, json: %s", jsonStr)
		}
	})
}

func TestStatusPayload_JSON(t *testing.T) {
	status := StatusPayload{
		DeviceID: "COLLAR_9E2B",
		Status:   "ONLINE",
	}

	bytes, err := json.Marshal(status)
	if err != nil {
		t.Fatalf("error serializando StatusPayload: %v", err)
	}

	var decoded StatusPayload
	if err := json.Unmarshal(bytes, &decoded); err != nil {
		t.Fatalf("error deserializando StatusPayload: %v", err)
	}

	if decoded != status {
		t.Errorf("obtenido %+v, esperado %+v", decoded, status)
	}
}

func TestAlertPayload_JSONSerialization(t *testing.T) {
	now := time.Date(2026, time.September, 10, 13, 0, 0, 0, time.UTC)

	t.Run("alerta con valor", func(t *testing.T) {
		alert := AlertPayload{
			DeviceID:  "COLLAR_9E2B",
			Type:      "LOW_BATTERY",
			Severity:  SeverityWarning,
			Value:     15.0,
			Timestamp: now,
		}

		bytes, err := json.Marshal(alert)
		if err != nil {
			t.Fatalf("error serializando AlertPayload: %v", err)
		}

		var decoded AlertPayload
		if err := json.Unmarshal(bytes, &decoded); err != nil {
			t.Fatalf("error deserializando AlertPayload: %v", err)
		}

		if decoded.DeviceID != alert.DeviceID || decoded.Severity != alert.Severity || decoded.Value != alert.Value {
			t.Errorf("datos no coinciden:\noriginal: %+v\nrecibido: %+v", alert, decoded)
		}
		if !decoded.Timestamp.Equal(alert.Timestamp) {
			t.Errorf("timestamp obtenido %v, esperado %v", decoded.Timestamp, alert.Timestamp)
		}
	})

	t.Run("alerta con valor omitido", func(t *testing.T) {
		alert := AlertPayload{
			DeviceID:  "COLLAR_9E2B",
			Type:      "GEOFENCE_EXIT",
			Severity:  SeverityCritical,
			Timestamp: now,
		}

		bytes, err := json.Marshal(alert)
		if err != nil {
			t.Fatalf("error serializando AlertPayload: %v", err)
		}

		if strings.Contains(string(bytes), `"value"`) {
			t.Errorf("el campo 'value' con valor cero debió omitirse, json: %s", string(bytes))
		}
	})
}

func TestCollarConfig_JSONTags(t *testing.T) {
	rawJSON := []byte(`{
		"max_dist_m": 150.5,
		"min_bat_pct": 25,
		"require_gps_fix": true
	}`)

	var cfg CollarConfig
	if err := json.Unmarshal(rawJSON, &cfg); err != nil {
		t.Fatalf("error deserializando CollarConfig: %v", err)
	}

	if cfg.MaxDistanceM != 150.5 {
		t.Errorf("MaxDistanceM: obtenido %f, esperado 150.5", cfg.MaxDistanceM)
	}
	if cfg.MinBatteryPct != 25 {
		t.Errorf("MinBatteryPct: obtenido %d, esperado 25", cfg.MinBatteryPct)
	}
	if !cfg.RequireGpsFix {
		t.Errorf("RequireGpsFix: obtenido %v, esperado true", cfg.RequireGpsFix)
	}

	encoded, err := json.Marshal(cfg)
	if err != nil {
		t.Fatalf("error serializando CollarConfig: %v", err)
	}

	encodedStr := string(encoded)
	expectedKeys := []string{"max_dist_m", "min_bat_pct", "require_gps_fix"}
	for _, key := range expectedKeys {
		if !strings.Contains(encodedStr, `"`+key+`"`) {
			t.Errorf("clave esperada %q no encontrada en JSON serializado: %s", key, encodedStr)
		}
	}
}

func TestRecords_Instantiation(t *testing.T) {
	now := time.Now().UTC()
	expire := now.Add(24 * time.Hour)

	t.Run("HistoryRecord campos válidos", func(t *testing.T) {
		record := HistoryRecord{
			Timestamp: now,
			ExpireAt:  expire,
			Seq:       10,
			Coords:    CoordsData{Lat: -8.0, Lon: -79.0, AltM: 100},
			Status:    StatusData{GpsFix: true, Sats: 8, BatteryV: 4.1, BatteryPct: 90},
			Radio:     RadioData{RSSI: -70, SNR: 8.0, DistanceHomeM: 25.0},
		}

		if record.Seq != 10 || record.Coords.Lat != -8.0 {
			t.Errorf("valores inesperados en HistoryRecord: %+v", record)
		}
		if !record.ExpireAt.After(record.Timestamp) {
			t.Errorf("ExpireAt debería ser posterior a Timestamp")
		}
	})

	t.Run("AlertRecord y LastAlertInfo", func(t *testing.T) {
		lastAlert := LastAlertInfo{
			Type:      "NO_SIGNAL",
			Severity:  SeverityWarning,
			Value:     120.0,
			Timestamp: now,
		}

		alertRec := AlertRecord{
			Timestamp: now,
			ExpireAt:  expire,
			Type:      lastAlert.Type,
			Severity:  lastAlert.Severity,
			Value:     lastAlert.Value,
		}

		if alertRec.Type != lastAlert.Type || alertRec.Severity != lastAlert.Severity {
			t.Errorf("inconsistencia entre LastAlertInfo y AlertRecord")
		}
	})
}
