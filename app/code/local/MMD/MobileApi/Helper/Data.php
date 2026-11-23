<?php
/**
 * Identity for the native learner apps: bearer tokens, email OTP and the
 * email + password check, plus the per-site facts the apps display.
 *
 * Who may sign in: anyone with a storefront customer account on THIS site, or
 * an active dashboard account holding the learner role — the same population
 * /lmslogin accepts for learners. Tokens and OTP codes are stored as SHA-256
 * hashes only (migration 1897).
 */
class MMD_MobileApi_Helper_Data extends Mage_Core_Helper_Abstract
{
    const TOKEN_TTL_DAYS   = 60;   // sliding: every request pushes expiry out
    const OTP_TTL          = 600;  // seconds — same as the web LMS
    const OTP_MAX_GUESSES  = 5;    // wrong codes per issued OTP
    const OTP_SENDS_EMAIL  = 3;    // per email per 10 minutes — same as the web LMS
    const OTP_SENDS_IP     = 20;   // per IP per hour (anti-spray)

    // ── Store-local time ─────────────────────────────────────────────────────

    /** Magento resets PHP to UTC; class dates are store-local. */
    public function today()
    {
        return Mage::getModel('core/date')->date('Y-m-d');
    }

    public function now()
    {
        return Mage::getModel('core/date')->date('Y-m-d H:i:s');
    }

    /** UTC timestamp for DB bookkeeping columns (sessions, OTPs). */
    public function utcNow($offsetSeconds = 0)
    {
        return gmdate('Y-m-d H:i:s', time() + $offsetSeconds);
    }

    // ── Site ─────────────────────────────────────────────────────────────────

    public function storeCode()
    {
        return (string) Mage::app()->getDefaultStoreView()->getCode();
    }

    /** SG / MY / GH from the store code (base = Singapore). */
    public function countryCode()
    {
        $code = $this->storeCode();
        if ($code === 'malaysia') return 'MY';
        if ($code === 'ghana')    return 'GH';
        $env = strtoupper((string) getenv('MMS_COUNTRY_CODE'));
        return in_array($env, array('MY', 'GH', 'NG'), true) ? $env : 'SG';
    }

    /**
     * The native TC LMS app for THIS site's country, for the store badges on the web
     * (learner login, admin login, top bar, storefront footer). A store is listed
     * only once the app is LIVE there, so a badge never leads to a missing listing:
     * leave a store's link '' until it is approved, then fill it in.
     * GH App Store: set 'ios' to https://apps.apple.com/app/id6830591693 once Apple approves it.
     */
    public function storeApp()
    {
        $apps = array(
            'SG' => array('name' => 'TC LMS SG', 'ios' => 'https://apps.apple.com/app/id6787036413',
                          'android' => 'https://play.google.com/store/apps/details?id=com.tertiaryinfotech.tertiarycoursesapp'),
            'MY' => array('name' => 'TC LMS MY', 'ios' => 'https://apps.apple.com/app/id6830591957',
                          'android' => 'https://play.google.com/store/apps/details?id=sg.com.tertiarycourses.tertiarycoursesmyapp'),
            'GH' => array('name' => 'TC LMS GH', 'ios' => '',
                          'android' => 'https://play.google.com/store/apps/details?id=sg.com.tertiarycourses.tertiarycoursesghapp'),
        );
        $cc = $this->countryCode();
        return isset($apps[$cc]) ? $apps[$cc] : null;
    }

    /**
     * App Store + Google Play badges for this site's app, as HTML ('' when the app has
     * no live store). $variant: 'nav' (compact, top bar), 'footer' (storefront footer)
     * or 'login' (under a sign-in form). Self-contained: its own scoped CSS.
     */
    public function appBadgesHtml($variant = 'nav')
    {
        $app = $this->storeApp();
        if (!$app || ($app['ios'] === '' && $app['android'] === '')) return '';
        $apple = <<<'SVG'
<svg viewBox="0 0 384 512" fill="currentColor" aria-hidden="true"><path d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C71.5 141.1 0 184.6 0 273.5c0 26.2 4.8 53.3 14.4 81.2 12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.9 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.9zM255.6 88.3c30.4-36.1 27.6-68.9 26.7-80.7-26.8 1.6-57.8 18.3-75.5 38.9-19.5 22.1-31 49.4-28.5 79.9 28.9 2.2 55.3-12.7 77.3-38.1z"/></svg>
SVG;
        $play = <<<'SVG'
<svg viewBox="0 0 512 512" aria-hidden="true"><path fill="#00D9FF" d="M47.6 24.6C41.2 31.3 37.5 41.7 37.5 55.2v401.6c0 13.5 3.7 23.9 10.1 30.6l1.3 1.3 225-225v-5.3l-225-225-1.3 1.2z"/><path fill="#FFD400" d="M348.2 336.9l-75-75v-5.3l75.1-75.1 1.7 1 88.9 50.5c25.4 14.4 25.4 38 0 52.5l-88.9 50.5-1.8.9z"/><path fill="#FF3A44" d="M349.9 335.9l-76.7-76.7L47.6 484.8c8.4 8.9 22.2 10 37.8 1.1l264.5-150z"/><path fill="#00C244" d="M349.9 176.1L85.4 26.1C69.8 17.2 56 18.3 47.6 27.2l225.6 225.6 76.7-76.7z"/></svg>
SVG;
        static $css = false;
        $style = '';
        if (!$css) {
            $css = true;
            $style = '<style>'
                . '.mmd-appb{display:inline-flex;flex-wrap:wrap;align-items:center;gap:8px;vertical-align:middle}'
                . '.mmd-appb-title{font-size:12px;opacity:.75;margin-right:2px;white-space:nowrap}'
                . '.mmd-appb a{display:inline-flex;align-items:center;gap:7px;min-height:34px;padding:4px 11px;border-radius:9px;background:#000;color:#fff!important;text-decoration:none!important;border:1px solid #3a3a3a;line-height:1.1}'
                . '.mmd-appb a:hover,.mmd-appb a:focus-visible{background:#1a1a1a}'
                . '.mmd-appb svg{width:18px;height:18px;flex:none}'
                . '.mmd-appb span{display:flex;flex-direction:column;text-align:left}'
                . '.mmd-appb small{font-size:8px;letter-spacing:.06em;text-transform:uppercase;opacity:.8;white-space:nowrap}'
                . '.mmd-appb strong{font-size:13px;font-weight:600;white-space:nowrap}'
                . '.mmd-appb-footer{margin:8px 0}.mmd-appb-footer a{min-height:40px}'
                . '.mmd-appb-login{margin-top:18px;justify-content:center;width:100%}'
                . '@media (max-width:1100px){.mmd-appb-nav .mmd-appb-title,.mmd-appb-nav small{display:none}}'
                . '</style>';
        }
        $h = $style . '<div class="mmd-appb mmd-appb-' . htmlspecialchars($variant) . '" aria-label="Get the mobile app">';
        $h .= '<span class="mmd-appb-title">Get the ' . htmlspecialchars($app['name']) . ' app</span>';
        if ($app['ios'] !== '') {
            $h .= '<a href="' . htmlspecialchars($app['ios']) . '" target="_blank" rel="noopener noreferrer" aria-label="Download on the App Store">'
                . $apple . '<span><small>Download on the</small><strong>App Store</strong></span></a>';
        }
        if ($app['android'] !== '') {
            $h .= '<a href="' . htmlspecialchars($app['android']) . '" target="_blank" rel="noopener noreferrer" aria-label="Get it on Google Play">'
                . $play . '<span><small>Get it on</small><strong>Google Play</strong></span></a>';
        }
        return $h . '</div>';
    }

    public function currencyCode()
    {
        $store = Mage::app()->getDefaultStoreView();
        return (string) ($store->getBaseCurrencyCode() ?: Mage::getStoreConfig('currency/options/base'));
    }

    public function siteInfo()
    {
        $store   = Mage::app()->getDefaultStoreView();
        $country = $this->countryCode();
        return array(
            'country'      => $country,
            'name'         => (string) Mage::getStoreConfig('general/store_information/name', $store) ?: 'Tertiary Courses',
            'website_url'  => rtrim((string) Mage::getStoreConfig('web/secure/base_url', $store), '/'),
            'currency'     => $this->currencyCode(),
            'timezone'     => (string) Mage::getStoreConfig('general/locale/timezone', $store),
            'phone'        => (string) Mage::getStoreConfig('general/store_information/phone', $store),
            'email'        => (string) Mage::getStoreConfig('trans_email/ident_general/email', $store),
            'academy'      => $country === 'MY' ? 'Tertiary Infotech Sdn. Bhd.' : (string) Mage::getStoreConfig('trans_email/ident_general/name', $store),
            // SG lists course fees before 9% GST; the partner sites list the payable fee.
            'price_note'   => $country === 'SG' ? 'before 9% GST' : '',
        );
    }

    // ── Accounts ─────────────────────────────────────────────────────────────

    public function normalizeEmail($email)
    {
        $email = strtolower(trim((string) $email));
        return filter_var($email, FILTER_VALIDATE_EMAIL) ? $email : '';
    }

    /** The storefront customer for this (single-store) site, or null. */
    public function loadCustomer($email)
    {
        try {
            $websiteId = (int) Mage::app()->getDefaultStoreView()->getWebsiteId();
            $customer  = Mage::getModel('customer/customer')->setWebsiteId($websiteId)->loadByEmail($email);
            return $customer->getId() ? $customer : null;
        } catch (Exception $e) {
            return null;
        }
    }

    /** The learner's dashboard (shadow) account, or null. */
    public function loadAdminUser($email)
    {
        $user = Mage::getModel('admin/user')->loadByUsername($email);
        if (!$user->getId()) {
            $id = (int) $this->_read()->fetchOne(
                'SELECT user_id FROM ' . $this->_table('admin/user') . ' WHERE email = ? LIMIT 1',
                array($email)
            );
            if ($id) $user = Mage::getModel('admin/user')->load($id);
        }
        return $user->getId() ? $user : null;
    }

    public function adminRoles($userId)
    {
        return (array) Mage::helper('mmd_rolemanager')->getUserRolesFromDb((int) $userId);
    }

    /** Can this email use the learner app on this site? */
    public function isLearner($email)
    {
        if ($this->loadCustomer($email)) {
            return true;
        }
        $user = $this->loadAdminUser($email);
        return $user && (int) $user->getIsActive() === 1 && in_array('learner', $this->adminRoles($user->getId()), true);
    }

    /**
     * How this email is matched to the classes it teaches — the same three
     * rules as the web LMS (MMD_Attendance_Helper_Data::_filterToTrainer):
     * the run's trainer account, the legacy trainer option whose
     * courses_trainers email is this one, or the trainer's full name.
     * Null when the email is not a trainer on this site.
     *
     * @return array{user_id:int, option_ids:int[], name:string}|null
     */
    public function trainerIdentity($email)
    {
        static $cache = array();
        if (array_key_exists($email, $cache)) {
            return $cache[$email];
        }
        $user   = $this->loadAdminUser($email);
        $active = $user && (int) $user->getIsActive() === 1;
        $optionIds = array();
        try {
            $optionIds = array_values(array_unique(array_filter(array_map('intval', $this->_read()->fetchCol(
                'SELECT relation_id FROM ' . $this->_table('courses_trainers') . ' WHERE LOWER(TRIM(email)) = ? AND status = 1',
                array($email)
            )))));
        } catch (Exception $e) {
            $optionIds = array();
        }
        $hasRole = $active && in_array('trainer', $this->adminRoles($user->getId()), true);
        if (!$hasRole && !$optionIds) {
            return $cache[$email] = null;
        }
        return $cache[$email] = array(
            'user_id'    => $active ? (int) $user->getId() : 0,
            'option_ids' => $optionIds,
            'name'       => $active ? strtolower(trim($user->getFirstname() . ' ' . $user->getLastname())) : '',
        );
    }

    public function isTrainer($email)
    {
        return $this->trainerIdentity($email) !== null;
    }

    /** Learners and trainers may sign in to the app. */
    public function canUseApp($email)
    {
        return $this->isLearner($email) || $this->isTrainer($email);
    }

    public function learnerProfile($email)
    {
        $customer = $this->loadCustomer($email);
        $user     = $this->loadAdminUser($email);
        $first = $customer ? (string) $customer->getFirstname() : ($user ? (string) $user->getFirstname() : '');
        $last  = $customer ? (string) $customer->getLastname()  : ($user ? (string) $user->getLastname()  : '');
        $pref  = $this->_profileRow($email);
        $phone = $user ? trim((string) $user->getTel()) : '';
        if ($phone === '' && $pref) {
            $phone = (string) $pref['phone'];
        }
        return array(
            'email'      => $email,
            'first_name' => $first,
            'last_name'  => $last,
            'full_name'  => trim($first . ' ' . $last),
            'phone'      => $phone,
            'theme'      => $pref && in_array($pref['theme'], $this->_themes, true) ? $pref['theme'] : 'system',
            'avatar_version' => $this->avatarVersion($email),
            'linkedin_url' => $user ? trim((string) $user->getData('linkedin_url')) : '',
            'employment_status' => $pref && isset($pref['employment_status']) ? (string) $pref['employment_status'] : '',
            'roles'      => array_merge(
                $this->isTrainer($email) ? array('learner', 'trainer') : array('learner'),
                $this->staffRoles($email)
            ),
        );
    }

    protected $_themes = array('system', 'light', 'dark');

    // ---- Admin sign-in with Google (native apps) ------------------------------

    /** The only accounts that may sign in to the apps with Google. Each must also be an active admin user. */
    protected $_googleAdmins = array('angch@tertiaryinfotech.com');

    public function mayUseGoogleAdminLogin($email)
    {
        $email = $this->normalizeEmail($email);
        if ($email === '' || !in_array($email, $this->_googleAdmins, true)) {
            return false;
        }
        $user = $this->loadAdminUser($email);
        return $user && $user->getId() && (int) $user->getIsActive() === 1;
    }

    /** This site's app URL scheme: tclmssg / tclmsmy / tclmsgh. Decided here, never taken from the request. */
    public function appScheme()
    {
        return 'tclms' . strtolower($this->countryCode());
    }

    /**
     * After Google has verified an allowed admin: a single-use code, valid two
     * minutes, that the app swaps for a session. It is tied to the challenge the
     * app sent when it started, so a code seen by anything else is useless.
     */
    public function saveGoogleCode($email, $challenge)
    {
        $code = bin2hex(random_bytes(32));
        Mage::app()->getCache()->save(
            json_encode(array('email' => $this->normalizeEmail($email), 'challenge' => (string) $challenge)),
            'mmd_mobile_gcode_' . hash('sha256', $code), array(), 120
        );
        return $code;
    }

    /** The email behind a code, once. Null when the code is unknown, used, expired, or the verifier does not match. */
    public function takeGoogleCode($code, $verifier)
    {
        $code = (string) $code; $verifier = (string) $verifier;
        if (!preg_match('/^[a-f0-9]{64}$/', $code) || strlen($verifier) < 32 || strlen($verifier) > 128) {
            return null;
        }
        $id  = 'mmd_mobile_gcode_' . hash('sha256', $code);
        $raw = Mage::app()->getCache()->load($id);
        Mage::app()->getCache()->remove($id);
        $row = $raw ? json_decode($raw, true) : null;
        if (!is_array($row) || empty($row['email']) || empty($row['challenge'])
            || !hash_equals((string) $row['challenge'], hash('sha256', $verifier))) {
            return null;
        }
        return $this->mayUseGoogleAdminLogin($row['email']) ? (string) $row['email'] : null;
    }

    /** Staff roles the apps have a dashboard for, in the order they are offered. */
    protected $_staffRoles = array('admin', 'marketing', 'developer', 'franchise_admin');

    /**
     * The staff roles this email holds on the website: read straight from
     * mmd_user_role_map for an ACTIVE admin account. (getUserRolesFromDb is not
     * used: it answers "admin" for an account with no rows.)
     */
    public function staffRoles($email)
    {
        try {
            $user = $this->loadAdminUser($email);
            if (!$user || !$user->getId() || !(int) $user->getIsActive()) {
                return array();
            }
            $have = $this->_read()->fetchCol(
                'SELECT role_code FROM ' . $this->_table('mmd_user_role_map') . ' WHERE user_id = ?', array((int) $user->getId())
            );
            $roles = array_values(array_intersect($this->_staffRoles, $have));
            // The franchise control centre exists on the Singapore site only.
            if ($this->countryCode() !== 'SG') {
                $roles = array_values(array_diff($roles, array('franchise_admin')));
            }
            return $roles;
        } catch (Exception $e) {
            return array();
        }
    }

    const MAX_CERTIFICATIONS = 30;

    /** A trainer's certifications, in the order they chose: [{name, issuer, year}]. */
    public function trainerCertifications($email)
    {
        try {
            $rows = $this->_read()->fetchAll(
                'SELECT name, issuer, year FROM ' . $this->_table('mmd_trainer_certification')
                . ' WHERE email = ? ORDER BY sort_order, id', array(strtolower($email))
            );
        } catch (Exception $e) {
            return array();   // table not migrated yet
        }
        foreach ($rows as &$r) {
            $r['year'] = $r['year'] ? (int) $r['year'] : null;
        }
        return $rows;
    }

    /** Replaces the whole list. Returns the cleaned list; throws a readable Exception on bad input. */
    public function saveTrainerCertifications($email, array $items)
    {
        $email = strtolower(trim($email));
        $clean = array();
        $maxYear = (int) gmdate('Y') + 1;
        foreach ($items as $it) {
            $name   = trim(preg_replace('/\s+/', ' ', strip_tags((string) (isset($it['name']) ? $it['name'] : ''))));
            $issuer = trim(preg_replace('/\s+/', ' ', strip_tags((string) (isset($it['issuer']) ? $it['issuer'] : ''))));
            $year   = trim((string) (isset($it['year']) ? $it['year'] : ''));
            if ($name === '' && $issuer === '' && $year === '') {
                continue;
            }
            if ($name === '') {
                throw new Exception('Each certification needs a name.');
            }
            if (mb_strlen($name) > 160 || mb_strlen($issuer) > 120) {
                throw new Exception('A certification name or issuer is too long.');
            }
            if ($year !== '' && (!ctype_digit($year) || (int) $year < 1950 || (int) $year > $maxYear)) {
                throw new Exception('"' . $name . '": the year must be between 1950 and ' . $maxYear . ', or left blank.');
            }
            $clean[] = array('name' => $name, 'issuer' => $issuer, 'year' => $year === '' ? null : (int) $year);
        }
        if (count($clean) > self::MAX_CERTIFICATIONS) {
            throw new Exception('You can list up to ' . self::MAX_CERTIFICATIONS . ' certifications.');
        }
        $w = $this->_write();
        $tbl = $this->_table('mmd_trainer_certification');
        $w->beginTransaction();
        try {
            $w->delete($tbl, array('email = ?' => $email));
            foreach ($clean as $i => $c) {
                $w->insert($tbl, array(
                    'email' => $email, 'name' => $c['name'], 'issuer' => $c['issuer'],
                    'year' => $c['year'], 'sort_order' => $i, 'updated_at' => $this->utcNow(),
                ));
            }
            $w->commit();
        } catch (Exception $e) {
            $w->rollBack();
            throw $e;
        }
        return $clean;
    }

    /** Web form text -> items. One per line: "Name | Issuer | Year" (issuer and year optional). */
    public function parseCertificationLines($text)
    {
        $items = array();
        foreach (preg_split('/\r\n|\r|\n/', (string) $text) as $line) {
            if (trim($line) === '') continue;
            $parts = array_map('trim', explode('|', $line));
            $items[] = array('name' => $parts[0], 'issuer' => isset($parts[1]) ? $parts[1] : '', 'year' => isset($parts[2]) ? $parts[2] : '');
        }
        return $items;
    }

    /** Unix time the picture was last set, or null when the account has none. */
    public function avatarVersion($email)
    {
        try {
            $at = $this->_read()->fetchOne(
                'SELECT avatar_at FROM ' . $this->_table('mmd_mobile_profile') . ' WHERE email = ? AND avatar IS NOT NULL LIMIT 1', array($email)
            );
            if ($at) return (int) strtotime($at . ' UTC');
        } catch (Exception $e) {
            // column not migrated yet
        }
        $def = $this->defaultAvatarFile($email);
        return $def ? (int) filemtime($def) : null;
    }

    /**
     * The picture a trainer or staff account already has on the website (the LinkedIn
     * image the TIA TMS sync stores), used until the person sets their own: the
     * dashboard profile picture, else the trainer record's. Null when there is none.
     */
    public function defaultAvatarFile($email)
    {
        $media = Mage::getBaseDir('media');
        $names = array();
        try {
            $names[] = array('admin/profile', (string) $this->_read()->fetchOne(
                'SELECT profile_image FROM ' . $this->_table('admin/user') . ' WHERE email = ? LIMIT 1', array($email)));
            $img = (string) $this->_read()->fetchOne(
                'SELECT profile_image FROM ' . $this->_table('courses_trainers') . ' WHERE email = ? LIMIT 1', array($email));
            $names[] = array('trainers', $img);
            $names[] = array('providers', $img);
        } catch (Exception $e) {
            return null;
        }
        foreach ($names as $n) {
            $file = basename(trim($n[1]));          // a stored value may be a path or a full URL: the file name is enough
            if ($file === '' || $file === '.' || $file === '..' || !preg_match('/\.(jpe?g|png|webp|gif)$/i', $file)) continue;
            $path = $media . '/' . $n[0] . '/' . $file;
            if (is_file($path) && filesize($path) > 0) return $path;
        }
        return null;
    }

    public function avatarBytes($email)
    {
        try {
            $b = $this->_read()->fetchOne(
                'SELECT avatar FROM ' . $this->_table('mmd_mobile_profile') . ' WHERE email = ? LIMIT 1', array($email)
            );
            if ($b) return (string) $b;
        } catch (Exception $e) {
            // column not migrated yet
        }
        $def = $this->defaultAvatarFile($email);
        if (!$def) return null;
        $raw = @file_get_contents($def);
        if ($raw === false || !function_exists('imagecreatefromstring') || !($src = @imagecreatefromstring($raw))) return null;
        $w = imagesx($src); $h = imagesy($src); $side = min($w, $h);
        $dst = imagecreatetruecolor(512, 512);
        imagefill($dst, 0, 0, imagecolorallocate($dst, 255, 255, 255));
        imagecopyresampled($dst, $src, 0, 0, (int) (($w - $side) / 2), (int) (($h - $side) / 2), 512, 512, $side, $side);
        ob_start(); imagejpeg($dst, null, 85); $jpeg = ob_get_clean();
        imagedestroy($src); imagedestroy($dst);
        return $jpeg ?: null;
    }

    /** Re-encodes an uploaded picture to a 512px JPEG (drops metadata and anything that is not an image) and stores it. */
    public function saveAvatar($email, $raw)
    {
        if (strlen($raw) > 6 * 1024 * 1024 || !function_exists('imagecreatefromstring')) {
            throw new Exception('That picture is too large. Please choose a smaller one.');
        }
        $info = @getimagesizefromstring($raw);
        if (!$info || !in_array($info[2], array(IMAGETYPE_JPEG, IMAGETYPE_PNG, IMAGETYPE_GIF, IMAGETYPE_WEBP), true)
            || $info[0] * $info[1] > 40000000) {
            throw new Exception('Please choose a JPEG or PNG picture.');
        }
        $src = @imagecreatefromstring($raw);
        if (!$src) {
            throw new Exception('Please choose a JPEG or PNG picture.');
        }
        $w = imagesx($src); $h = imagesy($src);
        $side = min($w, $h);                       // centre square crop
        $dst = imagecreatetruecolor(512, 512);
        imagefill($dst, 0, 0, imagecolorallocate($dst, 255, 255, 255));
        imagecopyresampled($dst, $src, 0, 0, (int) (($w - $side) / 2), (int) (($h - $side) / 2), 512, 512, $side, $side);
        ob_start();
        imagejpeg($dst, null, 85);
        $jpeg = ob_get_clean();
        imagedestroy($src); imagedestroy($dst);
        $this->_write()->insertOnDuplicate(
            $this->_table('mmd_mobile_profile'),
            array('email' => $email, 'avatar' => $jpeg, 'avatar_at' => $this->utcNow(), 'updated_at' => $this->utcNow()),
            array('avatar', 'avatar_at', 'updated_at')
        );
    }

    public function clearAvatar($email)
    {
        try {
            $this->_write()->update($this->_table('mmd_mobile_profile'),
                array('avatar' => null, 'avatar_at' => null), array('email = ?' => $email));
        } catch (Exception $e) {
        }
    }

    /**
     * Update the signed-in person's own name, phone and appearance. Only the
     * keys present in $in change. Throws with a user-facing message.
     */
    public function saveProfile($email, array $in)
    {
        $clean = function ($v, $max) {
            return mb_substr(trim(preg_replace('/\s+/u', ' ', strip_tags((string) $v))), 0, $max);
        };
        $names = array();
        foreach (array('first_name' => 'firstname', 'last_name' => 'lastname') as $key => $col) {
            if (!array_key_exists($key, $in)) continue;
            $v = $clean($in[$key], 32);
            if ($v === '') {
                throw new Exception($key === 'first_name' ? 'Please enter your first name.' : 'Please enter your last name.');
            }
            $names[$col] = $v;
        }
        $phone = null;
        if (array_key_exists('phone', $in)) {
            $phone = trim((string) $in['phone']);
            if ($phone !== '' && !preg_match('/^\+?[0-9 ()\-]{6,20}$/', $phone)) {
                throw new Exception('Please enter a valid phone number.');
            }
        }
        $theme = null;
        if (array_key_exists('theme', $in)) {
            $theme = strtolower(trim((string) $in['theme']));
            if (!in_array($theme, $this->_themes, true)) {
                throw new Exception('Please choose System, Light or Dark.');
            }
        }

        $employment = null;
        if (array_key_exists('employment_status', $in)) {
            $employment = trim((string) $in['employment_status']);
            if ($employment !== '' && !in_array($employment, array('Employed', 'Unemployed', 'Looking for Job'), true)) {
                throw new Exception('Please choose Employed, Unemployed or Looking for Job.');
            }
        }

        $user = $this->loadAdminUser($email);
        if ($names) {
            $customer = $this->loadCustomer($email);
            if ($customer) {
                if (isset($names['firstname'])) $customer->setFirstname($names['firstname']);
                if (isset($names['lastname']))  $customer->setLastname($names['lastname']);
                $customer->save();
            }
            if ($user) {
                $this->_write()->update($this->_table('admin/user'), $names, array('user_id = ?' => (int) $user->getId()));
            }
        }
        if ($phone !== null && $user) {
            $this->_write()->update($this->_table('admin/user'), array('tel' => $phone), array('user_id = ?' => (int) $user->getId()));
        }
        if (array_key_exists('linkedin_url', $in) && $user) {
            $link = trim((string) $in['linkedin_url']);
            if ($link !== '' && !preg_match('#^https://([a-z]{2,3}\.)?linkedin\.com/[A-Za-z0-9\-_/%.]+$#', $link)) {
                throw new Exception('Please enter your LinkedIn profile link, starting with https://www.linkedin.com/');
            }
            $link = $link === '' ? null : mb_substr($link, 0, 255);
            $this->_write()->update($this->_table('admin/user'), array('linkedin_url' => $link), array('user_id = ?' => (int) $user->getId()));
            // The trainer card on the storefront reads courses_trainers; keep it the same.
            $this->_write()->update($this->_table('courses_trainers'), array('linkedin_url' => $link), array('email = ?' => $email));
        }
        if ($theme !== null || $phone !== null || $employment !== null) {
            $row = array('email' => $email, 'updated_at' => $this->utcNow());
            $upd = array('updated_at');
            if ($employment !== null) { $row['employment_status'] = $employment === '' ? null : $employment; $upd[] = 'employment_status'; }
            if ($theme !== null) { $row['theme'] = $theme; $upd[] = 'theme'; }
            if ($phone !== null) { $row['phone'] = $phone; $upd[] = 'phone'; }
            $this->_write()->insertOnDuplicate($this->_table('mmd_mobile_profile'), $row, $upd);
        }
        return $this->learnerProfile($email);
    }

    protected function _profileRow($email)
    {
        try {
            return $this->_read()->fetchRow(
                'SELECT * FROM ' . $this->_table('mmd_mobile_profile') . ' WHERE email = ? LIMIT 1', array($email)
            ) ?: null;
        } catch (Exception $e) {
            return null;   // table not migrated yet
        }
    }

    public function isDemoEmail($email)
    {
        $list = array_filter(array_map(function ($e) {
            return strtolower(trim($e));
        }, explode(',', (string) Mage::getStoreConfig('mmd_mobileapi/general/demo_emails'))));
        return in_array($email, $list, true);
    }

    /**
     * Email + password. Checks the storefront account first (the learner's own
     * credentials), then the dashboard account for learner-role users without a
     * storefront account. Shares the web LMS's per-email lockout.
     * Returns the email on success; throws with a user-facing message.
     */
    public function authenticatePassword($email, $password)
    {
        $email = $this->normalizeEmail($email);
        if ($email === '' || (string) $password === '') {
            throw new Exception('Please enter your email and password.');
        }
        if (MMD_EmailLogin_Model_User::isLoginLocked($email)) {
            throw new Exception(MMD_EmailLogin_Model_User::LOCK_MESSAGE);
        }

        // App Review account: no customer record, bcrypt hash in config (migration 1897).
        if ($this->isDemoEmail($email)) {
            $hash = (string) Mage::getStoreConfig('mmd_mobileapi/general/demo_password_hash');
            if ($hash === '' || !password_verify((string) $password, $hash)) {
                MMD_EmailLogin_Model_User::recordLoginFailure($email);
                throw new Exception('Your email or password is incorrect.');
            }
            MMD_EmailLogin_Model_User::clearLoginFailures($email);
            return $email;
        }

        $ok = false;
        $customer = $this->loadCustomer($email);
        if ($customer) {
            try {
                $ok = (bool) $customer->authenticate($email, $password);
            } catch (Exception $e) {
                $ok = false;   // unconfirmed / bad password — same answer
            }
        }
        if (!$ok) {
            $user = $this->loadAdminUser($email);
            if ($user && (int) $user->getIsActive() === 1
                && array_intersect(array('learner', 'trainer'), $this->adminRoles($user->getId()))
                && Mage::helper('core')->validateHash($password, (string) $user->getPassword())) {
                $ok = true;
            }
        }
        if (!$ok) {
            MMD_EmailLogin_Model_User::recordLoginFailure($email);
            throw new Exception('Your email or password is incorrect.');
        }
        MMD_EmailLogin_Model_User::clearLoginFailures($email);
        return $email;
    }

    // ── Email OTP ────────────────────────────────────────────────────────────

    protected function _otpHash($email, $code)
    {
        return hash('sha256', $email . '|' . $code . '|' . (string) Mage::getConfig()->getNode('global/crypt/key'));
    }

    /**
     * Email a 6-digit login code. Always "succeeds" for a well-formed email so
     * the endpoint cannot be used to discover which emails have accounts.
     * Throws only for a malformed email or when rate-limited.
     */
    public function sendOtp($email, $ip)
    {
        $email = $this->normalizeEmail($email);
        if ($email === '') {
            throw new Exception('Please enter a valid email address.');
        }
        $tbl  = $this->_table('mmd_mobile_otp');
        $read = $this->_read();
        $sentToEmail = (int) $read->fetchOne(
            "SELECT COUNT(*) FROM `$tbl` WHERE email = ? AND created_at > ?",
            array($email, $this->utcNow(-600))
        );
        $sentFromIp = $ip === '' ? 0 : (int) $read->fetchOne(
            "SELECT COUNT(*) FROM `$tbl` WHERE ip = ? AND created_at > ?",
            array($ip, $this->utcNow(-3600))
        );
        if ($sentToEmail >= self::OTP_SENDS_EMAIL || $sentFromIp >= self::OTP_SENDS_IP) {
            throw new Exception('Too many codes requested. Please try again in a few minutes.');
        }

        // The App Review account signs in with its password; never mail it codes.
        if ($this->isDemoEmail($email) || !$this->canUseApp($email)) {
            return;
        }

        $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $this->_write()->insert($tbl, array(
            'email'      => $email,
            'code_hash'  => $this->_otpHash($email, $code),
            'ip'         => $ip !== '' ? substr($ip, 0, 64) : null,
            'created_at' => $this->utcNow(),
            'expires_at' => $this->utcNow(self::OTP_TTL),
        ));

        $profile  = $this->learnerProfile($email);
        $site     = $this->siteInfo();
        $subject  = 'Your login code - ' . $site['name'];
        $fromName = (string) Mage::getStoreConfig('trans_email/ident_general/name');
        $fromMail = (string) Mage::getStoreConfig('trans_email/ident_general/email');
        $bodyHtml =
            '<p>Hi ' . htmlspecialchars($profile['first_name'] ?: 'there') . ',</p>' .
            '<p>Your one-time code for the ' . htmlspecialchars($site['name']) . ' learner app is: '
            . '<strong style="font-size:18px;letter-spacing:2px;">' . $code . '</strong></p>' .
            '<p>This code expires in 10 minutes.<br>' .
            'If you did not request this, please ignore this email.</p>' .
            '<p>— ' . htmlspecialchars($site['academy']) . '</p>';
        try {
            $gmail = Mage::helper('mmd_email/gmail');
            if ($gmail && $gmail->isConfigured()) {
                $gmail->send($email, $subject, $bodyHtml, $fromName);
            } else {
                Mage::getModel('core/email')
                    ->setToEmail($email)->setToName($profile['full_name'])
                    ->setSubject($subject)
                    ->setBody(strip_tags(str_replace('<br>', "\n", $bodyHtml)))
                    ->setFromEmail($fromMail)->setFromName($fromName)->setType('text')
                    ->send();
            }
        } catch (Exception $e) {
            Mage::logException($e);
        }
    }

    /** Check a code against the newest live OTP. Returns the email; throws on failure. */
    public function verifyOtp($email, $code)
    {
        $email = $this->normalizeEmail($email);
        $code  = preg_replace('/\D/', '', (string) $code);
        if ($email === '' || strlen($code) !== 6) {
            throw new Exception('Please enter the 6-digit code from your email.');
        }
        $tbl = $this->_table('mmd_mobile_otp');
        $row = $this->_read()->fetchRow(
            "SELECT * FROM `$tbl` WHERE email = ? AND consumed_at IS NULL AND expires_at > ?
              ORDER BY otp_id DESC LIMIT 1",
            array($email, $this->utcNow())
        );
        if (!$row || (int) $row['attempts'] >= self::OTP_MAX_GUESSES) {
            throw new Exception('This code has expired. Please request a new one.');
        }
        if (!hash_equals((string) $row['code_hash'], $this->_otpHash($email, $code))) {
            $this->_write()->query("UPDATE `$tbl` SET attempts = attempts + 1 WHERE otp_id = ?", array((int) $row['otp_id']));
            throw new Exception('That code is incorrect. Please check your email and try again.');
        }
        // Single use: the conditional update wins only once under a race.
        $n = $this->_write()->update($tbl, array('consumed_at' => $this->utcNow()),
            array('otp_id = ?' => (int) $row['otp_id'], 'consumed_at IS NULL'));
        if (!$n) {
            throw new Exception('This code has already been used. Please request a new one.');
        }
        return $email;
    }

    // ── Bearer sessions ──────────────────────────────────────────────────────

    public function issueToken($email, $platform = '', $appVersion = '')
    {
        $token    = bin2hex(random_bytes(32));
        $customer = $this->loadCustomer($email);
        $this->_write()->insert($this->_table('mmd_mobile_session'), array(
            'token_hash'   => hash('sha256', $token),
            'email'        => $email,
            'customer_id'  => $customer ? (int) $customer->getId() : null,
            'is_demo'      => $this->isDemoEmail($email) ? 1 : 0,
            'platform'     => $platform !== '' ? substr(strtolower($platform), 0, 16) : null,
            'app_version'  => $appVersion !== '' ? substr($appVersion, 0, 32) : null,
            'created_at'   => $this->utcNow(),
            'last_used_at' => $this->utcNow(),
            'expires_at'   => $this->utcNow(self::TOKEN_TTL_DAYS * 86400),
        ));
        return $token;
    }

    /** The live session row for a bearer token, or null. Slides the expiry. */
    public function sessionForToken($token)
    {
        $token = trim((string) $token);
        if (!preg_match('/^[a-f0-9]{64}$/', $token)) {
            return null;
        }
        $tbl = $this->_table('mmd_mobile_session');
        $row = $this->_read()->fetchRow(
            "SELECT * FROM `$tbl` WHERE token_hash = ? AND revoked_at IS NULL AND expires_at > ? LIMIT 1",
            array(hash('sha256', $token), $this->utcNow())
        );
        if (!$row) {
            return null;
        }
        // A learner removed from the site since sign-in loses access at once.
        if (!(int) $row['is_demo'] && !$this->canUseApp($row['email'])) {
            $this->revokeAll($row['email']);
            return null;
        }
        if (strtotime($row['last_used_at']) < time() - 3600) {
            $this->_write()->update($tbl, array(
                'last_used_at' => $this->utcNow(),
                'expires_at'   => $this->utcNow(self::TOKEN_TTL_DAYS * 86400),
            ), array('session_id = ?' => (int) $row['session_id']));
        }
        return $row;
    }

    public function revokeToken($token)
    {
        $this->_write()->update($this->_table('mmd_mobile_session'),
            array('revoked_at' => $this->utcNow()),
            array('token_hash = ?' => hash('sha256', trim((string) $token)), 'revoked_at IS NULL'));
    }

    public function revokeAll($email)
    {
        $this->_write()->update($this->_table('mmd_mobile_session'),
            array('revoked_at' => $this->utcNow()),
            array('email = ?' => $email, 'revoked_at IS NULL'));
    }

    // ── Account deletion (App Store 5.1.1(v) / Play account-deletion policy) ──

    /**
     * Delete the learner's login account: the storefront customer and its
     * learner-only dashboard shadow account, and every app session. Training
     * records the academy must keep (registrations/invoices, attendance,
     * certificates) are retained, keyed by email as before. Staff accounts
     * (any role besides learner) are never deleted from the app.
     */
    public function deleteAccount($email)
    {
        $user = $this->loadAdminUser($email);
        if ($user) {
            $others = array_diff($this->adminRoles($user->getId()), array('learner'));
            if ($others) {
                throw new Exception('This email is also a staff account and cannot be deleted from the app. Please contact us to close it.');
            }
        }
        $this->revokeAll($email);

        $customer = $this->loadCustomer($email);
        if ($customer) {
            Mage::register('isSecureArea', true, true);
            try {
                $customer->delete();
            } catch (Exception $e) {
                Mage::unregister('isSecureArea');
                throw $e;
            }
            Mage::unregister('isSecureArea');
        }
        if ($user) {
            $this->_write()->delete($this->_table('mmd_user_role_map'), array('user_id = ?' => (int) $user->getId()));
            $user->delete();
        }
        Mage::log('Learner app account deletion: ' . md5($email), Zend_Log::INFO, 'mmd_mobileapi.log', true);
    }

    // ── DB ───────────────────────────────────────────────────────────────────

    public function _read()
    {
        return Mage::getSingleton('core/resource')->getConnection('core_read');
    }

    public function _write()
    {
        return Mage::getSingleton('core/resource')->getConnection('core_write');
    }

    public function _table($name)
    {
        return Mage::getSingleton('core/resource')->getTableName($name);
    }
}
