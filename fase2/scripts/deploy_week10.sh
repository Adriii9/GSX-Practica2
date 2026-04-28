#!/bin/bash
# deploy_week10.sh
# Propósito: Automatizar la preparación y el despliegue en Kubernetes (Minikube).

set -euo pipefail

# --- IMPORTANTE: Nos situamos en la raíz de fase2 ---
cd "$(dirname "$0")/.."

echo "🚀 Iniciando despliegue automatizado de la Semana 10 (Kubernetes)..."

echo "⚙️  Verificando e instalando dependencias (Setup)..."
if [ -f "scripts/setup_week10.sh" ]; then
    bash scripts/setup_week10.sh
else
    echo "⚠️  No se encontró setup_week10.sh. Asegúrate de tener minikube y kubectl."
fi
echo "---------------------------------------------------------"

echo "🧹 Apagando infraestructura de la Semana 9 (Docker Compose) para liberar RAM..."
docker-compose down 2>/dev/null || true

echo "⚙️  Comprobando el clúster de Minikube..."
if ! minikube status >/dev/null 2>&1; then
    echo "⏳ Iniciando Minikube (esto puede tardar un par de minutos)..."
    minikube start --driver=docker
else
    echo "✅ Minikube ya está en ejecución."
fi

echo "🏗️  Aplicando manifiestos YAML (ConfigMap, Deployments, Services)..."
kubectl apply -f kubernetes/

echo "⏳ Esperando a que Kubernetes declare los Pods como 'Listos'..."
kubectl rollout status deployment/backend
kubectl rollout status deployment/nginx

echo "📊 Estado final de los Pods:"
kubectl get pods

MINIKUBE_IP=$(minikube ip)
echo "========================================================="
echo "✅ ¡INFRAESTRUCTURA DE LA SEMANA 10 DESPLEGADA CON ÉXITO!"
echo "👉 Prueba tu web externa simulando un cliente real:"
echo "   curl http://$MINIKUBE_IP:30080"
echo "========================================================="
