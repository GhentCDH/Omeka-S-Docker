#!/bin/bash

OSC="omeka-s-cli"

ARGS=("$@")

# Remove entrypoint.d from the arguments if it is the first argument (sourced by the entrypoint at boot)
IS_BOOT=0
if [ ${#ARGS} -gt 0 ] && [ "$1" == "/entrypoint.d" ]; then
    IS_BOOT=1
    unset 'ARGS[0]'
fi

# At boot, download as the PHP user when themes can be managed from the admin interface, otherwise as root
# (omeka-s-cli keeps its cache in $HOME/.cache, the PHP user has no writable home folder)
if [ "$IS_BOOT" -eq 1 ] && [ "${OMEKA_S_ALLOW_EASY_ADMIN:-0}" -eq "1" ]; then
    PHP_USER="${CONTAINER_UID:-application}"
    OSC="gosu $PHP_USER:$PHP_USER env HOME=/tmp omeka-s-cli"
fi

# Check if any arguments are passed, if not, use the OMEKA_S_MODULES environment variable
if [ ${#ARGS[@]} -gt 0 ]; then
    THEME_LIST=${ARGS[@]}
else
    THEME_LIST=()
    if [ -n "${OMEKA_S_THEMES:-}" ]; then
        IFS=' ' read -ra THEME_LIST <<< $OMEKA_S_THEMES
    fi
fi

# If no modules are specified, exit
if [ ${#THEME_LIST[@]} -eq 0 ]; then
    echo "No Omeka S themes specified."
else
    # Download Omeka S modules
    echo "Downloading Omeka S themes ..."
    FAILED_THEMES=()
    for theme in ${THEME_LIST[@]}; do
        echo "Downloading theme: $theme"
        if [ -z "$theme" ]; then
            continue
        fi
        $OSC theme:download $theme --base-path /var/www/omeka-s || FAILED_THEMES+=("$theme")
    done

    # Fail the image build if a theme could not be downloaded; at boot, only report it
    if [ ${#FAILED_THEMES[@]} -gt 0 ]; then
        echo "Error: could not download theme(s): ${FAILED_THEMES[*]}" >&2
        [ "$IS_BOOT" -eq 1 ] || exit 1
    fi
fi
