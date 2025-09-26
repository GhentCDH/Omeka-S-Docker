# !/command/with-contenv bash

cd /var/www/omeka-s

# Create Omeka-S database.ini file
# echo "Creating Omeka S database.ini file ..."
omeka-s-cli config:create-db-ini --base-path /var/www/omeka-s \
    --username "${MYSQL_USER:-omeka}" \
    --password "${MYSQL_PASSWORD:-omeka}" \
    --dbname "${MYSQL_DATABASE:-omeka}" \
    --host "${MYSQL_HOST:-db}" \
    --port "${MYSQL_PORT:-3306}"
chmod 644 /var/www/omeka-s/config/database.ini

# Update APPLICATION_ENV in .htaccess
echo "Patch Omeka S .htaccess file ..."
APPLICATION_ENV=${APPLICATION_ENV:-production}
sed -i "s/_APPLICATION_ENV_/$APPLICATION_ENV/" .htaccess