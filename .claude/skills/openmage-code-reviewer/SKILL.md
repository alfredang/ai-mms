---
name: openmage-code-reviewer
description: Review OpenMage 1.x / Magento 1 LTS code in this LMS repo. Use when reviewing a PR, before committing custom-module changes, when asked "is this Magento-correct?", or proactively after writing PHP/XML/phtml in app/code/local/MMD/* or app/design/*. Covers OpenMage 1.x conventions (not Magento 2 — DI XML, service contracts, declare(strict_types) do NOT apply here). Enforces local-codepool overrides, ACL invariants, and migration patterns specific to this repo.
---

# OpenMage 1.x Code Reviewer (Tertiary Courses LMS)

You are reviewing code for an OpenMage 1.x LTS application on PHP 8.2. **Not Magento 2.** Modern Magento 2 conventions (`declare(strict_types=1)`, constructor property promotion, `di.xml`, service contracts, repositories, `db_schema.xml`) **do not apply**. Use OpenMage 1.x idioms.

## Hard rules — flag any violation as **Critical**

### 1. Never edit `app/code/core/`

If a diff touches `app/code/core/Mage/*` or `app/code/core/Zend/*`, reject the change. Even if it "works", core edits get reverted on `composer update` and pollute future merges.

**Correct alternatives**, in order of preference:
1. **Local codepool override**: same path under `app/code/local/Mage/...`. PHP's include path picks `local` before `core`.
2. **Class rewrite via config.xml**: in a custom module, add `<rewrite>` under `<global><models>` / `<blocks>` / `<helpers>` to redirect to your subclass. See `app/code/local/MMD/EmailLogin/etc/config.xml` for the canonical example (rewrites `admin/user`).
3. **Event observer**: hook the relevant `controller_action_predispatch`, `admin_session_user_login_success`, `model_save_before`, etc. See `app/code/local/MMD/RoleManager/Model/Observer.php`.
4. **Plugin via `app/etc/modules/`**: only as a last resort.

### 2. ACL invariant — `admin_rule.role_type` must equal `'G'` or `'U'`

`Mage_Admin_Model_Resource_Acl::loadRules` builds the Zend_Acl role identifier as `$rule['role_type'] . $rule['role_id']`. A NULL or empty `role_type` produces a phantom role that no user inherits from, and the rule is silently ignored. Any SQL migration that inserts into `admin_rule` MUST set `role_type='G'` (group) or `role_type='U'` (user). This bit us once — see migration 065.

### 3. Migrations live in `migrations/NNN-*.sql`, not in `Setup/Install`

OpenMage 1 ships an install/upgrade-script mechanism (`mysql4-install-*.php`, etc). This project **does not use it.** All schema/data changes go in `migrations/NNN-*.sql`, applied at container start by `migrations/apply.php`. The `schema_migrations` table tracks what's run.

If a PR adds `app/code/local/<Vendor>/<Module>/sql/<resource>/mysql4-install-*.php` or modifies `core_resource` directly, flag and propose moving the SQL into the migrations folder.

Rules for new migrations:
- **Idempotent**: `INSERT ... ON DUPLICATE KEY UPDATE`, `UPDATE` with sufficient `WHERE`, or `INSERT IGNORE`. The migration must be safe to re-run.
- **Resolve foreign keys via lookup**: never hardcode `store_id=2`. Use `WHERE code='malaysia'`. Store/website/role IDs differ between environments.
- **One concern per migration**: a single SQL file should do one logical change. Don't bundle ACL grants with store renames.
- **Numbered prefix matters**: take `ls migrations/ | tail -3` to find the next number. Don't skip numbers, don't reuse them.
- **Never name a table that may not exist on every instance — CRITICAL, this causes total outages.** `apply.php` aborts the whole chain on the first failed statement, so the container exits non-zero and **every route on the site 502s**, not just the affected page. The repeat offender is flat catalog: there is **no `catalog_category_flat` / `catalog_product_flat` table** (that name is the *indexer code*, valid only in PHP `Mage::getModel('index/process')->load(...)`). Flat data lives in per-store `catalog_category_flat_store_N`, and which exist differs per site. **Reject on sight**: a bare `catalog_category_flat`, or any `catalog_category_flat_store_N` not wrapped in an `information_schema` existence guard. Same applies to SG-only tables on partner DBs (`smtppro_email_log` etc). Real outage 2026-07-18 — migration 590 took SG and MY fully dark. Correct guarded form:

  ```sql
  SET @sql = IF((SELECT COUNT(*) FROM information_schema.TABLES
                 WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
    "UPDATE catalog_category_flat_store_1 SET name='X' WHERE name='Y'", 'DO 0');
  PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
  ```

  Often the right answer is to drop the flat write entirely and write EAV only, letting the post-deploy reindex propagate it.

### 4. Never commit credentials or runtime artefacts

Reject any diff that adds:
- `app/etc/local.xml` (the actual file — `local.xml.example` is fine)
- `.env` (the actual file — `.env.example` is fine)
- Anything under `media/wysiwyg/*.php`, `media/*.php` — these are upload directories; PHP files there are almost always webshells (we found `12345.php`, `cache.php`, `db.php`, `init.php` in the repo state on 2026-05-16 — they remain to be removed).
- `var/cache/`, `var/log/`, `var/session/` (covered by .gitignore but check additions).

## OpenMage 1 PHP idioms — what to expect, what to flag

### Models

```php
// Entity model
class MMD_Courses_Model_Course extends Mage_Core_Model_Abstract
{
    protected function _construct()
    {
        $this->_init('mmd_courses/course');  // alias → resource
    }
}

// Resource model
class MMD_Courses_Model_Resource_Course extends Mage_Core_Model_Resource_Db_Abstract
{
    protected function _construct()
    {
        $this->_init('mmd_courses/course', 'course_id');  // table alias, PK
    }
}

// Collection
class MMD_Courses_Model_Resource_Course_Collection extends Mage_Core_Model_Resource_Db_Collection_Abstract
{
    protected function _construct() { $this->_init('mmd_courses/course'); }
}
```

Flag if:
- Constructor is `public function __construct()` and chains parent — use `protected function _construct()` (note underscore, no parent call needed).
- Aliases use full class names — must be the resource alias defined in `config.xml`.
- Code instantiates via `new`. Use `Mage::getModel('mmd_courses/course')`, `Mage::getResourceModel(...)`, `Mage::getSingleton(...)`.

### Helpers

```php
class MMD_RoleManager_Helper_Data extends Mage_Core_Helper_Abstract
{
    public function getActiveRoleCode() { /* ... */ }
}
// Used as: Mage::helper('mmd_rolemanager')->getActiveRoleCode()
```

### Controllers (admin)

```php
class MMD_RoleManager_Adminhtml_RoleswitchController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed() { return Mage::getSingleton('admin/session')->isLoggedIn(); }
    public function switchAction() { /* ... */ }
}
```

Flag if:
- Missing `_isAllowed()` on adminhtml controllers — defaults to denying everything except `system`, often surfaces as "Access denied".
- POST handlers that don't validate form key. Use `$this->_validateFormKey()` or set `$_forcedFormKeyActions = ['switch'];`.
- Output uses `echo` or `print` — use `$this->getResponse()->setBody(...)` or template rendering.
- Output isn't escaped in templates: `<?= $escaper->escapeHtml($value) ?>` (OpenMage style) or `<?= $this->escapeHtml($value) ?>` — never raw echo of user input.

### Logging

`Mage::log('msg', Zend_Log::WARN, 'session_debug.log', true)` — note the **4th arg `$forceLog = true`** is required if `dev/log/active` is off (which it usually is in prod). Without it, the log call is silently dropped. We hit this debugging the cache-management bug.

### Database access

- Read: `$resource = Mage::getSingleton('core/resource'); $read = $resource->getConnection('core_read');`
- Write: `$resource->getConnection('core_write');`
- Table name: `$resource->getTableName('mmd_courses/course')` (always via alias).
- Parameterise: `$conn->quoteInto("WHERE id = ?", $id)`. Flag any raw `$conn->query("... $variable ...")` — SQL injection risk.

## Templates (`.phtml`)

- Escape all output. `$this->escapeHtml($x)`, `$this->escapeUrl($x)`, `$this->jsQuoteEscape($x)`.
- Don't put business logic in `.phtml`. Move to the Block class (`getMyData()`).
- Don't query the DB from a template. Move to the Block.
- Translations: `$this->__('Some text')`. Don't concatenate variables into translation strings — use `%s` placeholders: `$this->__('Hello %s', $name)`.

## Layout XML (`app/design/*/layout/*.xml`)

- Avoid editing core layout XML in `app/design/frontend/base/default/layout/`. Add a new XML file under your theme/module instead.
- Reference blocks by name, not by class path. `<reference name="content">` not `<block class="...">`.
- For admin theme overrides we use `app/design/adminhtml/default/default/template/*` — flag if someone adds a custom theme just to override one phtml.

## Performance red flags

- **DB query in a loop** — collection iteration is fine, but `Mage::getModel('foo/bar')->load($id)` inside a `foreach` is N+1. Use a single `Mage::getModel('foo/bar')->getCollection()->addFieldToFilter('id', ['in' => $ids])`.
- **`getCollection()->load()` then `count()`** — for counts, use `getSize()` (issues a separate COUNT query but doesn't load rows).
- **Catalog/product flat off** — don't introduce extra catalog joins without checking flat catalog config.
- **Cache types disabled** — any change that explicitly clears or disables `full_page_cache` / `block_html` cache without justification.

## Quick automated checks (run if relevant files are touched)

```bash
docker exec ai-mms-web-1 composer phpstan       # static analysis at the project's configured level
docker exec ai-mms-web-1 composer php-cs-fixer:fix  # code style
docker exec ai-mms-web-1 composer phpunit:test  # unit tests (mostly upstream OpenMage tests)
```

Note: this project's phpstan config is permissive — passing phpstan is not sufficient. Read the diff.

## Severity rubric

| Severity | Examples |
|----------|----------|
| **Critical** | Core file edit, missing `role_type='G'`, hardcoded credentials, SQL injection, missing form-key validation on POST, webshell in `media/` |
| **High** | N+1 query, missing `_isAllowed()` on admin controller, unescaped output in template, non-idempotent migration |
| **Medium** | Hardcoded store_id, business logic in template, missing translation, missing log on error path |
| **Low** | Style nits, missing docblock, inconsistent indentation |

## Report format

```
SUMMARY
- N critical, N high, N medium, N low issues
- Highest-leverage thing to fix first

[FILE: app/code/local/MMD/Foo/Bar.php]
- [Critical] Line 42: <issue>. <impact>. <suggested fix with code>.
- [High] Line 78: ...

[FILE: migrations/0NN-foo.sql]
- ...

OVERALL ASSESSMENT
- Ship / hold / revisit
```

Read the diff and write the review. Don't propose unrelated improvements; stay scoped to what changed.

## Don't

- Don't insist on Magento 2 patterns (DI XML, service contracts, repositories) for OpenMage 1 code.
- Don't propose `declare(strict_types=1)` everywhere — OpenMage 1 core doesn't use it and mixed strict-mode files cause subtle bugs.
- Don't require unit tests for every change — the project's test coverage is OpenMage-upstream; new tests are valuable but not blocking.
- Don't recommend extension marketplaces or unmaintained Magento 1 extensions. If a feature can be built locally in 50 lines, do that.
