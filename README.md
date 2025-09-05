
# Omeka-S-Docker

This repository provides a Docker setup for Omeka-S, utilizing Ubuntu, PHP, and Apache2. It is based on [webdevops/php-apache](https://github.com/webdevops/Dockerfile).

## Features

- Configurable Omeka & PHP version
- Configurable list of modules and themes to be added to the build image
- Install automation!
  - Install Omeka S core at boot
  - Install modules at boot

## Getting Started

To start the container, run:

```sh
docker compose up
```

Once started, you can access the Omeka-S installation at [http://localhost:8080](http://localhost:8080) and PHPMyAdmin at [http://localhost:8081](http://localhost:8081).

## Configuration

First, copy the `example.env` file to `.env` and update the values as needed.

### Omeka configuration

| Variable                 | Description                                                        | Default |
| ------------------------ | ------------------------------------------------------------------ | ------- |
| OMEKA_S_VERSION          | Omeka S Version                                                    | 4.1.1   |
| PHP_VERSION              | PHP Version                                                        | 8.2     |
| MYSQL_DATABASE           | Database name                                                      |         |
| MYSQL_USER               | Database user                                                      |         |
| MYSQL_PASSWORD           | Database password                                                  |         |
| MYSQL_HOST               | Database host                                                      | db      |
| SMTP_HOST                | SMTP host                                                          |         |
| SMTP_PORT                | 25, 465 for 'ssl', and 587 for 'tls'                               | 25      |
| SMTP_CONNECTION_TYPE     | 'null', 'ssl' or 'tls'                                             | none    |
| SMTP_USER                |                                                                    |         |
| SMTP_PASSWORD            |                                                                    |         |
| OMEKA_S_ALLOW_EASY_ADMIN | Set value to 1 to allow EasyAdmin module to install themes/modules | 0       |

The `database.ini` config file is automatically generated at startup based on these values.

### Database configuration (optional)

| Variable            | Description                                                    | Default |
| ------------------- | -------------------------------------------------------------- | ------- |
| MYSQL_ROOT_PASSWORD | Database root password |         |

### Install automation

| Variable                 | Description                                                        | Default |
| ------------------------ | ------------------------------------------------------------------ | ------- |
| OMEKA_S_MODULES          | A list of Omeka S modules/urls to download at boot time            |         |
| OMEKA_S_THEMES           | A list of Omeka S themes/urls to download at boot time             |         |
| OMEKA_S_INSTALL_CORE     | Install Omeka S core at boot time                                  | 0       |
| OMEKA_S_INSTALL_MODULES  | Install modules at boot time                                       | 0       |

## Download Modules at Startup

You can automatically download modules at startup by setting the OMEKA_S_MODULES environment variable. This should contain one or more:

- module identifiers (dirnames) as found in https://omeka.org/add-ons/json/s_module.json. You specify a specific version with the syntax `module:version`.
- urls pointing to ZIP releases of valid Omeka S modules.

The modules will be downloaded to the `modules` directory. Existing modules will not be overwritten.

### Example

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

## Download Themes at Startup

You can automatically download themes at container startup by setting the OMEKA_S_THEMES environment variable. This should contain one or more:

- theme identifiers (dirnames) as found in https://omeka.org/add-ons/json/s_theme.json. You specify a specific version with the syntax `theme:version`.
- urls pointing to ZIP releases of valid Omeka S themes.

The themes will be downloaded to the `themes` directory. Existing themes will not be overwritten.

### Example

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

