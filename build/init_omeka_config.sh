# !/command/with-contenv bash

cd /var/www/omeka-s

# PHP runs as CONTAINER_UID (a name or a number, the group gets the same value)
PHP_USER="${CONTAINER_UID:-application}"

# create_folder <dir> <owner>
# Creates a folder that is missing or empty (e.g. a new volume) with the given owner.
# Mountpoints of nested mounts (e.g. files/original on a network share) don't count as content.
# A folder with content is left alone: its ownership is up to the sysadmin.
create_folder() {
    local dir=$1 owner=$2
    if [ ! -d "$dir" ] || [ -z "$(find "$dir" -mindepth 1 -maxdepth 1 ! -exec mountpoint -q {} \; -print -quit)" ]; then
        install -d -o "$owner" -g "$owner" -m 755 "$dir" \
            || echo "Warning: could not create $dir with owner $owner" >&2
    fi
}

# Create volume folders
# config is not writable by PHP, modules and themes only when they can be managed from the admin interface
ADDONS_OWNER=root
if [ "${OMEKA_S_ALLOW_EASY_ADMIN:-0}" -eq "1" ]; then
    ADDONS_OWNER="$PHP_USER"
fi
create_folder /volume/config root
create_folder /volume/files "$PHP_USER"
create_folder /volume/logs "$PHP_USER"
create_folder /volume/modules "$ADDONS_OWNER"
create_folder /volume/themes "$ADDONS_OWNER"

# Warn when PHP can't write uploads and logs
for dir in /volume/files /volume/logs; do
    if ! gosu "$PHP_USER:$PHP_USER" test -w "$dir"; then
        echo "Warning: $dir is not writable by PHP ($PHP_USER)." >&2
        echo "         Fix it on the host, or run: docker compose exec omeka chown -R $PHP_USER:$PHP_USER $dir" >&2
    fi
done

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
if ! { chown root:"$PHP_USER" /volume/config/database.ini && chmod 640 /volume/config/database.ini; }; then
    echo "Warning: could not restrict access to database.ini, making it readable for everyone" >&2
    chmod 644 /volume/config/database.ini || echo "Warning: could not change permissions of database.ini" >&2
fi

# Update APPLICATION_ENV in .htaccess
echo "Patch Omeka S .htaccess file ..."
APPLICATION_ENV=${APPLICATION_ENV:-production}
sed -i "s/_APPLICATION_ENV_/$APPLICATION_ENV/" .htaccess
