# Replace FROM nginx:alpine
FROM cgr.dev/chainguard/nginx:latest

# Chainguard Nginx uses different default paths or user permissions 
# than the official image. Often you don't need to change much, 
# but be aware of the 'nonroot' user.

COPY --chown=nginx:nginx websrv.pem /etc/ssl/certs/websrv.pem
COPY --chown=root:nginx websrv-key.pem /etc/ssl/private/websrv-key.pem

# Copy your config
COPY nginx.conf /etc/nginx/nginx.conf

# Ownership and permissions are set via COPY --chown. Ensure the source
# files on the build host have secure permissions (key 0640, cert 0644).

# IMPORTANT: If your nginx.conf tries to write to /var/cache/nginx 
# or use port 80, you might need to adjust them to 8080 or 
# grant permissions because the container runs as non-root.

EXPOSE 443
