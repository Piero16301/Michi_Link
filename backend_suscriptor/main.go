package main

import (
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
	mqtt "github.com/eclipse/paho.mqtt.golang"
	"github.com/joho/godotenv"
)

// RetentionDays Constante de retención para la política TTL en Firestore (15 días)
const RetentionDays = 15

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

	svc := &IngestService{
		firestoreClient: fsClient,
		projectID:       projectID,
	}

	// 3. Configuración del cliente MQTT Paho
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

		// Suscripción 1: Telemetría periódica
		if token := c.Subscribe("mascotas/+/telemetria", 1, svc.handleTelemetry); token.Wait() && token.Error() != nil {
			log.Printf("[MQTT] Error al suscribirse a telemetria: %v", token.Error())
		}

		// Suscripción 2: Estado de conexión / Presencia
		if token := c.Subscribe("mascotas/+/status", 1, svc.handleStatus); token.Wait() && token.Error() != nil {
			log.Printf("[MQTT] Error al suscribirse a status: %v", token.Error())
		}

		// Suscripción 3: Alertas críticas
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

	// 4. Iniciar listener de cambios de configuración en Firestore
	go svc.watchConfigChanges(ctx, client)

	// 5. Esperar señal de apagado del sistema (Graceful Shutdown)
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
	var payload TelemetryPayload
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

	historyRecord := HistoryRecord{
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
	var payload StatusPayload
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
// HANDLER 3: ALERTAS CRÍTICAS
// ----------------------------------------------------------------------------
func (s *IngestService) handleAlerts(_ mqtt.Client, msg mqtt.Message) {
	var payload AlertPayload
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

	alertRecord := AlertRecord{
		Timestamp: payload.Timestamp,
		ExpireAt:  expireAt,
		Type:      payload.Type,
		Message:   payload.Message,
		Severity:  payload.Severity,
		Value:     payload.Value,
	}

	lastAlert := LastAlertInfo{
		Type:      payload.Type,
		Message:   payload.Message,
		Severity:  payload.Severity,
		Timestamp: payload.Timestamp,
	}

	err := s.firestoreClient.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		// A. Registrar en la sub colección histórica de alertas
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

	log.Printf("[ALERTA] %s disparó [%s]: %s (Nivel: %s)",
		payload.DeviceID, payload.Type, payload.Message, payload.Severity)
}

// ----------------------------------------------------------------------------
// HANDLER 4: CONFIGURACIÓN DINÁMICA
// ----------------------------------------------------------------------------
func (s *IngestService) watchConfigChanges(ctx context.Context, mqttClient mqtt.Client) {
	log.Println("[CONFIG] Iniciando listener en tiempo real de configuraciones...")

	// Caché local para comparar si la config cambió y no spamear MQTT
	cachedConfigs := make(map[string]CollarConfig)

	// Escuchar cambios en la colección 'collars'
	snapshots := s.firestoreClient.Collection("collars").Snapshots(ctx)

	for {
		snap, err := snapshots.Next()
		if err != nil {
			if ctx.Err() != nil {
				return // Salida limpia al detener el servicio
			}
			log.Printf("[CONFIG ERROR] Error en listener de Firestore: %v", err)
			time.Sleep(2 * time.Second)
			continue
		}

		for _, change := range snap.Changes {
			// Evaluamos solo creaciones o modificaciones
			if change.Kind == firestore.DocumentAdded || change.Kind == firestore.DocumentModified {
				deviceID := change.Doc.Ref.ID

				// Mapeamos el documento a una estructura auxiliar
				var docData struct {
					Config *CollarConfig `firestore:"config"`
				}

				if err := change.Doc.DataTo(&docData); err != nil || docData.Config == nil {
					continue // Si no tiene el campo 'config', lo ignoramos
				}

				newCfg := *docData.Config
				lastCfg, exists := cachedConfigs[deviceID]

				// Si no existía en caché o algún valor cambió, publicamos al ESP32
				if !exists || lastCfg != newCfg {
					cachedConfigs[deviceID] = newCfg

					payloadBytes, err := json.Marshal(newCfg)
					if err != nil {
						log.Printf("[CONFIG ERROR] Error serializando config: %v", err)
						continue
					}

					topic := fmt.Sprintf("mascotas/%s/config", deviceID)

					// Bandera 'retained = true' para que el broker guarde el mensaje
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
