#!/bin/bash
set -e

# Uso:
#   ./deploy.sh          -> despliega la rama actualmente activa en la VM
#   ./deploy.sh dev      -> cambia a la rama 'dev' (si no lo está) y la despliega

APP_DIR="/opt/michi-link"
SERVICE_NAME="michi-link"
BINARY_NAME="backend_suscriptor"
TARGET_BRANCH="$1"

# Ejecutar siempre desde la carpeta del script (backend_suscriptor/)
cd "$(dirname "$0")"

echo "=========================================="
echo "🚀 Iniciando despliegue de $SERVICE_NAME"
echo "=========================================="

# 1. Asegurar PATH de Go en el script
export PATH=$PATH:/usr/local/go/bin

# 2. Limpiar artefactos de despliegues previos que bloquean git
#    (versiones anteriores de este script ejecutaban 'go mod tidy' y modificaban go.mod)
git checkout -- go.mod

if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "❌ Hay cambios locales en archivos versionados. Revísalos antes de desplegar:"
    git status --short
    exit 1
fi

# 3. Seleccionar rama (opcional) y descargar últimos cambios
if [ -n "$TARGET_BRANCH" ] && [ "$(git rev-parse --abbrev-ref HEAD)" != "$TARGET_BRANCH" ]; then
    echo "🔀 Cambiando a la rama '$TARGET_BRANCH'..."
    git fetch origin
    git checkout "$TARGET_BRANCH"
fi

echo "📥 Actualizando código desde Git (rama: $(git rev-parse --abbrev-ref HEAD))..."
git pull --ff-only

# 4. Compilar binario de Go
#    -mod=mod permite que Go complete go.sum (ignorado en git) sin necesidad de 'go mod tidy'.
#    Al finalizar se restaura go.mod para no dejar cambios locales versionados.
echo "🔨 Compilando binario de Go (commit: $(git rev-parse --short HEAD))..."
go build -mod=mod -ldflags="-s -w" -o $BINARY_NAME ./cmd/ingester
git checkout -- go.mod

echo "📥 Actualizando código desde Git (rama: $(git rev-parse --abbrev-ref HEAD))..."
git pull --ff-only

# 4. Compilar binario de Go
#    -mod=mod permite que Go complete go.sum (ignorado en git) sin necesidad de 'go mod tidy'.
#    Al finalizar se restaura go.mod para no dejar cambios locales versionados.
echo "🔨 Compilando binario de Go (commit: $(git rev-parse --short HEAD))..."
go build -mod=mod -ldflags="-s -w" -o $BINARY_NAME ./cmd/ingester
git checkout -- go.mod

# 5. Detener el servicio previo si está activo
if systemctl is-active --quiet $SERVICE_NAME; then
    echo "⏸️  Deteniendo servicio en ejecución..."
    sudo systemctl stop $SERVICE_NAME
fi

# 6. Mover binario a /opt/michi-link
echo "📦 Instalando binario en $APP_DIR..."
sudo mkdir -p $APP_DIR
sudo cp $BINARY_NAME $APP_DIR/
sudo chmod +x $APP_DIR/$BINARY_NAME

# 7. Configurar el servicio Systemd
echo "⚙️  Actualizando configuración de Systemd..."
sudo bash -c "cat << SERVICE_EOF > /etc/systemd/system/${SERVICE_NAME}.service
[Unit]
Description=Michi Link MQTT to Firestore Ingestion Service
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=${APP_DIR}
EnvironmentFile=${APP_DIR}/.env
ExecStart=${APP_DIR}/${BINARY_NAME}
Restart=always
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
SERVICE_EOF"

# 8. Recargar systemd y arrancar
echo "🔄 Recargando demonios e iniciando servicio..."
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl restart $SERVICE_NAME

# 9. Comprobar estado final
sleep 2
if systemctl is-active --quiet $SERVICE_NAME; then
    echo "=========================================="
    echo "✅ ¡Servicio desplegado y corriendo con éxito!"
    echo "=========================================="
    sudo journalctl -u $SERVICE_NAME -n 5 --no-pager
else
    echo "❌ Error al iniciar el servicio. Logs:"
    sudo journalctl -u $SERVICE_NAME -n 20 --no-pager
    exit 1
fi
