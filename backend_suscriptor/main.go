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

// RetentionDays Constante de retención para la política TTL en Firestore
const RetentionDays = 15

// CoordsData Coordenadas geográficas
type CoordsData struct {
	Lat  float64 `json:"lat" firestore:"lat"`
	Lon  float64 `json:"lon" firestore:"lon"`
	AltM float64 `json:"alt_m" firestore:"alt_m"`
}

// StatusData Estado de sensores y energía
type StatusData struct {
	GpsFix     bool    `json:"gps_fix" firestore:"gps_fix"`
	Sats       int     `json:"sats" firestore:"sats"`
	BatteryV   float64 `json:"battery_v" firestore:"battery_v"`
	BatteryPct int     `json:"battery_pct" firestore:"battery_pct"`
}

// RadioData Métricas de radioenlace y distancia relativa
type RadioData struct {
	RSSI          int     `json:"rssi" firestore:"rssi"`
	SNR           float64 `json:"snr" firestore:"snr"`
	DistanceHomeM float64 `json:"distance_home_m" firestore:"distance_home_m"`
}

// TelemetryPayload Payload recibido vía MQTT
type TelemetryPayload struct {
	DeviceID string     `json:"device_id"`
	PetName  string     `json:"pet_name,omitempty"` // Opcional: si la base lo envía por MQTT
	Seq      uint32     `json:"seq"`
	Coords   CoordsData `json:"coords"`
	Status   StatusData `json:"status"`
	Radio    RadioData  `json:"radio"`
}

// HistoryRecord Estructura tipada para cada punto de la sub colección 'history'
type HistoryRecord struct {
	Timestamp time.Time  `firestore:"timestamp"`
	ExpireAt  time.Time  `firestore:"expire_at"` // TTL automático
	Seq       uint32     `firestore:"seq"`
	Coords    CoordsData `firestore:"coords"`
	Status    StatusData `firestore:"status"`
	Radio     RadioData  `firestore:"radio"`
}

type IngestService struct {
	firestoreClient *firestore.Client
	projectID       string
}

func main() {
	ctx := context.Background()

	// 0. Cargar variables de entorno desde archivo .env (si existe)
	if err := godotenv.Load(); err != nil {
		log.Println("[INFO] No se encontró archivo .env o no se pudo cargar; usando variables del sistema.")
	}

	// 1. Obtener variables
	projectID := getEnv("GCP_PROJECT_ID", "")
	hivemqBroker := getEnv("HIVEMQ_BROKER", "")
	hivemqUser := getEnv("HIVEMQ_USER", "")
	hivemqPass := getEnv("HIVEMQ_PASS", "")

	// 2. Inicializar cliente Firestore
	// Al correr en Compute Engine (e2-micro), utiliza automáticamente las credenciales
	// de la Service Account asignada a la VM (Application Default Credentials).
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
	opts.SetTLSConfig(&tls.Config{InsecureSkipVerify: false}) // TLS seguro con CAs estándar
	opts.SetAutoReconnect(true)
	opts.SetMaxReconnectInterval(10 * time.Second)
	opts.SetKeepAlive(60 * time.Second)

	opts.SetOnConnectHandler(func(c mqtt.Client) {
		log.Println("[MQTT] Conectado exitosamente a HiveMQ Cloud.")
		topic := "mascotas/+/telemetria"
		if token := c.Subscribe(topic, 1, svc.handleMessage); token.Wait() && token.Error() != nil {
			log.Printf("[MQTT] Error al suscribirse al tópico %s: %v", topic, token.Error())
		} else {
			log.Printf("[MQTT] Suscripción activa al tópico: %s", topic)
		}
	})

	opts.SetConnectionLostHandler(func(c mqtt.Client, err error) {
		log.Printf("[MQTT] Conexión perdida: %v. Intentando reconectar...", err)
	})

	client := mqtt.NewClient(opts)
	if token := client.Connect(); token.Wait() && token.Error() != nil {
		log.Fatalf("Error conectando a HiveMQ: %v", token.Error())
	}

	// 4. Manejo de terminación elegante (Graceful Shutdown)
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)
	<-sigChan

	log.Println("Cerrando servicio de ingesta...")
	client.Disconnect(250)
	log.Println("Servicio detenido correctamente.")
}

func (s *IngestService) handleMessage(_ mqtt.Client, msg mqtt.Message) {
	var payload TelemetryPayload
	if err := json.Unmarshal(msg.Payload(), &payload); err != nil {
		log.Printf("[ERROR] Payload JSON inválido: %v", err)
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

	// Objeto tipado para el historial
	historyRecord := HistoryRecord{
		Timestamp: now,
		ExpireAt:  expireAt,
		Seq:       payload.Seq,
		Coords:    payload.Coords,
		Status:    payload.Status,
		Radio:     payload.Radio,
	}

	err := s.firestoreClient.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		// 1. Verificar si el documento del collar ya existe para conservar su nombre personalizado
		docSnapshot, err := tx.Get(collarDocRef)
		nameToKeep := ""

		if err == nil && docSnapshot.Exists() {
			// Si ya tiene un nombre configurado previamente en la base de datos, lo mantenemos
			if existingName, err := docSnapshot.DataAt("name"); err == nil {
				nameToKeep = fmt.Sprintf("%v", existingName)
			}
		}

		// Si es la primera vez que se registra y no tiene nombre, asignamos uno por defecto
		if nameToKeep == "" {
			if payload.PetName != "" {
				nameToKeep = payload.PetName
			} else {
				nameToKeep = "Mi Mascota"
			}
		}

		// 2. Datos del estado en vivo del collar
		latestData := map[string]any{
			"device_id": payload.DeviceID,
			"name":      nameToKeep,
			"last_seen": now,
			"seq":       payload.Seq,
			"coords":    payload.Coords,
			"status":    payload.Status,
			"radio":     payload.Radio,
		}

		// 3. Escribir estado actual e histórico atómicamente
		if err := tx.Set(collarDocRef, latestData, firestore.MergeAll); err != nil {
			return err
		}
		return tx.Set(historyDocRef, historyRecord)
	})

	if err != nil {
		log.Printf("[ERROR] Fallo al persistir en Firestore (%s): %v", payload.DeviceID, err)
		return
	}

	log.Printf("[OK] Telemetría registrada: %s | Pkt #%d | Fix: %t | Bat: %.2fV | Expire: %s",
		payload.DeviceID, payload.Seq, payload.Status.GpsFix, payload.Status.BatteryV, expireAt.Format("2006-01-02"))
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}
