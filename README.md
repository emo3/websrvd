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

### 2. Set up IP Alias and Hostname (macOS/Linux)

Create an IP alias and add hostname to /etc/hosts for your local server:

```bash
# Add IP alias (run once per boot, or add to startup script)
# For macOS:
sudo ifconfig lo0 alias 10.1.1.30
# For Linux:
sudo ip addr add 10.1.1.30/24 dev lo

# Add hostname to /etc/hosts
echo "10.1.1.30 websrv" | sudo tee -a /etc/hosts
```

### 3. Server Setup

Follow these steps in order:

#### 1. **Add IP Alias and Hostname**

```bash
# Add IP alias for the server
sudo ip addr add 10.1.1.30/24 dev lo

# Add hostname to /etc/hosts
echo "10.1.1.30 websrv" | sudo tee -a /etc/hosts
```

#### 2. **Create Docker Network**

```bash
# Create network with specific options
docker network create --driver bridge --subnet=10.1.1.0/24 \
  --opt "com.docker.network.bridge.enable_icc"="true" \
  --opt "com.docker.network.bridge.enable_ip_masquerade"="true" \
  my_network
```

#### 3. **Start the Server**

```bash
# Start the container
docker compose up -d
```

#### 4. **Verify Setup**

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
mkcert -cert-file websrv.pem -key-file websrv-key.pem websrv websrvd-nginx-1 10.1.1.30
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

### Using Terraform (Optional)

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
mkcert -cert-file websrv.pem -key-file websrv-key.pem websrv 10.1.1.30

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
ping -c 1 websrv
docker network inspect my_network
curl -k https://10.1.1.30/
curl -k https://websrv/
```

### Permission Issues

If you encounter permission errors:

```bash
# Check SELinux context
ls -laZ /path/to/mounted/directory

# Fix SELinux context if needed
sudo chcon -Rt httpd_sys_content_t /path/to/mounted/directory
```

### Performance Issues

```bash
# Check nginx worker processes
docker exec websrv ps aux | grep nginx

# Monitor resource usage
docker stats websrv

# Check nginx error logs
docker logs websrv
```

### Container Won't Start

```bash
# Check for port conflicts
sudo netstat -tulpn | grep :443

# Check Docker logs
docker compose logs

# Try manual container start
docker run --rm -it nginx:alpine nginx -t -c /etc/nginx/nginx.conf
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

# Backup current configuration
./backup.sh

# List available backups
./restore.sh
```

## Directory Structure

```text
websrvd/
├── Dockerfile
├── docker-compose.yml
├── nginx.conf
├── main.tf                # Terraform configuration (optional)
├── startup.sh             # Convenience script to start services
├── shutdown.sh            # Convenience script to stop services
├── test-setup.sh          # Script to verify setup
├── test-shutdown.sh       # Script to verify shutdown
├── backup.sh              # Script to backup configuration
├── restore.sh             # Script to restore from backup
├── logrotate.conf         # Log rotation configuration
├── websrv.pem             # Generated by mkcert
├── websrv-key.pem         # Generated by mkcert
├── .env                   # Optional: environment variables
├── .gitignore
├── LICENSE
├── TODO.md                # Development tasks and improvements
└── README.md
```

## Environment Variables

The following environment variables can be set in a `.env` file or passed to docker-compose:

- `WEBSRV_IP`: IP address for the server (default: 10.1.1.30)
- `WEBSRV_PORT`: Port for HTTPS (default: 443)

## Convenience Scripts

This project includes several Bash scripts to simplify setup, testing, and management:

### startup.sh

Automates the startup process:

- Adds the IP alias (10.1.1.30)
- Adds the hostname 'websrv' to /etc/hosts
- Starts the Docker container with `docker compose up -d`
- Runs `test-setup.sh` to verify everything is working

### shutdown.sh

Automates the shutdown process:

- Stops the Docker container with `docker compose down`
- Removes the hostname 'websrv' from /etc/hosts
- Removes the IP alias
- Runs `test-shutdown.sh` to verify cleanup

### test-setup.sh

Comprehensive verification script that checks:

- Docker container status and networking mode
- IP alias configuration
- SELinux compatibility
- HTTPS server response and directory listing

### test-shutdown.sh

Verification script for shutdown that checks:

- Container is stopped
- IP alias is removed
- HTTPS server is no longer responding
- Optional: Docker network cleanup

### backup.sh

Creates a compressed backup of all configuration files, certificates, and environment settings:

- Backs up all config files and scripts
- Includes SSL certificates (if present)
- Creates timestamped archives
- Automatically cleans up old backups (keeps last 5)

### restore.sh

Restores configuration from a backup archive:

- Lists available backups if no argument provided
- Stops services before restore
- Extracts and restores all files
- Requires manual restart after restore

## Performance Tuning

### Nginx Configuration

- **Worker Processes**: Set to `auto` to match CPU cores
- **Rate Limiting**: Configured with different zones for various endpoints
- **Caching**: Static assets cached for 1 year, HTML for 30 days
- **Compression**: Gzip enabled with optimized settings

### Docker Considerations

- **Host Networking**: Used for performance and simplicity
- **Health Checks**: Enhanced to verify both connectivity and content
- **Resource Limits**: Consider adding CPU/memory limits in production

## Log Management

### Log Rotation

Use the provided `logrotate.conf` for automatic log rotation:

```bash
# Install logrotate config (run as root)
sudo cp logrotate.conf /etc/logrotate.d/websrvd

# Test rotation
sudo logrotate -f /etc/logrotate.d/websrvd
```

### Log Locations

- **Access Logs**: `/var/log/nginx/access.log`
- **Error Logs**: `/var/log/nginx/error.log`
- **Docker Logs**: `docker logs websrv`

## Production Deployment

For production use, consider these modifications:

### SSL Certificates

Replace mkcert certificates with production certificates:

```bash
# Example with Let's Encrypt
certbot certonly --webroot -w /usr/share/nginx/html -d yourdomain.com

# Copy certificates to project directory
cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem websrv.pem
cp /etc/letsencrypt/live/yourdomain.com/privkey.pem websrv-key.pem
```

### Security Hardening

- Remove host networking and use bridge networking
- Add resource limits to docker-compose.yml
- Implement proper firewall rules
- Use secrets management for certificates
- Enable nginx stub_status for monitoring

### Monitoring

- Set up log aggregation (ELK stack, etc.)
- Configure monitoring alerts
- Add metrics collection

## Security Notes

- This setup works with SELinux in enforcing mode
- SSL certificates are only trusted on the machine where mkcert was installed
- Setup is for **local development only** - do not use in production without modifications
- The `server_tokens off` directive in nginx.conf hides version information
- Rate limiting is configured to prevent abuse
- Host networking is used for simplicity, but provides less container isolation
- Non-root user is used in the container for better security
- Security headers are configured to prevent common attacks
