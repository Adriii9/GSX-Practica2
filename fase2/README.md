# GSX - Práctica 2: Containerización y Orquestación Completa

##  Índice
* [Semana 8: Dockerización (Básico e Intermedio)](#semana-8-dockerización-básico-e-intermedio)
* [Semana 9: Orquestación con Docker Compose (Básico e Intermedio)](#semana-9-orquestación-con-docker-compose)
* [Instalación y Verificación](#instalación-y-verificación)

---

## Semana 8: Dockerización (Básico e Intermedio)

En esta fase hemos migrado los servicios de la Fase 1 a un entorno de contenedores utilizando **Docker**. Se han cumplido los objetivos del nivel básico y se han implementado mejoras de nivel intermedio:

### 1. Servidor Web (Nginx)
Se ha configurado un contenedor Nginx que sirve una página estática inmutable.
* **Nivel Básico:** Creación de imagen personalizada con `Dockerfile` exponiendo el puerto del servidor.
* **Nivel Intermedio (Optimización):** Uso de imagen base `nginx:alpine` para reducir el tamaño de la imagen (~20MB vs ~140MB).
* **Nivel Intermedio (Seguridad):** El contenedor no corre como `root`. Se ha configurado el usuario `nginx` y se han redirigido los archivos temporales a `/tmp` para permitir la ejecución sin privilegios.

### 2. Aplicación Simple (Node.js)
Se ha desarrollado una API mínima en Node.js que responde "Hello from container".
* **Nivel Básico:** Dockerización de una app funcional con sus dependencias.
* **Nivel Intermedio (Multistage Build):** Se utiliza una construcción en dos etapas (Etapa 1: Build, Etapa 2: Runtime) para asegurar que la imagen final sea lo más ligera posible.
* **Nivel Intermedio (Seguridad):** Uso del usuario `node` por defecto para evitar vulnerabilidades de escalada de privilegios.

---

## Semana 9: Orquestación con Docker Compose

En la Semana 9 hemos dado el salto de gestionar contenedores aislados a gestionar un **Sistema de Microservicios Orquestado**. Esto permite que el Backend y el Frontend trabajen como una única unidad funcional.



### 1. Orquestación del Backend (Servicio `app`)
El servicio de Node.js se integra ahora en una estructura gobernada por código (IaC).
* **Nivel Básico:** El servicio se define en el archivo YAML para ser levantado junto al resto del sistema.
* **Nivel Intermedio (Gestión de Ciclo de Vida):** Implementación de políticas de reinicio automático (`restart: always`). Si el proceso del backend falla por un error crítico, Docker Compose lo levanta automáticamente sin intervención humana.

### 2. Orquestación del Frontend (Servicio `web`)
El servidor Nginx ahora actúa de forma coordinada con el resto de la infraestructura.
* **Nivel Básico:** Mapeo de puertos mediante variables para evitar conflictos en el host.
* **Nivel Intermedio (Dependencias):** Uso de la directiva `depends_on`. Esto garantiza un orden lógico de arranque: el servidor web no se inicia hasta que el backend está operativo, evitando errores de "Bad Gateway" o conexiones fallidas durante el inicio del sistema.

### 3. Redes y Aislamiento (Networking)
* **Nivel Básico:** Uso de la red bridge estándar para comunicación básica.
* **Nivel Intermedio (Aislamiento):** Hemos creado una red dedicada llamada `gsx-network`. Esto crea un entorno privado donde los contenedores pueden comunicarse entre sí mediante sus nombres de servicio (DNS interno de Docker), quedando aislados de otras aplicaciones que pudieran estar corriendo en la misma máquina virtual.

### 4. Persistencia de Datos (Volúmenes)
* **Nivel Básico:** Almacenamiento volátil (si el contenedor se borra, los datos se pierden).
* **Nivel Intermedio (Persistencia):** Configuración de un volumen persistente (`nginx_data`). Hemos vinculado la carpeta de logs de Nginx al host. Esto es vital para entornos profesionales, ya que permite mantener los registros de acceso y errores aunque los contenedores se actualicen o se eliminen.

### 5. Configuración Externa (Archivo `.env`)
* **Nivel Intermedio:** Implementación de un archivo de variables de entorno `.env`. Esto separa la configuración técnica (puertos, nombres de proyecto) del archivo de orquestación principal. Permite que el sistema sea portable y que cualquier administrador pueda cambiar los puertos de escucha sin necesidad de modificar el código del `docker-compose.yml`.

---

## Instalación y Verificación

Para facilitar el despliegue, se han creado scripts de automatización en la carpeta `fase2/scripts/`:

1. **[setup.sh](./fase2/scripts/setup.sh):** Instala las dependencias necesarias, construye las imágenes optimizadas y levanta la orquestación completa mediante `docker-compose`.
2. **[verify.sh](./fase2/scripts/verify.sh):** Comprueba el estado de salud de los servicios, verifica que los contenedores están en ejecución y realiza pruebas de conectividad (Curl) tanto al Backend (puerto 3000) como al Frontend (puerto 8080).

### Comandos rápidos:
```bash
chmod +x fase2/scripts/*.sh
./fase2/scripts/setup.sh
./fase2/scripts/verify.sh
