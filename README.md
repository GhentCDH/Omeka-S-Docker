# Omeka-S-Docker

This repository provides a Docker setup for Omeka S. It is based on [webdevops/php-apache](https://github.com/webdevops/Dockerfile).

## Features

- Configurable Omeka & PHP version
- Configurable list of modules and themes to be added to the build image
- Install automation!
  - Install Omeka S core at boot
  - Install and upgrade modules at boot
- Security rules for Apache (no access to hidden files, configuration, logs, code or direct PHP requests)

The default compose.yaml provides a MariaDB database, PHPMyAdmin, MailPit and Apache Solr.

## Getting Started

To start the container, run:

```sh
docker compose up
```

Once started, you can access the Omeka-S installation at [http://localhost:8080](http://localhost:8080), PHPMyAdmin at [http://localhost:8081](http://localhost:8081) and MailPit at [http://localhost:8025](http://localhost:8025).

## Build Arguments

The following build arguments can be used to customize the Docker image at build time:

| Argument          | Description                                              | Default Value |
| ----------------- | -------------------------------------------------------- | ------------- |
| `PHP_VERSION`     | PHP Version                                              | `8.3`         |
| `OMEKA_S_VERSION` | Version of Omeka S to download and install               | `4.2.1`       |
| `OMEKA_S_MODULES` | List of modules to download during build (examples below) | `""` (empty)  |
| `OMEKA_S_THEMES`  | List of themes to download during build (examples below) | `""` (empty)  |

### Usage

To build the image with custom arguments:

```bash
docker build \
  --build-arg OMEKA_S_VERSION=4.1.0 \
  --build-arg OMEKA_S_MODULES="Common Log EasyAdmin" \
  --build-arg OMEKA_S_THEMES="default Freedom" \
  --target prod \
  -t my-omeka-s:latest .
```

Modules and themes can also be downloaded from (private) git repositories, e.g. `git@github.com:org/Omeka-S-module-Foo.git#v1.0.0`. Use `build_image.sh` to build with SSH agent forwarding. The build fails if a module or theme can't be downloaded.

### Deploying a pre-built image

An image built with `OMEKA_S_MODULES` and `OMEKA_S_THEMES` contains the Omeka S core, modules and themes. On deployment, only mount the `files` and `logs` folders:

```yaml
services:
  omeka:
    image: my-omeka-s:latest
    volumes:
      - ./files:/volume/files
      - ./logs:/volume/logs
```

- `local.config.php` and `database.ini` are created in each new container, based on the environment variables.
- Set `OMEKA_S_INSTALL_MODULES=1` to install the modules of the image, and `OMEKA_S_UPGRADE_MODULES=1` to upgrade them when a new image ships a newer version.
- Don't repeat the build-time module list in the runtime `OMEKA_S_MODULES` variable: modules from git repositories would be cloned at every boot, and private repositories need SSH keys.

## Configuration

First, copy the `example.env` file to `.env` and update the values as needed.

### Omeka S

| Variable                   | Description                                                        | Default      |
| -------------------------- | ------------------------------------------------------------------ | ------------ |
| `MYSQL_DATABASE`           | Database name                                                      | `omeka`      |
| `MYSQL_USER`               | Database user                                                      | `omeka`      |
| `MYSQL_PASSWORD`           | Database password                                                  | `omeka`      |
| `MYSQL_HOST`               | Database host                                                      | `db`         |
| `MYSQL_PORT`               | Database port                                                      | `3306`       |
| `SMTP_HOST`                | SMTP host                                                          | `mailpit`    |
| `SMTP_PORT`                | 25, 465 for 'ssl', and 587 for 'tls'                               | `8025`       |
| `SMTP_CONNECTION_TYPE`     | 'null', 'ssl' or 'tls'                                             | `null`       |
| `SMTP_USER`                |                                                                    | `""` (empty) |
| `SMTP_PASSWORD`            |                                                                    | `""` (empty) |
| `OMEKA_S_ALLOW_EASY_ADMIN` | Set value to 1 to allow EasyAdmin module to install themes/modules | `0`          |

The `database.ini` config file is automatically generated at startup based on these values.

### Automated installation

| Variable                  | Description                                             | Default             |
| ------------------------- | ------------------------------------------------------- | ------------------- |
| `OMEKA_S_MODULES`         | A list of Omeka S modules/urls to download at boot time | `""` (empty)        |
| `OMEKA_S_THEMES`          | A list of Omeka S themes/urls to download at boot time  | `""` (empty)        |
| `OMEKA_S_INSTALL_CORE`    | Install Omeka S core at boot time                       | `0`                 |
| `OMEKA_S_INSTALL_MODULES` | Install all downloaded modules at boot time (added to the image or downloaded at boot) | `0` |
| `OMEKA_S_UPGRADE_MODULES` | Upgrade modules that need an upgrade at boot time       | `0`                 |
| `OMEKA_S_TITLE`           | Title for the Omeka S installation                      | `Omeka S`           |
| `OMEKA_S_TIME_ZONE`       | Time zone for the installation                          | `UTC`               |
| `OMEKA_S_LOCALE`          | Locale/language for the installation                    | `en_US`             |
| `OMEKA_S_ADMIN_NAME`      | Administrator name                                      | `admin`             |
| `OMEKA_S_ADMIN_EMAIL`     | Administrator email address                             | `admin@example.com` |
| `OMEKA_S_ADMIN_PASSWORD`  | Administrator password                                  | `admin`             |

### Containers

| Variable                  | Description             | Default |
| ------------------------- | ----------------------- | ------- |
| `MARIADB_VERSION`         | MariaDB Version         | `11.4`  |
| `MYSQL_ROOT_PASSWORD`     | Database root password  |         |
| `SOLR_VERSION`            | Apache Solr Version     | `9`     |
| `MAILPIT_EXPOSED_PORT`    | MailPit exposed port    | `8025`  |
| `OMEKA_S_EXPOSED_PORT`    | Omeka S exposted port   | `8080`  |
| `PHPMYADMIN_EXPOSED_PORT` | PhpMyAdmin exposed port | `8081`  |

## Automated installation

### Download Modules at Startup

You can automatically download modules at startup by setting the OMEKA_S_MODULES environment variable. This should contain one or more:

- module identifiers (dirnames) as found in https://omeka.org/add-ons/json/s_module.json. You specify a specific version with the syntax `module:version`.
- urls pointing to ZIP releases of valid Omeka S modules.

The modules will be downloaded to the `modules` directory. Existing modules will not be overwritten. A module that can't be downloaded is reported, but doesn't stop the container.

To install the downloaded modules, set `OMEKA_S_INSTALL_MODULES=1`.

#### Example

In your .env file:

```
OMEKA_S_MODULES="Common Log EasyAdmin:3.4.38"
```

In your compose.override.yaml file:

```
services:
  omeka:
    environment:
      OMEKA_S_MODULES: |
        Common
        Log
        EasyAdmin:3.4.38
```

### Download Themes at Startup

You can automatically download themes at container startup by setting the OMEKA_S_THEMES environment variable. This should contain one or more:

- theme identifiers (dirnames) as found in https://omeka.org/add-ons/json/s_theme.json. You specify a specific version with the syntax `theme:version`.
- urls pointing to ZIP releases of valid Omeka S themes.

The themes will be downloaded to the `themes` directory. Existing themes will not be overwritten.

#### Example

In your .env file:

```
OMEKA_S_THEMES="default Freedom:1.0.6"
```

In your compose.override.yaml file:

```
services:
  omeka:
    environment:
      OMEKA_S_THEMES: |
        default
        Freedom:1.0.6
```

## Security

The image adds Apache rules (`/opt/docker/etc/httpd/conf.d/20-omeka-security.conf`) that deny access (403) to:

- hidden files and folders, such as `.git` (except `.well-known`)
- the `config` and `logs` folders, `vendor` and `application` (except `application/asset`)
- documentation and package files: `README`, `LICENSE`, `*.md`, `composer.json`, `package.json`, ...
- PHP files, except `/index.php` (also in uploaded files)

At boot, the ownership and permissions of the files in `/volume` are checked, and fixed if needed.

## Credits

Development by [Ghent Centre for Digital Humanities - Ghent University](https://www.ghentcdh.ugent.be/). Funded by the [GhentCDH research projects](https://www.ghentcdh.ugent.be/projects).

<img src="https://www.ghentcdh.ugent.be/ghentcdh_logo_blue_text_transparent_bg_landscape.svg" alt="Landscape" width="500">
