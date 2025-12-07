# Reverse Proxy Dockerfile - Nginx-based proxy for OwlBoard
# Used for desktop_proxy, mobile_proxy, and load_balancer services
# Provides security, rate limiting, and request routing

FROM nginx:1.25-alpine

# Install required packages for health checks and SSL
RUN apk add --no-cache \
    wget \
    openssl \
    ca-certificates

# Create necessary directories
RUN mkdir -p /var/cache/nginx/proxy_cache \
    && mkdir -p /var/log/nginx \
    && mkdir -p /etc/ssl/certs \
    && mkdir -p /etc/ssl/private

# Set proper permissions
RUN chown -R nginx:nginx /var/cache/nginx \
    && chown -R nginx:nginx /var/log/nginx \
    && chmod 755 /var/cache/nginx \
    && chmod 755 /var/log/nginx

# The nginx.conf will be mounted from host via volume
# Configuration files: desktop_proxy_nginx.conf, mobile_proxy_nginx.conf, load_balancer_nginx.conf

# Expose HTTP and HTTPS ports
EXPOSE 80 443 9000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --retries=3 --start-period=5s \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1/health || exit 1

# Run nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
