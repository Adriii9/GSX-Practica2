#!/bin/bash

# --- IMPORTANTE: Ir a la carpeta raíz de fase2 ---
cd "$(dirname "$0")/.."

echo "--- 🚀 Iniciando Setup ---"

# 1. Instalación de dependencias completas
echo "[1/4] Verificando e instalando herramientas (Docker, Compose y Curl)..."
sudo apt update -qq
sudo apt install -y docker.io docker-compose curl

# 2. Asegurar que el motor de Docker está encendido
echo "[2/4] Arrancando el demonio de Docker..."
sudo systemctl start docker
sudo systemctl enable docker

# 3. Limpieza de entorno previo
echo "[3/4] Limpiando contenedores de pruebas anteriores..."
# Usamos sudo por si el usuario acaba de instalar Docker y no ha refrescado permisos
sudo docker-compose down 2>/dev/null

# 4. Construcción y arranque de la infraestructura
echo "[4/4] Levantando la infraestructura (Nginx + Node.js)..."
sudo docker-compose up -d --build

echo "--- ✅ Instalación y despliegue completados con éxito ---"
echo "💡 Nota: Si deseas ejecutar comandos de Docker manualmente sin escribir 'sudo',"
echo "asegúrate de ejecutar: sudo usermod -aG docker \$USER && newgrp docker"
