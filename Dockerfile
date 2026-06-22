# Pinned to a content digest so a Docker Hub tag mutation (intentional
# update OR upstream supply-chain compromise of php:8.2-apache) can't
# silently land a different base image in our prod build.
# Update intentionally: docker pull php:8.2-apache &&
# docker inspect --format='{{index .RepoDigests 0}}' php:8.2-apache
# Current pin: php:8.2-apache as of 2026-06-01
FROM php:8.2-apache@sha256:affc043fbd9acaa9a6394a71d162726fc0a6e4bea0400a3b94f925b6130858dd

# Build trigger: 2026-05-22 (bumped to force COPY layer rebuild — Coolify
# was reusing a stale image so migrations/112-backfill-course-image-url-from-r2.sql
# never landed on live and apply.php kept reporting applied_count=120.)

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
    brotli \
    gzip \
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

# phpredis: native client used by Cm_Cache_Backend_Redis and Cm_RedisSession
# when Redis is configured. Harmless when absent at runtime — Credis falls back
# to a pure-PHP socket client. Install non-fatally so a transient pecl outage
# never breaks the production build.
RUN pecl install redis && docker-php-ext-enable redis \
    || echo "WARNING: phpredis install failed — Magento will fall back to Credis if Redis is configured"

# Enable Apache modules. brotli gives ~20% smaller text payloads vs gzip;
# .htaccess already has AddOutputFilterByType BROTLI_COMPRESS rules.
RUN a2enmod rewrite headers expires deflate brotli

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

# Claude CLI — local-dev only fallback for the admin "Generate SEO Meta with AI"
# button. Production uses the Anthropic API key path when configured, then falls
# back to a deterministic stub; do not make production deploys depend on NodeSource
# or npm availability.
ARG INSTALL_CLAUDE_CLI=0
RUN if [ "$INSTALL_CLAUDE_CLI" = "1" ]; then \
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
        && apt-get install -y nodejs \
        && npm install -g @anthropic-ai/claude-code \
        && rm -rf /var/lib/apt/lists/*; \
    else \
        echo "Skipping local-only Claude CLI install"; \
    fi

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . /var/www/html/

# Install Composer dependencies.
#
# --ignore-platform-req=php: composer.json pins config.platform.php=7.4
# for tooling determinism (phpstan/rector resolve as if 7.4) but the
# container actually runs 8.2.31 and google/apiclient 2.15+ requires
# PHP 8+. Without this flag the install aborts with "Your requirements
# could not be resolved" → exit code 2 → failed Coolify build.
#
# COMPOSER_PROCESS_TIMEOUT=0: google/apiclient-services ships a large
# zip (every Google API's PHP classes) and the unzip can take 5+ min
# on slower runners. Default 300s timeout would kill it mid-extract.
RUN COMPOSER_PROCESS_TIMEOUT=0 composer install --no-dev --no-interaction --optimize-autoloader --ignore-platform-req=php

# Disable Cm_RedisSession in the PRODUCTION image. Locally, docker-compose
# ships a redis service and the host bind mount overrides this file, so the
# module is active in dev. Production Coolify has no Redis service (yet);
# without this sed, every prod request would crash trying to talk to Redis.
# Two layers force the sed: (a) magento-composer-installer's copy+magento-force
# overwrites our git-tracked Cm_RedisSession.xml with the vendor copy
# (active=true) on every build, and (b) our own git-tracked version is also
# active=true (so local dev works out of the box). Patch in place.
# REMOVE THIS sed once a Redis service is provisioned in Coolify.
RUN sed -i 's|<active>true</active>|<active>false</active>|' \
    /var/www/html/app/etc/modules/Cm_RedisSession.xml

# Precompress static text assets so Apache serves the .br/.gz sibling directly
# (see .htaccess rewrite). Build-time quality 11/9 beats per-request quality 4-5
# and saves CPU on every hit. Skip already-compressed siblings and small files.
RUN find /var/www/html/skin /var/www/html/js \
        \( -name '*.css' -o -name '*.js' -o -name '*.svg' \) \
        -type f -size +1k \
        ! -name '*.br' ! -name '*.gz' \
        -print0 2>/dev/null \
    | xargs -0 -P 4 -I {} sh -c 'brotli -kfq 11 "{}" 2>/dev/null; gzip -9kf "{}" 2>/dev/null' \
    || true

# Save build timestamp as version
RUN date -u '+%d-%m-%Y %H:%M' > /var/www/html/version.txt

# Clear Magento cache to ensure fresh templates/config on deploy
RUN rm -rf /var/www/html/var/cache/* /var/www/html/var/session/* /var/www/html/var/tmp/* 2>/dev/null || true

# Set proper permissions for Apache
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
