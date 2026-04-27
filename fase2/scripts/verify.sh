#!/bin/bash

# --- IMPORTANTE: Ir a la carpeta raíz de fase2 para leer el .env y docker-compose.yml ---
cd "$(dirname "$0")/.."

echo "--- 🔍 Verificando el estado de la Orquestación ---"
export GREEN='\033[0;32m'
export RED='\033[0;31m'
export NC='\033[0m' # No Color

# 1. Comprobar estado de los procesos de Compose
echo "Estado de los contenedores:"
docker-compose ps

# 2. Verificar que ambos servicios están "Up"
# Filtramos por el estado "Up" y contamos si hay 2
UP_COUNT=$(docker-compose ps | grep -c "Up")

if [ "$UP_COUNT" -eq 2 ]; then
    echo -e "${GREEN}[OK]${NC} Todos los servicios están corriendo correctamente."
else
    echo -e "${RED}[ERROR]${NC} Se esperaban 2 contenedores activos, pero hay $UP_COUNT."
    echo "Revisa 'docker-compose logs' para ver qué ha fallado."
fi

# 3. Pruebas de conectividad
echo "--- Probando respuestas HTTP ---"

# Test Backend (Node.js) - Usamos localhost porque está mapeado
if curl -s localhost:3000 | grep -q "Hello from container"; then
    echo -e "${GREEN}[OK]${NC} Backend (Puerto 3000) responde con el mensaje esperado."
else
    echo -e "${RED}[ERROR]${NC} Backend no responde o el mensaje es incorrecto."
fi

# Test Frontend (Nginx)
if curl -s localhost:8080 | grep -q "GreenDevCorp"; then
    echo -e "${GREEN}[OK]${NC} Frontend (Puerto 8080) sirve la web de GreenDevCorp."
else
    echo -e "${RED}[ERROR]${NC} Frontend no responde o no encuentra el index.html."
fi

echo "--- ✨ Verificación finalizada ---"
