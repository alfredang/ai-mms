# ai-mms

Tertiary Courses Singapore (tertiarycourses.com.sg) - E-commerce platform rebuilt on modern PHP stack.

## Stack

- **Platform**: Magento 1.x (OpenMage LTS v20.12.3)
- **PHP**: 8.2
- **Database**: MySQL 5.7
- **Web Server**: Apache 2.4
- **Infrastructure**: Docker Compose

## Features

- Multi-regional e-commerce (Singapore, Malaysia, Bhutan, Ghana, Nigeria, India)
- WSQ and IBF-STS certified course catalog
- Payment integrations: Stripe, HitPay, Bank Payment
- Custom course/provider management module
- Ultimo theme with responsive design

## Local Development Setup

### Prerequisites

- Docker Desktop installed and running

### Quick Start

```bash
# Start Docker Desktop
open -a Docker

# Copy .env.example to .env and set your credentials
cp .env.example .env
# Edit .env with your database passwords and API keys

# Build and start containers
docker compose up -d --build

# Import the database (place courses_mysql2.sql in project root)
docker exec -i ai-mms-db_mysql-1 mysql -u root -p$MYSQL_ROOT_PASSWORD $MYSQL_DATABASE < courses_mysql2.sql

# Apply migrations (localhost URLs, config fixes, enable all products)
for f in migrations/*.sql; do
  docker exec -i ai-mms-db_mysql-1 mysql -u root -p$MYSQL_ROOT_PASSWORD $MYSQL_DATABASE < "$f"
done

# Copy local.xml template and update credentials to match .env
cp app/etc/local.xml.example app/etc/local.xml

# Install composer dependencies inside the web container
docker exec ai-mms-web-1 bash -c 'cd /var/www/html && curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer && composer install --no-dev --optimize-autoloader'

# Clear cache
docker exec ai-mms-web-1 bash -c 'rm -rf /var/www/html/var/cache/*'
```

### Migrations

The `migrations/` folder contains incremental SQL fixes applied on top of the base DB dump. Running `for f in migrations/*.sql; do ...` from the Quick Start applies them in order:

| File | Purpose |
|------|---------|
| `001-remove-orphan-eav-entity-types.sql` | Removes broken EAV entities that crash product sliders in dev mode |
| `002-disable-customoptions-inventory.sql` | Disables per-option inventory so registration form works |
| `003-enable-all-products.sql` | Enables all ~441 disabled products for local dev visibility |
| `004-set-localhost-urls.sql` | Points base URLs at `localhost:8080` |
| `005-disable-admin-captcha.sql` | Turns off admin login captcha for local dev |
| `006-fix-rolemanager-rule-role-type.sql` | Backfills `role_type='G'` on RoleManager ACL rules (otherwise all rules silently fail and users get Access Denied) |
| `007-clean-orphan-acl-rules.sql` | Removes 34 leftover admin_rule rows from uninstalled modules (Braintree, old API, sendfriend, etc.) |
| `008-add-admin-user-profile-fields.sql` | Adds profile columns to admin_user table |
| `009-seed-demo-learner-enrollments.sql` | Seeds 3 test enrollments (Current / Upcoming / Past) on the first admin user so the Learner "My Classes" dashboard has content |

### Access

| Service | URL |
|---------|-----|
| Frontend | http://localhost:8080/ |
| Admin Panel | http://localhost:8080/admin/ (configured in local.xml) |
| MySQL | localhost:3307 (credentials in .env) |

### Configuration

1. Copy `.env.example` to `.env` and set your database passwords and API keys.
2. Copy `app/etc/local.xml.example` to `app/etc/local.xml` and update credentials:

```xml
<host><![CDATA[db_mysql]]></host>
<username><![CDATA[your_username]]></username>
<password><![CDATA[your_password]]></password>
<dbname><![CDATA[your_database]]></dbname>
```

## Docker Services

| Service | Image | Port |
|---------|-------|------|
| web | PHP 8.2 / Apache | 8080 |
| db_mysql | MySQL 5.7 | 3307 |

## Project Structure

```
app/
  code/
    core/Mage/     # OpenMage LTS core modules
    local/         # Custom modules (MMD, Infortis, Aschroder)
    community/     # Community modules (Stripe, HitPay)
  design/          # Frontend/admin templates (.phtml)
  etc/             # Configuration (local.xml, modules/)
lib/               # Libraries (Varien, Zend, Magento)
skin/              # Theme assets (CSS, JS, images)
js/                # JavaScript libraries
docker/            # Docker configuration files
```

## Custom Modules

| Module | Purpose |
|--------|---------|
| MMD_Courses | Course/provider management |
| MMD_CustomOptions | Enhanced product options with SKU policies |
| MMD_Checkoutoptions | Custom checkout options |
| MMD_BankPayment | Bank transfer payment method |
| MMD_Enhancedsalesgrid | Admin sales grid enhancements |
| Infortis_Ultimo | Premium responsive theme |
| Aschroder_SMTPPro | SMTP email transport |
| Stripe_Payments | Stripe payment gateway |
| Hitpay_Pay | HitPay payment gateway |
# auto-deploy test
