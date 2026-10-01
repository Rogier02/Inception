# Penultimate stable Alpine — verify current penultimate at https://alpinelinux.org/releases/
FROM alpine:3.20

RUN apk add --no-cache mariadb mariadb-client

COPY conf/mariadb.cnf /etc/my.cnf.d/inception.cnf

COPY tools/setup.sh /setup.sh
RUN chmod +x /setup.sh

RUN mkdir -p /run/mysqld /var/lib/mysql && \
    chown -R mysql:mysql /run/mysqld /var/lib/mysql

EXPOSE 3306

ENTRYPOINT ["/setup.sh"]
