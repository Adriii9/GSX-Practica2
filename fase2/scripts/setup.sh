#!/bin/bash

# --- IMPORTANTE: Ir a la carpeta donde está el docker-compose.yml y el .env ---
cd "$(dirname "$0")/.."

echo "--- 🚀 Iniciando Despliegue Orquestado (Semana 9) ---"

# 1. Instalación de dependencias si no existen
if ! command -v docker-compose &> /dev/null
then
    echo "[1/3] Instalando docker-compose..."
    sudo apt update && sudo apt install -y docker-compose
else
    echo "[1/3] docker-compose ya está instalado."
fi

# 2. Limpieza de entorno previo
echo "[2/3] Limpiando entorno previo..."
docker-compose down

# 3. Construcción y arranque de la infraestructura
echo "[3/3] Levantando servicios (Nginx + Node.js)..."
docker-compose up -d --build

echo "--- ✅ Instalación y despliegue completados con éxito ---"
