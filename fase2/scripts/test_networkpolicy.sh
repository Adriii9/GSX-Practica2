#!/bin/bash
# test_networkpolicy.sh
# Setmana 12: prova end-to-end que la NetworkPolicy 'backend-allow-nginx'
# realment bloca el trànsit cap al backend quan ve d'un pod no autoritzat.
#
# Requisit previ: Minikube ha d'estar arrencat amb un CNI compatible amb
# NetworkPolicies (Calico). Si no, llença:
#   minikube delete && minikube start --cni=calico --memory=4096 --cpus=2

set -euo pipefail

# --- IMPORTANTE: anar a la carpeta arrel de fase2 ---
cd "$(dirname "$0")/.."

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ATACANTE_POD="atacante"

cleanup() {
    echo ""
    echo " Netejant pod de prova..."
    kubectl delete pod "$ATACANTE_POD" --ignore-not-found=true --wait=false >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo " Iniciant prova de NetworkPolicy (Setmana 12)..."
echo "----------------------------------------------------"

# 1. Comprovar que el clúster Kubernetes és accessible
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo -e "${RED}[ERROR]${NC} No es pot connectar al clúster. Llença 'minikube start --cni=calico' primer."
    exit 1
fi
echo -e "${GREEN}[OK]${NC} Clúster Kubernetes accessible."

# 2. Comprovar que Calico està instal·lat (sinó la policy no s'aplicarà)
if ! kubectl get pods -n kube-system 2>/dev/null | grep -q "calico"; then
    echo -e "${YELLOW}[AVÍS]${NC} No detecto pods de Calico al clúster."
    echo "        Minikube segurament fa servir kindnet, que IGNORA les NetworkPolicies."
    echo "        La prova continuarà però el resultat no serà fiable."
    echo "        Per fer-ho bé: 'minikube delete && minikube start --cni=calico'"
    echo ""
fi

# 3. Aplicar els manifests si no hi són
echo " Aplicant manifests bàsics..."
kubectl apply -f kubernetes/configmap.yaml >/dev/null
kubectl apply -f kubernetes/backend.yaml >/dev/null
kubectl apply -f kubernetes/nginx.yaml >/dev/null
kubectl rollout status deployment/backend --timeout=300s >/dev/null
kubectl rollout status deployment/nginx --timeout=300s >/dev/null
echo -e "${GREEN}[OK]${NC} Backend i Nginx desplegats."

# 4. Netejar pod atacant si en queda algun d'una execució anterior
kubectl delete pod "$ATACANTE_POD" --ignore-not-found=true --wait=true >/dev/null 2>&1 || true

# 5. Treure la policy si ja existeix (per provar primer SENSE policy)
kubectl delete networkpolicy backend-allow-nginx --ignore-not-found=true >/dev/null 2>&1 || true

echo "----------------------------------------------------"
echo " FASE 1: Estat inicial SENSE NetworkPolicy"
echo "----------------------------------------------------"

# 6. Llençar el pod atacant amb una etiqueta diferent
echo "    Llençant pod atacant (label app=atacante)..."
kubectl run "$ATACANTE_POD" --image=busybox --restart=Never \
    --labels="app=atacante" \
    --command -- sleep 3600 >/dev/null
kubectl wait --for=condition=Ready pod/"$ATACANTE_POD" --timeout=300s >/dev/null

# 7. Sense policy, l'atacant HAURIA de poder accedir al backend
echo "    Provant accés des de l'atacant (hauria de FUNCIONAR)..."
if kubectl exec "$ATACANTE_POD" -- wget -qO- --timeout=5 http://backend:3000 2>/dev/null | grep -q "Hello from container"; then
    echo -e "   ${GREEN}[OK]${NC} L'atacant arriba al backend (esperat, encara no hi ha policy)."
else
    echo -e "   ${RED}[ERROR]${NC} L'atacant NO arriba al backend ja sense policy. Algo va malament."
    exit 1
fi

echo "----------------------------------------------------"
echo "  FASE 2: Aplicant NetworkPolicy"
echo "----------------------------------------------------"

# 8. Aplicar la NetworkPolicy
kubectl apply -f kubernetes/networkpolicy.yaml >/dev/null
echo -e "${GREEN}[OK]${NC} NetworkPolicy 'backend-allow-nginx' aplicada."

# Donar uns segons a Calico per propagar la regla
sleep 5

echo "----------------------------------------------------"
echo " FASE 3: Verificació AMB NetworkPolicy"
echo "----------------------------------------------------"

# 9. L'atacant ja NO hauria de poder accedir al backend
echo "    Provant accés des de l'atacant (hauria de FALLAR)..."
if kubectl exec "$ATACANTE_POD" -- wget -qO- --timeout=5 http://backend:3000 2>/dev/null | grep -q "Hello from container"; then
    echo -e "   ${RED}[ERROR]${NC} L'atacant TORNA a arribar al backend. La policy no s'està aplicant."
    echo "           Probablement el CNI no és Calico/Cilium. Comprova 'kubectl get pods -n kube-system'."
    exit 1
else
    echo -e "   ${GREEN}[OK]${NC} L'atacant queda bloquejat (esperat amb la policy aplicada)."
fi

# 10. Nginx (que sí té la label permesa) HAURIA de continuar accedint
echo "    Provant accés des d'Nginx (hauria de FUNCIONAR)..."
if kubectl exec deployment/nginx -- wget -qO- --timeout=5 http://backend:3000 2>/dev/null | grep -q "Hello from container"; then
    echo -e "   ${GREEN}[OK]${NC} Nginx continua arribant al backend (label 'app=nginx' permesa)."
else
    echo -e "   ${RED}[ERROR]${NC} Nginx NO arriba al backend. La policy és massa restrictiva."
    exit 1
fi

echo "----------------------------------------------------"
echo -e "${GREEN}🏁 Tot correcte. Resum:${NC}"
echo "   - SENSE policy: atacant → backend  = funciona"
echo "   - AMB policy:   atacant → backend  = bloquejat"
echo "   - AMB policy:   nginx   → backend  = funciona"
echo ""
echo "La NetworkPolicy aplica el principi de mínim privilegi correctament."
