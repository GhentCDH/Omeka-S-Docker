#!/bin/bash

OSC="omeka-s-cli"

ARGS=("$@")

# Remove entrypoint.d from the arguments if it is the first argument
if [ ${#ARGS} -gt 0 ] && [ "$1" == "/entrypoint.d" ]; then
    unset 'ARGS[0]'
fi

# Check if any arguments are passed, if not, use the OMEKA_S_MODULES environment variable
if [ ${#ARGS[@]} -gt 0 ]; then
    MODULE_LIST=${ARGS[@]}
else
    MODULE_LIST=()
    if [ -n "${OMEKA_S_MODULES:-}" ]; then
        IFS=' ' read -ra MODULE_LIST <<< "$OMEKA_S_MODULES"
    fi
fi

# If no modules are specified, exit
if [ ${#MODULE_LIST[@]} -eq 0 ]; then
    echo "No Omeka S modules specified to download."
else
    # Download Omeka S modules
    echo "Downloading Omeka S modules ..."
    for module in ${MODULE_LIST[@]}; do
        echo "Downloading module: $module"
        if [ -z "$module" ]; then
            continue
        fi
        $OSC module:download $module --base-path /var/www/omeka-s
    done
fi
