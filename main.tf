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

resource "docker_container" "nginx" {
  name  = "websrvd"
  image = docker_image.websrvd.name

  ports {
    internal = 443
    external = 443
  }

  volumes {
    host_path      = "${pathexpand("~")}/repos"
    container_path = "/usr/share/nginx/html"
  }
}
