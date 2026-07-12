# Fallback deploy path. The primary path (see README) uses OpenShift's
# httpd source-to-image builder and needs no Dockerfile at all.
FROM nginxinc/nginx-unprivileged:stable-alpine
# nginx-unprivileged already runs as non-root and listens on 8080 —
# which is what OpenShift's random-UID security model requires.
COPY --chown=nginx:nginx . /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 8080
