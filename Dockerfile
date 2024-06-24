ARG PHP_VERSION=8.1

FROM shinsenter/phpfpm-apache:php${PHP_VERSION}
ARG PHP_VERSION

# ==========================================================

ENV WEBHOME="/var/www/omeka-s"

# ==========================================================

# Install dependencies

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -qq update \ 
    && apt-get -qq -f --no-install-recommends install \
        wget \
        unzip \
        imagemagick \
        ghostscript \
        ffmpeg \
        libvips \
        git \
    && apt-get clean \
    && apt-get autoclean

# Configure apache

RUN a2dismod -f autoindex

# Configure PHP
# RUN phpdismod pdo_sqlite tidy gmp soap redis 
RUN phpaddmod solr imagick intl iconv pdo pdo_mysql mysqli gd

COPY ./config/prod/php-defaults.ini /etc/php/$PHP_VERSION/fpm/conf.d/99-defaults.ini

# Override default ImageMagick policy
COPY ./config/imagemagick-policy.xml /etc/ImageMagick-6/policy.xml

# ==========================================================

ARG OMEKA_S_VERSION="4.0.4"

# Download Omeka-S release
RUN usermod -u 1000 www-data \
&& wget --no-verbose "https://github.com/omeka/omeka-s/releases/download/v${OMEKA_S_VERSION}/omeka-s-${OMEKA_S_VERSION}.zip" -O /var/www/omeka-s.zip \
&& unzip -q /var/www/omeka-s.zip -d /var/www/ \
&& rm /var/www/omeka-s.zip \
&& chown -R www-data:www-data /var/www/omeka-s/logs /var/www/omeka-s/files

# Set default configuration
COPY ./config/prod/.htaccess /var/www/omeka-s/
COPY ./config/prod/local.config.php /var/www/omeka-s/config/

# Add boot script to generate /var/www/omeka-s/config/database.ini based on ENV
# see: https://github.com/just-containers/s6-overlay
COPY --chmod=755 ./config/build_omeka_config.sh /etc/cont-init.d/300-build_omeka_config