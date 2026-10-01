#!/bin/sh
set -e

# Read sensitive values from Docker secrets
DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

# Ensure correct ownership of data directory
mkdir -p /run/mysqld /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Only initialise on the very first run (data dir does not yet have mysql system tables)
if [ ! -d "/var/lib/mysql/mysql" ]; then

    mysql_install_db --user=mysql --datadir=/var/lib/mysql --skip-test-db

    # Start mysqld temporarily for bootstrapping (no networking so nothing external can connect)
    mysqld --user=mysql --skip-networking &
    MYSQLD_PID=$!

    # Wait until the server is accepting connections on the local socket
    until mysqladmin -u root --socket=/run/mysqld/mysqld.sock ping --silent 2>/dev/null; do
        sleep 1
    done

    # Create the WordPress database and user
    mysql -u root --socket=/run/mysqld/mysqld.sock << SQL
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
SQL

    # Shut down the bootstrap mysqld cleanly
    kill "$MYSQLD_PID"
    wait "$MYSQLD_PID" 2>/dev/null || true

    echo "MariaDB initialisation complete."
fi

# Replace this shell with mysqld as PID 1 — no daemon, no infinite loop
exec mysqld --user=mysql
