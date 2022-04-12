# caddy image
FROM ghcr.io/illallangi/caddy-builder:v0.0.3 as caddy

# main image
FROM php:7.4-fpm

# install prerequisites
RUN DEBIAN_FRONTEND=noninteractive \
  apt-get update \
  && \
  apt-get install -y --no-install-recommends \
    ca-certificates=20210119 \
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
    musl=1.2.2-1 \
    nginx=1.18.0-6.1 \
    xz-utils=5.2.5-2 \
  && \
  apt-get clean \
  && \
  rm -rf \
    /var/lib/apt/lists/* \
    /var/www/html \
    /etc/nginx/sites-enabled/*

RUN echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && \
    locale-gen

RUN docker-php-ext-configure gd \
      --with-jpeg=/usr/include/ \
      --with-freetype=/usr/include/ \
    && \
    docker-php-ext-install -j"$(nproc)" \
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

# Install S6 Overlay
ARG OVERLAY_VERSION="v2.2.0.3"
ARG OVERLAY_ARCH="amd64"
ADD https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-${OVERLAY_ARCH}-installer /tmp/
RUN chmod +x /tmp/s6-overlay-${OVERLAY_ARCH}-installer && /tmp/s6-overlay-${OVERLAY_ARCH}-installer / && rm /tmp/s6-overlay-${OVERLAY_ARCH}-installer
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

# Install ZenPhoto
ENV ZENPHOTO_VERSION=1.5.9
ADD https://github.com/zenphoto/zenphoto/archive/v${ZENPHOTO_VERSION}.tar.gz /usr/local/src/zenphoto.tar.gz

COPY root /

CMD ["/init"]

EXPOSE 80
VOLUME \
  /var/www/html/albums \
  /var/www/html/backup \
  /var/www/html/cache \
  /var/www/html/cache_html \
  /var/www/html/plugins \
  /var/www/html/uploaded \
  /var/www/html/zp-data
