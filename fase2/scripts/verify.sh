#!/bin/bash

echo "--- Iniciando Verificación del Entorno ---"
export GREEN='\033[0;32m'
export RED='\033[0;31m'
export NC='\033[0m' # No Color

# 1. Verificar si Docker está corriendo
if systemctl is-active --quiet docker; then
    echo -e "${GREEN}[OK]${NC} El servicio Docker está funcionando."
else
    echo -e "${RED}[ERROR]${NC} Docker no está arrancado."
fi

# 2. Verificar contenedores activos
for container in "nginx-web" "app-node"
do
    if [ "$(docker inspect -f '{{.State.Running}}' $container 2>/dev/null)" == "true" ]; then
        echo -e "${GREEN}[OK]${NC} Contenedor '$container' está en ejecución."
    else
        echo -e "${RED}[ERROR]${NC} Contenedor '$container' no encontrado o detenido."
    fi
done

# 3. Prueba de conectividad (CURL)
echo "--- Probando respuestas de red ---"

# Prueba Nginx (Puerto 8080) [cite: 1]
if curl -s localhost:8080 | grep -q "GreenDevCorp"; then
    echo -e "${GREEN}[OK]${NC} Nginx responde correctamente en el puerto 8080."
else
    echo -e "${RED}[ERROR]${NC} Nginx no responde o el contenido es incorrecto."
fi

# Prueba App Node (Puerto 3000)
if curl -s localhost:3000 | grep -q "Hello from container"; then
    echo -e "${GREEN}[OK]${NC} App Node responde correctamente en el puerto 3000."
else
    echo -e "${RED}[ERROR]${NC} App Node no responde."
fi

echo "--- Verificación finalizada ---"
