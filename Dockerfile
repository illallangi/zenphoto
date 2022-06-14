# main image
FROM ghcr.io/illallangi/php-base:v0.0.3
# Install ZenPhoto
ENV ZENPHOTO_VERSION=1.5.9
ADD https://github.com/zenphoto/zenphoto/archive/v${ZENPHOTO_VERSION}.tar.gz /usr/local/src/zenphoto.tar.gz

COPY root /

VOLUME \
  /var/www/html/albums \
  /var/www/html/backup \
  /var/www/html/cache \
  /var/www/html/cache_html \
  /var/www/html/plugins \
  /var/www/html/uploaded \
  /var/www/html/zp-data
