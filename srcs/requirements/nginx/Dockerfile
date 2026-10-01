# Penultimate stable Alpine — verify current penultimate at https://alpinelinux.org/releases/
FROM alpine:3.20

RUN apk add --no-cache nginx openssl

RUN mkdir -p /etc/nginx/ssl /var/www/wordpress

COPY tools/setup.sh /setup.sh
RUN chmod +x /setup.sh

EXPOSE 443

ENTRYPOINT ["/setup.sh"]
