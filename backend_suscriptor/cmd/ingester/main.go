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
	RetentionDays     = 15 // TTL para histórico y alertas en Firestore (días)
	CollarIntervalSec = 60 // Intervalo de transmisión predeterminado (segundos)

	// Parámetros oficiales del elipsoide de referencia WGS-84
	wgs84A = 6378137.0           // Semieje mayor (metros)
	wgs84F = 1.0 / 298.257223563 // Achatamiento polar
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

	// Leer intervalo de variable de entorno con fallback a 60 segundos
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
		if token := c.Subscribe("mascotas/+/alertas", 1, svc.handleAlerts); token.Wait() && token.Error() != nil {
			log.Printf("❌ [MQTT ERROR] Error al suscribirse a alertas: %v", token.Error())
		}

		log.Println("🎧 [MQTT] Escuchando tópicos de telemetria, status y alertas.")
	})

	opts.SetConnectionLostHandler(func(c mqtt.Client, err error) {
		log.Printf("⚠️ [MQTT] Conexión perdida: %v. Reintentando...", err)
	})

	client := mqtt.NewClient(opts)
	if token := client.Connect(); token.Wait() && token.Error() != nil {
		log.Fatalf("🔥 [FATAL] Error conectando a HiveMQ: %v", token.Error())
	}

	// 5. Iniciar listeners y supervisores en segundo plano
	go svc.watchConfigChanges(ctx, client)
	go svc.startOfflineWatchdog(ctx)

	// 6. Manejo de terminación elegante (Graceful Shutdown)
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)
	<-sigChan

	log.Println("🛑 Cerrando servicio de ingesta...")
	client.Disconnect(250)
	log.Println("👋 Servicio detenido correctamente.")
}

// ----------------------------------------------------------------------------
// HANDLER 1: TELEMETRÍA PERIÓDICA CON AUDITORÍA DE PÉRDIDAS Y CÁLCULO WGS-84
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

	err := s.firestoreClient.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		docSnapshot, err := tx.Get(collarDocRef)
		nameToKeep := ""
		var prevSeq uint32 = 0
		var totalReceived int64 = 0
		var totalLost int64 = 0
		hasConfig := false

		// Coordenadas base por defecto si el documento aún no tiene base_coords configurado
		baseCoords := models.BaseCoords{
			Lat: -8.066663,
			Lon: -79.062807,
		}

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
			if _, err := docSnapshot.DataAt("config"); err == nil {
				hasConfig = true
			}

			// 1. EXTRAER base_coords DINÁMICO DE FIRESTORE (Configurable desde Flutter)
			if bcVal, err := docSnapshot.DataAt("base_coords"); err == nil {
				if bcMap, ok := bcVal.(map[string]any); ok {
					if latVal, ok := parseCoordinate(bcMap["lat"]); ok {
						baseCoords.Lat = latVal
					}
					if lonVal, ok := parseCoordinate(bcMap["lon"]); ok {
						baseCoords.Lon = lonVal
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

		// Cálculo de paquetes perdidos en el salto
		var lostInGap int64 = 0
		if prevSeq > 0 {
			if payload.Seq > prevSeq {
				lostInGap = int64(payload.Seq - prevSeq - 1)
			} else if prevSeq > 65000 && payload.Seq < 500 {
				lostInGap = int64((65535 - prevSeq) + payload.Seq)
			} else {
				lostInGap = 0
			}
		}

		totalReceived++
		totalLost += lostInGap

		var lossPct = 0.0
		if totalExpected := totalReceived + totalLost; totalExpected > 0 {
			lossPct = (float64(totalLost) / float64(totalExpected)) * 100.0
		}

		payload.Radio.PacketsLostGap = int(lostInGap)

		// 2. CÁLCULO DE DISTANCIA GEODÉSICA SOBRE ELIPSOIDE WGS-84
		var distHomeM = 0.0
		if payload.Status.GpsFix && payload.Coords.Lat != 0 && payload.Coords.Lon != 0 && baseCoords.Lat != 0 && baseCoords.Lon != 0 {
			rawDist := GeodesicDistanceWGS84(payload.Coords.Lat, payload.Coords.Lon, baseCoords.Lat, baseCoords.Lon)
			distHomeM = math.Round(rawDist*10.0) / 10.0 // Redondeo a 1 decimal
		}
		payload.Radio.DistanceHomeM = distHomeM

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
			"base_coords":      baseCoords, // Preserva y persiste las coordenadas base dinámicas
			"status":           payload.Status,
			"radio":            payload.Radio,
			"packets_received": totalReceived,
			"packets_lost":     totalLost,
			"packet_loss_pct":  math.Round(lossPct*100.0) / 100.0,
		}

		// Inicialización si es un collar nuevo
		if !hasConfig {
			defaultConfig := models.CollarConfig{
				MaxDistanceM:  200.0,
				MinBatteryPct: 10,
				RequireGpsFix: true,
			}
			latestData["config"] = defaultConfig
			log.Printf("⚙️ [CONFIG INIT] Creando configuración por defecto en Firestore para %s", payload.DeviceID)
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

	log.Printf("📍 [TELEMETRIA] %s (#%d) | Lat: %.6f, Lon: %.6f | Dist WGS-84: %.1fm | Pérdida salto: %d",
		payload.DeviceID, payload.Seq, payload.Coords.Lat, payload.Coords.Lon, payload.Radio.DistanceHomeM, payload.Radio.PacketsLostGap)
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

// isRecoveryAlert identifica si el evento resuelve una incidencia previa
func isRecoveryAlert(alertType string) bool {
	return strings.HasSuffix(alertType, "_RESTORED") ||
		strings.HasSuffix(alertType, "_NORMAL") ||
		alertType == "ALERT_CLEARED"
}

// ----------------------------------------------------------------------------
// HANDLER 3: ALERTAS CRÍTICAS + PUSH NOTIFICATIONS
// ----------------------------------------------------------------------------
func (s *IngestService) handleAlerts(_ mqtt.Client, msg mqtt.Message) {
	var payload models.AlertPayload
	if err := json.Unmarshal(msg.Payload(), &payload); err != nil {
		log.Printf("❌ [ERROR] Alerta JSON inválida: %v", err)
		return
	}

	if payload.DeviceID == "" {
		return
	}

	payload.Severity = strings.ToUpper(strings.TrimSpace(payload.Severity))
	payload.Type = strings.ToUpper(strings.TrimSpace(payload.Type))

	now := time.Now().UTC()
	if payload.Timestamp.IsZero() {
		payload.Timestamp = now
	}
	expireAt := now.AddDate(0, 0, RetentionDays)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	collarDocRef := s.firestoreClient.Collection("collars").Doc(payload.DeviceID)
	alertDocRef := collarDocRef.Collection("alerts").NewDoc()

	alertRecord := models.AlertRecord{
		Timestamp: payload.Timestamp,
		ExpireAt:  expireAt,
		Type:      payload.Type,
		Severity:  payload.Severity,
		Value:     payload.Value,
	}

	lastAlert := models.LastAlertInfo{
		Type:      payload.Type,
		Severity:  payload.Severity,
		Value:     payload.Value,
		Timestamp: payload.Timestamp,
	}

	petName := "Mascota"

	err := s.firestoreClient.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		docSnapshot, err := tx.Get(collarDocRef)
		currentHasActiveAlert := false

		if err == nil && docSnapshot.Exists() {
			if existingName, err := docSnapshot.DataAt("name"); err == nil {
				petName = fmt.Sprintf("%v", existingName)
			}
			if activeAlertVal, err := docSnapshot.DataAt("has_active_alert"); err == nil {
				if b, ok := activeAlertVal.(bool); ok {
					currentHasActiveAlert = b
				}
			}
		}

		newHasActiveAlert := currentHasActiveAlert
		if isRecoveryAlert(payload.Type) {
			newHasActiveAlert = false
		} else if payload.Severity == models.SeverityCritical || payload.Severity == models.SeverityWarning {
			newHasActiveAlert = true
		}

		if err := tx.Set(alertDocRef, alertRecord); err != nil {
			return err
		}

		return tx.Set(collarDocRef, map[string]any{
			"has_active_alert": newHasActiveAlert,
			"last_alert":       lastAlert,
			"last_seen":        now,
		}, firestore.MergeAll)
	})

	if err != nil {
		log.Printf("❌ [ERROR] Fallo al registrar alerta para %s: %v", payload.DeviceID, err)
		return
	}

	log.Printf("🚨 [ALERTA] %s -> [%s] (Activa: %t)", payload.DeviceID, payload.Type, !isRecoveryAlert(payload.Type))

	s.sendPushNotification(context.Background(), payload, petName)
}

func (s *IngestService) sendPushNotification(ctx context.Context, alert models.AlertPayload, petName string) {
	topic := fmt.Sprintf("collar_%s", alert.DeviceID)

	titleLocKey := fmt.Sprintf("alert_%s_title", strings.ToLower(alert.Severity))
	bodyLocKey := fmt.Sprintf("alert_%s_body", strings.ToLower(alert.Type))

	valStr := fmt.Sprintf("%.1f", alert.Value)
	locArgs := []string{petName, valStr}

	channelID := "michi_info_channel"
	if alert.Severity == models.SeverityCritical {
		channelID = "michi_critical_channel"
	}

	fcmMessage := &messaging.Message{
		Topic: topic,
		Data: map[string]string{
			"device_id": alert.DeviceID,
			"pet_name":  petName,
			"type":      alert.Type,
			"severity":  alert.Severity,
			"value":     valStr,
			"timestamp": alert.Timestamp.Format(time.RFC3339),
		},
		Android: &messaging.AndroidConfig{
			Priority: "high",
			Notification: &messaging.AndroidNotification{
				Sound:        "default",
				ChannelID:    channelID,
				Tag:          fmt.Sprintf("collar_%s", alert.DeviceID),
				TitleLocKey:  titleLocKey,
				TitleLocArgs: []string{petName},
				BodyLocKey:   bodyLocKey,
				BodyLocArgs:  locArgs,
			},
		},
		APNS: &messaging.APNSConfig{
			Payload: &messaging.APNSPayload{
				Aps: &messaging.Aps{
					Sound: "default",
					Alert: &messaging.ApsAlert{
						TitleLocKey:  titleLocKey,
						TitleLocArgs: []string{petName},
						LocKey:       bodyLocKey,
						LocArgs:      locArgs,
					},
				},
			},
		},
	}

	response, err := s.fcmClient.Send(ctx, fcmMessage)
	if err != nil {
		log.Printf("❌ [FCM ERROR] Fallo enviando notificación al tópico %s: %v", topic, err)
		return
	}
	log.Printf("📲 [FCM OK] Push enviado con llaves de traducción (ID: %s)", response)
}

// ----------------------------------------------------------------------------
// HANDLER 4: CONFIGURACIÓN DINÁMICA
// ----------------------------------------------------------------------------
func (s *IngestService) watchConfigChanges(ctx context.Context, mqttClient mqtt.Client) {
	log.Println("⚙️ [CONFIG] Iniciando listener en tiempo real de configuraciones...")

	cachedConfigs := make(map[string]models.CollarConfig)
	snapshots := s.firestoreClient.Collection("collars").Snapshots(ctx)

	for {
		snap, err := snapshots.Next()
		if err != nil {
			if ctx.Err() != nil {
				return
			}
			log.Printf("❌ [CONFIG ERROR] Error en listener de Firestore: %v", err)
			time.Sleep(2 * time.Second)
			continue
		}

		for _, change := range snap.Changes {
			if change.Kind == firestore.DocumentAdded || change.Kind == firestore.DocumentModified {
				deviceID := change.Doc.Ref.ID

				var docData struct {
					Config *models.CollarConfig `firestore:"config"`
				}

				if err := change.Doc.DataTo(&docData); err != nil || docData.Config == nil {
					continue
				}

				newCfg := *docData.Config
				lastCfg, exists := cachedConfigs[deviceID]

				if !exists || lastCfg != newCfg {
					cachedConfigs[deviceID] = newCfg

					payloadBytes, err := json.Marshal(newCfg)
					if err != nil {
						log.Printf("❌ [CONFIG ERROR] Error serializando config: %v", err)
						continue
					}

					topic := fmt.Sprintf("mascotas/%s/config", deviceID)
					token := mqttClient.Publish(topic, 1, true, payloadBytes)
					token.Wait()

					if token.Error() != nil {
						log.Printf("❌ [CONFIG ERROR] Fallo al publicar config en %s: %v", topic, token.Error())
					} else {
						log.Printf("✅ [CONFIG OK] Nueva config enviada a %s (Retained): %s", topic, string(payloadBytes))
					}
				}
			}
		}
	}
}

// ----------------------------------------------------------------------------
// HANDLER 5: SUPERVISOR DE INACTIVIDAD DINÁMICO (HEARTBEAT WATCHDOG)
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

// GeodesicDistanceWGS84 calcula la distancia geodésica sobre el elipsoide WGS-84 (Lambert-Andoyer)
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

	// Latitudes reducidas sobre el elipsoide
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

// parseCoordinate castea con seguridad cualquier valor numérico (int, int64 o float64) de Firestore
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
