# !/command/with-contenv bash

cd /var/www/omeka-s

# Create volume folders (missing when an empty host folder is bind-mounted on /volume)
# owned by root, 755; files and logs are handed to the application user by 90-set_omeka_permissions.sh
if ! mkdir -p /volume/config /volume/files /volume/logs /volume/modules /volume/themes; then
    echo "Error: could not create folders in /volume, check that it is writable" >&2
    exit 1
fi

# Check if /var/www/omeka-s/config/local.config.php exists, if not copy the default one
if [ ! -f /volume/config/local.config.php ]; then
    echo "Copying local.config.php to /volume/config folder ..."
    install -m 644 /omeka/build/local.config.php /volume/config/local.config.php || exit 1
fi

# Copy bootstrap.php to volume folder (fixes issues with scripts that require the Omeka bootstrap file)
if [ ! -f /volume/bootstrap.php ]; then
    echo "Copying bootstrap.php to /volume folder ..."
    install -m 644 /omeka/build/bootstrap.php /volume/bootstrap.php || exit 1
fi

# Create Omeka-S database.ini file
# echo "Creating Omeka S database.ini file ..."
omeka-s-cli config:create-db-ini --base-path /var/www/omeka-s \
    --username "${MYSQL_USER:-omeka}" \
    --password "${MYSQL_PASSWORD:-omeka}" \
    --dbname "${MYSQL_DATABASE:-omeka}" \
    --host "${MYSQL_HOST:-db}" \
    --port "${MYSQL_PORT:-3306}"
# database.ini holds the database password: readable by root and the PHP user only
if ! { chown root:"${APPLICATION_GROUP:-application}" /volume/config/database.ini && chmod 640 /volume/config/database.ini; }; then
    echo "Warning: could not restrict access to database.ini, making it readable for everyone" >&2
    chmod 644 /volume/config/database.ini || echo "Warning: could not change permissions of database.ini" >&2
fi

# Update APPLICATION_ENV in .htaccess
echo "Patch Omeka S .htaccess file ..."
APPLICATION_ENV=${APPLICATION_ENV:-production}
sed -i "s/_APPLICATION_ENV_/$APPLICATION_ENV/" .htaccess

