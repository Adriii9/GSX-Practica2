terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "/home/gsx/.kube/config"
  config_context = "minikube"
}
# CONFIGMAP
resource "kubernetes_config_map" "app_config" {
  metadata {
    name = "app-config"
  }
  data = {
    ENV = "production"
  }
}

# BACKEND DEPLOYMENT
resource "kubernetes_deployment" "backend" {
  metadata {
    name = "backend"
  }
  spec {
    replicas = var.replicas_backend
    selector {
      match_labels = {
        app = "backend"
      }
    }
    template {
      metadata {
        labels = {
          app = "backend"
        }
      }
      spec {
        container {
          name  = "backend"
          image = "${var.docker_username}/simple-app-node:${var.image_tag}"

          port {
            container_port = 3000
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.app_config.metadata[0].name
            }
          }
          resources {
            requests = { memory = "64Mi", cpu = "100m" }
            limits   = { memory = "128Mi", cpu = "250m" }
          }
          liveness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
          readiness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 2
            period_seconds        = 5
          }
        }
      }
    }
  }
}

# BACKEND SERVICE
resource "kubernetes_service" "backend" {
  metadata {
    name = "backend"
  }
  spec {
    selector = {
      app = "backend"
    }
    port {
      port        = 3000
      target_port = 3000
    }
  }
}

# NGINX DEPLOYMENT
resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }
      spec {
        container {
          name  = "nginx"
          image = "${var.docker_username}/nginx-custom:${var.image_tag}"

          port {
            container_port = 8080
          }
          resources {
            requests = { memory = "32Mi", cpu = "50m" }
            limits   = { memory = "64Mi", cpu = "100m" }
          }
          liveness_probe {
            tcp_socket {
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }
  }
}

# NGINX SERVICE
resource "kubernetes_service" "nginx_service" {
  metadata {
    name = "nginx-service"
  }
  spec {
    type = "NodePort"
    selector = {
      app = "nginx"
    }
    port {
      port        = 80
      target_port = 8080
      node_port   = 30080
    }
  }
}
