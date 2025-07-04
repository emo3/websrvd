# Use the official Nginx image
FROM nginx:alpine

# Copy the certificate and key to the container
COPY localhost.pem /etc/ssl/certs/localhost.pem
COPY localhost-key.pem /etc/ssl/private/localhost-key.pem

# Copy the Nginx configuration file
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 443
EXPOSE 443
