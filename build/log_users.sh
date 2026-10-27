# !/command/with-contenv bash

# Log the users PHP and Apache run as.
# PHP-FPM runs as CONTAINER_UID (a name or a number, set by the webdevops entrypoint), Apache as www-data.

PHP_USER="${CONTAINER_UID:-application}"
APACHE_USER=$(sed -n 's/^export APACHE_RUN_USER=//p' /etc/apache2/envvars 2>/dev/null)
APACHE_USER="${APACHE_USER:-www-data}"

echo "PHP runs as $(id "$PHP_USER" 2>/dev/null || echo "$PHP_USER (unknown user)")"
echo "Apache runs as $(id "$APACHE_USER" 2>/dev/null || echo "$APACHE_USER (unknown user)")"
