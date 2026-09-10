package main

import (
	"backend_suscriptor/internal/models"
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
// CONFIGURACIÓN DE ORIGEN Y SIMULACIÓN
// ==========================================
const (
	DeviceID    = "COLLAR_01"
	PetName     = "Michin"
	MaxRadiusM  = 1000.0
	IntervalSec = 10 // Intervalo de prueba (ajustable a 60 en producción)
)

// Coordenadas base del hogar
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

	// Configuración de cliente MQTT con LWT (Last Will & Testament)
	opts := mqtt.NewClientOptions()
	opts.AddBroker(hivemqBroker)
	opts.SetClientID(fmt.Sprintf("simulador-base-%d", time.Now().Unix()))
	opts.SetUsername(hivemqUser)
	opts.SetPassword(hivemqPass)
	opts.SetTLSConfig(&tls.Config{InsecureSkipVerify: false})
	opts.SetAutoReconnect(true)

	// LWT: si el simulador se detiene abruptamente, HiveMQ publica 'offline'
	lwtPayload, _ := json.Marshal(models.StatusPayload{DeviceID: DeviceID, Status: "offline"})
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

	ticker := time.NewTicker(time.Duration(IntervalSec) * time.Second)
	defer ticker.Stop()

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	// Ejecutar primer ciclo inmediatamente
	simularPaso(client, &seq, &currLat, &currLon, &batteryPct, &batteryV)

	for {
		select {
		case <-ticker.C:
			simularPaso(client, &seq, &currLat, &currLon, &batteryPct, &batteryV)

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
) {
	// A. Desplazamiento aleatorio: paso de 20 a 70 metros por ciclo
	stepM := 20.0 + rand.Float64()*50.0
	angle := rand.Float64() * 2 * math.Pi

	// Si está cerca del límite de 1 km, orientar hacia casa
	distHome := haversineDistance(HomeLat, HomeLon, *currLat, *currLon)
	if distHome > MaxRadiusM*0.9 {
		angle = math.Atan2(HomeLon-*currLon, HomeLat-*currLat)
	}

	deltaLat := (stepM * math.Cos(angle)) / 111320.0
	deltaLon := (stepM * math.Sin(angle)) / (111320.0 * math.Cos(*currLat*(math.Pi/180.0)))
	*currLat += deltaLat
	*currLon += deltaLon

	distHome = haversineDistance(HomeLat, HomeLon, *currLat, *currLon)

	// B. Degradación ligera de batería
	if *batteryPct > 5 && rand.Float64() < 0.35 {
		*batteryPct--
		*batteryV = 3.3 + (float64(*batteryPct)/100.0)*0.9
	}

	// Simulación de fix GPS
	hasGpsFix := rand.Float64() > 0.08
	sats := 8
	if !hasGpsFix {
		sats = 2
	}

	// RSSI atenuado con la distancia (-60 dBm cerca de casa hasta -115 dBm a 1 Km)
	rssi := int(-60.0 - (distHome/MaxRadiusM)*55.0 + (rand.Float64()*6 - 3))

	// C. Empaquetar y publicar Telemetría habitual
	telemetry := models.TelemetryPayload{
		DeviceID: DeviceID,
		PetName:  PetName,
		Seq:      *seq,
		Coords: models.CoordsData{
			Lat:  math.Round(*currLat*1e6) / 1e6,
			Lon:  math.Round(*currLon*1e6) / 1e6,
			AltM: 25.0 + (rand.Float64()*4 - 2),
		},
		Status: models.StatusData{
			GpsFix:     hasGpsFix,
			Sats:       sats,
			BatteryV:   math.Round(*batteryV*100) / 100,
			BatteryPct: *batteryPct,
		},
		Radio: models.RadioData{
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

	// D. Publicar alerta rotativa con hardware real
	enviarAlertaPeriodica(client, distHome, *batteryPct, rssi)

	*seq++
}

var alertIndex int

// Catálogo de alertas soportadas por el hardware disponible
func enviarAlertaPeriodica(client mqtt.Client, distHome float64, batPct int, rssi int) {
	type AlertOption struct {
		Type        string
		Severity    string
		Value       float64
		Description string
	}

	distRedondeada := math.Round(distHome*10) / 10

	catalogo := []AlertOption{
		// --- 1. GEOVALLA ---
		{
			Type:        "GEOFENCE_BREACH",
			Severity:    models.SeverityCritical,
			Value:       distRedondeada,
			Description: "Michin cruzó el perímetro de seguridad",
		},
		{
			Type:        "GEOFENCE_RESTORED",
			Severity:    models.SeverityInfo,
			Value:       distRedondeada,
			Description: "Michin regresó a la zona segura",
		},

		// --- 2. BATERÍA ---
		{
			Type:        "LOW_BATTERY",
			Severity:    models.SeverityWarning,
			Value:       float64(batPct),
			Description: "Batería por debajo del umbral preventivo",
		},
		{
			Type:        "BATTERY_CRITICAL",
			Severity:    models.SeverityCritical,
			Value:       float64(int(math.Max(5, float64(batPct-15)))),
			Description: "Batería en estado crítico inminente a apagado",
		},
		{
			Type:        "BATTERY_NORMAL",
			Severity:    models.SeverityInfo,
			Value:       90.0,
			Description: "Collar cargado o conectado a energía",
		},

		// --- 3. SATÉLITES (GPS) ---
		{
			Type:        "NO_GPS_FIX",
			Severity:    models.SeverityWarning,
			Value:       0,
			Description: "Pérdida de señal satelital / Modo radiobaliza",
		},
		{
			Type:        "GPS_FIX_RESTORED",
			Severity:    models.SeverityInfo,
			Value:       8,
			Description: "Enlace satelital GPS restablecido con satélites",
		},

		// --- 4. RADIOENLACE LORA ---
		{
			Type:        "WEAK_SIGNAL",
			Severity:    models.SeverityWarning,
			Value:       float64(rssi),
			Description: "Atenuación severa de enlace LoRa con la base",
		},
		{
			Type:        "SIGNAL_NORMAL",
			Severity:    models.SeverityInfo,
			Value:       -65.0,
			Description: "Señal LoRa restablecida a niveles óptimos",
		},
	}

	// Rotación secuencial
	seleccionada := catalogo[alertIndex]
	alertIndex = (alertIndex + 1) % len(catalogo)

	dispararAlerta(client, seleccionada.Type, seleccionada.Severity, seleccionada.Value, seleccionada.Description)
}

func dispararAlerta(client mqtt.Client, alertType, severity string, val float64, desc string) {
	alert := models.AlertPayload{
		DeviceID:  DeviceID,
		Type:      alertType,
		Severity:  severity,
		Value:     val,
		Timestamp: time.Now().UTC(),
	}
	payloadBytes, _ := json.Marshal(alert)
	topic := fmt.Sprintf("mascotas/%s/alertas", DeviceID)
	client.Publish(topic, 1, false, payloadBytes)
	log.Printf(" ⚠️ [ALERTA ENVIADA] [%s] Sev: %-8s | Val: %.1f | (%s)", alertType, severity, val, desc)
}

func publishStatus(client mqtt.Client, devID, status string) {
	payloadBytes, _ := json.Marshal(models.StatusPayload{DeviceID: devID, Status: status})
	topic := fmt.Sprintf("mascotas/%s/status", devID)
	client.Publish(topic, 1, true, payloadBytes)
	log.Printf(" 📡 [STATUS ACTUALIZADO] %s -> %s", devID, status)
}

func haversineDistance(lat1, lon1, lat2, lon2 float64) float64 {
	const R = 6371000.0
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
