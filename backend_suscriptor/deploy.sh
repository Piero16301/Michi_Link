#!/bin/bash
set -e

APP_DIR="/opt/michi-link"
SERVICE_NAME="michi-link"
BINARY_NAME="backend_suscriptor"

echo "=========================================="
echo "🚀 Iniciando despliegue de $SERVICE_NAME"
echo "=========================================="

# 1. Asegurar PATH de Go en el script
export PATH=$PATH:/usr/local/go/bin

# 2. Descargar últimos cambios del repositorio
echo "📥 Actualizando código desde Git..."
git pull

# 3. Compilar binario de Go optimizado
echo "🔨 Compilando binario de Go..."
go build -ldflags="-s -w" -o $BINARY_NAME .

# 4. Detener el servicio previo si está activo
if systemctl is-active --quiet $SERVICE_NAME; then
    echo "⏸️  Deteniendo servicio en ejecución..."
    sudo systemctl stop $SERVICE_NAME
fi

# 5. Mover binario a /opt/michi-link
echo "📦 Instalando binario en $APP_DIR..."
sudo mkdir -p $APP_DIR
sudo cp $BINARY_NAME $APP_DIR/
sudo chmod +x $APP_DIR/$BINARY_NAME

# 6. Configurar el servicio Systemd
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

# 7. Recargar systemd y arrancar
echo "🔄 Recargando demonios e iniciando servicio..."
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl restart $SERVICE_NAME

# 8. Comprobar estado final
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
