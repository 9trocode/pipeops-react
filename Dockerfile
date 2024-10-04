# Build stage
FROM node:18 AS builder
WORKDIR /usr/src/app
ENV DEBIAN_FRONTEND=noninteractive
ENV CI=true
COPY . .
RUN npm install --force
RUN npm run build

# Final stage
FROM nginx:1.23.2-alpine
COPY --from=builder /usr/src/app/dist /usr/share/nginx/html
ARG PORT
ENV PORT=$PORT
# Create necessary directories and set up permissions
RUN mkdir -p /etc/nginx/templates && \
    chown -R nginx:nginx /etc/nginx && \
    chmod -R 755 /etc/nginx && \
    chown -R nginx:nginx /var/cache/nginx /var/log/nginx /usr/share/nginx/html && \
    touch /var/run/nginx.pid && \
    chown nginx:nginx /var/run/nginx.pid
RUN /bin/sh -c echo 'server_tokens off; \n\
server { \n\
    listen $PORT; \n\
    server_name localhost; \n\
    location / { \n\
        root /usr/share/nginx/html; \n\
        index index.html index.htm; \n\
        try_files $uri /index.html; \n\
    } \n\
}' > /etc/nginx/templates/default.conf.template
RUN touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid /usr/share/nginx/html /var/cache/nginx /var/log/nginx /etc/nginx/conf.d /etc/nginx/templates
USER nginx
ENV NGINX_ENVSUBST_TEMPLATE_DIR=/etc/nginx/templates
ENV NGINX_ENVSUBST_OUTPUT_DIR=/etc/nginx/conf.d
CMD ["nginx", "-g", "daemon off;"]
