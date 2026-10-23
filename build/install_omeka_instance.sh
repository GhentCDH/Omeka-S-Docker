#!/bin/bash
# set -e
# trap 'echo "An# error occurred. Exiting..."; exit 1;' ERR

OSC="omeka-s-cli"

# Wait for database to be available
wait_for_db() {
    echo "Waiting for database to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        # (without a connect timeout, mysql can hang forever on an unreachable host)
        if mysql --connect-timeout=5 -h"${MYSQL_HOST:-db}" -P"${MYSQL_PORT:-3306}" -u"${MYSQL_USER:-omeka}" -p"${MYSQL_PASSWORD:-omeka}" -e "SELECT 1;" >/dev/null 2>&1; then
            echo "Database is ready!"
            return 0
        fi
        echo "Database not ready, attempt $attempt/$max_attempts. Waiting 5 seconds..."
        sleep 5
        attempt=$((attempt + 1))
    done
    
    echo "ERROR: Database failed to become ready after $max_attempts attempts"
    exit 1
}
wait_for_db

# install omeka core?
INSTALL_ARGS=""
if [ "${OMEKA_S_INSTALL_CORE:-0}" -eq "1" ]; then

    # check if core is installed
    if $OSC core:status --base-path /var/www/omeka-s | grep -q "^installed"; then
        echo "Omeka S core is already installed. Skipping installation."
    else
        # install core
        echo "Installing Omeka S core ..."
        $OSC core:install \
            --admin-name "${OMEKA_S_ADMIN_NAME:-admin}" \
            --admin-email "${OMEKA_S_ADMIN_EMAIL:-admin@example.com}" \
            --admin-password "${OMEKA_S_ADMIN_PASSWORD:-admin}" \
            --title "${OMEKA_S_TITLE:-Omeka S}" \
            --time-zone "${OMEKA_S_TIME_ZONE:-UTC}" \
            --locale "${OMEKA_S_LOCALE:-en_US}" \
            --base-path /var/www/omeka-s
    fi
fi

# Module failures are reported, but don't stop the container (this script is sourced by the entrypoint, which runs with errexit)

# upgrade omeka modules? (before install, so new modules are installed against upgraded dependencies)
if [ "${OMEKA_S_UPGRADE_MODULES:-0}" -eq "1" ]; then
    echo "Upgrading Omeka S modules ..."
    $OSC module:upgrade --all --base-path /var/www/omeka-s || echo "Warning: could not upgrade Omeka S modules" >&2
fi

# install omeka modules? (all downloaded modules: added to the image at build time or downloaded at boot)
if [ "${OMEKA_S_INSTALL_MODULES:-0}" -eq "1" ]; then
    echo "Installing Omeka S modules ..."
    $OSC module:install --all --base-path /var/www/omeka-s || echo "Warning: could not install Omeka S modules" >&2
fi

# todo: import resource templates
# todo: import vocabularies
