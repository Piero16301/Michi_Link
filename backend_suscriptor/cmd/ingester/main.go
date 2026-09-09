package main

import (
	"backend_suscriptor/internal/models"
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"cloud.google.com/go/firestore"
	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	mqtt "github.com/eclipse/paho.mqtt.golang"
	"github.com/joho/godotenv"
)

// RetentionDays Constante de retención para la política TTL en Firestore (15 días)
const RetentionDays = 15

// IngestService Estructura de manejo de clientes y lógica para el servicio de ingesta
type IngestService struct {
	firestoreClient *firestore.Client
	fcmClient       *messaging.Client
	projectID       string
}

func main() {
	ctx := context.Background()

	// 0. Cargar variables de entorno locales si existen
	if err := godotenv.Load(); err != nil {
		log.Println("[INFO] Usando variables de entorno del sistema.")
	}

	// 1. Obtener variables de configuración
	projectID := getEnv("GCP_PROJECT_ID", "")
	hivemqBroker := getEnv("HIVEMQ_BROKER", "")
	hivemqUser := getEnv("HIVEMQ_USER", "")
	hivemqPass := getEnv("HIVEMQ_PASS", "")

	// 2. Inicializar cliente Firestore mediante Application Default Credentials (ADC)
	fsClient, err := firestore.NewClient(ctx, projectID)
	if err != nil {
		log.Fatalf("Error inicializando Firestore client: %v", err)
	}
	defer func(fsClient *firestore.Client) {
		if err := fsClient.Close(); err != nil {
			log.Printf("Error cerrando Firestore client: %v", err)
		}
	}(fsClient)

	// 3. Inicializar cliente Firebase Cloud Messaging (FCM)
	fbApp, err := firebase.NewApp(ctx, &firebase.Config{ProjectID: projectID})
	if err != nil {
		log.Fatalf("Error inicializando Firebase App: %v", err)
	}
	fcmClient, err := fbApp.Messaging(ctx)
	if err != nil {
		log.Fatalf("Error inicializando FCM Client: %v", err)
	}

	svc := &IngestService{
		firestoreClient: fsClient,
		fcmClient:       fcmClient,
		projectID:       projectID,
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
		log.Println("[MQTT] Conectado exitosamente a HiveMQ Cloud.")

		if token := c.Subscribe("mascotas/+/telemetria", 1, svc.handleTelemetry); token.Wait() && token.Error() != nil {
			log.Printf("[MQTT] Error al suscribirse a telemetria: %v", token.Error())
		}
		if token := c.Subscribe("mascotas/+/status", 1, svc.handleStatus); token.Wait() && token.Error() != nil {
			log.Printf("[MQTT] Error al suscribirse a status: %v", token.Error())
		}
		if token := c.Subscribe("mascotas/+/alertas", 1, svc.handleAlerts); token.Wait() && token.Error() != nil {
			log.Printf("[MQTT] Error al suscribirse a alertas: %v", token.Error())
		}

		log.Println("[MQTT] Escuchando tópicos de telemetria, status y alertas.")
	})

	opts.SetConnectionLostHandler(func(c mqtt.Client, err error) {
		log.Printf("[MQTT] Conexión perdida: %v. Reintentando...", err)
	})

	client := mqtt.NewClient(opts)
	if token := client.Connect(); token.Wait() && token.Error() != nil {
		log.Fatalf("Error conectando a HiveMQ: %v", token.Error())
	}

	// 5. Iniciar listener de cambios de configuración en Firestore
	go svc.watchConfigChanges(ctx, client)

	// 6. Manejo de terminación elegante (Graceful Shutdown)
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)
	<-sigChan

	log.Println("Cerrando servicio de ingesta...")
	client.Disconnect(250)
	log.Println("Servicio detenido correctamente.")
}

// ----------------------------------------------------------------------------
// HANDLER 1: TELEMETRÍA PERIÓDICA
// ----------------------------------------------------------------------------
func (s *IngestService) handleTelemetry(_ mqtt.Client, msg mqtt.Message) {
	var payload models.TelemetryPayload
	if err := json.Unmarshal(msg.Payload(), &payload); err != nil {
		log.Printf("[ERROR] Telemetría JSON inválida: %v", err)
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

	historyRecord := models.HistoryRecord{
		Timestamp: now,
		ExpireAt:  expireAt,
		Seq:       payload.Seq,
		Coords:    payload.Coords,
		Status:    payload.Status,
		Radio:     payload.Radio,
	}

	err := s.firestoreClient.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		// Preservar el nombre asignado al collar si ya existe en la base de datos
		docSnapshot, err := tx.Get(collarDocRef)
		nameToKeep := ""

		if err == nil && docSnapshot.Exists() {
			if existingName, err := docSnapshot.DataAt("name"); err == nil {
				nameToKeep = fmt.Sprintf("%v", existingName)
			}
		}

		if nameToKeep == "" {
			if payload.PetName != "" {
				nameToKeep = payload.PetName
			} else {
				nameToKeep = "Mi Mascota"
			}
		}

		latestData := map[string]any{
			"device_id": payload.DeviceID,
			"name":      nameToKeep,
			"last_seen": now,
			"is_online": true,
			"seq":       payload.Seq,
			"coords":    payload.Coords,
			"status":    payload.Status,
			"radio":     payload.Radio,
		}

		if err := tx.Set(collarDocRef, latestData, firestore.MergeAll); err != nil {
			return err
		}
		return tx.Set(historyDocRef, historyRecord)
	})

	if err != nil {
		log.Printf("[ERROR] Fallo al persistir telemetría para %s: %v", payload.DeviceID, err)
		return
	}

	log.Printf("[TELEMETRIA] %s (#%d) | Lat: %.6f, Lon: %.6f | Bat: %.2fV",
		payload.DeviceID, payload.Seq, payload.Coords.Lat, payload.Coords.Lon, payload.Status.BatteryV)
}

// ----------------------------------------------------------------------------
// HANDLER 2: ESTADO Y PRESENCIA (LWT)
// ----------------------------------------------------------------------------
func (s *IngestService) handleStatus(_ mqtt.Client, msg mqtt.Message) {
	var payload models.StatusPayload
	if err := json.Unmarshal(msg.Payload(), &payload); err != nil {
		log.Printf("[ERROR] Status JSON inválido: %v", err)
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
		"is_online":   payload.Status == "online",
		"status_text": payload.Status,
		"last_seen":   now,
	}, firestore.MergeAll)

	if err != nil {
		log.Printf("[ERROR] Fallo al actualizar status de %s: %v", payload.DeviceID, err)
		return
	}

	log.Printf("[STATUS] %s pasó a: %s", payload.DeviceID, payload.Status)
}

// ----------------------------------------------------------------------------
// HANDLER 3: ALERTAS CRÍTICAS + PUSH NOTIFICATIONS
// ----------------------------------------------------------------------------
func (s *IngestService) handleAlerts(_ mqtt.Client, msg mqtt.Message) {
	var payload models.AlertPayload
	if err := json.Unmarshal(msg.Payload(), &payload); err != nil {
		log.Printf("[ERROR] Alerta JSON inválida: %v", err)
		return
	}

	if payload.DeviceID == "" {
		return
	}

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
		Message:   payload.Message,
		Severity:  payload.Severity,
		Value:     payload.Value,
	}

	lastAlert := models.LastAlertInfo{
		Type:      payload.Type,
		Message:   payload.Message,
		Severity:  payload.Severity,
		Timestamp: payload.Timestamp,
	}

	petName := "Mascota"

	err := s.firestoreClient.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		// Obtener el nombre de la mascota configurado para la notificación
		if docSnapshot, err := tx.Get(collarDocRef); err == nil && docSnapshot.Exists() {
			if existingName, err := docSnapshot.DataAt("name"); err == nil {
				petName = fmt.Sprintf("%v", existingName)
			}
		}

		if err := tx.Set(alertDocRef, alertRecord); err != nil {
			return err
		}

		// B. Levantar indicador en el documento principal
		return tx.Set(collarDocRef, map[string]any{
			"has_active_alert": true,
			"last_alert":       lastAlert,
			"last_seen":        now,
		}, firestore.MergeAll)
	})

	if err != nil {
		log.Printf("[ERROR] Fallo al registrar alerta para %s: %v", payload.DeviceID, err)
		return
	}

	log.Printf("[ALERTA] %s disparó [%s]: %s", payload.DeviceID, payload.Type, payload.Message)

	// Disparar la Notificación Push vía Firebase Cloud Messaging
	s.sendPushNotification(context.Background(), payload, petName)
}

// sendPushNotification Envía la notificación al tópico asociado al collar
func (s *IngestService) sendPushNotification(ctx context.Context, alert models.AlertPayload, petName string) {
	topic := fmt.Sprintf("collar_%s", alert.DeviceID)

	var iconEmoji string
	switch alert.Severity {
	case "critical":
		iconEmoji = "🚨"
	case "warning":
		iconEmoji = "⚠️"
	default:
		iconEmoji = "ℹ️"
	}

	title := fmt.Sprintf("%s Alerta de %s", iconEmoji, petName)

	fcmMessage := &messaging.Message{
		Topic: topic,
		Notification: &messaging.Notification{
			Title: title,
			Body:  alert.Message,
		},
		Data: map[string]string{
			"device_id": alert.DeviceID,
			"type":      alert.Type,
			"severity":  alert.Severity,
			"value":     fmt.Sprintf("%.2f", alert.Value),
			"timestamp": alert.Timestamp.Format(time.RFC3339),
		},
		Android: &messaging.AndroidConfig{
			Priority: "high",
			Notification: &messaging.AndroidNotification{
				Sound:       "default",
				ChannelID:   "michi_alerts_channel",
				ClickAction: "FLUTTER_NOTIFICATION_CLICK",
			},
		},
		APNS: &messaging.APNSConfig{
			Payload: &messaging.APNSPayload{
				Aps: &messaging.Aps{
					Sound: "default",
				},
			},
		},
	}

	response, err := s.fcmClient.Send(ctx, fcmMessage)
	if err != nil {
		log.Printf("[FCM ERROR] Fallo enviando push al tópico %s: %v", topic, err)
		return
	}

	log.Printf("[FCM OK] Notificación enviada al tópico %s (ID: %s)", topic, response)
}

// ----------------------------------------------------------------------------
// HANDLER 4: CONFIGURACIÓN DINÁMICA
// ----------------------------------------------------------------------------
func (s *IngestService) watchConfigChanges(ctx context.Context, mqttClient mqtt.Client) {
	log.Println("[CONFIG] Iniciando listener en tiempo real de configuraciones...")

	cachedConfigs := make(map[string]models.CollarConfig)
	snapshots := s.firestoreClient.Collection("collars").Snapshots(ctx)

	for {
		snap, err := snapshots.Next()
		if err != nil {
			if ctx.Err() != nil {
				return
			}
			log.Printf("[CONFIG ERROR] Error en listener de Firestore: %v", err)
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
						log.Printf("[CONFIG ERROR] Error serializando config: %v", err)
						continue
					}

					topic := fmt.Sprintf("mascotas/%s/config", deviceID)
					token := mqttClient.Publish(topic, 1, true, payloadBytes)
					token.Wait()

					if token.Error() != nil {
						log.Printf("[CONFIG ERROR] Fallo al publicar config en %s: %v", topic, token.Error())
					} else {
						log.Printf("[CONFIG OK] Nueva config enviada a %s (Retained): %s", topic, string(payloadBytes))
					}
				}
			}
		}
	}
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}
