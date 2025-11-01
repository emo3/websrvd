# Running a Local HTTPS Server with Docker

This guide helps you set up a local HTTPS server using Docker with Nginx and self-signed SSL certificates. The server uses host networking mode for reliable connectivity and works with SELinux enabled.

## Quick Start

1. Add IP alias: `sudo ip addr add 10.1.1.30/24 dev lo`
2. Create network: `docker network create --driver bridge --subnet=10.1.1.0/24 my_network`
3. Start server: `docker compose up -d`
4. Verify setup: `./test-setup.sh`

## Prerequisites

### 1. Install Required Tools

To generate trusted local SSL certificates, install [mkcert](https://github.com/FiloSottile/mkcert):

```bash
# macOS (using Homebrew)
brew install mkcert
brew install nss # if you use Firefox

# Linux (using Homebrew or package manager)
brew install mkcert
# or follow instructions at https://github.com/FiloSottile/mkcert

# Setup Docker permissions (Linux only)
sudo usermod -aG docker $USER
# Log out and log back in for the changes to take effect

# Windows
choco install mkcert
```

### 2. Set up IP Alias (macOS/Linux)

Create an IP alias for your local server:

```bash
# Add IP alias (run once per boot, or add to startup script)
# For macOS:
sudo ifconfig lo0 alias 10.1.1.30
# For Linux:
sudo ip addr add 10.1.1.30/24 dev lo
```

### 3. Server Setup

Follow these steps in order:

1. **Add IP Alias**
```bash
# Add IP alias for the server
sudo ip addr add 10.1.1.30/24 dev lo
```

2. **Create Docker Network**
```bash
# Create network with specific options
docker network create --driver bridge --subnet=10.1.1.0/24 \
  --opt "com.docker.network.bridge.enable_icc"="true" \
  --opt "com.docker.network.bridge.enable_ip_masquerade"="true" \
  my_network
```

3. **Start the Server**
```bash
# Start the container
docker compose up -d
```

4. **Verify Setup**
```bash
# Run the test script to verify all components
./test-setup.sh
```

Note: The setup works with SELinux in enforcing mode, no need to disable it.

## Initial Setup (Run Once)

### 1. Create Project Directory

```bash
mkdir websrvd
cd websrvd
```

### 2. Generate SSL Certificates

```bash
# Install mkcert root CA
mkcert -install

# Generate certificates for your domains
mkcert -cert-file localhost.pem -key-file localhost-key.pem websrv websrvd-nginx-1 10.1.1.30 localhost
```

### 3. Create Required Files

Create these files in your project directory:

- `Dockerfile`
- `docker-compose.yml`
- `nginx.conf`

**Important:** You must generate the SSL certificates before building the Docker image.

### 4. Download Base Image (Optional)

```bash
docker pull nginx:alpine
```

## Configuration Options

This project supports flexible IP configuration through environment variables:

### Default Configuration

```bash
# Uses IP 10.1.1.30 (default)
docker compose up -d
```

### Custom IP Address

```bash
# Use different IP address
WEBSRV_IP=10.1.1.50 docker compose up -d

# Or set permanently
export WEBSRV_IP=10.1.1.50
docker compose up -d
```

### Environment Configuration (Optional)

For custom settings, create a `.env` file:

```bash
# Default values shown - modify as needed
echo "WEBSRV_IP=10.1.1.30" > .env
echo "WEBSRV_PORT=443" >> .env
```

Note: The test script assumes default values. If you change these, update the test script accordingly.

## Running the Server

### Docker Compose (Recommended)

```bash
# Build and start the server
docker compose up -d

# With custom IP
WEBSRV_IP=10.1.1.31 docker compose up  -d

# With custom IP and port
WEBSRV_IP=10.1.1.31 WEBSRV_PORT=8443 docker compose up  -d

# Stop the server
docker compose down
```

### Manual Docker Commands

```bash
# Build the image
docker build -t websrvd .

# Run the container
docker run -d -p 10.1.1.30:443:443 --name websrvd \
  -v ${HOME}/repos:/usr/share/nginx/html websrvd

# Stop and cleanup
docker stop websrvd
docker rm websrvd
docker rmi websrvd  # Optional: remove image
```

## Using with Terraform

# Using Terraform (Optional)

If you prefer using Terraform for infrastructure management:

```bash
# Initialize Terraform
terraform init -reconfigure

# Validate and format
terraform validate
terraform fmt -diff -recursive

# Apply configuration
terraform apply -auto-approve

# To remove resources
terraform destroy -auto-approve
```

## Verification

Open your web browser and navigate to:

- `https://websrv/` (using hostname)
- `https://10.1.1.30/` (using IP address)
- `https://localhost/` (local access)

You should **NOT** see SSL certificate warnings thanks to mkcert.

## Volume Mount Paths

Volume mount paths must be absolute and OS-specific:

### macOS/Linux

```yaml
volumes:
  - ${HOME}/repos:/usr/share/nginx/html
```

### Windows (Git Bash/WSL)

```yaml
volumes:
  - /c/Users/<YourUsername>/repos:/usr/share/nginx/html
```

### Windows (CMD/PowerShell)  

```yaml
volumes:
  - C:\Users\<YourUsername>\repos:/usr/share/nginx/html
```

**Note:** The path before the colon is on your host machine; the path after the colon is inside the container.

## Troubleshooting

### Automated Testing

The `test-setup.sh` script verifies:
- SELinux status and compatibility
- IP configuration
- Docker container status
- HTTPS server response
- Directory listing functionality

Run it anytime to check your setup:
```bash
./test-setup.sh
```

### SSL Certificate Issues

If you need to regenerate certificates:
```bash
# Regenerate certificates
mkcert -cert-file localhost.pem -key-file localhost-key.pem websrv 10.1.1.30 localhost

# If needed, reinstall mkcert CA
mkcert -uninstall
mkcert -install
```

### Network Connectivity Issues

```bash
# Run the comprehensive test script
./test-setup.sh

# Manual checks if needed:
ping -c 1 10.1.1.30
docker network inspect my_network
curl -k https://10.1.1.30/
```

### Useful Commands

```bash
# View container logs
docker compose logs

# Follow logs in real-time
docker compose logs -f

# Access container shell
docker compose exec nginx sh

# Check running containers and health status
docker compose ps

# Check network interfaces
# For macOS:
ifconfig lo0 | grep "inet 10.1.1"
# For Linux:
ip addr show dev lo | grep "10.1.1"

# Run network test script
./test-setup.sh
```

## Directory Structure

```text
websrvd/
├── Dockerfile
├── docker-compose.yml
├── nginx.conf
├── localhost.pem          # Generated by mkcert
├── localhost-key.pem      # Generated by mkcert
├── .env                   # Optional: environment variables
└── README.md
```

## Security Notes

- This setup works with SELinux in enforcing mode
- SSL certificates are only trusted on the machine where mkcert was installed
- Setup is for **local development only** - do not use in production
- The `server_tokens off` directive in nginx.conf hides version information
- Rate limiting is configured to prevent abuse
- Host networking is used for simplicity, but provides less container isolation
