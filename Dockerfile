# Build stage
FROM node:18 AS builder
WORKDIR /usr/src/app
ENV DEBIAN_FRONTEND=noninteractive
ENV CI=true
COPY . .
RUN npm install --quiet --force
RUN npm run build

# Final stage
FROM nginxinc/nginx-unprivileged:alpine3.20-slim
COPY --from=builder /usr/src/app/dist /usr/share/nginx/html

# Use build argument for PORT
ARG PORT
ENV PORT=$PORT

# Install envsubst
# RUN apk add --no-cache gettext

# Create necessary directories and set up permissions
RUN mkdir -p /etc/nginx/templates && \
    touch /var/run/nginx.pid && \
    chown nginx:nginx /var/run/nginx.pid

# Create Nginx configuration template
RUN echo 'server { listen $PORT default_server; root /usr/share/nginx/html; location / { try_files $uri $uri/ /index.html; } error_page 404 /index.html; include /etc/nginx/mime.types; }' > /etc/nginx/templates/default.conf.template

USER nginx
ENV NGINX_ENVSUBST_TEMPLATE_DIR=/etc/nginx/templates
ENV NGINX_ENVSUBST_OUTPUT_DIR=/etc/nginx/conf.d
CMD ["/bin/sh", "-c", "envsubst '$PORT' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
