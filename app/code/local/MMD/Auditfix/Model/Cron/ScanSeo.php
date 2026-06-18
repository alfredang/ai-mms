<?php
/**
 * MMD_Auditfix_Model_Cron_ScanSeo
 *
 * Daily 02:00. Heuristic SEO scan + low-risk auto-fix.
 *
 * Auto-fix scope (low risk, DB-only, store_id=0):
 *   - Empty meta_description on enabled, visible catalog products
 *     → backfill from short_description / description, capped 160 chars.
 *
 * Flag-only (status=open, no auto-fix):
 *   - Empty meta_title (might be deliberate; copywriter to decide).
 *   - Suspiciously short product name (< 10 chars) — possible SEO weakness.
 */
class MMD_Auditfix_Model_Cron_ScanSeo extends MMD_Auditfix_Model_Cron_AbstractScanner
{
    const AUTOFIX_LIMIT = 200;    // safety cap per run
    const FLAG_LIMIT    = 500;
    const META_DESC_MAX = 160;
    const SEGMENT_PER_STORE_LIMIT = 300;

    /** Per-store brand suffix + funding hooks. Mirrors the (now retired)
     *  MMD_Seoaudit profiles so the unified Audit Issues page reports the
     *  same segment-aware findings. Keyed by Magento store code. */
    protected $_storeProfiles = array(
        'singapore' => array('suffix' => '| Tertiary Courses Singapore', 'funding' => array('SkillsFuture', 'SFEC', 'UTAP', 'WSQ', 'Absentee Payroll', 'PSEA', 'IBF', 'MCES')),
        'nigeria'   => array('suffix' => '| Tertiary Courses Nigeria',   'funding' => array()),
    );

    protected function scannerCode() { return 'scan_seo'; }

    protected function scan()
    {
        // IMPORTANT: this scanner is flag-only. Per the seo-audit skill,
        // product `name`, `meta_title`, and `meta_description` are sacred —
        // never mutate them from cron, and never auto-resolve SEO findings
        // (a copywriter must decide). Severity is set so even "low" rows
        // stay visible: nothing in this scanner gets the low-risk sweep.
        $logged = 0; $fixed = 0;

        // ---- Flag: empty meta_description --------------------------------
        $missingDesc = Mage::getResourceModel('catalog/product_collection')
            ->addAttributeToSelect(array('name', 'meta_description'))
            ->addAttributeToFilter('status', Mage_Catalog_Model_Product_Status::STATUS_ENABLED)
            ->addAttributeToFilter('visibility', array('neq' => Mage_Catalog_Model_Product_Visibility::VISIBILITY_NOT_VISIBLE))
            ->addAttributeToFilter(array(
                array('attribute' => 'meta_description', 'null'   => true),
                array('attribute' => 'meta_description', 'eq'     => ''),
            ), null, 'left')
            ->setPageSize(self::FLAG_LIMIT);

        foreach ($missingDesc as $p) {
            $this->helper()->logIssue(array(
                'source' => 'cron_scan_seo', 'category' => 'seo', 'severity' => 'medium',
                'title' => 'Missing meta_description',
                'entity_type' => 'product', 'entity_id' => (int)$p->getId(),
                'detail' => 'SKU ' . $p->getSku() . ' — name="' . $p->getName() . '". Copywriter must add a 120–170 char meta description via Catalog → Edit Course → SEO. (Auto-fix disabled per the seo-audit skill — meta fields are not auto-written.)',
            ));
            $logged++;
        }

        // ---- Flag: empty meta_title --------------------------------------
        $missingTitle = Mage::getResourceModel('catalog/product_collection')
            ->addAttributeToSelect(array('name', 'meta_title'))
            ->addAttributeToFilter('status', Mage_Catalog_Model_Product_Status::STATUS_ENABLED)
            ->addAttributeToFilter('visibility', array('neq' => Mage_Catalog_Model_Product_Visibility::VISIBILITY_NOT_VISIBLE))
            ->addAttributeToFilter(array(
                array('attribute' => 'meta_title', 'null' => true),
                array('attribute' => 'meta_title', 'eq'   => ''),
            ), null, 'left')
            ->setPageSize(self::FLAG_LIMIT);

        foreach ($missingTitle as $p) {
            $this->helper()->logIssue(array(
                'source' => 'cron_scan_seo', 'category' => 'seo', 'severity' => 'medium',
                'title' => 'Missing meta_title',
                'entity_type' => 'product', 'entity_id' => (int)$p->getId(),
                'detail' => 'SKU ' . $p->getSku() . ' — name="' . $p->getName() . '". Add via Catalog → Edit Course → SEO. Title must end with the country brand suffix and follow segment rules in the seo-audit skill §4a.',
            ));
            $logged++;
        }

        // ---- Per-store segment-aware checks (replaces the standalone SEO
        //      Audit page, retired from the Marketing sidebar 2026-05-29).
        //      Mirrors the seo-audit skill §4a hard rules. Flag-only,
        //      never mutates a product.
        foreach (Mage::app()->getStores() as $store) {
            if (!$store->getIsActive()) continue;
            $logged += $this->scanStore((int)$store->getId(), (string)$store->getCode());
        }

        // NOTE: deliberately NOT calling autoResolveLowRiskFromSource() here.
        // SEO findings — even low-severity ones — must stay visible until a
        // copywriter triages them. Auto-resolving would silently sweep them
        // and contradict the seo-audit skill's "name/meta are sacred" rule.

        return array($logged, $fixed);
    }

    /**
     * Per-store segment-aware checks: brand suffix, WSQ token,
     * SG non-WSQ funding leak, title length. Reads catalog at the store's
     * scope so each country's meta values are evaluated correctly.
     */
    protected function scanStore($storeId, $storeCode)
    {
        $logged = 0;
        $profile = $this->_storeProfiles[$storeCode] ?? null;
        if (!$profile) return 0; // Unknown store code — skip.

        $suffix    = $profile['suffix'];
        $funding   = $profile['funding'];
        $isSgStore = ($storeCode === 'singapore' || $storeCode === 'default');

        $col = Mage::getModel('catalog/product')->getCollection()
            ->setStoreId($storeId)
            ->addStoreFilter($storeId)
            ->addAttributeToSelect(array('name', 'sku', 'meta_title', 'meta_description'))
            ->addAttributeToFilter('status', Mage_Catalog_Model_Product_Status::STATUS_ENABLED)
            ->addAttributeToFilter('visibility', array('neq' => Mage_Catalog_Model_Product_Visibility::VISIBILITY_NOT_VISIBLE))
            ->setPageSize(self::SEGMENT_PER_STORE_LIMIT);

        foreach ($col as $p) {
            $sku   = (string) $p->getSku();
            $name  = (string) $p->getName();
            $title = trim((string) $p->getMetaTitle());
            $desc  = trim((string) $p->getMetaDescription());
            if ($title === '') continue; // already flagged above

            $isWsq = ($isSgStore && stripos($sku, 'TGS-') === 0);
            $isSgC = ($isSgStore && !$isWsq && stripos($sku, 'C') === 0);

            // Brand suffix
            if (substr_compare($title, $suffix, -strlen($suffix)) !== 0) {
                $this->helper()->logIssue(array(
                    'source' => 'cron_scan_seo', 'category' => 'seo', 'severity' => 'medium',
                    'title' => 'meta_title missing brand suffix',
                    'entity_type' => 'product', 'entity_id' => (int)$p->getId(), 'store_id' => $storeId,
                    'detail' => "[$storeCode] SKU {$sku} — title ends with '…" . substr($title, -40) . "'. Expected to end with '{$suffix}' per the seo-audit skill §4a.",
                ));
                $logged++;
            }

            // Length cap
            if (function_exists('mb_strlen') && mb_strlen($title) > 60) {
                $this->helper()->logIssue(array(
                    'source' => 'cron_scan_seo', 'category' => 'seo', 'severity' => 'medium',
                    'title' => 'meta_title > 60 chars',
                    'entity_type' => 'product', 'entity_id' => (int)$p->getId(), 'store_id' => $storeId,
                    'detail' => "[$storeCode] SKU {$sku} — " . mb_strlen($title) . " chars. Course name likely too long; do NOT strip the brand suffix.",
                ));
                $logged++;
            }

            // SG WSQ — title must contain "WSQ"
            if ($isWsq && stripos($title, 'WSQ') === false) {
                $this->helper()->logIssue(array(
                    'source' => 'cron_scan_seo', 'category' => 'seo', 'severity' => 'high',
                    'title' => 'SG WSQ (TGS-) title missing "WSQ" token',
                    'entity_type' => 'product', 'entity_id' => (int)$p->getId(), 'store_id' => $storeId,
                    'detail' => "[$storeCode] SKU {$sku} — title '{$title}' lacks the literal token 'WSQ'. Highest-intent SG search keyword for WSQ courses.",
                ));
                $logged++;
            }
            if ($isWsq && $desc !== '' && !$this->_containsAny($desc, $funding)) {
                $this->helper()->logIssue(array(
                    'source' => 'cron_scan_seo', 'category' => 'seo', 'severity' => 'medium',
                    'title' => 'SG WSQ description missing funding hook',
                    'entity_type' => 'product', 'entity_id' => (int)$p->getId(), 'store_id' => $storeId,
                    'detail' => "[$storeCode] SKU {$sku} — description does not mention any of: " . implode(', ', $funding) . '. Only claim schemes the course actually carries (check funding badges).',
                ));
                $logged++;
            }

            // SG non-WSQ (C-prefix) — must NOT mention WSQ / SkillsFuture
            if ($isSgC && $this->_containsAny($title . ' ' . $desc, array('WSQ', 'SkillsFuture', 'SFEC', 'Funded'))) {
                $this->helper()->logIssue(array(
                    'source' => 'cron_scan_seo', 'category' => 'seo', 'severity' => 'high',
                    'title' => 'SG non-WSQ (C-prefix) leaks WSQ/SkillsFuture language',
                    'entity_type' => 'product', 'entity_id' => (int)$p->getId(), 'store_id' => $storeId,
                    'detail' => "[$storeCode] SKU {$sku} — non-WSQ course title/desc mentions WSQ/SkillsFuture/SFEC/Funded. Per seo-audit §4a, those tokens are reserved for TGS- courses.",
                ));
                $logged++;
            }

            // Description length sanity (only when present)
            if ($desc !== '' && function_exists('mb_strlen')) {
                $len = mb_strlen($desc);
                if ($len < 120 || $len > 170) {
                    $this->helper()->logIssue(array(
                        'source' => 'cron_scan_seo', 'category' => 'seo', 'severity' => 'medium',
                        'title' => 'meta_description outside 120–170 chars',
                        'entity_type' => 'product', 'entity_id' => (int)$p->getId(), 'store_id' => $storeId,
                        'detail' => "[$storeCode] SKU {$sku} — {$len} chars. Tighten / expand to the SERP-snippet range.",
                    ));
                    $logged++;
                }
            }
        }

        return $logged;
    }

    private function _containsAny($haystack, array $needles)
    {
        foreach ($needles as $n) {
            if ($n !== '' && stripos($haystack, $n) !== false) return true;
        }
        return false;
    }
}
