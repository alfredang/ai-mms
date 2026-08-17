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

# Claude Code CLI (Agent SDK) — powers the admin AI features (SEO meta,
# lead reply drafts) authenticated with the subscription OAuth token from
# mmd_marketing/api/anthropic_key (exported as CLAUDE_CODE_OAUTH_TOKEN by
# AiSeo::invokeClaude). Installed as the NATIVE standalone binary — no
# NodeSource/npm dependency — and NON-FATAL so a download hiccup can never
# block a production deploy; AI features degrade gracefully when absent.
# /var/www/.claude marks www-data's HOME for the CLI's config writes.
RUN (HOME=/opt/claude-home bash -c "curl -fsSL https://claude.ai/install.sh | bash" \
        && ln -sf "$(readlink -f /opt/claude-home/.local/bin/claude)" /usr/local/bin/claude \
        && chmod -R a+rX /opt/claude-home \
        || echo "Claude CLI install failed (non-fatal — AI drafts will be unavailable)") \
    && mkdir -p /var/www/.claude \
    && chown www-data:www-data /var/www /var/www/.claude

# Legacy local-dev npm install path (kept for compatibility with existing
# local compose setups that set INSTALL_CLAUDE_CLI=1).
ARG INSTALL_CLAUDE_CLI=0
RUN if [ "$INSTALL_CLAUDE_CLI" = "1" ]; then \
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
        && apt-get install -y nodejs \
        && npm install -g @anthropic-ai/claude-code \
        && rm -rf /var/lib/apt/lists/*; \
    else \
        echo "Skipping npm Claude CLI install (native binary above is canonical)"; \
    fi

# Set working directory
WORKDIR /var/www/html

# Copy application files. --chown writes ownership directly into the COPY
# layer; a later blanket `chown -R /var/www/html` would copy-up the entire
# ~70k-file tree into a duplicate layer — that step alone ran 45-60 min on
# the SG Coolify server and pushed every build past the 1-hour deployment
# timeout (2026-07-17 outage: builds 3919/3937 failed, queue jammed).
COPY --chown=www-data:www-data . /var/www/html/

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
#
# GITHUB_TOKEN (optional Coolify build variable): composer downloads most
# dists from codeload.github.com; anonymous requests get rate-limited
# (HTTP 429) when several builds run the same day (2026-08-17: two deploys
# failed at 59/62 packages). An authenticated token raises the limit to
# 5000/h. The token is configured and removed inside ONE layer so it is
# never persisted in the image filesystem.
ARG GITHUB_TOKEN
RUN if [ -n "$GITHUB_TOKEN" ]; then composer config -g github-oauth.github.com "$GITHUB_TOKEN"; fi \
 && COMPOSER_PROCESS_TIMEOUT=0 composer install --no-dev --no-interaction --optimize-autoloader --ignore-platform-req=php \
 && (composer config -g --unset github-oauth.github.com 2>/dev/null || true)

# Keep Cm_RedisSession disabled in every image build. The module is disabled
# in source (app/etc/modules/Cm_RedisSession.xml) due to a vendor package
# incompatibility (missing UsernameConfigInterface), so PHP sessions stay on
# MySQL regardless of Redis availability. The sed guards against a
# magento-composer-installer copy that ships with active=true overwriting our
# source file during composer install. Redis object cache is still used when
# REDIS_HOST env is set — see entrypoint.sh patch-redis-in-local-xml.php.
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

# Only vendor/ is created root-owned after the --chown COPY (composer
# install). Root-owned 644 build artifacts (version.txt, .br/.gz siblings)
# stay readable by Apache; runtime-writable dirs (media/css etc.) are
# chowned by entrypoint.sh on every boot. Never reinstate a blanket
# `chown -R /var/www/html` — see COPY comment above.
RUN chown -R www-data:www-data /var/www/html/vendor

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
