FROM php:8.2-apache

# Build trigger: 2026-04-26 (bumped to force COPY layer rebuild — Coolify
# was reusing a stale image where app/etc/modules/Cm_RedisSession.xml still
# had <active>true</active>, repeatedly breaking prod after each deploy.)

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

# Copy container entrypoint (runs migrations before starting Apache)
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

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

# Clear Magento cache to ensure fresh templates/config on deploy
RUN rm -rf /var/www/html/var/cache/* /var/www/html/var/session/* /var/www/html/var/tmp/* 2>/dev/null || true

# Set proper permissions for Apache
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
