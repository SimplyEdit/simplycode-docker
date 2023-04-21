FROM alpine:3.16 as builder

ARG GITLAB_TOKEN
ENV GITLAB_TOKEN="${GITLAB_TOKEN?}"

RUN apk add --no-cache git \
    && git clone 'https://github.com/SimplyEdit/simply-edit-backend.git' /app/simply-edit-backend \
    && git clone "https://token:${GITLAB_TOKEN}@gitlab.muze.nl/muze/simply-code.git" /app/simply-code

FROM php:7.4-apache

COPY --from=builder /app/simply-code/lib /var/www/lib
COPY --from=builder /app/simply-code/www/api/data/generated.html /var/www/html/simplycode/index.html
COPY --from=builder /app/simply-edit-backend /var/www/html/simplycode/simplyedit
