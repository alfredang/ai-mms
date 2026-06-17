<?php
class MMD_RoleManager_Helper_Data extends Mage_Core_Helper_Abstract
{
    const ROLE_LEARNER           = 'learner';
    const ROLE_TRAINER           = 'trainer';
    const ROLE_MARKETING         = 'marketing';
    const ROLE_ADMIN             = 'admin';
    const ROLE_TRAINING_PROVIDER = 'training_provider';
    const ROLE_DEVELOPER         = 'developer';

    protected $_roleLabels = array(
        'learner'           => 'Learner',
        'trainer'           => 'Trainer',
        'developer'         => 'Developer',
        'marketing'         => 'Marketing',
        'admin'             => 'Admin',
        'training_provider' => 'Super Admin',
    );

    protected $_roleIcons = array(
        'learner'           => '&#x1F4DA;',  // 📚
        'trainer'           => '&#x1F468;&#x200D;&#x1F3EB;', // 👨‍🏫
        'developer'         => '&#x1F4BB;',  // 💻
        'marketing'         => '&#x1F4E3;',  // 📣
        'admin'             => '&#x2699;&#xFE0F;',  // ⚙️
        'training_provider' => '&#x1F6E1;&#xFE0F;',  // 🛡️
    );

    protected $_roleDescriptions = array(
        'learner'           => 'Access courses and track your learning progress',
        'trainer'           => 'Manage classes and grade assessments',
        'developer'         => 'System development and technical configuration',
        'marketing'         => 'Manage campaigns, promotions, and CMS',
        'admin'             => 'Manage users, classes, and system settings',
        'training_provider' => 'Full system access and configuration',
    );

    protected $_rolePriority = array(
        'learner'           => 1,
        'trainer'           => 2,
        'developer'         => 3,
        'marketing'         => 4,
        'admin'             => 5,
        'training_provider' => 6,
    );

    // Maps a role code to the admin_role group name (role_type='G') that
    // applyRoleAcl() should point the user's parent_id at. Group rows + their
    // admin_rule grants live in install-1.0.0.php / upgrade-1.0.0-1.1.0.php /
    // migration 031-developer-acl-group.sql. Note the asymmetry:
    // training_provider is labeled "Super Admin" everywhere in the UI and
    // gets the wildcard-grant Super Admin group, not the narrower
    // "Training Provider" group seeded in upgrade-1.0.0-1.1.0.php.
    protected $_roleAclGroup = array(
        'learner'           => 'Learner',
        'trainer'           => 'Trainer',
        'developer'         => 'Developer',
        'marketing'         => 'Marketing',
        'admin'             => 'Admin',
        'training_provider' => 'Super Admin',
    );

    public function getAllRoles()
    {
        return $this->_roleLabels;
    }

    public function getRoleLabel($code)
    {
        return isset($this->_roleLabels[$code]) ? $this->_roleLabels[$code] : $code;
    }

    public function getRoleIcon($code)
    {
        return isset($this->_roleIcons[$code]) ? $this->_roleIcons[$code] : '';
    }

    public function getRoleDescription($code)
    {
        return isset($this->_roleDescriptions[$code]) ? $this->_roleDescriptions[$code] : '';
    }

    public function getActiveRoleCode()
    {
        $session = Mage::getSingleton('admin/session');
        $code = $session->getActiveRoleCode();
        return $code ? $code : self::ROLE_ADMIN;
    }

    /**
     * Country / website scope of the logged-in admin.
     *
     * Detection convention: if the admin's email starts with
     * "admin.<cc>@" (e.g. admin.my@example.com, admin.gh@example.com)
     * we treat <cc> as the country code. Falls back to Singapore for
     * any account that doesn't match — keeps existing real admins
     * (angch@…, alisha.go.sihua@…, etc.) on the SG default they're
     * already used to.
     *
     * Used by the Assign Trainer / Assign Learner / Enroll Learner /
     * Create New Class panels so each market's admin sees their own
     * catalog instead of the global SG-only view.
     */
    /**
     * Resolution order:
     *   1. Active branch tab (MMD_Branchscope) — only if the user has
     *      explicitly picked one (store_id 1..7). store_id 0 (All) is
     *      treated as "no override" and falls through to the email
     *      heuristic so AJAX endpoints don't end up unscoped.
     *   2. Email prefix admin.<cc>@ → country code.
     *   3. Singapore default.
     */
    public function getActiveCountryCode()
    {
        // 0. Country instances have exactly one market. MMS_COUNTRY_CODE is
        //    authoritative — the Store View bar is hidden so there is no
        //    branchscope pick, and the seed admin email doesn't carry a
        //    country prefix, so both steps 1 and 2 would silently fall
        //    through to the SG default and stamp every class as SG.
        if (getenv('MMS_MODE') === 'country') {
            $cc    = strtoupper((string) getenv('MMS_COUNTRY_CODE'));
            $valid = array('MY', 'GH', 'NG', 'BT', 'IN');
            if (in_array($cc, $valid, true)) {
                return $cc;
            }
        }

        // 1. Branchscope session pick wins ONLY if the user explicitly
        //    picked a branch (URL ?store= or stored session value). The
        //    Branchscope default of Singapore is not enough to override
        //    an admin.my@... email — only a deliberate click does that.
        try {
            if (Mage::getConfig()->getNode('global/helpers/branchscope')) {
                $bs = Mage::helper('branchscope');
                if ($bs->hasExplicitChoice()) {
                    $storeId = (int) $bs->getActiveStoreId();
                    $reverse = array(1 => 'SG', 2 => 'MY', 3 => 'GH', 4 => 'NG', 5 => 'BT', 6 => 'IN');
                    if ($storeId > 0 && isset($reverse[$storeId])) {
                        return $reverse[$storeId];
                    }
                }
            }
        } catch (Exception $e) {
            // Fall through to email heuristic.
        }

        // 2. Email prefix.
        $user = Mage::getSingleton('admin/session')->getUser();
        if (!$user) return 'SG';
        $email = strtolower((string) $user->getEmail());
        if (preg_match('/^admin\.([a-z]{2})@/', $email, $m)) {
            $cc = strtoupper($m[1]);
            $valid = array('SG', 'MY', 'GH', 'NG', 'BT', 'IN');
            if (in_array($cc, $valid, true)) return $cc;
        }

        // 3. Default.
        return 'SG';
    }

    public function getActiveWebsiteId()
    {
        $map = array('SG' => 1, 'MY' => 2, 'GH' => 3, 'NG' => 4, 'BT' => 5, 'IN' => 6);
        $cc  = $this->getActiveCountryCode();
        return isset($map[$cc]) ? $map[$cc] : 1;
    }

    public function getActiveCountryName()
    {
        $names = array('SG' => 'Singapore', 'MY' => 'Malaysia', 'GH' => 'Ghana', 'NG' => 'Nigeria', 'BT' => 'Bhutan', 'IN' => 'India');
        $cc    = $this->getActiveCountryCode();
        return isset($names[$cc]) ? $names[$cc] : 'Singapore';
    }

    public function getActiveCountryRunPrefix()
    {
        $prefix = array('SG' => 'SG', 'MY' => 'MY', 'GH' => 'GH', 'NG' => 'NG', 'BT' => 'BT', 'IN' => 'IN');
        $cc     = $this->getActiveCountryCode();
        return isset($prefix[$cc]) ? $prefix[$cc] : 'SG';
    }

    /**
     * Country prefix for a product based on its primary website.
     * Drives the Run ID prefix (SG-100000, MY-100000, GH-100000…) so a
     * class created on the Malaysia catalog displays MY- on the trainer
     * card regardless of who's viewing it. Cached per request.
     */
    public function getRunIdPrefixForProduct($productId)
    {
        static $cache = array();
        $productId = (int) $productId;
        if (!$productId) return 'SG';
        if (isset($cache[$productId])) return $cache[$productId];
        try {
            $wid = (int) Mage::getSingleton('core/resource')->getConnection('core_read')->fetchOne(
                "SELECT website_id FROM catalog_product_website WHERE product_id=? ORDER BY website_id LIMIT 1",
                array($productId)
            );
            $widPrefix = $this->_getWebsiteIdToPrefixMap();
            $cache[$productId] = isset($widPrefix[$wid]) ? $widPrefix[$wid] : 'SG';
        } catch (Exception $e) {
            $cache[$productId] = 'SG';
        }
        return $cache[$productId];
    }

    /**
     * Per-country Run ID. Numbering resets per country, so the first
     * Malaysia class is MY-100000, first Ghana is GH-100000, etc. The
     * rank is computed by ordering course_runs.run_id ascending and
     * counting how many earlier runs share the same country website.
     * Built once per request and cached.
     */
    public function formatRunId($productId, $runId)
    {
        $productId = (int) $productId;
        $runId     = (int) $runId;
        $prefix    = $this->getRunIdPrefixForProduct($productId);
        $rank      = $this->_getPerCountryRunRank($runId);
        return $prefix . '-' . str_pad((string)(100000 + $rank), 6, '0', STR_PAD_LEFT);
    }

    /**
     * Marketing newsletter API config (Anthropic + MailerLite).
     *
     * Resolution order:
     *   1. core_config_data with path 'mmd_marketing/api/<key>' — what
     *      the Credentials admin UI writes to. Takes precedence so a
     *      key entered through the UI overrides whatever is in
     *      local.xml.
     *   2. <mmd_marketing><api><key> in app/etc/local.xml — original
     *      static config, kept as a fallback so existing deployments
     *      keep working.
     *   3. Hardcoded sensible defaults (from_name / from_email / model)
     *      when neither source has a value.
     *
     * Empty values flip the marketing controller into stub mode.
     */
    public function getMarketingApiConfig()
    {
        $node = Mage::getConfig()->getNode('global/mmd_marketing/api');
        $xmlGet = function ($key) use ($node) {
            return $node && $node->$key ? trim((string) $node->$key) : '';
        };
        $cfgGet = function ($key) {
            $val = (string) Mage::getStoreConfig('mmd_marketing/api/' . $key);
            return trim($val);
        };
        $resolve = function ($key) use ($cfgGet, $xmlGet) {
            $v = $cfgGet($key);
            if ($v !== '') return $v;
            return $xmlGet($key);
        };
        return array(
            'anthropic_key'   => $resolve('anthropic_key'),
            'anthropic_model' => $resolve('anthropic_model') ?: 'claude-sonnet-4-6',
            'mailerlite_key'  => $resolve('mailerlite_key'),
            'from_name'       => $resolve('from_name')  ?: 'Tertiary Infotech Academy',
            'from_email'      => $resolve('from_email') ?: 'noreply@tertiaryinfotech.com',
        );
    }

    public function hasAnthropicKey()
    {
        $cfg = $this->getMarketingApiConfig();
        return $cfg['anthropic_key'] !== '';
    }

    public function hasMailerLiteKey()
    {
        $cfg = $this->getMarketingApiConfig();
        return $cfg['mailerlite_key'] !== '';
    }

    protected function _getWebsiteIdToPrefixMap()
    {
        return array(1 => 'SG', 2 => 'MY', 3 => 'GH', 4 => 'NG', 5 => 'BT', 6 => 'IN', 7 => 'INF');
    }

    protected function _getPerCountryRunRank($runId)
    {
        static $rankByRunId = null;
        if ($rankByRunId === null) {
            $rankByRunId = array();
            try {
                $rows = Mage::getSingleton('core/resource')->getConnection('core_read')->fetchAll(
                    "SELECT cr.run_id, MIN(pw.website_id) AS wid
                     FROM course_runs cr
                     LEFT JOIN catalog_product_website pw ON pw.product_id = cr.product_id
                     GROUP BY cr.run_id
                     ORDER BY cr.run_id ASC"
                );
                $perCountry = array();
                foreach ($rows as $r) {
                    $wid = (int) $r['wid'];
                    if (!isset($perCountry[$wid])) $perCountry[$wid] = 0;
                    $rankByRunId[(int) $r['run_id']] = $perCountry[$wid];
                    $perCountry[$wid]++;
                }
            } catch (Exception $e) {}
        }
        return isset($rankByRunId[$runId]) ? $rankByRunId[$runId] : 0;
    }

    public function getUserRoles()
    {
        $session = Mage::getSingleton('admin/session');
        $roles = $session->getUserRoles();
        return is_array($roles) ? $roles : array(self::ROLE_ADMIN);
    }

    public function getUserRolesFromDb($userId)
    {
        try {
            $model = Mage::getModel('mmd_rolemanager/role_map');
            if (!$model) {
                return array(self::ROLE_ADMIN);
            }
            $collection = $model->getCollection()
                ->addFieldToFilter('user_id', $userId);

            $roles = array();
            foreach ($collection as $item) {
                $roles[] = $item->getRoleCode();
            }

            if (empty($roles)) {
                return array(self::ROLE_ADMIN);
            }

            $priorities = $this->_rolePriority;
            usort($roles, function ($a, $b) use ($priorities) {
                $pa = isset($priorities[$a]) ? $priorities[$a] : 0;
                $pb = isset($priorities[$b]) ? $priorities[$b] : 0;
                return $pa - $pb;
            });

            return $roles;
        } catch (Exception $e) {
            return array(self::ROLE_ADMIN);
        }
    }

    /**
     * Per-page role gate. Returns true if the user's CURRENT active role
     * (the one selected via View As / role-select) is in the allowed list,
     * AND they're logged in. Used by custom controllers to enforce role
     * restrictions on actions that don't map to standard Magento ACL
     * resources.
     *
     * Why this exists in addition to Magento's ACL: many of our custom
     * controllers (CoursesaveController, RolemanagementController, etc.)
     * historically had `_isAllowed() { return true; }`, which let any
     * authenticated admin hit them — including the role assignment UI,
     * which would have allowed a learner-only user to assign themselves
     * Super Admin via URL-typing.
     *
     * Also blocks switched roles correctly: a user with both admin and
     * learner roles, currently switched to Learner, won't pass an
     * isRoleAllowed(['admin']) check until they switch back via View As.
     *
     * @param string|array $allowedRoles single code or list of codes
     * @return bool
     */
    public function isRoleAllowed($allowedRoles)
    {
        if (!Mage::getSingleton('admin/session')->isLoggedIn()) {
            return false;
        }
        $allowedRoles = is_array($allowedRoles) ? $allowedRoles : array($allowedRoles);
        return in_array($this->getActiveRoleCode(), $allowedRoles, true);
    }

    public function applyRoleAcl($userId, $roleCode)
    {
        $resource  = Mage::getSingleton('core/resource');
        $write     = $resource->getConnection('core_write');
        $roleTable = $resource->getTableName('admin/role');

        // Resolve the ACL group for this role; fall back to Administrators
        // so a missing group row never locks an admin out.
        $groupName   = isset($this->_roleAclGroup[$roleCode])
            ? $this->_roleAclGroup[$roleCode]
            : 'Administrators';
        $groupRoleId = $write->fetchOne(
            "SELECT role_id FROM {$roleTable} WHERE role_name = ? AND role_type = 'G'",
            $groupName
        );

        if (!$groupRoleId && $groupName !== 'Administrators') {
            $groupRoleId = $write->fetchOne(
                "SELECT role_id FROM {$roleTable} WHERE role_name = 'Administrators' AND role_type = 'G'"
            );
        }

        if (!$groupRoleId) {
            return false;
        }

        // Update the user's existing 'U' row, OR create one if missing.
        // The 'U' row is what Magento's auth checks via hasAssigned2Role() —
        // a user without it is rejected at login regardless of how many
        // mmd_user_role_map entries they have. We explicitly upsert here
        // so users created via the custom Role Management UI (which only
        // writes to mmd_user_role_map) can actually log in.
        $existing = $write->fetchOne(
            "SELECT role_id FROM {$roleTable} WHERE user_id = ? AND role_type = 'U'",
            (int) $userId
        );
        if ($existing) {
            $write->update(
                $roleTable,
                array('parent_id' => $groupRoleId),
                $write->quoteInto("user_id = ? AND role_type = 'U'", (int) $userId)
            );
        } else {
            $user = Mage::getModel('admin/user')->load((int) $userId);
            $write->insert($roleTable, array(
                'parent_id'  => $groupRoleId,
                'tree_level' => 2,
                'sort_order' => 0,
                'role_type'  => 'U',
                'user_id'    => (int) $userId,
                'role_name'  => $user->getUsername() ?: ('user_' . $userId),
            ));
        }

        // Refresh the live session ACL only in a web (admin) request. In CLI
        // — cron sweeps, bulk trainer import — there is no admin session, and
        // touching admin/session there triggers a session_start error. The DB
        // 'U' row written above is all that login/auth actually needs.
        if (PHP_SAPI !== 'cli') {
            Mage::getSingleton('admin/session')->setAcl(Mage::getResourceModel('admin/acl')->loadAcl());
        }
        return true;
    }

    // -------------------------------------------------------------------------
    // Class ID allocation
    // -------------------------------------------------------------------------

    /**
     * Country-code prefix map: website_id → 2-letter code.
     * Must stay in sync with store setup and $_storeToCc2 in index.phtml.
     */
    public static $websiteToCountryCode = array(
        1 => 'SG', 2 => 'MY', 3 => 'GH', 4 => 'NG', 5 => 'BT', 6 => 'IN', 7 => 'SG',
    );

    /**
     * Compute the next available class_id for a given country prefix.
     *
     * Reads MAX(numeric suffix) from course_runs where class_id starts with $cc,
     * then returns $cc + zero-padded($max + 1).  The caller is responsible for
     * persisting the value; the UNIQUE KEY on course_runs.class_id is the
     * final guard against duplicates from concurrent inserts.
     *
     * @param  object $write      core_write DB connection
     * @param  string $runTable   fully-qualified table name for course_runs
     * @param  string $cc         two-letter country code (e.g. 'SG')
     * @return string             e.g. 'SG000042'
     */
    public static function nextClassId($write, $runTable, $cc)
    {
        $prefixLen = strlen($cc);
        $maxNo = (int) $write->fetchOne(
            "SELECT COALESCE(MAX(CAST(SUBSTRING(class_id, " . ($prefixLen + 1) . ") AS UNSIGNED)), 0)
               FROM `{$runTable}`
              WHERE class_id LIKE ?",
            array($cc . '%')
        );
        return $cc . str_pad($maxNo + 1, 6, '0', STR_PAD_LEFT);
    }

    /**
     * Resolve the country code for a product by looking up its primary website.
     *
     * Returns the code for the lowest website_id the product belongs to,
     * defaulting to 'SG' if the product has no website assignment.
     *
     * @param  object $read      core_read DB connection
     * @param  int    $productId
     * @param  int    $websiteId optional — skip the lookup if already known
     * @return string            two-letter country code
     */
    public static function countryCodeForProduct($read, $productId, $websiteId = 0)
    {
        if (!$websiteId) {
            $websiteId = (int) $read->fetchOne(
                "SELECT website_id FROM catalog_product_website WHERE product_id = ? ORDER BY website_id LIMIT 1",
                array((int) $productId)
            );
        }
        $map = self::$websiteToCountryCode;
        return isset($map[$websiteId]) ? $map[$websiteId] : 'SG';
    }
}
