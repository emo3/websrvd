# Use the official Nginx image
FROM nginx:alpine

# Create a non-root user for better security
RUN addgroup -g 1001 -S nginx && \
    adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx

# Copy the certificate and key to the container
COPY websrv.pem /etc/ssl/certs/websrv.pem
COPY websrv-key.pem /etc/ssl/private/websrv-key.pem

# Copy the Nginx configuration file
COPY nginx.conf /etc/nginx/nginx.conf

# Create log directory and set permissions
RUN mkdir -p /var/log/nginx && \
    chown -R nginx:nginx /var/log/nginx /var/cache/nginx /etc/nginx

# Switch to non-root user
USER nginx

# Expose port 443
EXPOSE 443
