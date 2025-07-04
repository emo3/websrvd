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

resource "docker_image" "websrvd" {
  name = "websrvd:latest"
  build {
    context    = "."
    dockerfile = "Dockerfile"
  }
}

resource "docker_container" "nginx_server" {
  image = docker_image.websrvd.name
  name  = "nginx_server"

  ports {
    internal = 443
    external = 443
  }

  restart = "always"
}
