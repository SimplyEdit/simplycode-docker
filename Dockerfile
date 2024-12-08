FROM node:22.12-alpine AS builder

RUN apk add --no-cache bash git \
    && mkdir /app \
    && git -C /app/ clone 'https://github.com/SimplyEdit/simplycode-electron.git' \
    && git -C /app/ clone 'https://github.com/SimplyEdit/simplyedit-backend.git' \
    && npm --prefix /app/simplycode-electron install

FROM php:7.4-apache

COPY lib/ /var/www/lib/
COPY html/ /var/www/html/
COPY --from=builder /app/simplycode-electron/simplycode/ /var/www/html/simplycode/
COPY --from=builder /app/simplyedit-backend/www/ /var/www/www/

RUN a2enmod --quiet rewrite ssl headers \
    && ln -s /var/www/html/simplycode/js/ /var/www/html/js \
    && ln -s /var/www/www/api/data/generated.html /var/www/html/index.html \
    && ln -s /var/www/www/api/data/generated.html /var/www/html/index.js \
    && mv /var/www/lib/000-default.conf /etc/apache2/sites-available/000-default.conf \
    && mv /var/www/lib/403.php /var/www/html/403.php \
    && mv /var/www/lib/server.key /etc/ssl/private/ssl-cert-snakeoil.key \
    && mv /var/www/lib/server.pem /etc/ssl/certs/ssl-cert-snakeoil.pem \
    && chmod +x /entrypoint.sh \

ENTRYPOINT ["/var/www/lib/entrypoint.sh"]
