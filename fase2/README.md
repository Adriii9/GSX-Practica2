# GSX - Práctica 2: Containerización y Orquestación

## Índice
* [Semana 8: Dockerización (Básico e Intermedio)](#semana-8-dockerización-básico-e-intermedio)
* [Instalación y Verificación](#instalación-y-verificación)

---

## Semana 8: Dockerización (Básico e Intermedio)

En esta fase hemos migrado los servicios de la Fase 1 a un entorno de contenedores utilizando **Docker**. Se han cumplido los objetivos del nivel básico y se han implementado mejoras de nivel intermedio para optimizar el rendimiento y la seguridad.

### 1. Servidor Web (Nginx)
Se ha configurado un contenedor Nginx que sirve una página estática inmutable.
* **Nivel Básico:** Creación de imagen personalizada con `Dockerfile` exponiendo el puerto del servidor.
* [cite_start]**Nivel Intermedio (Optimización):** Uso de imagen base `nginx:alpine` para reducir el tamaño de la imagen (~20MB vs ~140MB). [cite: 1]
* **Nivel Intermedio (Seguridad):** El contenedor no corre como `root`. [cite_start]Se ha configurado el usuario `nginx` y se han redirigido los archivos temporales a `/tmp` para permitir la ejecución sin privilegios. [cite: 1]

### 2. Aplicación Simple (Node.js)
Se ha desarrollado una API mínima en Node.js que responde "Hello from container".
* **Nivel Básico:** Dockerización de una app funcional con sus dependencias.
* [cite_start]**Nivel Intermedio (Multistage Build):** Se utiliza una construcción en dos etapas (Etapa 1: Build, Etapa 2: Runtime) para asegurar que la imagen final no contenga herramientas de desarrollo innecesarias, solo los archivos de ejecución. [cite: 2, 3]
* [cite_start]**Nivel Intermedio (Seguridad):** Uso del usuario `node` por defecto para evitar vulnerabilidades de escalada de privilegios. [cite: 3]

---

## Instalación y Verificación

Para facilitar el despliegue, se han creado scripts de automatización en la carpeta `fase2/scripts/`:

1. **[setup.sh](./fase2/scripts/setup.sh):** Instala Docker, construye las imágenes y levanta los contenedores automáticamente.
2. **[verify.sh](./fase2/scripts/verify.sh):** Comprueba el estado de los contenedores y realiza pruebas de conectividad (Curl) en los puertos 3000 y 8080.

### Comandos rápidos:
```bash
chmod +x fase2/scripts/*.sh
./fase2/scripts/setup.sh
./fase2/scripts/verify.sh
