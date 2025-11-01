# Use the official Nginx image
FROM nginx:alpine

# Copy the certificate and key to the container
COPY websrv.pem /etc/ssl/certs/websrv.pem
COPY websrv-key.pem /etc/ssl/private/websrv-key.pem

# Copy the Nginx configuration file
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 443
EXPOSE 443
