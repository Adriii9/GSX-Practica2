variable "docker_username" {
  description = "Usuario de Docker Hub"
  type        = string
  default     = "adriii9"
}

variable "image_tag" {
  description = "Tag de la imagen que se desplegará (por defecto v1, pero s'actualizará al SHA de Git)"
  type        = string
  default     = "v1"
}

variable "replicas_backend" {
  description = "Número de replicas pel backend"
  type        = number
  default     = 2
}
