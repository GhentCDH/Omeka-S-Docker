ARG PHP_VERSION=8.2

FROM webdevops/php-apache:${PHP_VERSION} AS base

# ==========================================================

ENV WEB_DOCUMENT_ROOT="/var/www/omeka-s"
ENV PHP_DISMOD="pdo_sqlite,tidy,gmp,soap,redis,ioncube,mongodb,opentelemetry,excimer,protobuf,pgsql,ffi,amqp"

ENV PHP_MEMORY_LIMIT="512M"
ENV PHP_POST_MAX_SIZE="220M"
ENV PHP_UPLOAD_MAX_FILESIZE="220M"

ENV php.expose_php="Off"
ENV php.max_input_vars=4000

# Enable opcache
ENV php.opcache.enable=1
ENV php.opcache.memory_consumption=256
ENV php.opcache.interned_strings_buffer=64
ENV php.opcache.max_accelerated_files=50000
ENV php.opcache.max_wasted_percentage=15
ENV php.opcache.save_comments=1
ENV php.opcache.revalidate_freq=2
ENV php.opcache.validate_timestamps=1

# ==========================================================

# Install dependencies
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -qq update && \
    apt-get -qq -f --no-install-recommends install \
        curl \
        unzip \
        nano \
        imagemagick \
        ghostscript \
        ffmpeg \
        libvips-tools \
        libxml2 libxml2-dev libcurl4-openssl-dev libmagickwand-dev \
        git && \
    apt-get clean && \
    apt-get autoclean

# Add extra php dba extension
RUN docker-php-ext-install dba

# Disable apache2 modules
RUN a2dismod -f autoindex

# Override default ImageMagick policy
COPY ./build/imagemagick-policy.xml /etc/ImageMagick-6/policy.xml

# Install Omeka S cli tool
RUN curl -Lo /usr/local/bin/omeka-s-cli https://github.com/GhentCDH/Omeka-S-Cli/releases/latest/download/omeka-s-cli.phar && \
    chmod 755 /usr/local/bin/omeka-s-cli

# ==========================================================
# Download Omeka S
# ==========================================================

ARG OMEKA_S_VERSION="4.1.1"

# Download Omeka S release
# user "application" created by webdevops/php-apache
RUN curl -Lo /var/www/omeka-s.zip "https://github.com/omeka/omeka-s/releases/download/v${OMEKA_S_VERSION}/omeka-s-${OMEKA_S_VERSION}.zip" && \
    unzip -q /var/www/omeka-s.zip -d /var/www/ && \
    rm /var/www/omeka-s.zip && \
    rm -rf /var/www/html

# Create a single volume for config, files, themes, modules and logs
RUN mkdir -p /volume/config && \
    mkdir -p /volume/files && \
    mkdir -p /volume/themes && \
    mkdir -p /volume/modules && \
    mkdir -p /volume/logs

# Add symbolic links to the volume
RUN rm -Rf /var/www/omeka-s/config && \
    ln -s /volume/config /var/www/omeka-s/config && \
    rm -Rf /var/www/omeka-s/files && \
    ln -s /volume/files /var/www/omeka-s/files && \
    rm -Rf /var/www/omeka-s/modules && \
    ln -s /volume/modules /var/www/omeka-s/modules && \
    rm -Rf /var/www/omeka-s/themes && \
    ln -s /volume/themes /var/www/omeka-s/themes && \
    rm -Rf /var/www/omeka-s/logs && \
    ln -s /volume/logs /var/www/omeka-s/logs

# Copy .htaccess
COPY --chmod=755 ./build/prod/.htaccess /var/www/omeka-s/.htaccess

# Copy default configuration
RUN mkdir /dist
COPY --chmod=755 ./build/prod/local.config.php /var/www/omeka-s/config

# Set permissions
RUN chown -R application:application /var/www/omeka-s/logs /var/www/omeka-s/files

# ==========================================================
# Add entrypoint scripts
# ==========================================================

## todo: Bundle modules

## todo: Bundle themes

## Add boot script to generate config (database.ini, local.config.php)
COPY --chmod=755 ./build/init_omeka_config.sh /entrypoint.d/50-init_omeka_config.sh

## Add boot script to automatically download modules
COPY --chmod=755 ./build/download_omeka_modules.sh /entrypoint.d/60-download_omeka_modules.sh

## Add boot script to automatically download themes
COPY --chmod=755 ./build/download_omeka_themes.sh /entrypoint.d/61-download_omeka_themes.sh

## Add boot script to set file & folder permissions
COPY --chmod=755 ./build/set_omeka_permissions.sh /entrypoint.d/70-download_omeka_themes.sh
