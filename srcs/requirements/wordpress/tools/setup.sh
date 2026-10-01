#!/bin/sh
set -e

WP_PATH=/var/www/wordpress

# Read sensitive values from Docker secrets
DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASS=$(sed -n '1p' /run/secrets/credentials)
WP_USER_PASS=$(sed -n '2p' /run/secrets/credentials)

# Ensure the WordPress directory exists and is writable
mkdir -p "$WP_PATH"
chown -R nobody:nobody "$WP_PATH"

# Only install WordPress on the very first run
if [ ! -f "$WP_PATH/wp-login.php" ]; then

    # Download WordPress core
    wp core download --path="$WP_PATH" --allow-root

    # Create wp-config.php — no passwords hardcoded; reads from env
    wp config create \
        --path="$WP_PATH" \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost=mariadb \
        --allow-root

    # Wait for MariaDB to accept connections
    echo "Waiting for MariaDB..."
    until wp db check --path="$WP_PATH" --allow-root 2>/dev/null; do
        sleep 2
    done
    echo "MariaDB is ready."

    # Install WordPress
    wp core install \
        --path="$WP_PATH" \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASS" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root

    # Create a second (non-admin) user
    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --role=author \
        --user_pass="$WP_USER_PASS" \
        --path="$WP_PATH" \
        --allow-root

    echo "WordPress installation complete."
fi

exec php-fpm82 --nodaemonize
