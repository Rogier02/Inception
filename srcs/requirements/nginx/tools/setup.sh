#!/bin/sh
set -e

# Generate self-signed TLS certificate if not already present
if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out  /etc/nginx/ssl/nginx.crt \
        -subj "/C=NL/ST=Noord-Holland/L=Amsterdam/O=42/CN=${DOMAIN_NAME}"
fi

# Write nginx config — $DOMAIN_NAME is expanded by the shell;
# nginx variables ($uri etc.) are kept literal via backslash-escaping.
cat > /etc/nginx/http.d/default.conf << NGINX_CONF
server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name ${DOMAIN_NAME};

    ssl_certificate     /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_session_timeout 10m;
    ssl_session_cache   shared:SSL:10m;

    root  /var/www/wordpress;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass            wordpress:9000;
        fastcgi_index           index.php;
        include                 fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO       \$fastcgi_path_info;
    }

    location ~ /\.ht {
        deny all;
    }
}
NGINX_CONF

exec nginx -g "daemon off;"
