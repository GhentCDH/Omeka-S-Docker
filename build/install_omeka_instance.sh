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
        if mysql -h"${MYSQL_HOST:-db}" -P"${MYSQL_PORT:-3306}" -u"${MYSQL_USER:-omeka}" -p"${MYSQL_PASSWORD:-omeka}" -e "SELECT 1;" >/dev/null 2>&1; then
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

# install omeka modules?
if [ "${OMEKA_S_INSTALL_MODULES:-0}" -eq "1" ]; then
    # Get module list
    MODULE_LIST=()
    if [ -n "${OMEKA_S_MODULES:-}" ]; then
        IFS=' ' read -ra MODULE_LIST <<< "$OMEKA_S_MODULES"
    fi
    # If no modules are specified, exit
    if [ ${#MODULE_LIST[@]} -eq 0 ]; then
        echo "No Omeka S modules specified to install."
    else
        # Download Omeka S modules
        echo "Installing Omeka S modules ..."
        for module in ${MODULE_LIST[@]}; do
            echo "Installing module: $module"
            if [ -z "$module" ]; then
                continue
            fi
            $OSC module:install $module --base-path /var/www/omeka-s
        done
    fi
fi

# todo: import resource templates
# todo: import vocabularies
