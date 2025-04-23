#!/bin/bash

OSC="omeka-s-cli"

if [ -n "${OMEKA_S_MODULES:-}" ]; then
    echo "Downloading Omeka S modules ..."
    IFS=' ' read -ra MODULE_LIST <<< "$OMEKA_S_MODULES"
    for module in "${MODULE_LIST[@]}"; do
        $OSC module:download $module --base-path /var/www/omeka-s
    done
fi
