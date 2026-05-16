# Challenge B: Full Integration Test (Setmana 13)

> **Objectiu:** Demostrar que tota la infraestructura es pot desplegar **des de zero** usant únicament el codi del repositori (IaC), sense passos manuals amagats. És el test definitiu de reproductibilitat.

---

## 1. Estat inicial: destruir-ho tot

Comencem amb un clúster Minikube net per assegurar que no hi ha res "amagat" de proves anteriors.

```bash
# 1.1. Destrucció via Terraform 
cd fase2/terraform
terraform destroy -auto-approve

# 1.2. Verificació: no hi ha cap pod, deployment ni service del nostre stack
kubectl get all
# Resultat esperat: només el servei 'kubernetes' del control plane

# 1.3. (Opcional) Reset complet del clúster si volem partir 100% net
minikube delete
minikube start --driver=docker --memory=4096 --cpus=2
```

**Captura esperada de `kubectl get all` després del destroy:**
```
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   ...
```

---

## 2. Desplegament des de zero amb Terraform

```bash
# 2.1. Inicialitzar Terraform (baixa el provider de Kubernetes)
terraform init

# 2.2. Plan: veure què crearà
terraform plan

# 2.3. Apply: crear tots els recursos
terraform apply -auto-approve
```

**Recursos que crea Terraform (5 en total):**
1. `kubernetes_config_map.app_config`
2. `kubernetes_deployment.backend` (2 rèpliques)
3. `kubernetes_service.backend` (ClusterIP, port 3000)
4. `kubernetes_deployment.nginx` (1 rèplica)
5. `kubernetes_service.nginx_service` (NodePort 30080)

**Temps mesurat de desplegament:**

| Pas | Temps aproximat |
| :--- | :--- |
| `terraform init` (1a vegada) | 15–30 s |
| `terraform plan` | 2–4 s |
| `terraform apply` (creació de recursos K8s) | 20–40 s |
| Pull d'imatges Docker Hub (1a vegada) | 30–90 s (depèn de la xarxa) |
| Pods en estat `Running` | < 2 minuts total |

---

## 3. Verificació end-to-end

```bash
# 3.1. Tots els pods han d'estar Running
kubectl get pods
```
**Resultat esperat:**
```
NAME                       READY   STATUS    RESTARTS   AGE
backend-7f9c5d8b9-abcd1    1/1     Running   0          45s
backend-7f9c5d8b9-efgh2    1/1     Running   0          45s
nginx-6c8d9b7f4-xyz12      1/1     Running   0          45s
```

```bash
# 3.2. Els serveis estan exposats correctament
kubectl get svc
```
**Resultat esperat:**
```
NAME            TYPE        CLUSTER-IP       PORT(S)        AGE
backend         ClusterIP   10.108.x.x       3000/TCP       50s
nginx-service   NodePort    10.97.x.x        80:30080/TCP   50s
```

```bash
# 3.3. Comunicació entre serveis (backend accessible per nom DNS dins del clúster)
kubectl exec deployment/nginx -- wget -qO- http://backend:3000
```
**Resultat esperat:** `Hello from container - GreenDevCorp`

```bash
# 3.4. Accés extern via NodePort
curl http://$(minikube ip):30080
```
**Resultat esperat:** Pàgina HTML "Bienvenido al Contenedor Nginx de GreenDevCorp"

```bash
# 3.5. Outputs de Terraform
terraform output
```
**Resultat esperat:**
```
nginx_node_port = 30080
```

---

## 4. Proves de resiliència (auto-recuperació)

```bash
# 4.1. Eliminar un pod del backend manualment
POD=$(kubectl get pods -l app=backend -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD

# 4.2. Esperar 5–10 segons i comprovar que K8s n'ha creat un de nou
kubectl get pods -l app=backend
```
**Resultat esperat:** continuen havent 2 pods Running (un acabat de crear amb AGE petit).

---

## 5. Prova d'escalat horitzontal

```bash
# 5.1. Escalar nginx a 3 rèpliques modificant la variable Terraform
# (o directament amb kubectl)
kubectl scale deployment nginx --replicas=3
kubectl rollout status deployment/nginx

# 5.2. Verificar
kubectl get pods -l app=nginx
```
**Resultat esperat:** 3 pods de Nginx Running.

---

## 6. Resum del test

| Verificació | Estat esperat |
| :--- | :--- |
| Destrucció neta del clúster | ✅ |
| Desplegament des de IaC sense passos manuals | ✅ |
| Pods en estat Running en < 2 min | ✅ |
| Service nginx accessible via NodePort 30080 | ✅ |
| Backend accessible internament per DNS (`backend:3000`) | ✅ |
| Resiliència: pod eliminat → recreat automàticament | ✅ |
| Escalat: 1 → 3 rèpliques sense downtime | ✅ |

**Conclusió:** La infraestructura és **reproduïble**, **declarativa** i **resilient**. Qualsevol membre nou de l'equip pot tenir el sistema funcionant amb 3 comandes (`git clone`, `terraform init`, `terraform apply`).

---

## 7. Issues coneguts durant el test

| Issue | Causa | Solució |
| :--- | :--- | :--- |
| `ErrImagePull` la primera vegada | Connexió lenta a Docker Hub o NAT VirtualBox | Configurar adaptador en mode Bridge a la VM |
| `OOMKilled` als pods | Minikube amb < 4 GB RAM | Augmentar memòria de la VM a 4 GB |
| `terraform apply` falla amb "connection refused" | Minikube no està arrencat | Executar `minikube start` abans |
| Pods en `Pending` indefinidament | Recursos insuficients al node | `kubectl describe pod <nom>` per veure el motiu real |
