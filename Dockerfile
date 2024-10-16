FROM php:7.4-apache as builder

RUN apt-get update && apt-get install -y git ssl-cert \
    && git clone 'https://github.com/SimplyEdit/simplycode.git' /app/simplycode

FROM php:7.4-apache

COPY --from=builder /app/simplycode/lib /var/www/lib
COPY --from=builder /app/simplycode/www/api/.htaccess /var/www/html/api/.htaccess
COPY --from=builder /app/simplycode/www/api/data/generated.html /var/www/html/simplycode/index.html
COPY --from=builder /app/simplycode/www/api/index.php /var/www/html/api/index.php
COPY --from=builder /app/simplycode/www/css /var/www/html/simplycode/css
COPY --from=builder /app/simplycode/www/js /var/www/html/simplycode/js
COPY --from=builder /app/simplycode/www/simply /var/www/html/simplycode/simply

COPY --from=builder /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/certs/ssl-cert-snakeoil.pem
COPY --from=builder /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/ssl-cert-snakeoil.key

COPY 000-default.conf /etc/apache2/sites-available/000-default.conf
COPY entrypoint.sh /entrypoint.sh
COPY 403.php /var/www/html/403.php

RUN a2enmod --quiet rewrite ssl headers \
    && chmod +x /entrypoint.sh \
    && ln -s /var/www/html/simplycode/js/ /var/www/html/js \
    && ln -s /var/www/www/api/data/generated.html /var/www/html/index.html \
    && mkdir /var/www/html/data && echo '{}' > /var/www/html/data/data.json

ENTRYPOINT ["/entrypoint.sh"]
