FROM php:apache

LABEL maintainer="elitonluiz1989@gmail.com"
LABEL version="1.0.0"

RUN apt update

# install extensions
# intl, zip, soap
RUN apt install -y --no-install-recommends \
    curl \
    unzip \
    wget \
    libaio1 \
    nano \
    libzip-dev \
    libc6-dev \
    libicu63 \
    libicu-dev\
    libxml2-dev \
    && docker-php-ext-install intl zip pdo

# oracle
RUN wget https://download.oracle.com/otn_software/linux/instantclient/19600/instantclient-basic-linux.x64-19.6.0.0.0dbru.zip -P /tmp
RUN wget https://download.oracle.com/otn_software/linux/instantclient/19600/instantclient-sdk-linux.x64-19.6.0.0.0dbru.zip -P /tmp
RUN unzip /tmp/instantclient-basic-linux.x64-19.6.0.0.0dbru.zip -d /usr/local/
RUN unzip /tmp/instantclient-sdk-linux.x64-19.6.0.0.0dbru.zip -d /usr/local/
RUN mv /usr/local/instantclient_19_6 /usr/local/instantclient

ENV LD_LIBRARY_PATH=/usr/local/instantclient
RUN echo 'instantclient,/usr/local/instantclient' | pecl install oci8

RUN docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/usr/local/instantclient
RUN docker-php-ext-install pdo_oci
RUN docker-php-ext-enable oci8

# mcrypt, gd, iconv
RUN apt install -y --no-install-recommends \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
    && docker-php-ext-install -j"$(getconf _NPROCESSORS_ONLN)" iconv \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(getconf _NPROCESSORS_ONLN)" gd

# xdebug
RUN docker-php-source extract \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && docker-php-source delete

RUN echo 'ServerName 127.0.0.1' >> /etc/apache2/conf-available/servername.conf

RUN a2enmod rewrite
RUN a2enconf servername.conf

# Adding composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer 

CMD ["apachectl", "-D", "FOREGROUND"]