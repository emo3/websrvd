# Use the official Nginx image
FROM nginx:alpine

# Copy the certificate and key to the container
COPY localhost.pem /etc/ssl/certs/localhost.pem
COPY localhost-key.pem /etc/ssl/private/localhost-key.pem

# Copy the Nginx configuration file
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 443
EXPOSE 443

# Suggestion: If you want to serve custom static content, add a COPY for your web root:
# COPY ./html /usr/share/nginx/html

# Suggestion: Consider setting a non-root user for improved security (optional for simple local use).
# USER nginx

# Suggestion: Add a HEALTHCHECK to monitor container health (optional).
# HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
#   CMD wget --no-verbose --tries=1 --spider https://localhost || exit 1
