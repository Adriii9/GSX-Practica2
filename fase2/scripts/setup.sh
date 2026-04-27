#!/bin/bash

echo "--- Iniciando Instalación de la Semana 8 (Docker) ---"

# 1. Actualizar sistema e instalar dependencias
echo "[1/4] Instalando Docker y Curl..."
sudo apt update && sudo apt install -y docker.io curl

# 2. Configurar permisos de usuario para Docker
echo "[2/4] Configurando permisos para el usuario gsx..."
sudo usermod -aG docker $USER
# Nota: Los cambios de grupo suelen requerir reiniciar sesión, 
# pero intentamos aplicarlos para el script actual:
newgrp docker << EOF

# 3. Construir las imágenes (Nivel Intermedio: Alpine y Multi-stage)
echo "[3/4] Construyendo imágenes de Docker..."

# Nginx con configuración de seguridad y puerto 8080 [cite: 1]
cd nginx
docker build -t nginx-custom .
cd ..

# App Node.js con Multi-stage build y usuario non-root [cite: 2, 3]
cd simple-app
docker build -t simple-app-node .
cd ..

# 4. Levantar los contenedores
echo "[4/4] Arrancando contenedores..."

# Limpiar contenedores antiguos si existen
docker rm -f nginx-web app-node 2>/dev/null

# Ejecutar Nginx (Puerto 8080) [cite: 1]
docker run -d -p 8080:8080 --name nginx-web nginx-custom

# Ejecutar App Node (Puerto 3000)
docker run -d -p 3000:3000 --name app-node simple-app-node

echo "--- Instalación completada con éxito ---"
EOF
