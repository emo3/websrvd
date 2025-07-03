# Running a Local HTTPS Server with Docker

This guide will help you set up a local HTTPS server using Docker with Nginx
and self-signed SSL certificates. The main reason for using docker is the space
taken up by servers and how long it takes to build/rebuild the servers.

## Prerequisite: Install mkcert

To generate trusted local SSL certificates, install [mkcert](https://github.com/FiloSottile/mkcert):

```sh
# macOS (using Homebrew)
brew install mkcert
brew install nss # if you use Firefox

# Linux (using Homebrew or package manager)
brew install mkcert
# or follow instructions at https://github.com/FiloSottile/mkcert

# Windows
choco install mkcert
```

## Create a Directory for Your Project

Create a new directory for your project:

```bash
# Do these steps only ONCE!
mkdir websrvd
cd websrvd
mkcert -install
mkcert localhost
```

## Create files

- Dockerfile
- docker-compose.yml
- nginx.conf

## Initial Section

```sh
# download latest nginx:alpine
docker pull nginx:alpine
```

## Build and run with Docker commands

Build Docker commands

```sh
# and use it to create websrvd
docker build -t websrvd .
# run the code in above image
## -d = detach mode; p = port; -v = directories that nginx can serve
docker run -d -p 443:443 --name websrvd -v ${HOME}/repos:/usr/share/nginx/html websrvd
###
## To cleanup
# Stop the container
docker stop websrvd
# Remove the container
docker remove websrvd
# Remove the image, or keep it up to you
docker image rm websrvd
```

## Build and run with Docker compose commands

Build with docker compose. This will download image and run container  
The option -d = detach mode

```sh
docker compose up --build -d`
```

If you make code changes: Stop and remove containers, networks

```sh
docker compose down`
```

Then re-run compose up  

## Using Terraform with Docker

1. **Initialize and apply Terraform:**

    ```sh
    terraform init
    terraform apply
    ```

## Verify

Open your web browser and navigate to <https://localhost>. You should NOT see a warning about the self-signed certificate. Also navigate to other directories listed.

## Volume Mount Paths

When using Docker Compose, volume mount paths must be absolute and OS-specific:

- **macOS/Linux:**

    ```yaml
    volumes:
      - ${HOME}/repos:/usr/share/nginx/html
    ```

    Make sure to include the slash after `${HOME}`.

- **Windows (Git Bash or WSL):**

    ```yaml
    volumes:
      - /c/Users/<YourUsername>/repos:/usr/share/nginx/html
    ```

    Replace `<YourUsername>` with your actual Windows username.

- **Windows (CMD/PowerShell):**

    ```yaml
    volumes:
      - C:\Users\<YourUsername>\repos:/usr/share/nginx/html
    ```

**Note:**  
The path before the colon is the path on your host machine; the path after the colon is inside the container.
