ARG PHP_VERSION=8.1

FROM webdevops/php-apache:${PHP_VERSION}

# ==========================================================

ENV WEB_DOCUMENT_ROOT="/var/www/omeka-s"

# ==========================================================

# Install dependencies

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -qq update && \
    apt-get -qq -f --no-install-recommends install \
        wget \
        unzip \
        imagemagick \
        ghostscript \
        ffmpeg \
        libvips \
        dos2unix \
        libxml2 libxml2-dev libcurl4-openssl-dev libmagickwand-dev \
        git && \
        pecl install solr && \
    apt-get clean && \
    apt-get autoclean

# Configure apache

RUN a2dismod -f autoindex

# Override default PHP configuration
COPY ./config/prod/php-defaults.ini /opt/docker/etc/php/php.ini

# Override default ImageMagick policy
COPY ./config/imagemagick-policy.xml /etc/ImageMagick-6/policy.xml

# Add Omeka-S cli tool
RUN git clone https://github.com/GhentCDH/Omeka-S-Cli.git /opt/omeka-s-cli && \
    composer install --working-dir=/opt/omeka-s-cli && \
    ln -s /opt/omeka-s-cli/bin/omeka-s-cli /usr/local/bin/omeka-s-cli

# ==========================================================

ARG OMEKA_S_VERSION="4.0.4"

# Download Omeka-S release
# user "application" created by webdevops/php-apache
RUN wget --no-verbose "https://github.com/omeka/omeka-s/releases/download/v${OMEKA_S_VERSION}/omeka-s-${OMEKA_S_VERSION}.zip" -O /var/www/omeka-s.zip && \
    unzip -q /var/www/omeka-s.zip -d /var/www/ && \
    rm /var/www/omeka-s.zip && \
    chown -R application:application /var/www/omeka-s/logs /var/www/omeka-s/files

# Set default configuration
COPY ./config/prod/.htaccess /var/www/omeka-s/
COPY ./config/prod/local.config.php /var/www/omeka-s/config/

# Add boot script to generate /var/www/omeka-s/config/database.ini based on ENV
# see: https://github.com/just-containers/s6-overlay
COPY --chmod=755 ./config/build_omeka_config.sh /entrypoint.d/build_omeka_config.sh

# Convert line endings to Unix (For Windows compatibility)
RUN dos2unix /entrypoint.d/build_omeka_config.sh

