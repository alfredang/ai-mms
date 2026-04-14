FROM php:8.2-apache

# Build trigger: 2026-04-14

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libxml2-dev \
    libxslt1-dev \
    libzip-dev \
    libicu-dev \
    libpq-dev \
    libonig-dev \
    unzip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    pdo_pgsql \
    pgsql \
    gd \
    intl \
    soap \
    xsl \
    zip \
    bcmath \
    mbstring \
    ftp \
    opcache

# Enable Apache modules
RUN a2enmod rewrite headers expires deflate

# Set Apache DocumentRoot and AllowOverride
ENV APACHE_DOCUMENT_ROOT=/var/www/html
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Copy custom PHP config
COPY docker/php.ini /usr/local/etc/php/conf.d/magento.ini

# Copy Apache vhost config
COPY docker/apache-vhost.conf /etc/apache2/sites-available/000-default.conf

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . /var/www/html/

# Install Composer dependencies
RUN composer install --no-dev --no-interaction --optimize-autoloader

# Save build timestamp as version
RUN date -u '+%d-%m-%Y %H:%M' > /var/www/html/version.txt

# Set proper permissions for Apache
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
