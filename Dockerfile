FROM php:8.1-apache-buster as production

WORKDIR /var/www/html

ENV APP_ENV=local
ENV APP_DEBUG=true
ARG NODE_VERSION=18

RUN apt-get update && apt-get install -y \
    gnupg \
    curl \
    ca-certificates \
    libpng-dev \
    libmcrypt-dev \
    libpq-dev \
    zlib1g-dev \
    libzip-dev \
    zip \
    unzip &&\
    a2enmod rewrite
RUN mkdir -p /etc/apt/keyrings

RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION.x nodistro main" > /etc/apt/sources.list.d/nodesource.list

RUN apt-get update \
    && apt-get install -y nodejs \
    && npm install -g npm

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer --ansi --version --no-interaction

RUN docker-php-ext-install mysqli pdo pdo_mysql gd zip

#COPY devops/php/conf.d/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY devops/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY . .
RUN composer install --prefer-dist --no-dev --optimize-autoloader --no-interaction

RUN echo "NODE Version:" && node --version
RUN echo "NPM Version:" && npm --version
RUN npm install && npm run build

RUN chmod 777 -R /var/www/html/storage/ && \
    chown -R www-data:www-data /var/www/ && \
    a2enmod rewrite
