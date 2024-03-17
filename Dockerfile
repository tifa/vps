FROM traefik:latest

COPY ./assets/logrotate/ /etc/logrotate.d/

RUN apk add --no-cache \
        logrotate==3.21.0-r1 \
    && rm -rf /var/cache/apk/*
