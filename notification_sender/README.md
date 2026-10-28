# 🐱 MichiLink - Enviador de Notificaciones de Prueba

Herramienta en Node.js para enviar notificaciones push de prueba a la aplicación móvil MichiLink vía **Firebase Cloud Messaging (FCM)**.

Permite enviar notificaciones tanto a **Topics** (collares específicos) como a **Tokens directos** (dispositivos específicos), soportando las 3 severidades de la aplicación (`CRITICAL`, `WARNING`, `INFO`).

---

## 🚀 Requisitos Previos

1. Tener instalado **Node.js** (versión 18 o superior).
2. Descargar la clave de cuenta de servicio de Firebase:
   - Ingresa a la [Consola de Firebase](https://console.firebase.google.com/).
   - Selecciona el proyecto **michi-link**.
   - Dirígete a **Configuración del proyecto (⚙️)** > pestaña **Cuentas de servicio**.
   - Haz clic en **Generar nueva clave privada**.
   - Guarda el archivo descargado dentro de esta carpeta con el nombre exacto:
     ```
     serviceAccountKey.json
     ```
   *(Nota: `serviceAccountKey.json` está en `.gitignore` para no subir credenciales al repositorio).*

---

## 📦 Instalación

Desde la terminal, entra a esta carpeta e instala las dependencias:

```bash
cd notification_sender
npm install
```

---

## 🎮 Modos de Uso

### 1. Modo Interactivo (Recomendado)

Ejecuta el siguiente comando para abrir el menú paso a paso en tu terminal:

```bash
npm start
```

El script te preguntará:
1. Si deseas enviar por **Topic** (Collar) o por **Token** (Dispositivo).
2. El Topic (por ejemplo: `COLLAR_9E2B4A1F8C3D2E5A`) o el Token FCM.
3. La severidad de la alerta:
   - `[1] CRITICAL` (Alerta roja en `michi_critical_channel`, máxima prioridad y sonido)
   - `[2] WARNING`  (Advertencia amarilla en `michi_warning_channel`, prioridad alta)
   - `[3] INFO`     (Informativo azul en `michi_info_channel`, prioridad normal)
4. Si deseas usar el título/cuerpo predeterminado o redactar uno propio.

---

### 2. Modo Directo por Línea de Comandos (CLI)

También puedes disparar notificaciones directamente sin interacción pasando argumentos:

#### Enviar por Topic (Collar):
```bash
node index.js --topic=COLLAR_9E2B4A1F8C3D2E5A --severity=CRITICAL
```

#### Enviar por Token de dispositivo:
```bash
node index.js --token=tu_fcm_token_aqui --severity=WARNING --device-id=COLLAR_9E2B4A1F8C3D2E5A
```

#### Enviar con título y cuerpo personalizados:
```bash
node index.js --topic=COLLAR_9E2B4A1F8C3D2E5A --severity=INFO --title="¡Michi almorzó!" --body="Michi comió sus croquetas a tiempo."
```

#### Ver ayuda de parámetros:
```bash
node index.js --help
```

---

## 📲 Comportamiento en la App Móvil

| Estado de la App | Comportamiento |
| :--- | :--- |
| **Abierta (Primer plano)** | Se procesa con `flutter_local_notifications` y aparece el banner emergente en la parte superior con sonido y vibración. |
| **Segundo plano / Cerrada** | El sistema operativo muestra la notificación en la barra de estado según el canal configurado. |
| **Al tocar la notificación** | Redirige automáticamente a la pantalla de historial y alertas del collar correspondiente (`device_id`). |
