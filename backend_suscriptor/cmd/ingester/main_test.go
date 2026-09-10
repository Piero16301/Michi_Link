package main

import (
	"testing"
)

func TestIsRecoveryAlert(t *testing.T) {
	tests := []struct {
		name      string
		alertType string
		expected  bool
	}{
		// Alertas de resolución / recuperación (deben devolver true)
		{"Geofence restored", "GEOFENCE_RESTORED", true},
		{"Battery normal", "BATTERY_NORMAL", true},
		{"GPS fix restored", "GPS_FIX_RESTORED", true},
		{"Signal normal", "SIGNAL_NORMAL", true},
		{"Alert cleared manual", "ALERT_CLEARED", true},
		{"Custom restored", "TEMPERATURE_RESTORED", true},

		// Alertas de incidencia / críticas (deben devolver false)
		{"Geofence breach", "GEOFENCE_BREACH", false},
		{"Low battery", "LOW_BATTERY", false},
		{"Battery critical", "BATTERY_CRITICAL", false},
		{"No GPS fix", "NO_GPS_FIX", false},
		{"Weak signal", "WEAK_SIGNAL", false},
		{"Tipo vacío", "", false},
		{"Sufijo parcial no coincidente", "RESTORED_ALERT", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := isRecoveryAlert(tt.alertType)
			if got != tt.expected {
				t.Errorf("isRecoveryAlert(%q) = %v, esperado %v", tt.alertType, got, tt.expected)
			}
		})
	}
}

func TestGetEnv(t *testing.T) {
	const testKey = "TEST_INGESTER_ENV_VAR"
	const fallbackVal = "default_fallback"

	t.Run("variable existente", func(t *testing.T) {
		t.Setenv(testKey, "custom_value")
		got := getEnv(testKey, fallbackVal)
		if got != "custom_value" {
			t.Errorf("getEnv() = %q, esperado 'custom_value'", got)
		}
	})

	t.Run("variable inexistente retorna fallback", func(t *testing.T) {
		got := getEnv("NON_EXISTENT_VAR_XYZ_123", fallbackVal)
		if got != fallbackVal {
			t.Errorf("getEnv() = %q, esperado %q", got, fallbackVal)
		}
	})
}
