# Penultimate stable Alpine — verify current penultimate at https://alpinelinux.org/releases/
FROM alpine:3.20

RUN apk add --no-cache \
    php82 \
    php82-fpm \
    php82-mysqli \
    php82-curl \
    php82-dom \
    php82-exif \
    php82-fileinfo \
    php82-gd \
    php82-iconv \
    php82-mbstring \
    php82-openssl \
    php82-phar \
    php82-session \
    php82-simplexml \
    php82-tokenizer \
    php82-xml \
    php82-xmlreader \
    php82-zip \
    php82-ctype \
    php82-zlib \
    curl

# Make 'php' available for WP-CLI
RUN ln -sf /usr/bin/php82 /usr/local/bin/php

# Install WP-CLI (latest stable phar)
RUN curl -Lo /usr/local/bin/wp \
    https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp

# Replace default php-fpm pool config with ours
COPY conf/www.conf /etc/php82/php-fpm.d/www.conf

COPY tools/setup.sh /setup.sh
RUN chmod +x /setup.sh

RUN mkdir -p /var/www/wordpress

EXPOSE 9000

ENTRYPOINT ["/setup.sh"]
