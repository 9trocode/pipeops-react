# Build stage
FROM node:18 AS builder
WORKDIR /usr/src/app
ENV DEBIAN_FRONTEND=noninteractive
ENV CI=true
COPY . .
RUN npm install --force
RUN npm run build

# Final stage
FROM nginx:alpine3.20-slim
COPY --from=builder /usr/src/app/dist /usr/share/nginx/html

# Use build argument for PORT
ARG PORT
ENV PORT=$PORT

# Install envsubst
RUN apk add --no-cache gettext

# Create necessary directories and set up permissions
RUN mkdir -p /etc/nginx/templates && \
    chown -R nginx:nginx /etc/nginx && \
    chmod -R 755 /etc/nginx && \
    chown -R nginx:nginx /var/cache/nginx /var/log/nginx /usr/share/nginx/html && \
    touch /var/run/nginx.pid && \
    chown nginx:nginx /var/run/nginx.pid

RUN /bin/sh -c echo 'server_tokens off; \n\
server { \n\
    listen ${PORT}; \n\
    server_name localhost; \n\
    location / { \n\
        root /usr/share/nginx/html; \n\
        index index.html index.htm; \n\
        try_files $uri /index.html; \n\
    } \n\
}' > /etc/nginx/templates/default.conf.template

USER nginx
ENV NGINX_ENVSUBST_TEMPLATE_DIR=/etc/nginx/templates
ENV NGINX_ENVSUBST_OUTPUT_DIR=/etc/nginx/conf.d
CMD /bin/sh", "-c", "envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
