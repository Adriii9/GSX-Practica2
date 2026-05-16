#!/bin/bash

echo "🚀 Iniciando la instalación de Terraform (Week 11 Setup)..."

# 1. Instalar dependencias
echo "⚙️ Instalando dependencias (curl, gnupg, software-properties-common)..."
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl

# 2. Añadir la clave GPG oficial de HashiCorp (CORREGIDO)
echo "🔑 Descargando y añadiendo la clave GPG de HashiCorp..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# 3. Añadir el repositorio oficial
echo "📦 Añadiendo el repositorio de Terraform..."
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

# 4. Actualizar e instalar
echo "⬇️ Descargando e instalando Terraform..."
sudo apt-get update && sudo apt-get install -y terraform

# 5. Verificación
echo "✅ ¡Instalación completada! Verificando la versión:"
terraform -version

echo "🎉 ¡Entorno preparado! Ya puedes ir a tu carpeta fase2/terraform y ejecutar 'terraform init'."
