# Omeka-S-Docker

[![Docker Pulls](https://img.shields.io/docker/pulls/ghentcdh/omeka-s-docker)](https://hub.docker.com/r/ghentcdh/omeka-s-docker)
[![Docker Image Size](https://img.shields.io/docker/image-size/ghentcdh/omeka-s-docker/4.2.1-php-8.3)](https://hub.docker.com/r/ghentcdh/omeka-s-docker/tags)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Ready-to-use Docker images for [Omeka S](https://omeka.org/s/), published on Docker Hub as [`ghentcdh/omeka-s-docker`](https://hub.docker.com/r/ghentcdh/omeka-s-docker). You don't have to build anything: pick the Omeka S and PHP version you need, add a database and start the container. The images are based on [webdevops/php-apache](https://github.com/webdevops/Dockerfile).

The images can also be used as a base for your own images, with the Omeka S core, modules and themes included.

## Features

- Pre-built images for each supported Omeka S and PHP version, rebuilt weekly to pick up PHP and OS security updates
- [omeka-s-cli](https://github.com/GhentCDH/Omeka-S-Cli) included, to manage Omeka S from the command line
- Install automation:
  - Install the Omeka S core at boot
  - Download modules and themes at boot
  - Install and upgrade modules at boot
- Build a custom image with modules and themes included, also from (private) git repositories
- All persistent data in a single `/volume` folder

## Quick start

1. Download [`compose.prod.yaml`](compose.prod.yaml) and [`example.env`](example.env), and rename `example.env` to `.env`.
2. Edit `.env`:
   - change the database passwords (`MYSQL_ROOT_PASSWORD`, `MYSQL_PASSWORD`)
   - set `OMEKA_S_INSTALL_CORE=1` and the `OMEKA_S_ADMIN_*` variables to install Omeka S at the first boot
   - set `APPLICATION_ENV=production` (or remove it, `production` is the default)
   - point the `SMTP_*` variables to your mail server
3. Start Omeka S and MariaDB:

   ```sh
   docker compose -f compose.prod.yaml up -d
   ```

4. Open [http://localhost:8080](http://localhost:8080).

## Image tags

Tags have the format `<omeka-s-version>-php-<php-version>`, e.g. `ghentcdh/omeka-s-docker:4.2.1-php-8.3`. There is no `latest` tag: always choose an Omeka S and PHP version.

| Omeka S | Tags                                                               |
| ------- | ------------------------------------------------------------------ |
| 4.2.1   | `4.2.1-php-8.2`, `4.2.1-php-8.3`, `4.2.1-php-8.4`, `4.2.1-php-8.5` |
| 4.2.0   | `4.2.0-php-8.2`, `4.2.0-php-8.3`, `4.2.0-php-8.4`                  |
| 4.1.1   | `4.1.1-php-8.2`, `4.1.1-php-8.3`                                   |
| 4.1.0   | `4.1.0-php-8.2`, `4.1.0-php-8.3`                                   |
| 4.0.4   | `4.0.4-php-8.2`                                                    |

These images are rebuilt every week. Older tags (e.g. `4.1.1-php-8.1`) are still available on Docker Hub, but are no longer updated.

## Volume layout

All data that can change is stored in `/volume`. The matching folders of the Omeka S installation in `/var/www/omeka-s` are symbolic links to this volume.

```
/volume
├── bootstrap.php     # copy of the Omeka S bootstrap file (for scripts that require it)
├── config/           # local.config.php and database.ini  -> /var/www/omeka-s/config
├── files/            # uploaded media and derivatives     -> /var/www/omeka-s/files
├── logs/             # Omeka S logs                       -> /var/www/omeka-s/logs
├── modules/          # modules                            -> /var/www/omeka-s/modules
└── themes/           # themes                             -> /var/www/omeka-s/themes
```

What to persist:

| Folder    | Base image | Custom image | Notes                                                                                       |
| --------- | :--------: | :----------: | ------------------------------------------------------------------------------------------- |
| `config`  |    yes     |     yes      | Contains `database.ini`and `local.config.php`. |
| `files`   |    yes     |     yes      | Uploaded media.                                                                             |
| `logs`    |    yes     |     yes      |                                                                                             |
| `modules` |    yes     |      no      | In a [custom image](#building-a-custom-image), the modules are part of the image.           |
| `themes`  |    yes     |      no      | In a [custom image](#building-a-custom-image), the themes are part of the image.                                        |

- `database.ini` is created at every boot, based on the `MYSQL_*` environment variables. `local.config.php` is copied at boot when it doesn't exist, so you can customize it in the volume.
- Modules can store files in `config`. The [Common](https://github.com/Daniel-KM/Omeka-S-module-Common) module, for example, uses `secret_key.php` to encrypt secrets (such as API keys) in the database. If `config` is not persisted, a new container can't decrypt those secrets anymore. `config` is not writable by PHP, so Common can't generate this file when it is installed: create `config/secret_key.php` yourself, or set the `OMEKA_SECRET_KEY` environment variable.
- Don't mount `modules` or `themes` with a custom image: a bind mount hides the modules and themes of the image, and a named volume is only filled with the content of the image when it is created, so it keeps the old versions when you upgrade the image.

### Permissions

PHP runs as the user set in `CONTAINER_UID` (default `application`, uid 1000), Apache as `www-data`.

- `files` and `logs` are writable by PHP. `config` is not. `modules` and `themes` are only writable by PHP when `OMEKA_S_ALLOW_EASY_ADMIN=1`.
- At boot, folders in `/volume` that are missing or empty (e.g. a new volume) are created with the right owner. Folders with content are left alone: their ownership is up to you. When PHP can't write to `files` or `logs`, a warning is shown at boot.
- Modules and themes are downloaded as root (as the PHP user when `OMEKA_S_ALLOW_EASY_ADMIN=1`), and installed as the PHP user, like an install from the admin interface.
- Apache serves files, module and theme assets directly, so they must be readable by `www-data`.
- Storage that you mount yourself must be writable for PHP. For a CIFS share, set the owner with the mount options, e.g. `uid=www-data,gid=www-data,file_mode=0644,dir_mode=0755` with `CONTAINER_UID=www-data`.

To make existing data writable for PHP, e.g. after a migration, after changing `CONTAINER_UID`, or after setting `OMEKA_S_ALLOW_EASY_ADMIN=1` (add `/volume/modules /volume/themes`), run once:

```sh
docker compose exec omeka chown -R application:application /volume/files /volume/logs
```

Replace `application` with the value of `CONTAINER_UID`.

## Configuration

Copy the `example.env` file to `.env` and update the values as needed.

### Omeka S

| Variable                      | Description                                                        | Default       |
| ----------------------------- | ------------------------------------------------------------------ | ------------- |
| `APPLICATION_ENV`             | `production` or `development`                                      | `production`  |
| `MYSQL_DATABASE`              | Database name                                                      | `omeka`       |
| `MYSQL_USER`                  | Database user                                                      | `omeka`       |
| `MYSQL_PASSWORD`              | Database password                                                  | `omeka`       |
| `MYSQL_HOST`                  | Database host                                                      | `db`          |
| `MYSQL_PORT`                  | Database port                                                      | `3306`        |
| `SMTP_HOST`                   | SMTP host                                                          | `""` (empty)  |
| `SMTP_PORT`                   | 25, 465 for 'ssl', and 587 for 'tls' (1025 for Mailpit)            | `""` (empty)  |
| `SMTP_CONNECTION_TYPE`        | 'null', 'ssl' or 'tls'                                             | `""` (empty)  |
| `SMTP_USER`                   |                                                                    | `""` (empty)  |
| `SMTP_PASSWORD`               |                                                                    | `""` (empty)  |
| `THUMBNAIL_LARGE_CONSTRAINT`  | Size of large thumbnails (px)                                      | `1000`        |
| `THUMBNAIL_MEDIUM_CONSTRAINT` | Size of medium thumbnails (px)                                     | `600`         |
| `THUMBNAIL_SQUARE_CONSTRAINT` | Size of square thumbnails (px)                                     | `400`         |
| `OMEKA_S_ALLOW_EASY_ADMIN`    | Set value to 1 to allow EasyAdmin module to install themes/modules | `0`           |
| `CONTAINER_UID`               | User PHP runs as: a name (e.g. `www-data`) or a number (e.g. your own uid). The group gets the same value. See [Permissions](#permissions). | `application` |

### Automated installation

| Variable                  | Description                                                                             | Default             |
| ------------------------- | --------------------------------------------------------------------------------------- | ------------------- |
| `OMEKA_S_MODULES`         | A list of Omeka S modules/urls to download at boot time                                 | `""` (empty)        |
| `OMEKA_S_THEMES`          | A list of Omeka S themes/urls to download at boot time                                  | `""` (empty)        |
| `OMEKA_S_INSTALL_CORE`    | Install Omeka S core at boot time                                                       | `0`                 |
| `OMEKA_S_INSTALL_MODULES` | Install all downloaded modules at boot time (added to the image or downloaded at boot) | `0`                 |
| `OMEKA_S_UPGRADE_MODULES` | Upgrade modules that need an upgrade at boot time                                       | `0`                 |
| `OMEKA_S_TITLE`           | Title for the Omeka S installation                                                      | `Omeka S`           |
| `OMEKA_S_TIME_ZONE`       | Time zone for the installation                                                          | `UTC`               |
| `OMEKA_S_LOCALE`          | Locale/language for the installation                                                    | `en_US`             |
| `OMEKA_S_ADMIN_NAME`      | Administrator name                                                                      | `admin`             |
| `OMEKA_S_ADMIN_EMAIL`     | Administrator email address                                                             | `admin@example.com` |
| `OMEKA_S_ADMIN_PASSWORD`  | Administrator password                                                                  | `admin`             |

### PHP

The PHP settings can be changed with the environment variables of [webdevops/php-apache](https://dockerfile.readthedocs.io/en/latest/content/DockerImages/dockerfiles/php-apache.html#environment-variables). The image changes these defaults:

| Variable                  | Default |
| ------------------------- | ------- |
| `PHP_MEMORY_LIMIT`        | `512M`  |
| `PHP_POST_MAX_SIZE`       | `220M`  |
| `PHP_UPLOAD_MAX_FILESIZE` | `220M`  |

### Containers

These variables are used by the compose files.

| Variable                  | Description                         | Default |
| ------------------------- | ----------------------------------- | ------- |
| `OMEKA_S_VERSION`         | Omeka S version (image tag / build) | `4.2.1` |
| `PHP_VERSION`             | PHP version (image tag / build)     | `8.3`   |
| `MARIADB_VERSION`         | MariaDB version                     | `11.4`  |
| `MYSQL_ROOT_PASSWORD`     | Database root password              |         |
| `SOLR_VERSION`            | Apache Solr version                 | `9`     |
| `OMEKA_S_EXPOSED_PORT`    | Omeka S exposed port                | `8080`  |
| `PHPMYADMIN_EXPOSED_PORT` | PhpMyAdmin exposed port             | `8081`  |
| `MAILPIT_EXPOSED_PORT`    | MailPit exposed port                | `8025`  |

## Download modules and themes at boot

Modules and themes can be downloaded when the container starts, with the `OMEKA_S_MODULES` and `OMEKA_S_THEMES` environment variables. They contain one or more:

- module or theme identifiers (dirnames), as found in https://omeka.org/add-ons/json/s_module.json and https://omeka.org/add-ons/json/s_theme.json. Use `name:version` to download a specific version.
- urls pointing to ZIP releases of valid Omeka S modules or themes.

The modules and themes are downloaded to the `modules` and `themes` folders. Existing modules and themes are not overwritten. A module that can't be downloaded is reported, but doesn't stop the container.

To install the downloaded modules, set `OMEKA_S_INSTALL_MODULES=1`.

### Example

In your `.env` file:

```
OMEKA_S_MODULES="Common Log EasyAdmin:3.4.38"
OMEKA_S_THEMES="default Freedom:1.0.6"
```

Or in your `compose.override.yaml` file:

```yaml
services:
  omeka:
    environment:
      OMEKA_S_MODULES: |
        Common
        Log
        EasyAdmin:3.4.38
      OMEKA_S_THEMES: |
        default
        Freedom:1.0.6
```

## omeka-s-cli

The images include [omeka-s-cli](https://github.com/GhentCDH/Omeka-S-Cli), a command line tool for Omeka S, also developed by GhentCDH. The boot scripts use it to download the core, modules and themes, create `database.ini` and install Omeka S.

You can use it to manage your installation. Run it from the Omeka S folder (add `-f compose.prod.yaml` after `docker compose` when you use that file):

```sh
# list all commands
docker compose exec omeka omeka-s-cli --help

# core status and version
docker compose exec -w /var/www/omeka-s omeka omeka-s-cli core:status

# list and download modules
docker compose exec -w /var/www/omeka-s omeka omeka-s-cli module:list
docker compose exec -w /var/www/omeka-s omeka omeka-s-cli module:download Common

# install and upgrade modules
docker compose exec -u application -e HOME=/tmp -w /var/www/omeka-s omeka omeka-s-cli module:install Common
docker compose exec -u application -e HOME=/tmp -w /var/www/omeka-s omeka omeka-s-cli module:upgrade --all
```

Run omeka-s-cli as the same user as the boot scripts (see [Permissions](#permissions)), so new files get the right owner:

- Download modules and themes as root, or as the PHP user when `OMEKA_S_ALLOW_EASY_ADMIN=1`.
- Install and upgrade as the PHP user, like the admin interface does. Replace `application` with the value of `CONTAINER_UID`. `HOME` must be writable, because omeka-s-cli keeps its cache in `$HOME/.cache`.

See the [omeka-s-cli documentation](https://github.com/GhentCDH/Omeka-S-Cli) for all commands.

## Building a custom image

The pre-built images contain only the Omeka S core. To deploy a site with a fixed set of modules and themes, you can build your own image with the core, modules and themes included. Every container started from that image has the same code, and upgrading is a matter of deploying a new image.

### Build arguments

| Argument          | Description                                                | Default       |
| ----------------- | ---------------------------------------------------------- | ------------- |
| `PHP_VERSION`     | PHP version                                                | `8.3`         |
| `OMEKA_S_VERSION` | Version of Omeka S to download                             | `4.2.1`       |
| `OMEKA_S_MODULES` | List of modules to download during build (see [above](#download-modules-and-themes-at-boot)) | `""` (empty)  |
| `OMEKA_S_THEMES`  | List of themes to download during build (see [above](#download-modules-and-themes-at-boot))  | `""` (empty)  |

```bash
docker build \
  --build-arg OMEKA_S_VERSION=4.2.1 \
  --build-arg PHP_VERSION=8.3 \
  --build-arg OMEKA_S_MODULES="Common Log EasyAdmin" \
  --build-arg OMEKA_S_THEMES="default Freedom" \
  --target prod \
  -t my-omeka-s:1.0.0 .
```

The build fails if a module or theme can't be downloaded.

### Modules and themes from git repositories

Modules and themes can also be downloaded from (private) git repositories, e.g. `git@github.com:org/Omeka-S-module-Foo.git#v1.0.0`. Use `build_image.sh` to build with SSH agent forwarding. It reads the build arguments from a config file:

```bash
# .env.build
OMEKA_S_VERSION=4.2.1
PHP_VERSION=8.3
OMEKA_S_MODULES="Common Log git@github.com:org/Omeka-S-module-Foo.git#v1.0.0"
OMEKA_S_THEMES="default"
```

```bash
./build_image.sh .env.build my-omeka-s:1.0.0
```

### Deploying a custom image

Use `compose.prod.yaml` with your own image, and only persist the `config`, `files` and `logs` folders (see [Volume layout](#volume-layout)):

```yaml
services:
  omeka:
    image: my-omeka-s:1.0.0
    volumes:
      - omeka-config:/volume/config
      - omeka-files:/volume/files
      - omeka-logs:/volume/logs
```

- Set `OMEKA_S_INSTALL_MODULES=1` to install the modules of the image, and `OMEKA_S_UPGRADE_MODULES=1` to upgrade them when a new image ships a newer version.
- Don't repeat the build-time module list in the runtime `OMEKA_S_MODULES` variable: modules from git repositories would be cloned at every boot, and private repositories need SSH keys.

## Local development

`compose.yaml` builds the image from source, and adds PHPMyAdmin, MailPit and Apache Solr:

```sh
cp example.env .env
docker compose up
```

- Omeka S: [http://localhost:8080](http://localhost:8080)
- PHPMyAdmin: [http://localhost:8081](http://localhost:8081)
- MailPit: [http://localhost:8025](http://localhost:8025)

## Credits

Development by [Ghent Centre for Digital Humanities - Ghent University](https://www.ghentcdh.ugent.be/). Funded by the [GhentCDH research projects](https://www.ghentcdh.ugent.be/projects).

<img src="https://www.ghentcdh.ugent.be/ghentcdh_logo_blue_text_transparent_bg_landscape.svg" alt="Landscape" width="500">
