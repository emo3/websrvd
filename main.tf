terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_image" "nginx" {
  name = "nginx:alpine" # Use the official Nginx image
}

resource "docker_container" "nginx_server" {
  image = docker_image.nginx.name
  name  = "nginx_server"

  ports {
    internal = 443
    external = 443
  }

  volumes {
    host_path      = var.cert_pem_path
    container_path = "/etc/ssl/certs/localhost.pem"
  }

  volumes {
    host_path      = var.cert_key_path
    container_path = "/etc/ssl/private/localhost-key.pem"
  }

  restart = "always"
}
