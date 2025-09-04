#!/bin/bash

OSC="omeka-s-cli"

ARGS=("$@")

# Remove entrypoint.d from the arguments if it is the first argument
if [ ${#ARGS} -gt 0 ] && [ "$1" == "/entrypoint.d" ]; then
    unset 'ARGS[0]'
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
    for theme in ${THEME_LIST[@]}; do
        echo "Downloading theme: $theme"
        if [ -z "$theme" ]; then
            continue
        fi
        $OSC theme:download $theme --base-path /var/www/omeka-s
    done
fi
