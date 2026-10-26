package main

import (
	"backend_suscriptor/internal/models"
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"log"
	"math"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"

	"cloud.google.com/go/firestore"
	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	mqtt "github.com/eclipse/paho.mqtt.golang"
	"github.com/joho/godotenv"
)

// Constantes globales de configuración
const (
	RetentionDays     = 15  // TTL para histórico y alertas en Firestore (días)
	CollarIntervalSec = 120 // Intervalo de transmisión predeterminado (segundos)

	// NotificationChannelCritical Canales de notificación Android
	NotificationChannelCritical = "michi_critical_channel"
	NotificationChannelWarning  = "michi_warning_channel"
	NotificationChannelInfo     = "michi_info_channel"

	// Parámetros oficiales del elipsoide de referencia WGS-84
	wgs84A = 6378137.0           // Semieje mayor (metros)
	wgs84F = 1.0 / 298.257223563 // Achatamiento polar

	// LoraWeakRssiThreshold Umbrales de enlace y batería
	LoraWeakRssiThreshold = -115 // dBm
	BatteryCriticalPct    = 10   // %
)

// IngestService Estructura de manejo de clientes y lógica para el servicio de ingesta
type IngestService struct {
	firestoreClient   *firestore.Client
	fcmClient         *messaging.Client
	projectID         string
	collarIntervalSec int
}

func main() {
	ctx := context.Background()

	// 0. Cargar variables de entorno locales si existen
	if err := godotenv.Load(); err != nil {
		log.Println("ℹ️ [INFO] Usando variables de entorno del sistema.")
	}

	// 1. Obtener variables de configuración
	projectID := getEnv("GCP_PROJECT_ID", "")
	hivemqBroker := getEnv("HIVEMQ_BROKER", "")
	hivemqUser := getEnv("HIVEMQ_USER", "")
	hivemqPass := getEnv("HIVEMQ_PASS", "")

	// 2. Inicializar cliente Firestore mediante Application Default Credentials (ADC)
	fsClient, err := firestore.NewClient(ctx, projectID)
	if err != nil {
		log.Fatalf("🔥 [FATAL] Error inicializando Firestore client: %v", err)
	}
	defer func(fsClient *firestore.Client) {
		if err := fsClient.Close(); err != nil {
			log.Printf("⚠️ [WARN] Error cerrando Firestore client: %v", err)
		}
	}(fsClient)

	// 3. Inicializar cliente Firebase Cloud Messaging (FCM)
	fbApp, err := firebase.NewApp(ctx, &firebase.Config{ProjectID: projectID})
	if err != nil {
		log.Fatalf("🔥 [FATAL] Error inicializando Firebase App: %v", err)
	}
	fcmClient, err := fbApp.Messaging(ctx)
	if err != nil {
		log.Fatalf("🔥 [FATAL] Error inicializando FCM Client: %v", err)
	}

	// Leer intervalo de variable de entorno con fallback a 120 segundos
	intervalSec := CollarIntervalSec
	if envInterval := getEnv("COLLAR_INTERVAL_SEC", ""); envInterval != "" {
		if val, err := strconv.Atoi(envInterval); err == nil && val > 0 {
			intervalSec = val
		}
	}

	svc := &IngestService{
		firestoreClient:   fsClient,
		fcmClient:         fcmClient,
		projectID:         projectID,
		collarIntervalSec: intervalSec,
	}

	// 4. Configuración del cliente MQTT Paho
	opts := mqtt.NewClientOptions()
	opts.AddBroker(hivemqBroker)
	opts.SetClientID(fmt.Sprintf("gcp-ingest-%d", time.Now().Unix()))
	opts.SetUsername(hivemqUser)
	opts.SetPassword(hivemqPass)
	opts.SetTLSConfig(&tls.Config{InsecureSkipVerify: false})
	opts.SetAutoReconnect(true)
	opts.SetMaxReconnectInterval(10 * time.Second)
	opts.SetKeepAlive(60 * time.Second)

	opts.SetOnConnectHandler(func(c mqtt.Client) {
		log.Println("📡 [MQTT] Conectado exitosamente a HiveMQ Cloud.")

		if token := c.Subscribe("mascotas/+/telemetria", 1, svc.handleTelemetry); token.Wait() && token.Error() != nil {
			log.Printf("❌ [MQTT ERROR] Error al suscribirse a telemetria: %v", token.Error())
		}
		if token := c.Subscribe("mascotas/+/status", 1, svc.handleStatus); token.Wait() && token.Error() != nil {
			log.Printf("❌ [MQTT ERROR] Error al suscribirse a status: %v", token.Error())
		}

		log.Println("🎧 [MQTT] Escuchando tópicos de telemetria y status.")
	})

	opts.SetConnectionLostHandler(func(c mqtt.Client, err error) {
		log.Printf("⚠️ [MQTT] Conexión perdida: %v. Reintentando...", err)
	})

	client := mqtt.NewClient(opts)
	if token := client.Connect(); token.Wait() && token.Error() != nil {
		log.Fatalf("🔥 [FATAL] Error conectando a HiveMQ: %v", token.Error())
	}

	// 5. Iniciar supervisor de inactividad
	go svc.startOfflineWatchdog(ctx)

	// 6. Manejo de terminación elegante
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)
	<-sigChan

	log.Println("🛑 Cerrando servicio de ingesta...")
	client.Disconnect(250)
	log.Println("👋 Servicio detenido correctamente.")
}

// ----------------------------------------------------------------------------
// HANDLER 1: TELEMETRÍA, WGS-84 Y MOTOR DE ALERTAS EN SERVIDOR
// ----------------------------------------------------------------------------
func (s *IngestService) handleTelemetry(_ mqtt.Client, msg mqtt.Message) {
	var payload models.TelemetryPayload
	if err := json.Unmarshal(msg.Payload(), &payload); err != nil {
		log.Printf("❌ [ERROR] Telemetría JSON inválida: %v", err)
		return
	}

	if payload.DeviceID == "" {
		payload.DeviceID = "COLLAR_01"
	}

	now := time.Now().UTC()
	expireAt := now.AddDate(0, 0, RetentionDays)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	collarDocRef := s.firestoreClient.Collection("collars").Doc(payload.DeviceID)
	historyDocRef := collarDocRef.Collection("history").NewDoc()

	var alertsToTrigger []models.AlertPayload
	petNameToNotify := "Mi Mascota"
	langToNotify := "es"

	err := s.firestoreClient.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		docSnapshot, err := tx.Get(collarDocRef)
		nameToKeep := ""
		var prevSeq uint32 = 0
		var totalReceived int64 = 0
		var totalLost int64 = 0
		hasConfig := false
		hasValidBaseCoords := false

		// Coordenadas base por defecto
		baseLat := -8.066663
		baseLon := -79.062807

		// Configuración predeterminada
		collarConfig := models.CollarConfig{
			MaxDistanceM:  150.0,
			MinBatteryPct: 10,
			RequireGpsFix: true,
			NotifLanguage: "es",
		}

		// Estado previo de alertas almacenado en Firestore (No en memoria volátil)
		var lastAlert models.LastAlertInfo
		hasActiveAlert := false

		if err == nil && docSnapshot.Exists() {
			if existingName, err := docSnapshot.DataAt("name"); err == nil {
				nameToKeep = fmt.Sprintf("%v", existingName)
			}
			if seqVal, err := docSnapshot.DataAt("seq"); err == nil {
				if v, ok := seqVal.(int64); ok {
					prevSeq = uint32(v)
				}
			}
			if rxVal, err := docSnapshot.DataAt("packets_received"); err == nil {
				if v, ok := rxVal.(int64); ok {
					totalReceived = v
				}
			}
			if lostVal, err := docSnapshot.DataAt("packets_lost"); err == nil {
				if v, ok := lostVal.(int64); ok {
					totalLost = v
				}
			}

			// 1. LEER CONFIGURACIÓN DEL COLLAR
			if cfgVal, err := docSnapshot.DataAt("config"); err == nil {
				if cfgMap, ok := cfgVal.(map[string]any); ok {
					hasConfig = true
					if maxD, ok := parseCoordinate(cfgMap["max_distance_m"]); ok && maxD > 0 {
						collarConfig.MaxDistanceM = maxD
					}
					if minBat, ok := parseCoordinate(cfgMap["min_battery_pct"]); ok && minBat > 0 {
						collarConfig.MinBatteryPct = int(minBat)
					}
					if reqFix, ok := cfgMap["require_gps_fix"].(bool); ok {
						collarConfig.RequireGpsFix = reqFix
					}
					if lang, ok := cfgMap["notif_language"].(string); ok && lang != "" {
						collarConfig.NotifLanguage = lang
					}
				}
			}

			// 2. LEER ESTADO PREVIO DE ALERTAS DE FIRESTORE
			if haVal, err := docSnapshot.DataAt("has_active_alert"); err == nil {
				if b, ok := haVal.(bool); ok {
					hasActiveAlert = b
				}
			}
			if laVal, err := docSnapshot.DataAt("last_alert"); err == nil {
				if laMap, ok := laVal.(map[string]any); ok {
					if t, ok := laMap["type"].(string); ok {
						lastAlert.Type = t
					}
					if s, ok := laMap["severity"].(string); ok {
						lastAlert.Severity = s
					}
				}
			}

			// 3. LEER base_coords DE FIRESTORE (Sin sobrescribir)
			if bcVal, err := docSnapshot.DataAt("base_coords"); err == nil {
				if bcMap, ok := bcVal.(map[string]any); ok {
					latVal, okLat := parseCoordinate(bcMap["lat"])
					lonVal, okLon := parseCoordinate(bcMap["lon"])
					if okLat && okLon && (latVal != 0 || lonVal != 0) {
						baseLat = latVal
						baseLon = lonVal
						hasValidBaseCoords = true
					}
				}
			}
		}

		if nameToKeep == "" {
			if payload.PetName != "" {
				nameToKeep = payload.PetName
			} else {
				nameToKeep = "Mi Mascota"
			}
		}
		petNameToNotify = nameToKeep
		langToNotify = collarConfig.NotifLanguage

		// Cálculo de paquetes perdidos
		var lostInGap int64 = 0
		if prevSeq > 0 {
			if payload.Seq > prevSeq {
				lostInGap = int64(payload.Seq - prevSeq - 1)
			} else if prevSeq > 65000 && payload.Seq < 500 {
				lostInGap = int64((65535 - prevSeq) + payload.Seq)
			}
		}

		totalReceived++
		totalLost += lostInGap

		var lossPct = 0.0
		if totalExpected := totalReceived + totalLost; totalExpected > 0 {
			lossPct = (float64(totalLost) / float64(totalExpected)) * 100.0
		}
		payload.Radio.PacketsLostGap = int(lostInGap)

		// 4. CÁLCULO DE DISTANCIA GEODÉSICA WGS-84
		var distHomeM = 0.0
		if payload.Status.GpsFix && payload.Coords.Lat != 0 && payload.Coords.Lon != 0 && baseLat != 0 && baseLon != 0 {
			rawDist := GeodesicDistanceWGS84(payload.Coords.Lat, payload.Coords.Lon, baseLat, baseLon)
			distHomeM = math.Round(rawDist*10.0) / 10.0
		}
		payload.Radio.DistanceHomeM = distHomeM

		// 5. MOTOR DE EVALUACIÓN BASADO EN EL ESTADO REAL DE FIRESTORE
		alertsToTrigger = evaluateAlertTransitions(payload.DeviceID, payload.Status.GpsFix, uint8(payload.Status.Sats),
			distHomeM, payload.Status.BatteryPct, float64(payload.Radio.RSSI), collarConfig, lastAlert, now)

		historyRecord := models.HistoryRecord{
			Timestamp: now,
			ExpireAt:  expireAt,
			Seq:       payload.Seq,
			Coords:    payload.Coords,
			Status:    payload.Status,
			Radio:     payload.Radio,
		}

		latestData := map[string]any{
			"device_id":        payload.DeviceID,
			"name":             nameToKeep,
			"last_seen":        now,
			"is_online":        true,
			"seq":              payload.Seq,
			"coords":           payload.Coords,
			"status":           payload.Status,
			"radio":            payload.Radio,
			"packets_received": totalReceived,
			"packets_lost":     totalLost,
			"packet_loss_pct":  math.Round(lossPct*100.0) / 100.0,
		}

		// 6. PERSISTENCIA DE ALERTAS EN LA COLECCIÓN 'alerts'
		for _, alert := range alertsToTrigger {
			alertDocRef := collarDocRef.Collection("alerts").NewDoc()
			alertRecord := models.AlertRecord{
				Timestamp: alert.Timestamp,
				ExpireAt:  expireAt,
				Type:      alert.Type,
				Severity:  alert.Severity,
				Value:     alert.Value,
			}
			if err := tx.Set(alertDocRef, alertRecord); err != nil {
				return err
			}

			if isRecoveryAlert(alert.Type) {
				hasActiveAlert = false
			} else if alert.Severity == models.SeverityCritical || alert.Severity == models.SeverityWarning {
				hasActiveAlert = true
			}

			lastAlert = models.LastAlertInfo{
				Type:      alert.Type,
				Severity:  alert.Severity,
				Value:     alert.Value,
				Timestamp: alert.Timestamp,
			}
		}

		latestData["has_active_alert"] = hasActiveAlert
		latestData["last_alert"] = lastAlert

		if !hasValidBaseCoords {
			latestData["base_coords"] = models.BaseCoords{
				Lat: baseLat,
				Lon: baseLon,
			}
		}

		if !hasConfig {
			latestData["config"] = collarConfig
		}

		if err := tx.Set(collarDocRef, latestData, firestore.MergeAll); err != nil {
			return err
		}
		return tx.Set(historyDocRef, historyRecord)
	})

	if err != nil {
		log.Printf("❌ [ERROR] Fallo al persistir telemetría para %s: %v", payload.DeviceID, err)
		return
	}

	log.Printf("📍 [TELEMETRIA] %s (#%d) | Lat: %.6f, Lon: %.6f | Dist WGS-84: %.1fm | Fix: %t (%dS)",
		payload.DeviceID, payload.Seq, payload.Coords.Lat, payload.Coords.Lon, payload.Radio.DistanceHomeM, payload.Status.GpsFix, payload.Status.Sats)

	// 7. DISPARAR PUSH NOTIFICATIONS
	for _, alert := range alertsToTrigger {
		log.Printf("🚨 [ALERTA GENERADA] %s -> [%s] (%s): %.1f", alert.DeviceID, alert.Type, alert.Severity, alert.Value)
		s.sendPushNotification(context.Background(), alert, petNameToNotify, langToNotify)
	}
}

// ----------------------------------------------------------------------------
// EVALUACIÓN DE TRANSICIONES CONTRA EL ÚLTIMO ESTADO DE FIRESTORE
// ----------------------------------------------------------------------------
func evaluateAlertTransitions(devID string, hasFix bool, sats uint8,
	distM float64, batPct int, rssi float64, cfg models.CollarConfig,
	lastAlert models.LastAlertInfo, now time.Time) []models.AlertPayload {

	var alerts []models.AlertPayload

	// --- 1. GEOVALLA ---
	if hasFix {
		if distM > cfg.MaxDistanceM && lastAlert.Type != "GEOFENCE_BREACH" {
			alerts = append(alerts, models.AlertPayload{
				DeviceID:  devID,
				Type:      "GEOFENCE_BREACH",
				Severity:  models.SeverityCritical,
				Value:     distM,
				Timestamp: now,
			})
		} else if distM <= cfg.MaxDistanceM && lastAlert.Type == "GEOFENCE_BREACH" {
			alerts = append(alerts, models.AlertPayload{
				DeviceID:  devID,
				Type:      "GEOFENCE_RESTORED",
				Severity:  models.SeverityInfo,
				Value:     distM,
				Timestamp: now,
			})
		}
	}

	// --- 2. BATERÍA ---
	if batPct <= BatteryCriticalPct {
		if lastAlert.Type != "BATTERY_CRITICAL" {
			alerts = append(alerts, models.AlertPayload{
				DeviceID:  devID,
				Type:      "BATTERY_CRITICAL",
				Severity:  models.SeverityCritical,
				Value:     float64(batPct),
				Timestamp: now,
			})
		}
	} else if batPct <= cfg.MinBatteryPct {
		if lastAlert.Type != "LOW_BATTERY" && lastAlert.Type != "BATTERY_CRITICAL" {
			alerts = append(alerts, models.AlertPayload{
				DeviceID:  devID,
				Type:      "LOW_BATTERY",
				Severity:  models.SeverityWarning,
				Value:     float64(batPct),
				Timestamp: now,
			})
		}
	} else {
		if lastAlert.Type == "LOW_BATTERY" || lastAlert.Type == "BATTERY_CRITICAL" {
			alerts = append(alerts, models.AlertPayload{
				DeviceID:  devID,
				Type:      "BATTERY_NORMAL",
				Severity:  models.SeverityInfo,
				Value:     float64(batPct),
				Timestamp: now,
			})
		}
	}

	// --- 3. FIX SATELITAL (GPS) ---
	if cfg.RequireGpsFix {
		// Se dispara cuando no hay fix y la última alerta registrada no fue NO_GPS_FIX
		if !hasFix && lastAlert.Type != "NO_GPS_FIX" {
			alerts = append(alerts, models.AlertPayload{
				DeviceID:  devID,
				Type:      "NO_GPS_FIX",
				Severity:  models.SeverityWarning,
				Value:     0,
				Timestamp: now,
			})
		} else if hasFix && lastAlert.Type == "NO_GPS_FIX" {
			alerts = append(alerts, models.AlertPayload{
				DeviceID:  devID,
				Type:      "GPS_FIX_RESTORED",
				Severity:  models.SeverityInfo,
				Value:     float64(sats),
				Timestamp: now,
			})
		}
	}

	// --- 4. SEÑAL LORA ---
	if rssi < LoraWeakRssiThreshold && lastAlert.Type != "WEAK_SIGNAL" {
		alerts = append(alerts, models.AlertPayload{
			DeviceID:  devID,
			Type:      "WEAK_SIGNAL",
			Severity:  models.SeverityWarning,
			Value:     rssi,
			Timestamp: now,
		})
	} else if rssi >= LoraWeakRssiThreshold+10 && lastAlert.Type == "WEAK_SIGNAL" {
		alerts = append(alerts, models.AlertPayload{
			DeviceID:  devID,
			Type:      "SIGNAL_NORMAL",
			Severity:  models.SeverityInfo,
			Value:     rssi,
			Timestamp: now,
		})
	}

	return alerts
}

func isRecoveryAlert(alertType string) bool {
	return strings.HasSuffix(alertType, "_RESTORED") ||
		strings.HasSuffix(alertType, "_NORMAL") ||
		alertType == "ALERT_CLEARED"
}

// ----------------------------------------------------------------------------
// HANDLER 2: ESTADO Y PRESENCIA (LWT)
// ----------------------------------------------------------------------------
func (s *IngestService) handleStatus(_ mqtt.Client, msg mqtt.Message) {
	var payload models.StatusPayload
	if err := json.Unmarshal(msg.Payload(), &payload); err != nil {
		log.Printf("❌ [ERROR] Status JSON inválido: %v", err)
		return
	}

	if payload.DeviceID == "" {
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	collarDocRef := s.firestoreClient.Collection("collars").Doc(payload.DeviceID)
	now := time.Now().UTC()

	_, err := collarDocRef.Set(ctx, map[string]any{
		"is_online": payload.Status == "online",
		"last_seen": now,
	}, firestore.MergeAll)

	if err != nil {
		log.Printf("❌ [ERROR] Fallo al actualizar status de %s: %v", payload.DeviceID, err)
		return
	}

	log.Printf("📶 [STATUS] %s pasó a: %s (is_online: %t)", payload.DeviceID, payload.Status, payload.Status == "online")
}

// ----------------------------------------------------------------------------
// NOTIFICACIONES PUSH MULTI-IDIOMA
// ----------------------------------------------------------------------------
func (s *IngestService) sendPushNotification(ctx context.Context, alert models.AlertPayload, petName string, lang string) {
	topic := alert.DeviceID

	title, body := buildLocalizedNotification(lang, alert.Severity, alert.Type, petName, alert.Value)

	channelID := NotificationChannelInfo
	androidPriority := "normal"
	notifPriority := messaging.PriorityDefault

	switch alert.Severity {
	case models.SeverityCritical:
		channelID = NotificationChannelCritical
		androidPriority = "high"
		notifPriority = messaging.PriorityHigh
	case models.SeverityWarning:
		channelID = NotificationChannelWarning
		androidPriority = "high"
		notifPriority = messaging.PriorityHigh
	default:
		channelID = NotificationChannelInfo
		androidPriority = "normal"
		notifPriority = messaging.PriorityDefault
	}

	fcmMessage := &messaging.Message{
		Topic: topic,
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data: map[string]string{
			"device_id": alert.DeviceID,
		},
		Android: &messaging.AndroidConfig{
			CollapseKey: alert.DeviceID,
			Priority:    androidPriority,
			Notification: &messaging.AndroidNotification{
				Sound:     "default",
				ChannelID: channelID,
				Priority:  notifPriority,
				Tag:       alert.DeviceID,
				Title:     title,
				Body:      body,
			},
		},
		APNS: &messaging.APNSConfig{
			Headers: map[string]string{
				"apns-collapse-id": alert.DeviceID,
			},
			Payload: &messaging.APNSPayload{
				Aps: &messaging.Aps{
					Sound: "default",
					Alert: &messaging.ApsAlert{
						Title: title,
						Body:  body,
					},
				},
			},
		},
	}

	response, err := s.fcmClient.Send(ctx, fcmMessage)
	if err != nil {
		log.Printf("❌ [FCM ERROR] Fallo enviando notificación al tópico %s (%s): %v", topic, channelID, err)
		return
	}
	log.Printf("📲 [FCM OK] Push enviado (%s) [Canal: %s, ID: %s]", lang, channelID, response)
}

func buildLocalizedNotification(lang, severity, alertType, petName string, val float64) (string, string) {
	lang = strings.ToLower(strings.TrimSpace(lang))
	if len(lang) >= 2 {
		lang = lang[:2]
	}

	var title, body string

	switch lang {
	case "en":
		switch severity {
		case models.SeverityCritical:
			title = "🚨 Critical Alert"
		case models.SeverityWarning:
			title = "⚠️ Warning"
		default:
			title = "ℹ️ Information"
		}

		switch alertType {
		case "GEOFENCE_BREACH":
			body = fmt.Sprintf("%s has left the safe zone! (Distance: %.0fm)", petName, val)
		case "GEOFENCE_RESTORED":
			body = fmt.Sprintf("%s has returned to the safe zone (Distance: %.0fm).", petName, val)
		case "BATTERY_CRITICAL":
			body = fmt.Sprintf("Critical battery on %s's collar: %.0f%%. Please recharge!", petName, val)
		case "LOW_BATTERY":
			body = fmt.Sprintf("Low battery on %s's collar: %.0f%%.", petName, val)
		case "BATTERY_NORMAL":
			body = fmt.Sprintf("Battery level normalized for %s: %.0f%%.", petName, val)
		case "NO_GPS_FIX":
			body = fmt.Sprintf("%s lost GPS satellite fix.", petName)
		case "GPS_FIX_RESTORED":
			body = fmt.Sprintf("GPS signal restored for %s (%d satellites).", petName, int(val))
		case "WEAK_SIGNAL":
			body = fmt.Sprintf("Weak LoRa connection with %s's collar (%.0f dBm).", petName, val)
		case "SIGNAL_NORMAL":
			body = fmt.Sprintf("LoRa signal normalized for %s (%.0f dBm).", petName, val)
		default:
			body = fmt.Sprintf("Event %s for %s", alertType, petName)
		}

	case "fr":
		switch severity {
		case models.SeverityCritical:
			title = "🚨 Alerte Critique"
		case models.SeverityWarning:
			title = "⚠️ Avertissement"
		default:
			title = "ℹ️ Information"
		}

		switch alertType {
		case "GEOFENCE_BREACH":
			body = fmt.Sprintf("%s a quitté la zone de sécurité ! (Distance : %.0fm)", petName, val)
		case "GEOFENCE_RESTORED":
			body = fmt.Sprintf("%s est de retour dans la zone de sécurité (Distance : %.0fm).", petName, val)
		case "BATTERY_CRITICAL":
			body = fmt.Sprintf("Batterie critique sur le collier de %s : %.0f%% ! Veuillez recharger.", petName, val)
		case "LOW_BATTERY":
			body = fmt.Sprintf("Batterie faible sur le collier de %s : %.0f%%.", petName, val)
		case "BATTERY_NORMAL":
			body = fmt.Sprintf("Niveau de batterie normalisé pour %s : %.0f%%.", petName, val)
		case "NO_GPS_FIX":
			body = fmt.Sprintf("%s a perdu le signal satellite GPS.", petName)
		case "GPS_FIX_RESTORED":
			body = fmt.Sprintf("Signal GPS rétabli pour %s (%d satellites).", petName, int(val))
		case "WEAK_SIGNAL":
			body = fmt.Sprintf("Signal LoRa faible avec le collier de %s (%.0f dBm).", petName, val)
		case "SIGNAL_NORMAL":
			body = fmt.Sprintf("Signal LoRa normalisé pour %s (%.0f dBm).", petName, val)
		default:
			body = fmt.Sprintf("Événement %s pour %s", alertType, petName)
		}

	case "de":
		switch severity {
		case models.SeverityCritical:
			title = "🚨 Kritischer Alarm"
		case models.SeverityWarning:
			title = "⚠️ Warnung"
		default:
			title = "ℹ️ Information"
		}

		switch alertType {
		case "GEOFENCE_BREACH":
			body = fmt.Sprintf("%s hat die Sicherheitszone verlassen! (Entfernung: %.0fm)", petName, val)
		case "GEOFENCE_RESTORED":
			body = fmt.Sprintf("%s ist in die Sicherheitszone zurückgekehrt (Entfernung: %.0fm).", petName, val)
		case "BATTERY_CRITICAL":
			body = fmt.Sprintf("Kritischer Akkustand am Halsband von %s: %.0f%%! Bitte aufladen.", petName, val)
		case "LOW_BATTERY":
			body = fmt.Sprintf("Niedriger Akkustand am Halsband von %s: %.0f%%.", petName, val)
		case "BATTERY_NORMAL":
			body = fmt.Sprintf("Akkustand normalisiert für %s: %.0f%%.", petName, val)
		case "NO_GPS_FIX":
			body = fmt.Sprintf("%s hat das GPS-Satellitensignal verloren.", petName)
		case "GPS_FIX_RESTORED":
			body = fmt.Sprintf("GPS-Signal wiederhergestellt für %s (%d Satelliten).", petName, int(val))
		case "WEAK_SIGNAL":
			body = fmt.Sprintf("Schwache LoRa-Verbindung mit dem Halsband von %s (%.0f dBm).", petName, val)
		case "SIGNAL_NORMAL":
			body = fmt.Sprintf("LoRa-Signal normalisiert für %s (%.0f dBm).", petName, val)
		default:
			body = fmt.Sprintf("Ereignis %s für %s", alertType, petName)
		}

	case "it":
		switch severity {
		case models.SeverityCritical:
			title = "🚨 Allarme Critico"
		case models.SeverityWarning:
			title = "⚠️ Avviso"
		default:
			title = "ℹ️ Informazione"
		}

		switch alertType {
		case "GEOFENCE_BREACH":
			body = fmt.Sprintf("%s è uscito dalla zona sicura! (Distanza: %.0fm)", petName, val)
		case "GEOFENCE_RESTORED":
			body = fmt.Sprintf("%s è tornato nella zona sicura (Distanza: %.0fm).", petName, val)
		case "BATTERY_CRITICAL":
			body = fmt.Sprintf("Batteria critica sul collare di %s: %.0f%%! Ricarica presto.", petName, val)
		case "LOW_BATTERY":
			body = fmt.Sprintf("Batteria scarica sul collare di %s: %.0f%%.", petName, val)
		case "BATTERY_NORMAL":
			body = fmt.Sprintf("Livello batteria normalizzato per %s: %.0f%%.", petName, val)
		case "NO_GPS_FIX":
			body = fmt.Sprintf("%s ha perso il segnale satellitare GPS.", petName)
		case "GPS_FIX_RESTORED":
			body = fmt.Sprintf("Segnale GPS ripristinato per %s (%d satelliti).", petName, int(val))
		case "WEAK_SIGNAL":
			body = fmt.Sprintf("Segnale LoRa debole con il collare di %s (%.0f dBm).", petName, val)
		case "SIGNAL_NORMAL":
			body = fmt.Sprintf("Segnale LoRa normalizzato per %s (%.0f dBm).", petName, val)
		default:
			body = fmt.Sprintf("Evento %s per %s", alertType, petName)
		}

	case "pt":
		switch severity {
		case models.SeverityCritical:
			title = "🚨 Alerta Crítico"
		case models.SeverityWarning:
			title = "⚠️ Aviso"
		default:
			title = "ℹ️ Informação"
		}

		switch alertType {
		case "GEOFENCE_BREACH":
			body = fmt.Sprintf("%s saiu da zona de segurança! (Distância: %.0fm)", petName, val)
		case "GEOFENCE_RESTORED":
			body = fmt.Sprintf("%s retornou à zona de segurança (Distância: %.0fm).", petName, val)
		case "BATTERY_CRITICAL":
			body = fmt.Sprintf("Bateria crítica na coleira de %s: %.0f%%! Recarregue logo.", petName, val)
		case "LOW_BATTERY":
			body = fmt.Sprintf("Bateria fraca na coleira de %s: %.0f%%.", petName, val)
		case "BATTERY_NORMAL":
			body = fmt.Sprintf("Nível de bateria normalizado para %s: %.0f%%.", petName, val)
		case "NO_GPS_FIX":
			body = fmt.Sprintf("%s perdeu o sinal de satélite GPS.", petName)
		case "GPS_FIX_RESTORED":
			body = fmt.Sprintf("Sinal GPS restaurado para %s (%d satélites).", petName, int(val))
		case "WEAK_SIGNAL":
			body = fmt.Sprintf("Sinal LoRa fraco com a coleira de %s (%.0f dBm).", petName, val)
		case "SIGNAL_NORMAL":
			body = fmt.Sprintf("Sinal LoRa normalizado para %s (%.0f dBm).", petName, val)
		default:
			body = fmt.Sprintf("Evento %s para %s", alertType, petName)
		}

	default: // "es"
		switch severity {
		case models.SeverityCritical:
			title = "🚨 Alerta Crítica"
		case models.SeverityWarning:
			title = "⚠️ Advertencia"
		default:
			title = "ℹ️ Información"
		}

		switch alertType {
		case "GEOFENCE_BREACH":
			body = fmt.Sprintf("¡%s ha salido de la zona segura! (Distancia: %.0fm)", petName, val)
		case "GEOFENCE_RESTORED":
			body = fmt.Sprintf("%s ha regresado a la zona segura (Distancia: %.0fm).", petName, val)
		case "BATTERY_CRITICAL":
			body = fmt.Sprintf("¡Batería crítica en el collar de %s: %.0f%%! Recárgalo pronto.", petName, val)
		case "LOW_BATTERY":
			body = fmt.Sprintf("Batería baja en el collar de %s: %.0f%%.", petName, val)
		case "BATTERY_NORMAL":
			body = fmt.Sprintf("Batería normalizada en el collar de %s: %.0f%%.", petName, val)
		case "NO_GPS_FIX":
			body = fmt.Sprintf("%s no tiene señal satelital GPS.", petName)
		case "GPS_FIX_RESTORED":
			body = fmt.Sprintf("Señal GPS recuperada para %s (%d satélites).", petName, int(val))
		case "WEAK_SIGNAL":
			body = fmt.Sprintf("Señal LoRa débil con el collar de %s (%.0f dBm).", petName, val)
		case "SIGNAL_NORMAL":
			body = fmt.Sprintf("Señal LoRa normalizada para %s (%.0f dBm).", petName, val)
		default:
			body = fmt.Sprintf("Evento %s para %s", alertType, petName)
		}
	}

	return title, body
}

// ----------------------------------------------------------------------------
// HANDLER 3: SUPERVISOR DE INACTIVIDAD DINÁMICO (HEARTBEAT WATCHDOG)
// ----------------------------------------------------------------------------
func (s *IngestService) startOfflineWatchdog(ctx context.Context) {
	log.Printf("⏱️ [WATCHDOG] Iniciando supervisor de presencia (Intervalo base: %ds)...", s.collarIntervalSec)

	checkDuration := 30 * time.Second
	ticker := time.NewTicker(checkDuration)
	defer ticker.Stop()

	offlineThreshold := time.Duration(float64(s.collarIntervalSec)*3.5) * time.Second

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			docs, err := s.firestoreClient.Collection("collars").
				Where("is_online", "==", true).
				Documents(ctx).
				GetAll()

			if err != nil {
				log.Printf("⚠️ [WATCHDOG ERROR] Error consultando collares online: %v", err)
				continue
			}

			now := time.Now().UTC()
			for _, doc := range docs {
				lastSeenVal, err := doc.DataAt("last_seen")
				if err != nil {
					continue
				}

				if lastSeen, ok := lastSeenVal.(time.Time); ok {
					if now.Sub(lastSeen) > offlineThreshold {
						deviceID := doc.Ref.ID
						log.Printf("🔌 [WATCHDOG] Collar %s inactivo por %v (> %v umbral). Marcando offline...",
							deviceID, now.Sub(lastSeen).Round(time.Second), offlineThreshold)

						_, err := doc.Ref.Update(ctx, []firestore.Update{
							{Path: "is_online", Value: false},
						})
						if err != nil {
							log.Printf("❌ [WATCHDOG ERROR] Fallo al marcar offline a %s: %v", deviceID, err)
						}
					}
				}
			}
		}
	}
}

// ----------------------------------------------------------------------------
// HELPERS MATEMÁTICOS Y GEODÉSICOS
// ----------------------------------------------------------------------------

func GeodesicDistanceWGS84(lat1, lon1, lat2, lon2 float64) float64 {
	if lat1 == lat2 && lon1 == lon2 {
		return 0.0
	}

	rad := math.Pi / 180.0
	phi1 := lat1 * rad
	phi2 := lat2 * rad
	lambda1 := lon1 * rad
	lambda2 := lon2 * rad

	f := wgs84F
	a := wgs84A

	u1 := math.Atan((1.0 - f) * math.Tan(phi1))
	u2 := math.Atan((1.0 - f) * math.Tan(phi2))

	deltaLambda := lambda2 - lambda1

	sinU1, cosU1 := math.Sin(u1), math.Cos(u1)
	sinU2, cosU2 := math.Sin(u2), math.Cos(u2)
	cosDeltaLambda := math.Cos(deltaLambda)

	cosD := sinU1*sinU2 + cosU1*cosU2*cosDeltaLambda
	if cosD > 1.0 {
		cosD = 1.0
	} else if cosD < -1.0 {
		cosD = -1.0
	}
	d := math.Acos(cosD)

	if d == 0.0 {
		return 0.0
	}

	sinD := math.Sin(d)
	p := (u1 + u2) / 2.0
	q := (u2 - u1) / 2.0

	sinP := math.Sin(p)
	cosP := math.Cos(p)
	sinQ := math.Sin(q)
	cosQ := math.Cos(q)

	cosHalfD := math.Cos(d / 2.0)
	sinHalfD := math.Sin(d / 2.0)
	if cosHalfD == 0.0 || sinHalfD == 0.0 {
		return a * d
	}

	termX := (d - sinD) * (sinP * sinP * cosQ * cosQ) / (cosHalfD * cosHalfD)
	termY := (d + sinD) * (cosP * cosP * sinQ * sinQ) / (sinHalfD * sinHalfD)

	deltaD := (f / 4.0) * (termX - termY)
	distance := a * (d + deltaD)

	return math.Abs(distance)
}

func parseCoordinate(val any) (float64, bool) {
	switch v := val.(type) {
	case float64:
		return v, true
	case int64:
		return float64(v), true
	case int:
		return float64(v), true
	default:
		return 0, false
	}
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}
