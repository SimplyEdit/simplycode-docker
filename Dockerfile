FROM php:7.4-apache as builder

ARG GITLAB_TOKEN
ENV GITLAB_TOKEN="${GITLAB_TOKEN?}"

RUN apt-get update && apt-get install -y git ssl-cert \
    && git clone 'https://github.com/SimplyEdit/simply-edit-backend.git' /app/simply-edit-backend \
    && git clone "https://token:${GITLAB_TOKEN}@gitlab.muze.nl/muze/simply-code.git" /app/simply-code

FROM php:7.4-apache

COPY --from=builder /app/simply-code/lib /var/www/lib
COPY --from=builder /app/simply-code/www/api/data/generated.html /var/www/html/simplycode/index.html
COPY --from=builder /app/simply-code/www/css /var/www/html/simplycode/css
COPY --from=builder /app/simply-code/www/js /var/www/html/simplycode/js

COPY --from=builder /app/simply-edit-backend /var/www/html/simplycode/simplyedit

COPY --from=builder /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/certs/ssl-cert-snakeoil.pem
COPY --from=builder /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/ssl-cert-snakeoil.key

COPY 000-default.conf /etc/apache2/sites-available/000-default.conf

RUN a2enmod rewrite ssl headers \
    && sed --in-place --expression 's%src="/js/%src="js/%g' /var/www/html/simplycode/index.html
