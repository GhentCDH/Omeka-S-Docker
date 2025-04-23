#!/bin/bash

OSC="omeka-s-cli"

if [ -n "${OMEKA_S_THEMES:-}" ]; then
    echo "Downloading Omeka S themes ..."
    IFS=' ' read -ra THEME_LIST <<< "$OMEKA_S_THEMES"
    for theme in "${THEME_LIST[@]}"; do
        $OSC theme:download $theme --base-path /var/www/omeka-s
    done
fi

