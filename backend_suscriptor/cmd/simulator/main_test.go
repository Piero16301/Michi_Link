package main

import (
	"math"
	"testing"
)

func TestHaversineDistance(t *testing.T) {
	t.Run("distancia entre el mismo punto es cero", func(t *testing.T) {
		dist := haversineDistance(HomeLat, HomeLon, HomeLat, HomeLon)
		if dist > 0.001 {
			t.Errorf("distancia al mismo punto debería ser 0 m, obtenido %f m", dist)
		}
	})

	t.Run("distancia simétrica (A -> B == B -> A)", func(t *testing.T) {
		latB := HomeLat + 0.002
		lonB := HomeLon + 0.002

		d1 := haversineDistance(HomeLat, HomeLon, latB, lonB)
		d2 := haversineDistance(latB, lonB, HomeLat, HomeLon)

		if math.Abs(d1-d2) > 0.001 {
			t.Errorf("la distancia de Haversine debe ser simétrica: %f != %f", d1, d2)
		}
	})

	t.Run("desplazamiento de 1 grado latitud es aprox 111.13 km", func(t *testing.T) {
		// 1 grado en latitud equivale teóricamente a ~111.1 - 111.3 km
		dist := haversineDistance(0.0, 0.0, 1.0, 0.0)
		expected := 111195.0 // ~111.19 km en el ecuador
		tolerance := 500.0   // tolerancia de 500 metros

		if math.Abs(dist-expected) > tolerance {
			t.Errorf("distancia 1 grado lat = %f m, esperado dentro de rango de %f m", dist, expected)
		}
	})

	t.Run("distancias cortas de simulación (radio de 1 km)", func(t *testing.T) {
		// Punto desplazado ~100 metros hacia el norte
		latDesplazado := HomeLat + (100.0 / 111320.0)
		dist := haversineDistance(HomeLat, HomeLon, latDesplazado, HomeLon)

		if math.Abs(dist-100.0) > 2.0 {
			t.Errorf("distancia corta calculada = %f m, esperado ~100 m", dist)
		}
	})
}

func TestSimulatorGetEnv(t *testing.T) {
	const key = "TEST_SIMULATOR_VAR"
	const fallback = "fallback_broker"

	t.Run("retorna valor cuando existe", func(t *testing.T) {
		t.Setenv(key, "ssl://custom-hivemq:8883")
		got := getEnv(key, fallback)
		if got != "ssl://custom-hivemq:8883" {
			t.Errorf("getEnv() = %q, esperado 'ssl://custom-hivemq:8883'", got)
		}
	})

	t.Run("retorna fallback cuando no existe", func(t *testing.T) {
		got := getEnv("MISSING_SIMULATOR_ENV_ABC", fallback)
		if got != fallback {
			t.Errorf("getEnv() = %q, esperado %q", got, fallback)
		}
	})
}
