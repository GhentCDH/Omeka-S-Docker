# !/command/with-contenv bash

# Set folder permissions
echo "Setting permissions for files and logs ..."
chown -R application:application /volume/files
chmod -R 0775 /volume/files
chown -R application:application /volume/logs
chmod -R 0775 /volume/logs

# Set permissions for modules and themes
if [ "${OMEKA_S_ALLOW_EASY_ADMIN:-0}" -eq "1" ]; then
    echo "Setting permissions for modules and themes ..."
    chown -R application:application /volume/modules
    chmod -R 0775 /volume/modules
    chown -R application:application /volume/themes
    chmod -R 0775 /volume/themes
fi
