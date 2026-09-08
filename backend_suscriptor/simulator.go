//go:build ignore

package main

import (
	"crypto/tls"
	"encoding/json"
	"fmt"
	"log"
	"math"
	"math/rand"
	"os"
	"os/signal"
	"syscall"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	"github.com/joho/godotenv"
)

// ==========================================
// ESTRUCTURAS DE PAYLOAD SIMULADAS
// ==========================================

type CoordsData struct {
	Lat  float64 `json:"lat"`
	Lon  float64 `json:"lon"`
	AltM float64 `json:"alt_m"`
}

type StatusData struct {
	GpsFix     bool    `json:"gps_fix"`
	Sats       int     `json:"sats"`
	BatteryV   float64 `json:"battery_v"`
	BatteryPct int     `json:"battery_pct"`
}

type RadioData struct {
	RSSI          int     `json:"rssi"`
	SNR           float64 `json:"snr"`
	DistanceHomeM float64 `json:"distance_home_m"`
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

type AlertPayload struct {
	DeviceID  string    `json:"device_id"`
	Type      string    `json:"type"`
	Message   string    `json:"message"`
	Severity  string    `json:"severity"`
	Value     float64   `json:"value,omitempty"`
	Timestamp time.Time `json:"timestamp"`
}

// ==========================================
// CONFIGURACIÓN DE ORIGEN Y SIMULACIÓN
// ==========================================
const (
	DeviceID       = "COLLAR_01"
	PetName        = "Michin"
	GeofenceLimitM = 150.0  // Umbral para disparar alerta de geo valla
	MaxRadiusM     = 1000.0 // Límite máximo de desplazamiento (1 km)
	IntervalSec    = 60     // Envío cada 60 segundos
)

// Coordenadas base de tu hogar (puedes ajustar estos valores)
var (
	HomeLat = -8.066661
	HomeLon = -79.062814
)

func main() {
	// 0. Cargar variables de entorno locales si existen
	if err := godotenv.Load(); err != nil {
		log.Println("[INFO] Usando variables de entorno del sistema.")
	}

	// 1. Obtener variables de configuración
	hivemqBroker := getEnv("HIVEMQ_BROKER", "")
	hivemqUser := getEnv("HIVEMQ_USER", "")
	hivemqPass := getEnv("HIVEMQ_PASS", "")

	// 1. Configuración de cliente MQTT con LWT (Last Will & Testament)
	opts := mqtt.NewClientOptions()
	opts.AddBroker(hivemqBroker)
	opts.SetClientID(fmt.Sprintf("simulador-base-%d", time.Now().Unix()))
	opts.SetUsername(hivemqUser)
	opts.SetPassword(hivemqPass)
	opts.SetTLSConfig(&tls.Config{InsecureSkipVerify: false})
	opts.SetAutoReconnect(true)

	// LWT: si el simulador se apaga abruptamente, HiveMQ publicará 'offline'
	lwtPayload, _ := json.Marshal(StatusPayload{DeviceID: DeviceID, Status: "offline"})
	opts.SetWill(fmt.Sprintf("mascotas/%s/status", DeviceID), string(lwtPayload), 1, true)

	client := mqtt.NewClient(opts)
	if token := client.Connect(); token.Wait() && token.Error() != nil {
		log.Fatalf("Error conectando al broker: %v", token.Error())
	}
	defer client.Disconnect(250)

	log.Printf("[SIMULADOR] Conectado a HiveMQ. Simulando collar %s (%s)...", DeviceID, PetName)

	// 2. Publicar estado ONLINE al conectar
	publishStatus(client, DeviceID, "online")

	// 3. Variables de estado del collar simulado
	currLat := HomeLat
	currLon := HomeLon
	batteryPct := 95
	batteryV := 4.15
	var seq uint32 = 1
	geofenceActive := false
	lowBatteryActive := false

	ticker := time.NewTicker(time.Duration(IntervalSec) * time.Second)
	defer ticker.Stop()

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	// Ejecutar primer envío inmediatamente sin esperar los 60s iniciales
	simularPaso(client, &seq, &currLat, &currLon, &batteryPct, &batteryV, &geofenceActive, &lowBatteryActive)

	for {
		select {
		case <-ticker.C:
			simularPaso(client, &seq, &currLat, &currLon, &batteryPct, &batteryV, &geofenceActive, &lowBatteryActive)

		case <-sigChan:
			log.Println("\n[SIMULADOR] Deteniendo simulador... Notificando status offline.")
			publishStatus(client, DeviceID, "offline")
			time.Sleep(500 * time.Millisecond)
			return
		}
	}
}

func simularPaso(
	client mqtt.Client,
	seq *uint32,
	currLat *float64,
	currLon *float64,
	batteryPct *int,
	batteryV *float64,
	geofenceActive *bool,
	lowBatteryActive *bool,
) {
	// A. Desplazamiento aleatorio: paso de 20 a 70 metros por minuto
	stepM := 20.0 + rand.Float64()*50.0
	angle := rand.Float64() * 2 * math.Pi

	// Si está cerca del límite de 1 km, orientar el ángulo de regreso a casa
	distHome := haversineDistance(HomeLat, HomeLon, *currLat, *currLon)
	if distHome > MaxRadiusM*0.9 {
		angle = math.Atan2(HomeLon-*currLon, HomeLat-*currLat)
	}

	// Conversión de metros a grados aproximados
	deltaLat := (stepM * math.Cos(angle)) / 111320.0
	deltaLon := (stepM * math.Sin(angle)) / (111320.0 * math.Cos(*currLat*(math.Pi/180.0)))
	*currLat += deltaLat
	*currLon += deltaLon

	// Recalcular distancia exacta a casa
	distHome = haversineDistance(HomeLat, HomeLon, *currLat, *currLon)

	// B. Degradación ligera de batería
	if *batteryPct > 5 && rand.Float64() < 0.3 {
		*batteryPct--
		*batteryV = 3.3 + (float64(*batteryPct)/100.0)*0.9
	}

	// Pérdida temporal y aleatoria de fix GPS (5% de probabilidad)
	hasGpsFix := rand.Float64() > 0.05
	sats := 8
	if !hasGpsFix {
		sats = 2
	}

	// RSSI atenúa con la distancia (aprox: -60 dBm en casa, hasta -115 dBm a 1km)
	rssi := int(-60.0 - (distHome/MaxRadiusM)*55.0 + (rand.Float64()*6 - 3))

	// C. Empaquetar y publicar Telemetría
	telemetry := TelemetryPayload{
		DeviceID: DeviceID,
		PetName:  PetName,
		Seq:      *seq,
		Coords: CoordsData{
			Lat:  math.Round(*currLat*1e6) / 1e6,
			Lon:  math.Round(*currLon*1e6) / 1e6,
			AltM: 25.0 + (rand.Float64()*4 - 2),
		},
		Status: StatusData{
			GpsFix:     hasGpsFix,
			Sats:       sats,
			BatteryV:   math.Round(*batteryV*100) / 100,
			BatteryPct: *batteryPct,
		},
		Radio: RadioData{
			RSSI:          rssi,
			SNR:           math.Round((9.5-(distHome/MaxRadiusM)*12.0)*10) / 10,
			DistanceHomeM: math.Round(distHome*10) / 10,
		},
	}

	payloadBytes, _ := json.Marshal(telemetry)
	telemetryTopic := fmt.Sprintf("mascotas/%s/telemetria", DeviceID)
	client.Publish(telemetryTopic, 1, false, payloadBytes)

	log.Printf("[Pkt #%03d] Dist: %6.1fm | Bat: %d%% | Fix: %-5t | RSSI: %d dBm",
		*seq, distHome, *batteryPct, hasGpsFix, rssi)

	// D. Lógica de Alertas Condicionales (Histeresis)
	// 1. Geovalla
	if distHome > GeofenceLimitM {
		if !*geofenceActive {
			dispararAlerta(client, "GEOFENCE_BREACH",
				fmt.Sprintf("%s superó la distancia segura (Distancia: %.1fm)", PetName, distHome),
				"critical", distHome)
			*geofenceActive = true
		}
	} else if *geofenceActive {
		dispararAlerta(client, "GEOFENCE_RESTORED",
			fmt.Sprintf("%s regresó dentro de la zona segura", PetName),
			"info", distHome)
		*geofenceActive = false
	}

	// 2. Batería Baja
	if *batteryPct <= 15 {
		if !*lowBatteryActive {
			dispararAlerta(client, "LOW_BATTERY",
				fmt.Sprintf("Batería de %s en nivel crítico: %d%%", PetName, *batteryPct),
				"warning", float64(*batteryPct))
			*lowBatteryActive = true
		}
	} else {
		*lowBatteryActive = false
	}

	// 3. Evento esporádico: pérdida de señal satelital
	if !hasGpsFix {
		dispararAlerta(client, "NO_GPS_FIX",
			fmt.Sprintf("%s perdió enlace satelital. Activando modo radiobaliza LoRa.", PetName),
			"warning", 0)
	}

	*seq++
}

func dispararAlerta(client mqtt.Client, alertType, msg, severity string, val float64) {
	alert := AlertPayload{
		DeviceID:  DeviceID,
		Type:      alertType,
		Message:   msg,
		Severity:  severity,
		Value:     val,
		Timestamp: time.Now().UTC(),
	}
	payloadBytes, _ := json.Marshal(alert)
	topic := fmt.Sprintf("mascotas/%s/alertas", DeviceID)
	client.Publish(topic, 1, false, payloadBytes)
	log.Printf(" ⚠️ [ALERTA DISPARADA] [%s] %s", alertType, msg)
}

func publishStatus(client mqtt.Client, devID, status string) {
	payloadBytes, _ := json.Marshal(StatusPayload{DeviceID: devID, Status: status})
	topic := fmt.Sprintf("mascotas/%s/status", devID)
	client.Publish(topic, 1, true, payloadBytes)
	log.Printf(" 📡 [STATUS ACTUALIZADO] %s -> %s", devID, status)
}

func haversineDistance(lat1, lon1, lat2, lon2 float64) float64 {
	const R = 6371000.0 // Radio medio de la Tierra en metros
	phi1 := lat1 * math.Pi / 180.0
	phi2 := lat2 * math.Pi / 180.0
	deltaPhi := (lat2 - lat1) * math.Pi / 180.0
	deltaLambda := (lon2 - lon1) * math.Pi / 180.0

	a := math.Sin(deltaPhi/2.0)*math.Sin(deltaPhi/2.0) +
		math.Cos(phi1)*math.Cos(phi2)*
			math.Sin(deltaLambda/2.0)*math.Sin(deltaLambda/2.0)
	c := 2.0 * math.Atan2(math.Sqrt(a), math.Sqrt(1.0-a))

	return R * c
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}
