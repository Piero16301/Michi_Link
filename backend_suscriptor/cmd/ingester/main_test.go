package main

import (
	"backend_suscriptor/internal/models"
	"fmt"
	"math"
	"strings"
	"sync"
	"testing"
	"time"
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

func TestBuildLocalizedNotification(t *testing.T) {
	const pet = "Michi"

	tests := []struct {
		name          string
		lang          string
		severity      string
		alertType     string
		val           float64
		expectedTitle string
		expectedBody  string
	}{
		// Español (es)
		{
			name:          "ES - Geofence breach",
			lang:          "es",
			severity:      models.SeverityCritical,
			alertType:     "GEOFENCE_BREACH",
			val:           220.0,
			expectedTitle: "🚨 Alerta Crítica",
			expectedBody:  "¡Michi ha salido de la zona segura! (Distancia: 220m)",
		},
		{
			name:          "ES - Geofence restored",
			lang:          "es",
			severity:      models.SeverityInfo,
			alertType:     "GEOFENCE_RESTORED",
			val:           45.0,
			expectedTitle: "ℹ️ Información",
			expectedBody:  "Michi ha regresado a la zona segura (Distancia: 45m).",
		},
		{
			name:          "ES - Low battery",
			lang:          "es",
			severity:      models.SeverityWarning,
			alertType:     "LOW_BATTERY",
			val:           15.0,
			expectedTitle: "⚠️ Advertencia",
			expectedBody:  "Batería baja en el collar de Michi: 15%.",
		},
		{
			name:          "ES - Battery critical",
			lang:          "es",
			severity:      models.SeverityCritical,
			alertType:     "BATTERY_CRITICAL",
			val:           8.0,
			expectedTitle: "🚨 Alerta Crítica",
			expectedBody:  "¡Batería crítica en el collar de Michi: 8%! Recárgalo pronto.",
		},
		{
			name:          "ES - Battery normal",
			lang:          "es",
			severity:      models.SeverityInfo,
			alertType:     "BATTERY_NORMAL",
			val:           85.0,
			expectedTitle: "ℹ️ Información",
			expectedBody:  "Batería normalizada en el collar de Michi: 85%.",
		},
		{
			name:          "ES - No GPS fix",
			lang:          "es",
			severity:      models.SeverityWarning,
			alertType:     "NO_GPS_FIX",
			val:           0,
			expectedTitle: "⚠️ Advertencia",
			expectedBody:  "Michi no tiene señal satelital GPS.",
		},
		{
			name:          "ES - GPS fix restored",
			lang:          "es",
			severity:      models.SeverityInfo,
			alertType:     "GPS_FIX_RESTORED",
			val:           7,
			expectedTitle: "ℹ️ Información",
			expectedBody:  "Señal GPS recuperada para Michi (7 satélites).",
		},
		{
			name:          "ES - Weak signal",
			lang:          "es",
			severity:      models.SeverityWarning,
			alertType:     "WEAK_SIGNAL",
			val:           -118,
			expectedTitle: "⚠️ Advertencia",
			expectedBody:  "Señal LoRa débil con el collar de Michi (-118 dBm).",
		},
		{
			name:          "ES - Signal normal",
			lang:          "es",
			severity:      models.SeverityInfo,
			alertType:     "SIGNAL_NORMAL",
			val:           -90,
			expectedTitle: "ℹ️ Información",
			expectedBody:  "Señal LoRa normalizada para Michi (-90 dBm).",
		},
		{
			name:          "ES - Fallback de idioma desconocido",
			lang:          "unknown_lang",
			severity:      models.SeverityCritical,
			alertType:     "GEOFENCE_BREACH",
			val:           100,
			expectedTitle: "🚨 Alerta Crítica",
			expectedBody:  "¡Michi ha salido de la zona segura! (Distancia: 100m)",
		},

		// Inglés (en)
		{
			name:          "EN - Geofence breach",
			lang:          "en",
			severity:      models.SeverityCritical,
			alertType:     "GEOFENCE_BREACH",
			val:           220.0,
			expectedTitle: "🚨 Critical Alert",
			expectedBody:  "Michi has left the safe zone! (Distance: 220m)",
		},
		{
			name:          "EN - Geofence restored",
			lang:          "en-US",
			severity:      models.SeverityInfo,
			alertType:     "GEOFENCE_RESTORED",
			val:           50.0,
			expectedTitle: "ℹ️ Information",
			expectedBody:  "Michi has returned to the safe zone (Distance: 50m).",
		},
		{
			name:          "EN - Low battery",
			lang:          "en",
			severity:      models.SeverityWarning,
			alertType:     "LOW_BATTERY",
			val:           12.0,
			expectedTitle: "⚠️ Warning",
			expectedBody:  "Low battery on Michi's collar: 12%.",
		},
		{
			name:          "EN - GPS restored",
			lang:          "en",
			severity:      models.SeverityInfo,
			alertType:     "GPS_FIX_RESTORED",
			val:           6,
			expectedTitle: "ℹ️ Information",
			expectedBody:  "GPS signal restored for Michi (6 satellites).",
		},

		// Francés (fr)
		{
			name:          "FR - Geofence breach",
			lang:          "fr",
			severity:      models.SeverityCritical,
			alertType:     "GEOFENCE_BREACH",
			val:           180.0,
			expectedTitle: "🚨 Alerte Critique",
			expectedBody:  "Michi a quitté la zone de sécurité ! (Distance : 180m)",
		},
		{
			name:          "FR - Geofence restored (fr-FR)",
			lang:          "fr-FR",
			severity:      models.SeverityInfo,
			alertType:     "GEOFENCE_RESTORED",
			val:           20.0,
			expectedTitle: "ℹ️ Information",
			expectedBody:  "Michi est de retour dans la zone de sécurité (Distance : 20m).",
		},
		{
			name:          "FR - Critical battery",
			lang:          "fr",
			severity:      models.SeverityCritical,
			alertType:     "BATTERY_CRITICAL",
			val:           8.0,
			expectedTitle: "🚨 Alerte Critique",
			expectedBody:  "Batterie critique sur le collier de Michi : 8% ! Veuillez recharger.",
		},
		{
			name:          "FR - Low battery",
			lang:          "fr",
			severity:      models.SeverityWarning,
			alertType:     "LOW_BATTERY",
			val:           15.0,
			expectedTitle: "⚠️ Avertissement",
			expectedBody:  "Batterie faible sur le collier de Michi : 15%.",
		},
		{
			name:          "FR - Battery normal",
			lang:          "fr",
			severity:      models.SeverityInfo,
			alertType:     "BATTERY_NORMAL",
			val:           80.0,
			expectedTitle: "ℹ️ Information",
			expectedBody:  "Niveau de batterie normalisé pour Michi : 80%.",
		},
		{
			name:          "FR - No GPS fix",
			lang:          "fr",
			severity:      models.SeverityWarning,
			alertType:     "NO_GPS_FIX",
			val:           0,
			expectedTitle: "⚠️ Avertissement",
			expectedBody:  "Michi a perdu le signal satellite GPS.",
		},
		{
			name:          "FR - GPS fix restored",
			lang:          "fr",
			severity:      models.SeverityInfo,
			alertType:     "GPS_FIX_RESTORED",
			val:           5,
			expectedTitle: "ℹ️ Information",
			expectedBody:  "Signal GPS rétabli pour Michi (5 satellites).",
		},
		{
			name:          "FR - Weak signal",
			lang:          "fr",
			severity:      models.SeverityWarning,
			alertType:     "WEAK_SIGNAL",
			val:           -116,
			expectedTitle: "⚠️ Avertissement",
			expectedBody:  "Signal LoRa faible avec le collier de Michi (-116 dBm).",
		},
		{
			name:          "FR - Signal normal",
			lang:          "fr",
			severity:      models.SeverityInfo,
			alertType:     "SIGNAL_NORMAL",
			val:           -88,
			expectedTitle: "ℹ️ Information",
			expectedBody:  "Signal LoRa normalisé pour Michi (-88 dBm).",
		},

		// Alemán (de)
		{
			name:          "DE - Geofence breach",
			lang:          "de",
			severity:      models.SeverityCritical,
			alertType:     "GEOFENCE_BREACH",
			val:           250.0,
			expectedTitle: "🚨 Kritischer Alarm",
			expectedBody:  "Michi hat die Sicherheitszone verlassen! (Entfernung: 250m)",
		},
		{
			name:          "DE - Geofence restored (de-DE)",
			lang:          "de-DE",
			severity:      models.SeverityInfo,
			alertType:     "GEOFENCE_RESTORED",
			val:           30.0,
			expectedTitle: "ℹ️ Information",
			expectedBody:  "Michi ist in die Sicherheitszone zurückgekehrt (Entfernung: 30m).",
		},
		{
			name:          "DE - Critical battery",
			lang:          "de",
			severity:      models.SeverityCritical,
			alertType:     "BATTERY_CRITICAL",
			val:           9.0,
			expectedTitle: "🚨 Kritischer Alarm",
			expectedBody:  "Kritischer Akkustand am Halsband von Michi: 9%! Bitte aufladen.",
		},
		{
			name:          "DE - Low battery",
			lang:          "de",
			severity:      models.SeverityWarning,
			alertType:     "LOW_BATTERY",
			val:           14.0,
			expectedTitle: "⚠️ Warnung",
			expectedBody:  "Niedriger Akkustand am Halsband von Michi: 14%.",
		},
		{
			name:          "DE - Battery normal",
			lang:          "de",
			severity:      models.SeverityInfo,
			alertType:     "BATTERY_NORMAL",
			val:           90.0,
			expectedTitle: "ℹ️ Information",
			expectedBody:  "Akkustand normalisiert für Michi: 90%.",
		},
		{
			name:          "DE - No GPS fix",
			lang:          "de",
			severity:      models.SeverityWarning,
			alertType:     "NO_GPS_FIX",
			val:           0,
			expectedTitle: "⚠️ Warnung",
			expectedBody:  "Michi hat das GPS-Satellitensignal verloren.",
		},
		{
			name:          "DE - GPS fix restored",
			lang:          "de",
			severity:      models.SeverityInfo,
			alertType:     "GPS_FIX_RESTORED",
			val:           8,
			expectedTitle: "ℹ️ Information",
			expectedBody:  "GPS-Signal wiederhergestellt für Michi (8 Satelliten).",
		},
		{
			name:          "DE - Weak signal",
			lang:          "de",
			severity:      models.SeverityWarning,
			alertType:     "WEAK_SIGNAL",
			val:           -120,
			expectedTitle: "⚠️ Warnung",
			expectedBody:  "Schwache LoRa-Verbindung mit dem Halsband von Michi (-120 dBm).",
		},
		{
			name:          "DE - Signal normal",
			lang:          "de",
			severity:      models.SeverityInfo,
			alertType:     "SIGNAL_NORMAL",
			val:           -80,
			expectedTitle: "ℹ️ Information",
			expectedBody:  "LoRa-Signal normalisiert für Michi (-80 dBm).",
		},

		// Italiano (it)
		{
			name:          "IT - Geofence breach",
			lang:          "it",
			severity:      models.SeverityCritical,
			alertType:     "GEOFENCE_BREACH",
			val:           190.0,
			expectedTitle: "🚨 Allarme Critico",
			expectedBody:  "Michi è uscito dalla zona sicura! (Distanza: 190m)",
		},
		{
			name:          "IT - Geofence restored (it-IT)",
			lang:          "it-IT",
			severity:      models.SeverityInfo,
			alertType:     "GEOFENCE_RESTORED",
			val:           10.0,
			expectedTitle: "ℹ️ Informazione",
			expectedBody:  "Michi è tornato nella zona sicura (Distanza: 10m).",
		},
		{
			name:          "IT - Critical battery",
			lang:          "it",
			severity:      models.SeverityCritical,
			alertType:     "BATTERY_CRITICAL",
			val:           5.0,
			expectedTitle: "🚨 Allarme Critico",
			expectedBody:  "Batteria critica sul collare di Michi: 5%! Ricarica presto.",
		},
		{
			name:          "IT - Low battery",
			lang:          "it",
			severity:      models.SeverityWarning,
			alertType:     "LOW_BATTERY",
			val:           15.0,
			expectedTitle: "⚠️ Avviso",
			expectedBody:  "Batteria scarica sul collare di Michi: 15%.",
		},
		{
			name:          "IT - Battery normal",
			lang:          "it",
			severity:      models.SeverityInfo,
			alertType:     "BATTERY_NORMAL",
			val:           100.0,
			expectedTitle: "ℹ️ Informazione",
			expectedBody:  "Livello batteria normalizzato per Michi: 100%.",
		},
		{
			name:          "IT - No GPS fix",
			lang:          "it",
			severity:      models.SeverityWarning,
			alertType:     "NO_GPS_FIX",
			val:           0,
			expectedTitle: "⚠️ Avviso",
			expectedBody:  "Michi ha perso il segnale satellitare GPS.",
		},
		{
			name:          "IT - GPS fix restored",
			lang:          "it",
			severity:      models.SeverityInfo,
			alertType:     "GPS_FIX_RESTORED",
			val:           9,
			expectedTitle: "ℹ️ Informazione",
			expectedBody:  "Segnale GPS ripristinato per Michi (9 satelliti).",
		},
		{
			name:          "IT - Weak signal",
			lang:          "it",
			severity:      models.SeverityWarning,
			alertType:     "WEAK_SIGNAL",
			val:           -119,
			expectedTitle: "⚠️ Avviso",
			expectedBody:  "Segnale LoRa debole con il collare di Michi (-119 dBm).",
		},
		{
			name:          "IT - Signal normal",
			lang:          "it",
			severity:      models.SeverityInfo,
			alertType:     "SIGNAL_NORMAL",
			val:           -75,
			expectedTitle: "ℹ️ Informazione",
			expectedBody:  "Segnale LoRa normalizzato per Michi (-75 dBm).",
		},

		// Português (pt)
		{
			name:          "PT - Geofence breach",
			lang:          "pt",
			severity:      models.SeverityCritical,
			alertType:     "GEOFENCE_BREACH",
			val:           300.0,
			expectedTitle: "🚨 Alerta Crítico",
			expectedBody:  "Michi saiu da zona de segurança! (Distância: 300m)",
		},
		{
			name:          "PT - Geofence restored (pt-BR)",
			lang:          "pt-BR",
			severity:      models.SeverityInfo,
			alertType:     "GEOFENCE_RESTORED",
			val:           25.0,
			expectedTitle: "ℹ️ Informação",
			expectedBody:  "Michi retornou à zona de segurança (Distância: 25m).",
		},
		{
			name:          "PT - Critical battery",
			lang:          "pt",
			severity:      models.SeverityCritical,
			alertType:     "BATTERY_CRITICAL",
			val:           7.0,
			expectedTitle: "🚨 Alerta Crítico",
			expectedBody:  "Bateria crítica na coleira de Michi: 7%! Recarregue logo.",
		},
		{
			name:          "PT - Low battery",
			lang:          "pt",
			severity:      models.SeverityWarning,
			alertType:     "LOW_BATTERY",
			val:           18.0,
			expectedTitle: "⚠️ Aviso",
			expectedBody:  "Bateria fraca na coleira de Michi: 18%.",
		},
		{
			name:          "PT - Battery normal",
			lang:          "pt",
			severity:      models.SeverityInfo,
			alertType:     "BATTERY_NORMAL",
			val:           95.0,
			expectedTitle: "ℹ️ Informação",
			expectedBody:  "Nível de bateria normalizado para Michi: 95%.",
		},
		{
			name:          "PT - No GPS fix",
			lang:          "pt",
			severity:      models.SeverityWarning,
			alertType:     "NO_GPS_FIX",
			val:           0,
			expectedTitle: "⚠️ Aviso",
			expectedBody:  "Michi perdeu o sinal de satélite GPS.",
		},
		{
			name:          "PT - GPS fix restored",
			lang:          "pt",
			severity:      models.SeverityInfo,
			alertType:     "GPS_FIX_RESTORED",
			val:           11,
			expectedTitle: "ℹ️ Informação",
			expectedBody:  "Sinal GPS restaurado para Michi (11 satélites).",
		},
		{
			name:          "PT - Weak signal",
			lang:          "pt",
			severity:      models.SeverityWarning,
			alertType:     "WEAK_SIGNAL",
			val:           -117,
			expectedTitle: "⚠️ Aviso",
			expectedBody:  "Sinal LoRa fraco com a coleira de Michi (-117 dBm).",
		},
		{
			name:          "PT - Signal normal",
			lang:          "pt",
			severity:      models.SeverityInfo,
			alertType:     "SIGNAL_NORMAL",
			val:           -82,
			expectedTitle: "ℹ️ Informação",
			expectedBody:  "Sinal LoRa normalizado para Michi (-82 dBm).",
		},

		// Caso de alerta desconocido en diferentes idiomas
		{
			name:          "FR - Default event",
			lang:          "fr",
			severity:      "UNKNOWN_SEV",
			alertType:     "CUSTOM_EVENT",
			val:           0,
			expectedTitle: "ℹ️ Information",
			expectedBody:  "Événement CUSTOM_EVENT pour Michi",
		},
		{
			name:          "DE - Default event",
			lang:          "de",
			severity:      "UNKNOWN_SEV",
			alertType:     "CUSTOM_EVENT",
			val:           0,
			expectedTitle: "ℹ️ Information",
			expectedBody:  "Ereignis CUSTOM_EVENT für Michi",
		},
		{
			name:          "IT - Default event",
			lang:          "it",
			severity:      "UNKNOWN_SEV",
			alertType:     "CUSTOM_EVENT",
			val:           0,
			expectedTitle: "ℹ️ Informazione",
			expectedBody:  "Evento CUSTOM_EVENT per Michi",
		},
		{
			name:          "PT - Default event",
			lang:          "pt",
			severity:      "UNKNOWN_SEV",
			alertType:     "CUSTOM_EVENT",
			val:           0,
			expectedTitle: "ℹ️ Informação",
			expectedBody:  "Evento CUSTOM_EVENT para Michi",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			title, body := buildLocalizedNotification(tt.lang, tt.severity, tt.alertType, pet, tt.val)
			if title != tt.expectedTitle {
				t.Errorf("buildLocalizedNotification(%q, %q, %q) title = %q, esperado %q",
					tt.lang, tt.severity, tt.alertType, title, tt.expectedTitle)
			}
			if body != tt.expectedBody {
				t.Errorf("buildLocalizedNotification(%q, %q, %q) body = %q, esperado %q",
					tt.lang, tt.severity, tt.alertType, body, tt.expectedBody)
			}
		})
	}

	// Verificar limpieza de espacios y mayúsculas
	t.Run("Normalización de idioma", func(t *testing.T) {
		title, body := buildLocalizedNotification("  FR  ", models.SeverityCritical, "BATTERY_CRITICAL", pet, 5.0)
		if !strings.Contains(title, "Alerte Critique") || !strings.Contains(body, "Batterie critique") {
			t.Errorf("Falló normalización de '  FR  ': title=%q, body=%q", title, body)
		}
	})
}

func TestParseCoordinate(t *testing.T) {
	tests := []struct {
		name      string
		input     any
		expected  float64
		expectOk  bool
	}{
		{"float64 positivo", 123.456, 123.456, true},
		{"float64 negativo", -79.0628, -79.0628, true},
		{"float64 cero", 0.0, 0.0, true},
		{"int64 positivo", int64(150), 150.0, true},
		{"int64 negativo", int64(-50), -50.0, true},
		{"int64 cero", int64(0), 0.0, true},
		{"int positivo", 42, 42.0, true},
		{"int negativo", -10, -10.0, true},
		{"int cero", 0, 0.0, true},
		{"string no numérico", "123.456", 0.0, false},
		{"nil", nil, 0.0, false},
		{"bool true", true, 0.0, false},
		{"slice de bytes", []byte{1, 2, 3}, 0.0, false},
		{"struct", struct{}{}, 0.0, false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, ok := parseCoordinate(tt.input)
			if ok != tt.expectOk {
				t.Fatalf("parseCoordinate(%v) ok = %v, esperado %v", tt.input, ok, tt.expectOk)
			}
			if ok && got != tt.expected {
				t.Errorf("parseCoordinate(%v) = %v, esperado %v", tt.input, got, tt.expected)
			}
		})
	}
}

func TestGeodesicDistanceWGS84(t *testing.T) {
	t.Run("coordenadas idénticas retornan 0", func(t *testing.T) {
		dist := GeodesicDistanceWGS84(-8.066663, -79.062807, -8.066663, -79.062807)
		if dist != 0.0 {
			t.Errorf("distancia entre puntos idénticos = %v, esperado 0.0", dist)
		}
	})

	t.Run("simetría dist(A, B) == dist(B, A)", func(t *testing.T) {
		latA, lonA := -8.066663, -79.062807
		latB, lonB := -8.065000, -79.061000
		d1 := GeodesicDistanceWGS84(latA, lonA, latB, lonB)
		d2 := GeodesicDistanceWGS84(latB, lonB, latA, lonA)
		if math.Abs(d1-d2) > 1e-6 {
			t.Errorf("violación de simetría: d(A,B)=%v != d(B,A)=%v", d1, d2)
		}
	})

	t.Run("cálculo aproximado en el meridiano", func(t *testing.T) {
		// 0.001 grados de latitud es aprox ~110.78 metros en WGS84
		dist := GeodesicDistanceWGS84(-8.066663, -79.062807, -8.065663, -79.062807)
		if dist < 105.0 || dist > 115.0 {
			t.Errorf("distancia calculada %v fuera del rango esperado (~110.8m)", dist)
		}
	})
}

func defaultTestConfig() models.CollarConfig {
	return models.CollarConfig{
		MaxDistanceM:  150.0,
		MinBatteryPct: 20,
		RequireGpsFix: true,
		NotifLanguage: "es",
	}
}

func TestEvaluateAlertTransitions_Geofence(t *testing.T) {
	cfg := defaultTestConfig()
	now := time.Now().UTC()
	devID := "COLLAR_GEOFENCE"

	// 1. Paquete inicial dentro de zona segura con fix (distancia <= 150m) -> sin alerta
	lastAlert := models.LastAlertInfo{}
	alerts := evaluateAlertTransitions(devID, true, 8, 50.0, 80, -90.0, cfg, lastAlert, now)
	if len(alerts) != 0 {
		t.Fatalf("no se esperaba alerta dentro de zona segura, se obtuvo: %+v", alerts)
	}

	// 2. Salida de geocerca (distancia > 150m) con fix -> Dispara GEOFENCE_BREACH (CRITICAL)
	alerts = evaluateAlertTransitions(devID, true, 8, 200.0, 80, -90.0, cfg, lastAlert, now)
	if len(alerts) != 1 || alerts[0].Type != "GEOFENCE_BREACH" || alerts[0].Severity != models.SeverityCritical || alerts[0].Value != 200.0 {
		t.Fatalf("se esperaba 1 alerta GEOFENCE_BREACH (CRITICAL), se obtuvo: %+v", alerts)
	}
	if alerts[0].DeviceID != devID || alerts[0].Timestamp != now {
		t.Errorf("campos de metadatos DeviceID o Timestamp incorrectos: %+v", alerts[0])
	}

	// 3. Paquete sucesivo aún fuera de geocerca (lastAlert ya es GEOFENCE_BREACH) -> No debe enviar spam
	lastAlert = models.LastAlertInfo{
		Type:      "GEOFENCE_BREACH",
		Severity:  models.SeverityCritical,
		Value:     200.0,
		Timestamp: now,
	}
	alerts = evaluateAlertTransitions(devID, true, 8, 210.0, 80, -90.0, cfg, lastAlert, now)
	if len(alerts) != 0 {
		t.Fatalf("no se esperaba spam mientras permanece fuera, se obtuvo: %+v", alerts)
	}

	// 4. Retorno a zona segura (distancia <= 150m) con lastAlert=GEOFENCE_BREACH -> Dispara GEOFENCE_RESTORED (INFO)
	alerts = evaluateAlertTransitions(devID, true, 8, 80.0, 80, -90.0, cfg, lastAlert, now)
	if len(alerts) != 1 || alerts[0].Type != "GEOFENCE_RESTORED" || alerts[0].Severity != models.SeverityInfo || alerts[0].Value != 80.0 {
		t.Fatalf("se esperaba 1 alerta GEOFENCE_RESTORED (INFO), se obtuvo: %+v", alerts)
	}

	// 5. Sin fix satelital -> No debe disparar alerta de geocerca aunque distM > MaxDistanceM
	lastAlert = models.LastAlertInfo{}
	alerts = evaluateAlertTransitions(devID, false, 0, 500.0, 80, -90.0, cfg, lastAlert, now)
	for _, a := range alerts {
		if a.Type == "GEOFENCE_BREACH" {
			t.Errorf("no se debe disparar GEOFENCE_BREACH si hasFix es false")
		}
	}
}

func TestEvaluateAlertTransitions_Battery(t *testing.T) {
	cfg := defaultTestConfig() // MinBatteryPct: 20, BatteryCriticalPct: 10
	now := time.Now().UTC()
	devID := "COLLAR_BAT"

	// 1. Paquete inicial normal (100%) -> sin alertas
	lastAlert := models.LastAlertInfo{}
	alerts := evaluateAlertTransitions(devID, true, 8, 50.0, 100, -85.0, cfg, lastAlert, now)
	if len(alerts) != 0 {
		t.Fatalf("no se esperaba alerta con batería al 100%%, se obtuvo: %+v", alerts)
	}

	// 2. Caída a batería baja (15% <= 20%, > 10%) -> Dispara LOW_BATTERY (WARNING)
	alerts = evaluateAlertTransitions(devID, true, 8, 50.0, 15, -85.0, cfg, lastAlert, now)
	if len(alerts) != 1 || alerts[0].Type != "LOW_BATTERY" || alerts[0].Severity != models.SeverityWarning || alerts[0].Value != 15.0 {
		t.Fatalf("se esperaba LOW_BATTERY (WARNING), se obtuvo: %+v", alerts)
	}

	// 3. Permanece en 14% con lastAlert=LOW_BATTERY -> sin spam
	lastAlert = models.LastAlertInfo{
		Type:      "LOW_BATTERY",
		Severity:  models.SeverityWarning,
		Value:     15.0,
		Timestamp: now,
	}
	alerts = evaluateAlertTransitions(devID, true, 8, 50.0, 14, -85.0, cfg, lastAlert, now)
	if len(alerts) != 0 {
		t.Fatalf("no se esperaba spam de LOW_BATTERY, se obtuvo: %+v", alerts)
	}

	// 4. Caída a batería crítica (8% <= BatteryCriticalPct: 10%) -> Dispara BATTERY_CRITICAL (CRITICAL)
	alerts = evaluateAlertTransitions(devID, true, 8, 50.0, 8, -85.0, cfg, lastAlert, now)
	if len(alerts) != 1 || alerts[0].Type != "BATTERY_CRITICAL" || alerts[0].Severity != models.SeverityCritical || alerts[0].Value != 8.0 {
		t.Fatalf("se esperaba BATTERY_CRITICAL (CRITICAL), se obtuvo: %+v", alerts)
	}

	// 5. Permanece en 7% con lastAlert=BATTERY_CRITICAL -> sin spam
	lastAlert = models.LastAlertInfo{
		Type:      "BATTERY_CRITICAL",
		Severity:  models.SeverityCritical,
		Value:     8.0,
		Timestamp: now,
	}
	alerts = evaluateAlertTransitions(devID, true, 8, 50.0, 7, -85.0, cfg, lastAlert, now)
	if len(alerts) != 0 {
		t.Fatalf("no se esperaba spam de BATTERY_CRITICAL, se obtuvo: %+v", alerts)
	}

	// 6. Carga completa normalizada (90% > 20%) tras BATTERY_CRITICAL -> Dispara BATTERY_NORMAL (INFO)
	alerts = evaluateAlertTransitions(devID, true, 8, 50.0, 90, -85.0, cfg, lastAlert, now)
	if len(alerts) != 1 || alerts[0].Type != "BATTERY_NORMAL" || alerts[0].Severity != models.SeverityInfo || alerts[0].Value != 90.0 {
		t.Fatalf("se esperaba BATTERY_NORMAL (INFO), se obtuvo: %+v", alerts)
	}

	// 7. Carga normalizada tras LOW_BATTERY -> Dispara BATTERY_NORMAL (INFO)
	lastAlertLow := models.LastAlertInfo{Type: "LOW_BATTERY", Severity: models.SeverityWarning, Value: 18.0}
	alerts = evaluateAlertTransitions(devID, true, 8, 50.0, 85, -85.0, cfg, lastAlertLow, now)
	if len(alerts) != 1 || alerts[0].Type != "BATTERY_NORMAL" || alerts[0].Severity != models.SeverityInfo || alerts[0].Value != 85.0 {
		t.Fatalf("se esperaba BATTERY_NORMAL tras LOW_BATTERY, se obtuvo: %+v", alerts)
	}

	// 8. Permanece en 95% con lastAlert=BATTERY_NORMAL -> sin spam
	lastAlertNormal := models.LastAlertInfo{Type: "BATTERY_NORMAL", Severity: models.SeverityInfo, Value: 90.0}
	alerts = evaluateAlertTransitions(devID, true, 8, 50.0, 95, -85.0, cfg, lastAlertNormal, now)
	if len(alerts) != 0 {
		t.Fatalf("no se esperaba spam de BATTERY_NORMAL, se obtuvo: %+v", alerts)
	}
}

func TestEvaluateAlertTransitions_GPSFix(t *testing.T) {
	cfg := defaultTestConfig() // RequireGpsFix: true
	now := time.Now().UTC()
	devID := "COLLAR_GPS"

	// 1. Paquete inicial con fix -> sin alertas
	lastAlert := models.LastAlertInfo{}
	alerts := evaluateAlertTransitions(devID, true, 7, 50.0, 90, -80.0, cfg, lastAlert, now)
	if len(alerts) != 0 {
		t.Fatalf("no se esperaba alerta con GPS fix activo, se obtuvo: %+v", alerts)
	}

	// 2. Pérdida de fix GPS -> Dispara NO_GPS_FIX (WARNING)
	alerts = evaluateAlertTransitions(devID, false, 0, 50.0, 90, -80.0, cfg, lastAlert, now)
	if len(alerts) != 1 || alerts[0].Type != "NO_GPS_FIX" || alerts[0].Severity != models.SeverityWarning || alerts[0].Value != 0 {
		t.Fatalf("se esperaba NO_GPS_FIX (WARNING), se obtuvo: %+v", alerts)
	}

	// 3. Permanece sin fix con lastAlert=NO_GPS_FIX -> sin spam
	lastAlert = models.LastAlertInfo{
		Type:      "NO_GPS_FIX",
		Severity:  models.SeverityWarning,
		Value:     0,
		Timestamp: now,
	}
	alerts = evaluateAlertTransitions(devID, false, 0, 50.0, 90, -80.0, cfg, lastAlert, now)
	if len(alerts) != 0 {
		t.Fatalf("no se esperaba spam de NO_GPS_FIX, se obtuvo: %+v", alerts)
	}

	// 4. Recuperación de fix GPS con 6 satélites -> Dispara GPS_FIX_RESTORED (INFO) con sats
	alerts = evaluateAlertTransitions(devID, true, 6, 50.0, 90, -80.0, cfg, lastAlert, now)
	if len(alerts) != 1 || alerts[0].Type != "GPS_FIX_RESTORED" || alerts[0].Severity != models.SeverityInfo || alerts[0].Value != 6 {
		t.Fatalf("se esperaba GPS_FIX_RESTORED (INFO) con valor 6 satélites, se obtuvo: %+v", alerts)
	}

	// 5. Configuración con RequireGpsFix = false no debe alertar sobre fix
	cfgNoFixReq := cfg
	cfgNoFixReq.RequireGpsFix = false
	alerts = evaluateAlertTransitions(devID, false, 0, 50.0, 90, -80.0, cfgNoFixReq, models.LastAlertInfo{}, now)
	if len(alerts) != 0 {
		t.Errorf("no se esperaba alerta de fix si RequireGpsFix es false, se obtuvo: %+v", alerts)
	}
}

func TestEvaluateAlertTransitions_LoraSignalHysteresis(t *testing.T) {
	cfg := defaultTestConfig()
	now := time.Now().UTC()
	devID := "COLLAR_LORA"

	// 1. Paquete inicial con señal fuerte (-80 dBm) -> sin alertas
	lastAlert := models.LastAlertInfo{}
	alerts := evaluateAlertTransitions(devID, true, 7, 50.0, 90, -80.0, cfg, lastAlert, now)
	if len(alerts) != 0 {
		t.Fatalf("no se esperaba alerta con señal normal, se obtuvo: %+v", alerts)
	}

	// 2. Señal cae bajo el umbral crítico LoraWeakRssiThreshold (-115 dBm) a -118 dBm -> Dispara WEAK_SIGNAL (WARNING)
	alerts = evaluateAlertTransitions(devID, true, 7, 50.0, 90, -118.0, cfg, lastAlert, now)
	if len(alerts) != 1 || alerts[0].Type != "WEAK_SIGNAL" || alerts[0].Severity != models.SeverityWarning || alerts[0].Value != -118.0 {
		t.Fatalf("se esperaba WEAK_SIGNAL (WARNING), se obtuvo: %+v", alerts)
	}

	// 3. Señal sube levemente a -110 dBm (dentro de la banda de histéresis -115 a -105 dBm) -> no debe restaurarse aún
	lastAlert = models.LastAlertInfo{
		Type:      "WEAK_SIGNAL",
		Severity:  models.SeverityWarning,
		Value:     -118.0,
		Timestamp: now,
	}
	alerts = evaluateAlertTransitions(devID, true, 7, 50.0, 90, -110.0, cfg, lastAlert, now)
	if len(alerts) != 0 {
		t.Fatalf("no se esperaba alerta en la banda de histéresis (-110 dBm), se obtuvo: %+v", alerts)
	}

	// 4. Señal sube a -104 dBm (>= LoraWeakRssiThreshold + 10 = -105 dBm) -> se restaura a SIGNAL_NORMAL (INFO)
	alerts = evaluateAlertTransitions(devID, true, 7, 50.0, 90, -104.0, cfg, lastAlert, now)
	if len(alerts) != 1 || alerts[0].Type != "SIGNAL_NORMAL" || alerts[0].Severity != models.SeverityInfo || alerts[0].Value != -104.0 {
		t.Fatalf("se esperaba SIGNAL_NORMAL (INFO), se obtuvo: %+v", alerts)
	}

	// 5. Señal normalizada continúa fuerte con lastAlert=SIGNAL_NORMAL -> sin spam
	lastAlertNormal := models.LastAlertInfo{
		Type:      "SIGNAL_NORMAL",
		Severity:  models.SeverityInfo,
		Value:     -104.0,
		Timestamp: now,
	}
	alerts = evaluateAlertTransitions(devID, true, 7, 50.0, 90, -85.0, cfg, lastAlertNormal, now)
	if len(alerts) != 0 {
		t.Fatalf("no se esperaba spam de SIGNAL_NORMAL, se obtuvo: %+v", alerts)
	}
}

func TestEvaluateAlertTransitions_SimultaneousAlerts(t *testing.T) {
	cfg := defaultTestConfig()
	now := time.Now().UTC()
	devID := "COLLAR_MULTI"

	// Suceso simultáneo con lastAlert vacío: breach de geovalla, batería crítica y señal débil
	alerts := evaluateAlertTransitions(devID, true, 8, 350.0, 5, -122.0, cfg, models.LastAlertInfo{}, now)
	if len(alerts) != 3 {
		t.Fatalf("se esperaban 3 alertas simultáneas, se obtuvieron %d: %+v", len(alerts), alerts)
	}

	alertTypes := make(map[string]models.AlertPayload)
	for _, a := range alerts {
		alertTypes[a.Type] = a
	}

	if geofence, ok := alertTypes["GEOFENCE_BREACH"]; !ok || geofence.Severity != models.SeverityCritical || geofence.Value != 350.0 {
		t.Errorf("alerta GEOFENCE_BREACH incorrecta: %+v", geofence)
	}
	if bat, ok := alertTypes["BATTERY_CRITICAL"]; !ok || bat.Severity != models.SeverityCritical || bat.Value != 5.0 {
		t.Errorf("alerta BATTERY_CRITICAL incorrecta: %+v", bat)
	}
	if rssi, ok := alertTypes["WEAK_SIGNAL"]; !ok || rssi.Severity != models.SeverityWarning || rssi.Value != -122.0 {
		t.Errorf("alerta WEAK_SIGNAL incorrecta: %+v", rssi)
	}
}

func TestEvaluateAlertTransitions_ConcurrentSafe(t *testing.T) {
	cfg := defaultTestConfig()
	now := time.Now().UTC()

	const workers = 20
	const iterations = 50
	var wg sync.WaitGroup

	for w := 0; w < workers; w++ {
		wg.Add(1)
		devID := fmt.Sprintf("COLLAR_CONCUR_%d", w%4)
		go func(id string) {
			defer wg.Done()
			for i := 0; i < iterations; i++ {
				dist := float64(50 + (i % 200))
				bat := 10 + (i % 90)
				rssi := float64(-120 + (i % 50))
				hasFix := (i % 2) == 0
				lastAlert := models.LastAlertInfo{
					Type: "NONE",
				}
				_ = evaluateAlertTransitions(id, hasFix, 7, dist, bat, rssi, cfg, lastAlert, now)
			}
		}(devID)
	}

	wg.Wait()
}
