# Running a Local HTTPS Server with Docker

This guide will help you set up a local HTTPS server using Docker with Chainguard Nginx and mkcert self-signed SSL certificates. The main reason for using Docker is the space taken up by servers and how long it takes to build/rebuild the servers.

## Prerequisites

### 1. Install mkcert

To generate trusted local SSL certificates, install [mkcert](https://github.com/FiloSottile/mkcert):

```bash
# macOS (using Homebrew)
brew install mkcert
brew install nss # if you use Firefox

# Linux (using Homebrew or package manager)
brew install mkcert
# or follow instructions at https://github.com/FiloSottile/mkcert
```

### 2. Set up IP Alias (macOS/Linux)

Create an IP alias for your local server:

```bash
# Add IP alias (run once per boot, or add to startup script)
sudo ifconfig lo0 alias 10.1.1.30
```

### 3. Create Docker Network

Create a shared Docker network (run once):

```bash
docker network create --driver bridge --subnet=10.1.1.0/24 my_network
```

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

**Important:** You must generate the SSL certificates before building the Docker image.

### 4. Download Base Image (Optional)

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
echo \"WEBSRV_HOST=10.1.1.30\" > .env
echo \"WEBSRV_PORT=443\" >> .env
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
  -v ${HOME}/repos:/usr/share/nginx/html websrvd

# Stop and cleanup
docker stop websrvd
docker rm websrvd
docker rmi websrvd  # Optional: remove image
```

## Using with Terraform

1. **Initialize and apply Terraform:**

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
mkcert -cert-file localhost.pem -key-file localhost-key.pem websrv 10.1.1.30 localhost websrv.net websrv.lan

# Reinstall mkcert CA
mkcert -uninstall
mkcert -install
```

### Network Connectivity Issues

```bash
# Test IP alias
ping -c 1 10.1.1.30

# Check Docker network
docker network inspect local_network

# Test container connectivity
# If you installed mkcert and added the certificate to your system trust, use:
curl https://10.1.1.30/
# Otherwise (skip cert validation):
curl -k https://10.1.1.30/
# Test (localhost:8443 timeouts normal on Docker Desktop):
curl -k https://10.1.1.30/media/
docker compose logs nginx
# Health unhealthy OK - minimal image lacks curl for healthcheck.
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
ifconfig lo0 | grep \"inet 10.1.1\"

# Run network test script
./test-setup.sh
```

## Directory Structure

```text
websrvd/
├── .git/
├── Dockerfile
├── Dockerfile.cg
├── Dockerfile.old
├── docker-compose.yml
├── nginx.conf
├── websrv.pem             # Generated by mkcert (for container)
├── websrv-key.pem         # Generated by mkcert (for container)
├── test-setup.sh
├── README.md
└── (Terraform files: main.tf, .terraform/, terraform.tfstate*)
```

## Security Notes

- SSL certificates are only trusted on the machine where mkcert was installed
- This setup is for **local development only** - do not use in production
- The `server_tokens off` directive in nginx.conf hides version information
- Rate limiting is configured to prevent abuse

## macOS / Chainguard Notes

- Base image: this project now uses the Chainguard stable nginx image (`cgr.dev/chainguard/nginx:latest`) built so the nginx process can run as a non-root user.

- Certificates and permissions **(fix for connection refused):**

  ```bash
  docker stop websrv && docker rm websrv || true
  chmod 0644 websrv.pem
  chmod 0640 websrv-key.pem
  docker compose build --no-cache
  WEBSRV_HOST=127.0.0.1 WEBSRV_PORT=8443 docker compose up -d
  ```

  Rebuild required for non-root nginx to read key/certs. Direct localhost:8443 binding + PF for macOS.

- Binding to 10.1.1.30 on macOS: Docker Desktop on macOS may not allow directly binding containers to a host alias. The recommended approach used here is to run the container bound to `127.0.0.1:8443` and use a kernel redirect (PF) to forward `10.1.1.30:443` → `127.0.0.1:8443`.

  Quick PF commands (temporary):

  ```bash
  # add loopback alias (one-time per boot)
  sudo ifconfig lo0 alias 10.1.1.30

  # temporary in-memory redirect
  echo 'rdr pass on lo0 inet proto tcp from any to 10.1.1.30 port 443 -> 127.0.0.1 port 8443' | sudo pfctl -f -
  sudo pfctl -E
  ```

  Persistent PF anchor (recommended): create `/etc/pf.anchors/websrvd` with the single `rdr` line, back up `/etc/pf.conf`, then append an anchor/include and reload PF:

  ```bash
  # create anchor
  sudo tee /etc/pf.anchors/websrvd > /dev/null <<'PF'
  rdr pass on lo0 inet proto tcp from any to 10.1.1.30 port 443 -> 127.0.0.1 port 8443
  PF

  # backup and include anchor
  sudo cp /etc/pf.conf /etc/pf.conf.websrvd.bak
  printf "\nanchor \"websrvd\"\nload anchor \"websrvd\" from \"/etc/pf.anchors/websrvd\"\n" | sudo tee -a /etc/pf.conf

  # reload
  sudo pfctl -f /etc/pf.conf
  sudo pfctl -E
  ```

- Running the compose stack with the HOST/PORT override used in this repo:

  ```bash
  # build and run bound to localhost:8443
  WEBSRV_HOST=127.0.0.1 WEBSRV_PORT=8443 docker compose up -d --build
  ```

- Revert anchor and PF changes (if needed):

  ```bash
  # remove anchor and reload
  sudo sed -i.bak '/anchor \"websrvd\"/ ,+2d' /etc/pf.conf
  sudo pfctl -f /etc/pf.conf
  sudo pfctl -a websrvd -F all
  ```

- Total Clean Up of Docker Resources (if needed):

  ```bash
  # Remove containers, images, volumes, and build cache
  docker system prune -a --volumes -f
  # Remove build cache history
  docker buildx history rm --all
  ```

## AlmaLinux 9 (Linux) notes

This section is specifically for AlmaLinux 9 (or other Linux hosts). Keep in mind:

- The macOS-only pieces in this README (`lo0`, `ifconfig ...`, `pfctl rdr ...`) are **not** applicable on AlmaLinux.
- If you want to use `10.1.1.30` as a “local development IP”, you can either:
  1) bind Docker to your *real* host IP (recommended), or
  2) add `10.1.1.30/32` as a loopback alias on the host, and bind Docker to that IP.
- Whatever IP/hostname you type in your browser must be present in the mkcert SANs.

### Option A (recommended): bind to the real host IP (no loopback alias)

1) Generate certs that include your **real host IP** (example shown as `ALMA9_IP`) and any hostname you use.

```bash
mkcert -install
mkcert -cert-file websrv.pem -key-file websrv-key.pem \
  websrv \
  ALMA9_IP \
  localhost
```

2) Run compose binding to your actual host IP:

```bash
WEBSRV_HOST=ALMA9_IP WEBSRV_PORT=443 docker compose up -d --build
```

3) Verify from the Alma9 host.

If you have curl:

```bash
curl -k https://ALMA9_IP/ || true
```

If you don’t, you can still test TLS reachability by checking the listener:

```bash
ss -ltnp | grep -E ':443\b' || true
```

### Option B: add `10.1.1.30/32` to loopback and bind to it

This is useful if you want the same `10.1.1.30` URL style as in the macOS instructions.

1) Add alias (run once):

```bash
sudo ip addr add 10.1.1.30/32 dev lo || true
```

2) Remove alias (cleanup):

```bash
sudo ip addr del 10.1.1.30/32 dev lo || true
```

3) Generate certs including the loopback IP:

```bash
mkcert -install
mkcert -cert-file websrv.pem -key-file websrv-key.pem \
  websrv \
  10.1.1.30 \
  localhost
```

4) Bind Docker to `10.1.1.30`:

```bash
WEBSRV_HOST=10.1.1.30 WEBSRV_PORT=443 docker compose up -d --build
```

### If you bind to all interfaces

Alternatively, you can expose the service on all host interfaces:

```bash
WEBSRV_HOST=0.0.0.0 WEBSRV_PORT=443 docker compose up -d --build
```

You can then browse using `https://ALMA9_IP/` from another machine. (Update your mkcert SAN list accordingly.)

### TLS/connection troubleshooting

If you see `connection refused`, confirm the bind:

```bash
docker compose ps
ss -ltnp | grep -E ':443\b' || true
```

If you see certificate errors, confirm the mkcert cert includes the exact IP/hostname you typed.

### AlmaLinux 9 bind error: `cannot assign requested address`

Docker may fail during startup with:

`failed to bind host port 10.1.1.30:443/tcp: cannot assign requested address`

This happens when Compose tries to publish `WEBSRV_HOST=10.1.1.30`, but `10.1.1.30` is **not assigned to any local interface** on your AlmaLinux host.

Fix options:

**Option A (recommended): bind to a real local IP or to all interfaces**

```bash
# publish on all host interfaces
WEBSRV_HOST=0.0.0.0 WEBSRV_PORT=443 docker compose up -d --build

# or publish to your actual host IP
WEBSRV_HOST=<YOUR_ALMA9_IP> WEBSRV_PORT=443 docker compose up -d --build
```

Verify the listener:

```bash
ss -ltnp | grep -E ':443\b' || true
docker compose ps
```

**Option B: add `10.1.1.30/32` to loopback on the host (so Docker can bind it)**

```bash
sudo ip addr add 10.1.1.30/32 dev lo || true

WEBSRV_HOST=10.1.1.30 WEBSRV_PORT=443 docker compose up -d --build
```

To remove later:

```bash
sudo ip addr del 10.1.1.30/32 dev lo || true
```


## macOS / Chainguard Notes

- Base image: this project now uses the Chainguard stable nginx image (`cgr.dev/chainguard/nginx:latest`) built so the nginx process can run as a non-root user.

- Certificates and permissions **(fix for connection refused):**

  ```bash
  docker stop websrv && docker rm websrv || true
  chmod 0644 websrv.pem
  chmod 0640 websrv-key.pem
  docker compose build --no-cache
  WEBSRV_HOST=127.0.0.1 WEBSRV_PORT=8443 docker compose up -d
  ```

  Rebuild required for non-root nginx to read key/certs. Direct localhost:8443 binding + PF for macOS.

- Binding to 10.1.1.30 on macOS: Docker Desktop on macOS may not allow directly binding containers to a host alias. The recommended approach used here is to run the container bound to `127.0.0.1:8443` and use a kernel redirect (PF) to forward `10.1.1.30:443` → `127.0.0.1:8443`.

  Quick PF commands (temporary):

  ```bash
  # add loopback alias (one-time per boot)
  sudo ifconfig lo0 alias 10.1.1.30

  # temporary in-memory redirect
  echo 'rdr pass on lo0 inet proto tcp from any to 10.1.1.30 port 443 -> 127.0.0.1 port 8443' | sudo pfctl -f -
  sudo pfctl -E
  ```

  Persistent PF anchor (recommended): create `/etc/pf.anchors/websrvd` with the single `rdr` line, back up `/etc/pf.conf`, then append an anchor/include and reload PF:

  ```bash
  # create anchor
  sudo tee /etc/pf.anchors/websrvd > /dev/null <<'PF'
  rdr pass on lo0 inet proto tcp from any to 10.1.1.30 port 443 -> 127.0.0.1 port 8443
  PF

  # backup and include anchor
  sudo cp /etc/pf.conf /etc/pf.conf.websrvd.bak
  printf \"\\nanchor \\\"websrvd\\\"\\nload anchor \\\"websrvd\\\" from \\\"/etc/pf.anchors/websrvd\\\"\\n\" | sudo tee -a /etc/pf.conf

  # reload
  sudo pfctl -f /etc/pf.conf
  sudo pfctl -E
  ```

- Running the compose stack with the HOST/PORT override used in this repo:

  ```bash
  # build and run bound to localhost:8443
  WEBSRV_HOST=127.0.0.1 WEBSRV_PORT=8443 docker compose up -d --build
  ```

- Revert anchor and PF changes (if needed):

  ```bash
  # remove anchor and reload
  sudo sed -i.bak '/anchor \"websrvd\"/ ,+2d' /etc/pf.conf
  sudo pfctl -f /etc/pf.conf
  sudo pfctl -a websrvd -F all
  ```

- Total Clean Up of Docker Resources (if needed):

  ```bash
  # Remove containers, images, volumes, and build cache
  docker system prune -a --volumes -f
  # Remove build cache history
  docker buildx history rm --all
  ```

## Post-Docker Reset Quick Fix

After Docker reset (containers/networks gone), run this sequence in `websrvd/`:

```bash
docker compose down
docker stop websrv || true; docker rm websrv || true
brew install mkcert nss || true
mkcert -install
ls -la *.pem || mkcert -cert-file websrv.pem -key-file websrv-key.pem 10.1.1.30 localhost websrv
chmod 644 websrv.pem; chmod 640 websrv-key.pem
sudo ifconfig lo0 alias 10.1.1.30/32
docker network create --driver bridge --subnet=10.1.1.0/24 local_network || true
WEBSRV_HOST=127.0.0.1 WEBSRV_PORT=8443 docker compose up -d --build
echo 'rdr pass on lo0 inet proto tcp from any to 10.1.1.30 port 443 -> 127.0.0.1 port 8443' | sudo pfctl -Ef -
sudo pfctl -E
```

Test: `open https://10.1.1.30/alma9`
