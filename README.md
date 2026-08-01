# Running a Local HTTPS Server with Docker

This guide will help you set up a local HTTPS server using Docker with Chainguard Nginx and mkcert self-signed SSL certificates. The main reason for using Docker is the space taken up by servers and how long it takes to build/rebuild the servers.

## Prerequisites

### Install mkcert (AlmaLinux 9)

Install the NSS tools used by `mkcert`, then install the upstream Linux binary. Homebrew is not required.

```bash
sudo dnf install -y nss-tools curl

# AlmaLinux 9 on x86_64
curl -JLO 'https://dl.filippo.io/mkcert/latest?for=linux/amd64'
chmod +x mkcert-v*-linux-amd64
sudo install -m 0755 mkcert-v*-linux-amd64 /usr/local/bin/mkcert
mkcert -version
```

For ARM64 AlmaLinux, replace `amd64` with `arm64` in the URL and file name.

### Set up the IP Address (Linux)

Assign the address that Docker Compose publishes to the Linux loopback interface:

```bash
# This is temporary and must be repeated after reboot.
sudo ip address add 10.1.1.30/32 dev lo

# Confirm the address is present.
ip -brief address show dev lo
```

If the command reports `RTNETLINK answers: File exists`, the address is already configured.

To make the `websrv` name resolve locally, add it to `/etc/hosts` once:

```text
10.1.1.30 websrv
```

To remove the temporary address:

```bash
sudo ip address delete 10.1.1.30/32 dev lo
```

## Initial Setup (Run Once)

### Create Project Directory

```bash
mkdir websrvd
cd websrvd
```

### Generate SSL Certificates

```bash
# Install mkcert root CA
mkcert -install

# Generate certificates for your domains
mkcert -cert-file websrv.pem -key-file websrv-key.pem websrv 10.1.1.30 localhost 127.0.0.1 ::1

# Keep the private key out of source control and restrict its permissions.
chmod 0640 websrv-key.pem
```

**Important:** Generate `websrv.pem` and `websrv-key.pem` before building the image. These are the exact filenames copied by the `Dockerfile`.

### Download Base Image (Optional)

```bash
docker pull cgr.dev/chainguard/nginx:latest
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
# Use different host/IP
WEBSRV_HOST=10.1.1.50 docker compose up -d

# Or set permanently
export WEBSRV_HOST=10.1.1.50
docker compose up -d
```

### Using .env File

Create a `.env` file for persistent configuration:

```bash
printf '%s\n' 'WEBSRV_HOST=10.1.1.30' 'WEBSRV_PORT=8443' > .env
```

## Running the Server

### Docker Compose (Recommended)

```bash
# Build and start the server
docker compose up -d

# With custom IP
WEBSRV_HOST=10.1.1.31 docker compose up  -d

# With custom IP and port
WEBSRV_HOST=10.1.1.31 WEBSRV_PORT=8443 docker compose up  -d

# Stop the server
docker compose down
```

### Manual Docker Commands

```bash
# Build the image
docker build -t websrvd .

# Run the container
docker run -d -p 10.1.1.30:443:443 --name websrvd \
  -v "${HOME}/repos:/usr/share/nginx/html" websrvd

# Stop and cleanup
docker stop websrvd
docker rm websrvd
docker rmi websrvd  # Optional: remove image
```

## Using with Terraform

- Initialize and apply Terraform:

    ```bash
    # Reconfigure backend, ignoring any saved configuration
    terraform init -reconfigure
    
    # Validate terraform files
    terraform validate
    
    # Format files (optional)
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

### SSL Certificate Issues

```bash
# Regenerate certificates if needed
mkcert -cert-file websrv.pem -key-file websrv-key.pem websrv 10.1.1.30 localhost 127.0.0.1 ::1

# Reinstall mkcert CA
mkcert -uninstall
mkcert -install
```

### Network Connectivity Issues

```bash
# Test IP alias
ping -c 1 10.1.1.30

# Check the published port
docker compose ps

# Test container connectivity
# If you installed mkcert and added the certificate to your system trust, use:
curl https://10.1.1.30/
# Otherwise (skip cert validation):
curl -k https://10.1.1.30/
# Test a served path:
curl -k https://10.1.1.30/media/
docker compose logs nginx
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

# Check the Linux loopback address
ip address show dev lo

# Run network test script
./test-setup.sh
```

## Directory Structure

```text
websrvd/
├── .git/
├── Dockerfile
├── docker-compose.yml
├── nginx.conf
├── main.tf
├── websrv.pem             # Generated by mkcert (for container)
├── websrv-key.pem         # Generated by mkcert (for container)
├── test-setup.sh
└── README.md
```

## Security Notes

- SSL certificates are only trusted on the machine where mkcert was installed
- This setup is for **local development only** - do not use in production
- The `server_tokens off` directive in nginx.conf hides version information
- Rate limiting is configured to prevent abuse

## AlmaLinux 9 Notes

- The default Compose bind address, `10.1.1.30`, must exist on the host. Add it to `lo` as shown above or set `WEBSRV_HOST` to a real address assigned to the machine.
- To expose the server to other machines, bind to the AlmaLinux host's LAN address and regenerate the certificate with that address as a SAN. Binding to `0.0.0.0` publishes on every interface, but `0.0.0.0` is not a browser address and should not be added to the certificate.
- If remote clients cannot connect, check the AlmaLinux firewall. Only open HTTPS when remote access is intended:

  ```bash
  sudo firewall-cmd --permanent --add-service=https
  sudo firewall-cmd --reload
  ```

- A client trusts the certificate only after the mkcert root CA has been installed on that client. Never copy or share `rootCA-key.pem`.
- If Docker reports `cannot assign requested address`, verify the configured bind address with `ip address`.
- If port 443 is already occupied, identify the listener with `sudo ss -ltnp 'sport = :443'`, or set a different `WEBSRV_PORT`.
