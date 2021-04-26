FROM alpine:3.13

ENV APPLICATION application
ENV PHP_TZ UTC
ENV USER user
ENV CERT_CRT cert.crt
ENV CERT_KEY cert.key
ENV COMPOSER_CACHE_DIR /composer

LABEL Maintainer="Maykon Facincani <facincani.maykon@gmail.com>"
LABEL Description="Laravel optimized Docker Image based on Alpine Linux, NGINX and PHP 7.4"

# https://github.com/docker-library/php/issues/240
RUN apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing gnu-libiconv
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# Install essentials packages
RUN apk add --no-cache zip unzip curl sqlite nginx supervisor bash openssl tzdata

# Install PHP packages
RUN apk --no-cache add php7 php7-common php7-fpm \
    php7-zip php7-json php7-openssl php7-curl php7-ldap \
    php7-zlib php7-xml php7-phar php7-intl php7-dom  \
    php7-xmlreader php7-xmlwriter php7-ctype \
    php7-mbstring php7-gd php7-session php7-pdo php7-pdo_mysql \
    php7-pdo_pgsql php7-pdo_sqlite php7-tokenizer php7-posix \
    php7-fileinfo php7-opcache php7-cli php7-mcrypt \
    php7-pcntl php7-iconv php7-simplexml \
    php7-pear php7-bcmath php7-pecl-redis

# Configure composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN mkdir /composer

# Configure Supervisor
COPY supervisor.d/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Configure PHP-FPM
COPY php-fpm.d/www.conf /etc/php7/php-fpm.d/www.conf

ADD php.d /etc/php7/conf.d

# Configure NGINX
RUN rm /etc/nginx/conf.d/default.conf
RUN mkdir -p /etc/ssl/nginx
COPY ssl /etc/ssl/nginx

COPY nginx.d/nginx.conf /etc/nginx/nginx.conf

# COPY nginx.d/default.conf /etc/nginx/conf.d/default.conf
# COPY nginx.d/fastcgi-php.conf /etc/nginx/fastcgi-php.conf

RUN mkdir -p /run/nginx
RUN touch /run/nginx/nginx.pid

RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

# Adjust permissions
RUN mkdir /www
RUN adduser -S -G 'nobody' user
RUN chown -R nobody.nobody /www && \
  chown -R nobody.nobody /run && \
  chown -R nobody.nobody /var/lib/nginx && \
  chown -R nobody.nobody /var/log/nginx && \
  chown -R nobody:nobody /etc/php7/conf.d && \
  chown -R nobody:nobody /etc/ssl/nginx

# Configure Entrypoint
COPY main.sh /main.sh
RUN chown nobody:nobody /main.sh
RUN chmod 755 /main.sh

USER nobody

# Setup Application Folder
WORKDIR /www

EXPOSE 80/tcp 443/tcp

VOLUME [ "/www", "/etc/ssl/ngnix" ]

CMD ["/main.sh"]

HEALTHCHECK --interval=5s --timeout=3s CMD curl -k --fail https://localhost/ || exit 1
