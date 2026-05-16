# GSX - Práctica 2: Infraestructura IT Organizativa

### Proyecto: Organizational IT Infrastructure (GreenDevCorp)
**Administradores:** Pau Domingo Torrijos i Adrià Cabré Acer

---

## Índice de Contenidos
1. [Visión General del Proyecto](#1-visión-general-del-proyecto)
2. [Arquitectura del Sistema](#2-arquitectura-del-sistema)
3. [Semana 8: Dockerización (Básico e Intermedio)](#3-semana-8-dockerización)
4. [Semana 9: Orquestación con Docker Compose](#4-semana-9-orquestación-con-docker-compose)
5. [Semana 10: Despliegue Avanzado con Kubernetes](#5-semana-10-despliegue-avanzado-con-kubernetes)
6. [Semana 11: Infrastructure as Code (Terraform) y CI/CD](#6-semana-11-infrastructure-as-code-y-cicd)
7. [Semana 12: Diseño de Red e Identidad](#7-semana-12-diseño-de-red-e-identidad)
8. [Semana 13: Integración, Documentación y Reflexión](#8-semana-13-integración-documentación-y-reflexión)
9. [Instalación y Verificación](#9-instalación-y-verificación)
10. [Runbook Operacional](#10-runbook-operacional)
11. [Guía de Troubleshooting](#11-guía-de-troubleshooting)
12. [Estructura del Repositorio](#12-estructura-del-repositorio)
13. [Documentación Adicional](#13-documentación-adicional)

---

## 1. Visión General del Proyecto

GreenDevCorp ha crecido de 4 a 20+ desarrolladores y la infraestructura monoservidor de la Práctica 1 ya no escala. En esta Práctica 2 hemos rediseñado la infraestructura aplicando prácticas modernas de DevOps:

- **Contenedores** (Docker) para portabilidad entre entornos.
- **Orquestación local** (Docker Compose) para desarrollo multiservicio.
- **Orquestación de producción** (Kubernetes / Minikube) con auto-recuperación y escalado.
- **Infrastructure as Code** (Terraform) para infraestructura reproducible.
- **CI/CD** (GitHub Actions) para construir, validar y publicar artefactos automáticamente.

---

## 2. Arquitectura del Sistema

El sistema tiene dos partes claras: el pipeline de CI en la nube (GitHub Actions + Docker Hub) y el clúster de Kubernetes local (Minikube) donde corren los servicios.

```
   Repo (GitHub)
        |
        | git push
        v
   GitHub Actions  ----->  Docker Hub
   (build + validate)      (imágenes adriii9/...)
                                |
                                | pull
                                v
   +---------------------------------------+
   |          Minikube (local)             |
   |                                       |
   |   nginx (1 pod)    backend (2 pods)   |
   |     |                  ^              |
   |     |                  |              |
   |     +---- red interna -+              |
   |                                       |
   |   ConfigMap: app-config               |
   +---------------------------------------+
                |
                | NodePort 30080
                v
            Cliente
```

Flujo:
1. Hacemos `git push` con cambios en el código, el Dockerfile o el Terraform.
2. GitHub Actions construye las imágenes Docker, las taggea con el SHA corto del commit y las sube a Docker Hub. En paralelo valida la sintaxis del código Terraform.
3. En la máquina local, ejecutamos `terraform apply` (o `kubectl apply -f kubernetes/`) contra Minikube para que se descarguen las imágenes nuevas y se actualicen los Deployments.
4. El cliente accede a la web a través del NodePort `30080`.

---

## 3. Semana 8: Dockerización

En esta fase hemos migrado los servicios de la Práctica 1 a un entorno de contenedores utilizando **Docker**. Se han cumplido los objetivos del nivel básico y se han implementado mejoras de nivel intermedio.

### 3.1. Servidor Web (Nginx)
Contenedor Nginx que sirve una página estática inmutable.
- **Nivel Básico:** Creación de imagen personalizada con `Dockerfile` exponiendo el puerto del servidor.
- **Nivel Intermedio (Optimización):** Uso de imagen base `nginx:alpine` para reducir el tamaño (~20 MB frente a ~140 MB de `nginx:latest`).
- **Nivel Intermedio (Seguridad):** El contenedor no corre como `root`. Se ha reconfigurado el usuario `nginx` y se han redirigido los archivos temporales y el PID a `/tmp` para permitir ejecución sin privilegios.
- **Puerto interno:** 8080 (puerto no privilegiado para poder correr como usuario `nginx`).

Archivos clave:
- `fase2/nginx/Dockerfile`
- `fase2/nginx/nginx.conf`
- `fase2/nginx/index.html`

### 3.2. Aplicación Simple (Node.js)
API mínima en Node.js que responde `Hello from container - GreenDevCorp`.
- **Nivel Básico:** Dockerización de una app funcional con sus dependencias.
- **Nivel Intermedio (Multistage Build):** Construcción en dos etapas (`builder` y `runtime`) para minimizar el tamaño de la imagen final.
- **Nivel Intermedio (Caché de capas):** Se copia primero `package*.json` y se hace `npm install` antes de copiar el resto del código, aprovechando la caché de capas Docker.
- **Nivel Intermedio (Seguridad):** Se utiliza el usuario `node` por defecto para evitar escaladas de privilegios.

Archivos clave:
- `fase2/simple-app/Dockerfile`
- `fase2/simple-app/server.js`
- `fase2/simple-app/package.json`
- `fase2/simple-app/.dockerignore`

### 3.3. Publicación en Docker Hub
Ambas imágenes están publicadas en Docker Hub bajo el usuario `adriii9`:
- `adriii9/nginx-custom:v1` (y tags `:latest`, `:<sha>`)
- `adriii9/simple-app-node:v1` (y tags `:latest`, `:<sha>`)

---

## 4. Semana 9: Orquestación con Docker Compose

En la Semana 9 hemos pasado de gestionar contenedores aislados a definir todo el stack (backend + frontend) en un único `docker-compose.yml`, con red dedicada y volúmenes persistentes.

### 4.1. Orquestación del Backend (Servicio `app`)
- **Nivel Básico:** El servicio se define en el YAML para levantarse junto al resto del sistema.
- **Nivel Intermedio (Gestión de ciclo de vida):** Política de reinicio automático (`restart: always`). Si el proceso del backend muere, Docker Compose lo reinicia sin intervención humana.

### 4.2. Orquestación del Frontend (Servicio `web`)
- **Nivel Básico:** Mapeo de puertos vía variables de entorno para evitar conflictos en el host.
- **Nivel Intermedio (Dependencias):** Uso de la directiva `depends_on` para garantizar el orden de arranque: el frontend espera al backend para evitar errores tipo "Bad Gateway" durante el boot.

### 4.3. Redes y Aislamiento (Networking)
- **Nivel Básico:** Comunicación básica entre contenedores.
- **Nivel Intermedio (Aislamiento):** Se crea una red dedicada `gsx-network` (bridge). Los contenedores se comunican por nombre de servicio (DNS interno de Docker) y quedan aislados de otras aplicaciones del host.

### 4.4. Persistencia de Datos (Volúmenes)
- **Nivel Básico:** Almacenamiento volátil.
- **Nivel Intermedio (Persistencia):** Volumen persistente `nginx_data` montado en `/var/log/nginx`. Los logs sobreviven a la recreación de contenedores.

### 4.5. Configuración Externa (Archivo `.env`)
- **Nivel Intermedio:** Variables como `PORT_WEB`, `PORT_APP` y `COMPOSE_PROJECT_NAME` se definen en un fichero `.env` separado del `docker-compose.yml`. Permite cambiar puertos sin tocar el YAML.

Archivos clave:
- `fase2/docker-compose.yml`
- `fase2/.env`

---

## 5. Semana 10: Despliegue Avanzado con Kubernetes

En esta fase migramos la arquitectura de Docker Compose a un clúster Kubernetes local usando Minikube, con el objetivo de tener auto-recuperación, escalado y resistencia a fallos.

### 5.1. Orquestación Avanzada y Resiliencia
- **Nivel Básico:** Despliegue de Nginx y Node.js como `Deployment` expuestos mediante `Service`.
- **Nivel Intermedio (Health Checks):** `livenessProbe` y `readinessProbe` en puertos 3000 (backend) y 8080 (nginx). El clúster solo enruta tráfico a pods sanos.
- **Nivel Avanzado (Auto-sanado):** Si un pod muere, el `ReplicaSet` lo recrea automáticamente en segundos. Verificado en `verify_week10.sh` matando un pod intencionadamente.

### 5.2. Gestión de Recursos y Configuración
- **Nivel Intermedio (Requests & Limits):** Límites estrictos de CPU/RAM para evitar `OOMKilled`:
  - Backend: `requests: 64Mi/100m`, `limits: 128Mi/250m`.
  - Nginx: `requests: 32Mi/50m`, `limits: 64Mi/100m`.
- **Nivel Intermedio (ConfigMap):** Variables de entorno (`APP_MESSAGE`, `PORT`) inyectadas en el backend vía `ConfigMap` (`app-config`), sin necesidad de reconstruir la imagen.

### 5.3. Exposición Externa (Service)
- **NodePort 30080** mapeado al puerto 80 del Service, que apunta al puerto 8080 del contenedor Nginx. Accesible mediante `curl http://$(minikube ip):30080`.

### 5.4. Escalabilidad Horizontal
- Escalado dinámico verificado: `kubectl scale deployment nginx --replicas=3` permite absorber picos de tráfico al instante.

### 5.5. Lecciones aprendidas (Troubleshooting Minikube)
Durante el desarrollo detectamos cuellos de botella en la VM:
- **RAM:** Minikube necesita ~2 GB para el control plane. Con solo 2 GB totales aparecía `fork: retry: Resource temporarily unavailable`. **Solución:** ampliar la VM a 4 GB.
- **Red:** La configuración NAT de VirtualBox provocaba `ErrImagePull` por timeouts. **Solución:** adaptador en modo Bridge.
- **CPU:** Asignar mínimo 2 vCPUs para que el arranque del clúster no se congestione.

Archivos clave:
- `fase2/kubernetes/nginx.yaml`
- `fase2/kubernetes/backend.yaml`
- `fase2/kubernetes/configmap.yaml`

---

## 6. Semana 11: Infrastructure as Code y CI/CD

En esta fase dejamos de escribir manifiestos Kubernetes a mano y montamos un pipeline de CI que construye y valida el código automáticamente en cada push.

### 6.1. IaC con Terraform

Hemos optado por Terraform en vez de Ansible por varios motivos:
1. Es declarativa: describimos el estado final, no los pasos para llegar.
2. Mantiene un `tfstate` que permite detectar diferencias entre el código y la infraestructura real.
3. Es una de las herramientas más usadas en infraestructura cloud y tiene un provider oficial de Kubernetes con buena documentación.

El código Terraform sustituye los manifiestos YAML manuales de la Semana 10 y genera exactamente los mismos recursos (`ConfigMap`, `Deployment` y `Service` para backend y nginx).

**Organización del código** (`fase2/terraform/`):
- `main.tf`: define ConfigMap, Deployments y Services del backend y Nginx.
- `variables.tf`: parametriza el deployment (`docker_username`, `image_tag`, `replicas_backend`).
- `outputs.tf`: expone el `node_port` del Service Nginx tras el `apply`.

**Variables clave:**

| Variable | Por defecto | Propósito |
| :--- | :--- | :--- |
| `docker_username` | `adriii9` | Usuario de Docker Hub del que se tiran las imágenes. |
| `image_tag` | `v1` | Tag de imagen a desplegar. En despliegues reales se pasa el SHA del commit. |
| `replicas_backend` | `2` | Número de réplicas del backend. |

**Comandos básicos:**
```bash
cd fase2/terraform
terraform init           # Inicializa providers
terraform plan           # Muestra qué cambiará
terraform apply          # Aplica los cambios al clúster Minikube
terraform output         # Muestra el NodePort de Nginx
terraform destroy        # Limpia la infraestructura
```

### 6.2. Pipeline CI con GitHub Actions

Siguiendo la restricción del enunciado (GitHub Actions **no puede acceder a Minikube local**), separamos las responsabilidades:

- **CI en GitHub Actions:** construye/rebuilds imágenes Docker, las publica en Docker Hub con el SHA corto del commit + `latest`, y valida la sintaxis de Terraform.
- **CD local a Minikube:** el administrador ejecuta `terraform apply` (o `kubectl apply -f kubernetes/`) en su máquina contra el clúster local.

**Workflow** (`.github/workflows/ci.yml`):

Se ejecuta en cada `push` y `pull_request` contra `main`/`master` y consta de dos jobs paralelos:

1. **`build-and-push`** (Ubuntu latest):
   - Checkout del código.
   - Cálculo del SHA corto del commit.
   - Login en Docker Hub mediante secretos del repositorio (`DOCKER_USERNAME`, `DOCKER_PASSWORD`).
   - Build & push del backend: `adriii9/simple-app-node:<sha>` + `:latest`.
   - Build & push del nginx: `adriii9/nginx-custom:<sha>` + `:latest`.

2. **`terraform-validate`** (Ubuntu latest):
   - Setup de Terraform.
   - `terraform init -backend=false` (sin backend remoto, solo validación).
   - `terraform validate` para asegurar que el código IaC compila.

**Estrategia de tagging:**
- Cada commit genera una imagen `:<sha>` inmutable (trazabilidad).
- Además se publica como `:latest` para conveniencia.
- En producción, `terraform apply -var="image_tag=<sha>"` ata el deployment a un SHA concreto.

### 6.3. Flujo end-to-end (push → producción local)

1. El desarrollador hace `git push` con un cambio en el código.
2. GitHub Actions arranca el workflow `CI Pipeline (Build & Validate)`.
3. Si el job `build-and-push` termina correctamente, las imágenes nuevas están en Docker Hub.
4. Si el job `terraform-validate` termina correctamente, el IaC es sintácticamente válido.
5. En la máquina local: `cd fase2/terraform && terraform apply -var="image_tag=<sha_short>"`.
6. Terraform actualiza los Deployments de Minikube con la nueva imagen.
7. Verificación: `curl http://$(minikube ip):30080`.

### 6.4. Lecciones del Pipeline
- El workflow estaba inicialmente en `fase2/.github/workflows/`. **GitHub solo detecta workflows en `.github/workflows/` a la raíz del repositorio**, por eso fue movido (commit `ccf90e2`).
- Los secretos `DOCKER_USERNAME` y `DOCKER_PASSWORD` se configuran en **Settings → Secrets and variables → Actions** del repositorio de GitHub.

---

## 7. Semana 12: Diseño de Red e Identidad

En esta semana nos hemos puesto el sombrero de arquitecto de seguridad: hemos diseñado cómo se segmentaría la red de GreenDevCorp a medida que crezca, hemos implementado segmentación real dentro del clúster con NetworkPolicies y hemos investigado los servicios de red e identidad que necesitará la empresa.

### 7.1. Diseño de la arquitectura de red y plan CIDR

Hemos diseñado una red segmentada para GreenDevCorp utilizando el bloque `10.0.0.0/16` para toda la organización.

Plan de direccionamiento (CIDR):
- **Organización global:** `10.0.0.0/16` (65.536 IPs, suficiente para el crecimiento futuro).
- **Desarrollo (Dev):** `10.0.1.0/24` (254 IPs). Entorno aislado para pruebas continuas y experimentación.
- **Staging:** `10.0.2.0/24` (254 IPs). Entorno de pre-producción idéntico a producción para validar cambios.
- **Producción (Prod):** `10.0.3.0/24` (254 IPs). Solo accesible vía Load Balancers / Ingress.
- **Partners externos (DMZ):** `10.0.10.0/24` (254 IPs). Zona aislada para contratistas o integraciones de terceros.

*Razonamiento:* esta subdivisión permite aplicar reglas de firewall claras entre entornos. Por ejemplo, bloquear el tráfico del bloque `10.0.1.0/24` hacia el `10.0.3.0/24` para evitar que un desarrollador afecte a producción accidentalmente.

Diagrama de la arquitectura:
```text
[Internet] --> [DMZ (10.0.10.0/24) VPN Partners]
   |
[Load Balancer / Ingress]
   |
   +---> [Producción (10.0.3.0/24)] ---> [Prod Database]
   |
   +---> [Staging (10.0.2.0/24)]    ---> [Staging Database]
   |
   +---> [Desarrollo (10.0.1.0/24)] ---> [Dev Database]
```

### 7.2. Segmentación interna del clúster con NetworkPolicies

Aplicando el principio de mínimo privilegio, hemos implementado segmentación interna en el clúster con una `NetworkPolicy` (`fase2/kubernetes/networkpolicy.yaml`). La regla fuerza que los pods con la etiqueta `app: backend` solo acepten tráfico entrante por el puerto 3000 proveniente de pods con la etiqueta `app: nginx`. Cualquier otro pod, entorno o atacante interno que intente conectarse directamente al backend queda bloqueado.

Aplicarla:
```bash
kubectl apply -f fase2/kubernetes/networkpolicy.yaml
kubectl get networkpolicy
```

**Verificación end-to-end.** Como Minikube por defecto utiliza `kindnet` (que no aplica NetworkPolicies), hemos reiniciado el clúster con Calico para poder probar la regla de verdad:
```bash
minikube delete
minikube start --cni=calico --memory=3072 --cpus=2
```

Una vez con Calico, el script `fase2/scripts/test_networkpolicy.sh` automatiza el test completo en tres fases:
1. **Sin policy:** lanza un pod `atacante` (label `app=atacante`) y verifica que SÍ puede acceder al backend.
2. **Aplica la policy.**
3. **Con policy aplicada:** verifica que el atacante YA NO puede acceder (`wget` da timeout), pero que Nginx sí sigue accediendo correctamente.

El script ha pasado con los tres `[OK]`, confirmando que la segmentación funciona. El manifiesto es válido y se aplicará igual en cualquier clúster Kubernetes de producción (EKS, GKE, AKS, on-prem con Calico/Cilium).

### 7.3. Servicios de red core: DNS, DHCP, NTP

- **DNS (Domain Name System):** traduce nombres de dominio legibles (`api.greendevcorp.com`) a direcciones IP (`10.0.3.45`). En una organización, y especialmente en entornos de contenedores donde las IPs cambian constantemente, el DNS es vital para que los servicios se descubran y comuniquen entre ellos usando nombres fijos y estables.
- **DHCP (Dynamic Host Configuration Protocol):** asigna direcciones IP, máscaras de subred y puertas de enlace de manera dinámica y automática a los dispositivos de la red. Ahorra mucho tiempo al equipo de operaciones, evita tener que configurar IPs manualmente y previene conflictos de IPs duplicadas en la oficina.
- **NTP (Network Time Protocol):** mantiene sincronizados los relojes de todos los servidores. Es crítico tanto para la seguridad como para la operativa: si los relojes no coinciden, la validación de certificados SSL falla, la correlación de logs durante una investigación es imposible y las bases de datos distribuidas sufren para ordenar las transacciones.

### 7.4. Identidad: autenticación, autorización y estrategia para GreenDevCorp

**Autenticación vs Autorización:** la autenticación responde a "¿quién eres?" (validar usuario y contraseña al entrar al sistema). La autorización responde a "¿qué puedes hacer?" (una vez dentro, validar si tienes permisos para borrar una base de datos).

**Sistemas de identidad evaluados:**
- **LDAP:** protocolo estándar abierto para consultar directorios de usuarios. Ligero pero primitivo y requiere mantenimiento alto.
- **Active Directory (AD):** solución corporativa de Microsoft, excelente para redes locales y gestión de equipos Windows, pero requiere infraestructura dedicada.
- **SSO (Single Sign-On):** permite al usuario autenticarse una sola vez y acceder a múltiples aplicaciones. Mejora la seguridad y la experiencia de usuario drásticamente.

**Recomendación para GreenDevCorp:** dada la escala de la startup (20+ personas en crecimiento), recomendamos un proveedor de identidad cloud con capacidades SSO (Google Workspace, Microsoft Entra ID u Okta).

*Razonamiento:* mantener servidores LDAP o AD locales consumiría demasiados recursos para un equipo de operaciones pequeño. Una solución cloud SSO centraliza la autenticación, facilita el offboarding (revocar acceso a todos los sistemas con un solo clic), aplica MFA por defecto y se integra nativamente con herramientas modernas como GitHub y Kubernetes.

---

## 8. Semana 13: Integración, Documentación y Reflexión

En la Semana 13 cerramos el proyecto: validamos que toda la infraestructura construida en las semanas anteriores funciona como un sistema unificado, generamos la documentación operativa y reflexionamos sobre el proceso.

Por limitaciones de tiempo, nos hemos centrado en los tres challenges obligatorios del enunciado (B, C y D). El Challenge A (observabilidad con Prometheus y Grafana) es opcional y no lo hemos implementado.

### 8.1. Challenge B: Full Integration Test

Hemos validado que toda la infraestructura puede destruirse y recrearse desde cero usando solo el código del repositorio, sin pasos manuales escondidos.

Flujo del test:
1. `terraform destroy -auto-approve`: el clúster queda limpio.
2. `terraform apply -auto-approve`: recreación de los 5 recursos (ConfigMap, 2 Deployments y 2 Services).
3. Verificación de pods `Running`, comunicación interna y acceso externo vía NodePort.
4. Prueba de resiliencia (matar un pod manualmente y comprobar que K8s lo recrea).
5. Prueba de escalado (escalar Nginx de 1 a 3 réplicas).

Tiempo total medido: alrededor de 2 minutos desde `apply` hasta pods en estado `Running`.

Procedimiento completo, comandos paso a paso y resultados esperados: [`fase2/docs/week13/integration-test.md`](./fase2/docs/week13/integration-test.md).

### 8.2. Challenge C: Documentación operacional

Hemos elaborado documentación pensada para que cualquier persona del equipo pueda operar el sistema sin necesidad de ayuda externa. Toda ella está integrada en este mismo README:

- Runbook operacional: procedimientos del día a día (desplegar una nueva versión vía CI + Terraform, escalar servicios, hacer rollback, leer logs, reiniciar servicios). Ver [Sección 10](#10-runbook-operacional).
- Guía de troubleshooting: diagnóstico de fallos habituales (`CrashLoopBackOff`, `ImagePullBackOff`, `OOMKilled`, fallos del CI, fallos de `terraform apply`, etc.) con el patrón síntoma, diagnóstico y solución. Ver [Sección 11](#11-guía-de-troubleshooting).
- Diagrama de arquitectura: incluido en la [Sección 2](#2-arquitectura-del-sistema).

### 8.3. Challenge D: Reflexión y preparación de la entrevista

- Reflexiones individuales (una por miembro del equipo), de entre 500 y 1000 palabras, donde cada uno cuenta qué le ha resultado más difícil, qué le ha sorprendido, qué haría diferente y qué quiere seguir aprendiendo:
  - [`fase2/docs/week13/reflection-adria.md`](./fase2/docs/week13/reflection-adria.md)
  - [`fase2/docs/week13/reflection-pau.md`](./fase2/docs/week13/reflection-pau.md)
- Preparación de la entrevista oral: notas internas con las preguntas que esperamos defender (por qué Kubernetes en vez de Compose, por qué Alpine, por qué Terraform en vez de Ansible, diferencia entre `livenessProbe` y `readinessProbe`, etc.) y un checklist pre-entrevista. [`fase2/docs/week13/interview-prep.md`](./fase2/docs/week13/interview-prep.md).

---

## 9. Instalación y Verificación

Todo el proceso de aprovisionamiento se ha automatizado mediante scripts en `fase2/scripts/`.

### 9.1. Despliegue con Docker Compose (Semana 9)
```bash
chmod +x fase2/scripts/*.sh
./fase2/scripts/setup.sh      # Instala Docker, construye imágenes y levanta el stack
./fase2/scripts/verify.sh     # Verifica salud y conectividad (curl al :3000 y :8080)
```

### 9.2. Despliegue con Kubernetes / Minikube (Semana 10)
```bash
chmod +x fase2/scripts/*_week10.sh
./fase2/scripts/setup_week10.sh    # Instala kubectl + minikube
./fase2/scripts/deploy_week10.sh   # Arranca Minikube y aplica manifiestos
./fase2/scripts/verify_week10.sh   # Test: web externa, resiliencia (pod kill), escalado
```

### 9.3. Despliegue con Terraform (Semana 11)
```bash
cd fase2/terraform
terraform init
terraform plan
terraform apply -auto-approve
terraform output nginx_node_port
```

### 9.4. Test de la NetworkPolicy (Semana 12)

Requiere Minikube arrancado con Calico (`minikube start --cni=calico`).
```bash
chmod +x fase2/scripts/test_networkpolicy.sh
./fase2/scripts/test_networkpolicy.sh
```
El script despliega la app, lanza un pod atacante, aplica la policy y verifica que el atacante queda bloqueado mientras Nginx sigue accediendo. Tres `[OK]` al final = test pasado.

### 9.5. Verificación manual rápida
```bash
# Estado del clúster
kubectl get pods,svc,deployments,configmaps

# Logs de un servicio
kubectl logs deployment/backend
kubectl logs deployment/nginx

# Acceso externo
curl http://$(minikube ip):30080
```

---

## 10. Runbook Operacional

Guía práctica de las operaciones del día a día: desplegar una versión nueva, escalar, leer logs y recuperarse de errores. Pensada para que un miembro nuevo del equipo pueda operar el sistema sin ayuda.

### 10.1. Desplegar una nueva versión de la aplicación

**Caso de uso:** un desarrollador ha modificado el código del backend o del nginx y quiere que los cambios lleguen al clúster.

**Pasos:**
```bash
# 1. Push del código
git add .
git commit -m "feat: descripción del cambio"
git push origin main

# 2. Esperar que CI genere las imágenes
# Comprobar en: https://github.com/Adriii9/GSX-Practica2/actions
# Los dos jobs (build-and-push y terraform-validate) deben estar en verde

# 3. Obtener el SHA corto del commit (es el tag de la imagen nueva)
SHA=$(git rev-parse --short HEAD)

# 4. Desplegar a Minikube con el tag nuevo
cd fase2/terraform
terraform apply -var="image_tag=$SHA" -auto-approve

# 5. Verificar rollout
kubectl rollout status deployment/backend
kubectl rollout status deployment/nginx

# 6. Comprobar que responde
curl http://$(minikube ip):30080
```

### 10.2. Escalar un servicio

**Caso de uso:** se prevé un pico de tráfico y queremos más réplicas del backend.

**Opción A. Vía Terraform (preferida, queda en código):**
Editar `fase2/terraform/variables.tf`:
```hcl
variable "replicas_backend" {
  default = 5    # antes era 2
}
```
Aplicar:
```bash
terraform apply -auto-approve
```

**Opción B. Vía kubectl (cambio temporal, no quedará en IaC):**
```bash
kubectl scale deployment backend --replicas=5
kubectl rollout status deployment/backend
```

**Verificar:**
```bash
kubectl get pods -l app=backend
```

### 10.3. Rollback a la versión anterior

**Caso de uso:** la nueva versión que acabamos de desplegar rompe producción.

**Opción A. Rollback rápido con kubectl:**
```bash
kubectl rollout undo deployment/backend
kubectl rollout undo deployment/nginx
kubectl rollout status deployment/backend
```

**Opción B. Redesplegar el SHA anterior con Terraform:**
```bash
# 1. Encontrar el SHA anterior en el git log
git log --oneline -5

# 2. Desplegarlo
cd fase2/terraform
terraform apply -var="image_tag=<sha_anterior>" -auto-approve
```

### 10.4. Leer logs de un servicio

```bash
# Listar pods
kubectl get pods

# Últimas 100 líneas de un pod
kubectl logs <nombre-del-pod> --tail=100

# Logs en tiempo real (tail -f)
kubectl logs -f <nombre-del-pod>

# Logs de todos los pods de un deployment
kubectl logs deployment/backend --tail=200
kubectl logs deployment/nginx --tail=200

# Logs anteriores (si el pod ha hecho restart)
kubectl logs <nombre-del-pod> --previous
```

### 10.5. Inspección rápida del estado del clúster

```bash
# Resumen global
kubectl get all

# Detalle de un pod (events, condiciones, motivo de errores)
kubectl describe pod <nombre-del-pod>

# Detalle de un deployment
kubectl describe deployment backend

# Recursos usados por pod (requiere metrics-server)
kubectl top pods
```

### 10.6. Acceso en vivo a un pod (debug)

```bash
# Abrir una shell dentro del pod backend
kubectl exec -it deployment/backend -- sh

# Lanzar un curl desde dentro para probar la red interna
kubectl exec deployment/nginx -- wget -qO- http://backend:3000
```

### 10.7. Reiniciar un servicio sin desplegar

**Caso de uso:** el servicio está "atascado" pero el código es correcto (ej: conexión pendiente a una BBDD externa).

```bash
kubectl rollout restart deployment/backend
kubectl rollout status deployment/backend
```

Esto fuerza a todos los pods a recrearse manteniendo la misma imagen.

### 10.8. Detener toda la infraestructura

**Parada temporal** (se recupera con `minikube start`):
```bash
minikube stop
```

**Destrucción total** (hay que redesplegar con Terraform después):
```bash
cd fase2/terraform
terraform destroy -auto-approve
```

### 10.9. Tareas de mantenimiento periódico

| Tarea | Periodicidad | Comando |
| :--- | :--- | :--- |
| Actualizar imágenes base (alpine, node) | Mensual | Modificar `Dockerfile`, hacer push, esperar CI |
| Limpiar imágenes Docker antiguas en el host | Semanal | `docker image prune -a` |
| Rotar logs de Nginx (volumen `nginx_data`) | Mensual | Manual: copiar a backup y vaciar |
| Revisar pods con muchos restarts | Semanal | `kubectl get pods --sort-by=.status.containerStatuses[0].restartCount` |

### 10.10. Contactos y responsables

| Componente | Responsable |
| :--- | :--- |
| Aplicación backend (Node.js) | Equipo Dev |
| Frontend Nginx + estáticos | Equipo Dev |
| Infra K8s + Terraform | Equipo Ops (Pau, Adrià) |
| CI/CD GitHub Actions | Equipo Ops (Pau, Adrià) |
| Credenciales Docker Hub | Adrià (cuenta `adriii9`) |

---

## 11. Guía de Troubleshooting

Diagnóstico de los problemas más habituales. Para cada caso indicamos el síntoma, cómo diagnosticarlo y cómo solucionarlo.

### 11.1. El pod no arranca

**Síntomas:** `kubectl get pods` muestra estado `Pending`, `CrashLoopBackOff`, `ImagePullBackOff` o `Error`.

**Diagnóstico:**
```bash
# 1. Primero: ver el motivo exacto
kubectl describe pod <nombre-del-pod>
# Mirar la sección "Events" al final

# 2. Si el pod ya ha arrancado alguna vez pero falla después
kubectl logs <nombre-del-pod>
kubectl logs <nombre-del-pod> --previous   # logs de la ejecución anterior si ha reiniciado
```

**Soluciones según el estado:**

| Estado | Causa probable | Solución |
| :--- | :--- | :--- |
| `Pending` | No hay recursos suficientes en el node | Reducir `requests` en los manifests o ampliar la VM |
| `Pending` | El node no cumple `nodeSelectors`/`tolerations` | Revisar la spec del pod (nosotros no usamos estas features) |
| `ImagePullBackOff` | Tag de imagen incorrecto o imagen privada sin credenciales | Verificar `image:` en el Deployment y que la imagen existe en Docker Hub |
| `CrashLoopBackOff` | La aplicación crashea justo después de arrancar | Mirar `kubectl logs --previous`. Suele ser por variable de entorno que falta |
| `OOMKilled` (en `describe`) | El pod consume más memoria que el límite | Subir `resources.limits.memory` u optimizar el código |

### 11.2. El servicio A no puede conectar con el servicio B

**Ejemplo concreto:** "Nginx muestra 502 Bad Gateway porque no puede hablar con el backend."

**Diagnóstico paso a paso:**
```bash
# 1. Comprobar que el servicio de destino existe
kubectl get svc backend
# Debe retornar un ClusterIP y el port 3000

# 2. Comprobar que los pods detrás del servicio están Ready
kubectl get pods -l app=backend
# La columna READY debe ser 1/1 (no 0/1)

# 3. Comprobar que el selector del servicio coincide con la label de los pods
kubectl describe svc backend | grep Selector
kubectl get pods --show-labels | grep backend

# 4. Probar la conexión desde otro pod
kubectl exec deployment/nginx -- wget -qO- http://backend:3000
# Si esto funciona, el problema es la configuración del cliente, no la red
```

**Causas habituales:**

| Causa | Solución |
| :--- | :--- |
| Selector del Service no coincide con labels de los pods | Ajustar `spec.selector` en el manifest o volver a `terraform apply` |
| `readinessProbe` falla y el pod no se añade al Service | Mirar `kubectl describe pod` y corregir el probe |
| Nombre del servicio mal escrito en el código cliente | Debe ser `http://backend:3000`, no `localhost:3000` |
| Servicio en otro namespace | Usar `backend.<namespace>.svc.cluster.local` |

### 11.3. Acceso externo a Nginx falla

**Síntoma:** `curl http://$(minikube ip):30080` retorna `Connection refused` o timeout.

**Diagnóstico:**
```bash
# 1. ¿Minikube está arrancado?
minikube status

# 2. ¿El Service es de tipo NodePort y el puerto es 30080?
kubectl get svc nginx-service
# TYPE debe ser NodePort, PORT(S) debe mostrar 80:30080/TCP

# 3. ¿Hay algún pod de Nginx Ready?
kubectl get pods -l app=nginx

# 4. ¿La IP de Minikube es la correcta?
minikube ip
```

**Soluciones:**
- Si Minikube no está arrancado: `minikube start`.
- Si el NodePort no es 30080: revisar `fase2/kubernetes/nginx.yaml` o `fase2/terraform/main.tf` y volver a aplicar.
- Si los pods Nginx no están Ready: ir al apartado 11.1.
- Si todo está OK pero sigue sin responder: probar `minikube service nginx-service --url` para obtener una URL alternativa mediante un túnel.

### 11.4. El CI en GitHub Actions falla

**Caso A. El job `build-and-push` falla:**
```
Error: denied: requested access to the resource is denied
```
**Causa:** secrets `DOCKER_USERNAME` o `DOCKER_PASSWORD` no configurados o incorrectos.
**Solución:** Ir a `Settings → Secrets and variables → Actions` del repo en GitHub y revisarlos. La password debe ser un **Access Token** de Docker Hub, no la contraseña del usuario.

**Caso B. El job `terraform-validate` falla:**
```
Error: Invalid argument name
```
**Causa:** Error de sintaxis en el código `.tf`.
**Solución:** Local: `cd fase2/terraform && terraform fmt && terraform validate` para ver el error exacto antes de volver a hacer push.

**Caso C. El workflow no se ejecuta:**
**Causa probable:** Fichero `ci.yml` está en `fase2/.github/workflows/` en lugar de `.github/workflows/` en la raíz.
**Solución:** Moverlo a la ubicación correcta:
```bash
mkdir -p .github/workflows
git mv fase2/.github/workflows/ci.yml .github/workflows/ci.yml
git commit -m "fix: mover workflow a la raíz"
git push
```

### 11.5. `terraform apply` falla con "connection refused"

**Síntoma:**
```
Error: Failed to construct REST client
Get "https://127.0.0.1:XXXXX/api?...": dial tcp: connection refused
```

**Diagnóstico:**
```bash
# 1. ¿Minikube está arrancado?
minikube status

# 2. ¿El contexto de kubectl es minikube?
kubectl config current-context

# 3. ¿El path al kubeconfig en main.tf es correcto?
grep config_path fase2/terraform/main.tf
# Debe ser /home/<usuario>/.kube/config
```

**Soluciones:**
- `minikube start`
- `kubectl config use-context minikube`
- Ajustar `config_path` en el `provider "kubernetes"` para que coincida con la ruta real del kubeconfig en tu sistema.

### 11.6. Pods con muchos restarts (sin estar en crash)

**Síntoma:** `RESTARTS` es > 10 y sube.

**Diagnóstico:**
```bash
kubectl describe pod <nombre> | grep -A 5 "Last State"
kubectl logs <nombre> --previous
```

**Causas habituales y soluciones:**

| Causa | Solución |
| :--- | :--- |
| `livenessProbe` demasiado agresivo (initialDelaySeconds bajo) | Subir `initialDelaySeconds` en el manifest para que la app tenga tiempo de arrancar |
| Memoria al límite, OOMKilled cíclico | Aumentar `resources.limits.memory` |
| La app sale voluntariamente tras una operación | Revisar el código de la app, debe ser un proceso persistente |

### 11.7. Referencia rápida de comandos de diagnóstico

```bash
# Estado global
kubectl get all
kubectl get events --sort-by=.lastTimestamp | tail -20

# Detalle de un objeto
kubectl describe <tipo> <nombre>

# Logs
kubectl logs <pod>
kubectl logs deployment/<nombre>
kubectl logs -f <pod>                    # tail en vivo
kubectl logs <pod> --previous            # ejecución anterior

# Recursos
kubectl top nodes
kubectl top pods

# Test de red desde dentro
kubectl exec -it deployment/nginx -- sh
# (una vez dentro) wget -qO- http://backend:3000

# Verificar Service ↔ Pods
kubectl get endpoints
# Si Endpoints está vacío, el selector no encuentra pods Ready
```

### 11.8. Cuando nada de lo anterior funciona

1. **Restart suave:** `minikube stop && minikube start`.
2. **Restart fuerte:** `minikube delete && minikube start --memory=4096 --cpus=2`, luego `terraform apply`.
3. **Última opción:** mirar la documentación oficial de Kubernetes para el mensaje de error concreto en [kubernetes.io/docs](https://kubernetes.io/docs/).
4. **Si es un problema recurrente que afecta a todo el equipo:** abrir un issue en el repo describiendo síntoma, comandas probadas y logs adjuntos.

---

## 12. Estructura del Repositorio

```
GSX-Practica2/
├── .github/
│   └── workflows/
│       └── ci.yml                  # Pipeline CI: build, push, validate
├── configs/                        # Configuraciones systemd de la Práctica 1
├── scripts/                        # Scripts de la Práctica 1
├── logs/
├── fase2/                          # ← Toda la Práctica 2
│   ├── docker-compose.yml          # Semana 9: orquestación local
│   ├── .env                        # Variables de entorno (puertos)
│   ├── nginx/
│   │   ├── Dockerfile              # Semana 8: imagen Nginx alpine, non-root
│   │   ├── nginx.conf
│   │   └── index.html
│   ├── simple-app/
│   │   ├── Dockerfile              # Semana 8: multistage Node.js
│   │   ├── server.js
│   │   ├── package.json
│   │   └── .dockerignore
│   ├── kubernetes/                 # Semanas 10 y 12: manifiestos K8s
│   │   ├── nginx.yaml
│   │   ├── backend.yaml
│   │   ├── configmap.yaml
│   │   └── networkpolicy.yaml      # Semana 12: segmentación interna
│   ├── terraform/                  # Semana 11: IaC
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── scripts/                    # Automatización
│   │   ├── setup.sh                # Despliegue Compose
│   │   ├── verify.sh
│   │   ├── setup_week10.sh         # Instalación K8s
│   │   ├── deploy_week10.sh        # Despliegue K8s
│   │   ├── verify_week10.sh
│   │   └── test_networkpolicy.sh   # Semana 12: test NetworkPolicy
│   ├── docs/                       # Semana 13: docs específicos
│   │       ├── integration-test.md
│   │       ├── reflection-adria.md
│   │       ├── reflection-pau.md
│   └── README.md
└── README.md                       # README de la Práctica 1
```

---

## 13. Documentación Adicional

El runbook y la guía de troubleshooting están integrados directamente en este README (Secciones 10 y 11). El resto de documentación de la Semana 13 vive en `fase2/docs/week13/`:

- [`integration-test.md`](./fase2/docs/week13/integration-test.md): test completo de destruir la infraestructura y volver a desplegarla desde cero.
- [`reflection-adria.md`](./fase2/docs/week13/reflection-adria.md) y [`reflection-pau.md`](./fase2/docs/week13/reflection-pau.md): reflexiones individuales sobre el aprendizaje.

---


