# Xenforo 2 PHP FPM Container Image

A PHP 8, FPM based image to mount a xenforo installation inside of, and then use a reverse proxy to pass through requests

Includes [php-fpm-healthcheck](https://github.com/renatomefi/php-fpm-healthcheck) to make it easy to configure a container health check as shown in the usage example below.

Looking for a complete template to get started with Xenforo? Checkout my [Xenforo Addon Template Repo](https://github.com/Jarvvski/xenforo-development)

## Alpine

Also supports an alpine linux tagged version, for smaller container sizes.

```text
jarvvski/xenforo-2-php-fpm:alpine
```

## Usage

Please note this is just a quick sample for a Xenforo deployment, not a production ready config. You should use better secrets and environment variables across the board, as well as an nginx config to correct proxy requests to the php-fpm container.

```yaml
version: '3.7'

services:
  xenforo:
    image: jarvvski/xenforo-2-php-fpm:alpine
    container_name: xenforo
    # use a specific uuid/gid mask if the files need it
    # user: 1001:998 
    healthcheck:
      test: ["CMD", "php-fpm-healthcheck"]
      interval: 15s
      timeout: 10s
      retries: 3
      start_period: 1m
    restart: always
    working_dir: /var/www/html
    volumes:
      - xenforo-www:/var/www/html
      - xenforo-data:/var/www/html/data
      - xenforo-internal_data:/var/www/html/internal_data          

  nginx:
    image: nginx:1.21-alpine
    container_name: xenforo-nginx
    networks:
      - edge
      - xenforo
    volumes_from:
      - xenforo_server

  database:
    container_name: xenforo-db
    networks:
      - xenforo
    image: mariadb
    volumes:
      - xenforo-database:/var/lib/mysql
    environment:
      MYSQL_DATABASE: xenforo
      MYSQL_USER: xenforo
      MYSQL_PASSWORD: secret
      MYSQL_ROOT_PASSWORD: secret

volumes:
  xenforo-database:
  xenforo-www:
  xenforo-data:
  xenforo-internal_data:      
```
