FROM node:22.21-alpine3.21 AS builder

RUN apk add --no-cache bash git \
    && mkdir /app \
    && git -C /app/ clone --depth=1 --branch 'v0.9.8' 'https://github.com/SimplyEdit/simplycode-electron.git' \
    && git -C /app/ clone --depth=1 --branch 'v0.5.2' 'https://github.com/SimplyEdit/simplyedit-backend.git' \
    && npm --prefix /app/simplycode-electron install

FROM php:7.4-apache

COPY lib/ /var/www/lib/
COPY html/ /var/www/html/

COPY --from=builder /app/simplycode-electron/simplycode/ /var/www/html/simplycode/
COPY --from=builder /app/simplyedit-backend/www/ /var/www/www/

RUN echo "ServerName simplycode" >> /etc/apache2/apache2.conf \
    && a2enmod --quiet rewrite ssl headers \
    && chmod +x /var/www/lib/entrypoint.sh

ENTRYPOINT ["/var/www/lib/entrypoint.sh"]
