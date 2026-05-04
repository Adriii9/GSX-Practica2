output "nginx_node_port" {
  description = "El puerto por el cual se puede acceder a Nginx desde el navegador"
  value       = kubernetes_service.nginx_service.spec[0].port[0].node_port
}
