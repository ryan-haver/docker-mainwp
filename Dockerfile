# syntax=docker/dockerfile:1.6
ARG WORDPRESS_TAG=6.6.2-php8.2-apache
FROM wordpress:${WORDPRESS_TAG}

ENV WORDPRESS_PATH=/var/www/html \
    MAINWP_AUTO_INSTALL=true \
    MAINWP_EXTRA_PLUGINS="" \
    MAINWP_MAX_RETRIES=30 \
    MAINWP_RETRY_INTERVAL=10

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      mariadb-client \
      less \
      jq; \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp \
    && wp --info --allow-root

COPY docker/mainwp-bootstrap.sh /usr/local/bin/mainwp-bootstrap.sh
COPY docker/mainwp-entrypoint.sh /usr/local/bin/mainwp-entrypoint.sh

RUN chmod +x /usr/local/bin/mainwp-bootstrap.sh /usr/local/bin/mainwp-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/mainwp-entrypoint.sh"]
CMD ["apache2-foreground"]
