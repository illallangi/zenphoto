# caddy image
FROM ghcr.io/illallangi/caddy-builder:v0.0.3 as caddy

# main image
FROM php:7.4-fpm

# install caddy
COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy

ARG ZENPHOTO_VERSION=1.5.9

ADD https://github.com/zenphoto/zenphoto/archive/v${ZENPHOTO_VERSION}.tar.gz /usr/local/src/zenphoto.tar.gz

# install php extensions
RUN DEBIAN_FRONTEND=noninteractive \
  apt-get update \
  && \
  apt-get install -y --no-install-recommends \
    imagemagick=8:6.9.11.60+dfsg-1.3 \
    libbz2-dev=1.0.8-4 \
    libgd-dev=2.3.0-2 \
    libicu-dev=67.1-7 \
    libjpeg-dev=1:2.0.6-4 \
    libmagickwand-dev=8:6.9.11.60+dfsg-1.3 \
    libpng-dev=1.6.37-3 \
    libtidy-dev=2:5.6.0-11 \
    libzip-dev=1.7.3-1 \
    locales=2.31-13+deb11u3 \
  && \
  apt-get clean \
  && \
  rm -rf /var/lib/apt/lists/*

RUN echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && \
    locale-gen

RUN docker-php-ext-configure gd \
      --with-jpeg=/usr/include/ \
      --with-freetype=/usr/include/ \
    && \
    docker-php-ext-install -j$(nproc) \
      bz2 \
      exif \
      gd \
      gettext \
      intl \
      mysqli \
      pdo_mysql \
      tidy \
      zip \
    && \
    docker-php-ext-enable \
      bz2 \
      exif \
      gd \
      gettext \
      intl \
      mysqli \
      pdo_mysql \
      tidy \
      zip

RUN tar \
      --strip-components=1 \
      --exclude=README.md \
      --exclude=SECURITY.md \
      --exclude=SUPPORT.md \
      --exclude=contributing.md \
      --exclude=.git* \
      --gzip \
      --extract \
      --file /usr/local/src/zenphoto.tar.gz \
    && \
    /bin/bash -c "mkdir -p /var/www/html/{albums,backup,cache,cache_html,uploaded,plugins,zp-data}" && \
    cp /var/www/html/zp-core/htaccess /var/www/html/.htaccess && \
    cp /var/www/html/zp-core/example_robots.txt /var/www/html/robots.txt && \
    chmod 0600 /var/www/html/.htaccess && \
    sed -i s/\\/zenphoto//g /var/www/html/robots.txt && \
    find /var/www/html ! -group 33 -exec chown 33.33 {} \; && \
    find /var/www/html ! -user 33 -exec chown 33 {} \; && \
    find /var/www/html -type d ! -perm 0500 -exec chmod 0500 {} \; && \
    find /var/www/html -type f ! -perm 0400 -exec chmod 0400 {} \; && \
    /bin/bash -c "find /var/www/html/{albums,backup,cache,cache_html,uploaded,plugins,zp-data} -type d ! -perm 0700 -exec chmod 0700 {} \;" && \
    /bin/bash -c "find /var/www/html/{albums,backup,cache,cache_html,uploaded,plugins,zp-data} -type f ! -perm 0600 -exec chmod 0600 {} \;"

# add local files
COPY root/ /

EXPOSE 80 443
VOLUME \
  /var/www/html/albums \
  /var/www/html/backup \
  /var/www/html/cache \
  /var/www/html/cache_html \
  /var/www/html/uploaded \
  /var/www/html/zp-data

# set entrypoint
ENTRYPOINT ["custom-entrypoint"]

# set command
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile", "--watch"]
