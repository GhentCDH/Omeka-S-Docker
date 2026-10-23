# !/command/with-contenv bash

# Check ownership and permissions in /volume and fix only what is wrong.
# Runs last, so it also covers files created by root during module download and installation.
# Apache (www-data) serves files, module and theme assets directly, so they must be readable by everyone.
# PHP-FPM (application) writes uploads, derivatives and logs.
# This script is sourced by the entrypoint, which runs with errexit: every command that can fail is guarded,
# so a failure is reported as a warning but never stops the container.

APP_USER="${APPLICATION_USER:-application}"
APP_GROUP="${APPLICATION_GROUP:-application}"

# fix_perms <description> <command> <path...> <find expression...>
# Runs <command> on every path matched by find. Symbolic links are skipped.
fix_perms() {
    local description=$1 command=$2 count
    shift 2
    count=$(find "$@" ! -type l -print 2>/dev/null | wc -l) || true
    [ "$count" -gt 0 ] || return 0
    echo "Fixing $description ($count) ..."
    if ! find "$@" ! -type l -exec $command {} + ; then
        echo "Warning: could not fix $description, check the permissions of the volume" >&2
    fi
}

echo "Checking permissions in /volume ..."

# Config: owned by root, not writable by PHP (database.ini is handled by 50-init_omeka_config.sh)
fix_perms "owner of config files" "chown root:root" \
    /volume/config /volume/bootstrap.php ! -name database.ini \( ! -user root -o ! -group root \)
fix_perms "permissions of config folder" "chmod 755" \
    /volume/config -type d ! -perm 755
fix_perms "permissions of config files" "chmod 644" \
    /volume/config /volume/bootstrap.php -type f ! -name database.ini ! -perm 644

# Files and logs: written by PHP, readable by everyone, files not executable
fix_perms "owner of files and logs" "chown $APP_USER:$APP_GROUP" \
    /volume/files /volume/logs \( ! -user "$APP_USER" -o ! -group "$APP_GROUP" \)
fix_perms "permissions of files and logs folders" "chmod u+rwx,go+rx" \
    /volume/files /volume/logs -type d ! -perm -755
fix_perms "permissions of files and logs" "chmod u+rw,go+r,a-x" \
    /volume/files /volume/logs -type f \( ! -perm -644 -o -perm /111 \)

# Modules and themes: writable by PHP only when modules and themes can be managed from the admin interface
if [ "${OMEKA_S_ALLOW_EASY_ADMIN:-0}" -eq "1" ]; then
    fix_perms "owner of modules and themes" "chown $APP_USER:$APP_GROUP" \
        /volume/modules /volume/themes \( ! -user "$APP_USER" -o ! -group "$APP_GROUP" \)
    fix_perms "write permissions of modules and themes" "chmod ug+rwX" \
        /volume/modules /volume/themes \( -type d ! -perm -770 -o -type f ! -perm -660 \)
fi
fix_perms "read permissions of modules and themes" "chmod a+rX" \
    /volume/modules /volume/themes \( -type d ! -perm -555 -o -type f ! -perm -444 \)
