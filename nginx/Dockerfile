# =============================================================================
# Nginx Reverse Proxy Dockerfile
# =============================================================================
FROM nginx:1.25-alpine

# Add labels
LABEL maintainer="DevOps Team"
LABEL description="Nginx Reverse Proxy for Multi-Service Application"
LABEL version="1.0.0"

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Create non-root user
RUN addgroup -g 1001 -S nginx-group && \
    chown -R nginx:nginx-group /var/cache/nginx && \
    chown -R nginx:nginx-group /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx-group /var/run/nginx.pid

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/nginx-health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]



