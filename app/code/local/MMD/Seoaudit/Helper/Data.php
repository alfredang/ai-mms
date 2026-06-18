<?php
/**
 * SEO Audit runner — pure read-only.
 *
 * Returns a structured result array consumed by the audit template. All
 * SQL goes through the catalog/product collection or direct read adapter.
 * Per-segment meta rules mirror .claude/skills/seo-audit/SKILL.md §4a:
 *   - SG WSQ (TGS-) → title MUST contain "WSQ" + end with brand suffix +
 *                     description SHOULD mention funding.
 *   - SG non-WSQ (C…) → brand suffix; MUST NOT mention WSQ/SkillsFuture.
 *   - NG → brand suffix only; no funding language.
 *
 * Sample size is capped (SAMPLE_LIMIT) so the page stays responsive even
 * on the 2k+ product catalog.
 */
class MMD_Seoaudit_Helper_Data extends Mage_Core_Helper_Abstract
{
    const SAMPLE_LIMIT = 200;

    /** Per-store brand suffix and segment hints. Keyed by store code. */
    protected $_storeProfiles = array(
        'singapore' => array('country' => 'Singapore', 'suffix' => '| Tertiary Courses Singapore', 'fundingKeywords' => array('SkillsFuture', 'SFEC', 'UTAP', 'WSQ', 'Absentee Payroll', 'PSEA', 'IBF', 'MCES')),
        'nigeria'   => array('country' => 'Nigeria',   'suffix' => '| Tertiary Courses Nigeria',   'fundingKeywords' => array()),
    );

    /**
     * Run the full audit for one store id (must be > 0 — All-stores is rejected).
     *
     * @param int $storeId
     * @return array
     */
    public function run($storeId)
    {
        $storeId = (int) $storeId;
        if ($storeId <= 0) {
            $storeId = 1; // SG default
        }
        try {
            $store = Mage::app()->getStore($storeId);
        } catch (Mage_Core_Model_Store_Exception $e) {
            $store = Mage::app()->getStore(1);
            $storeId = (int) $store->getId();
        }
        $storeCode = (string) $store->getCode();
        $profile = isset($this->_storeProfiles[$storeCode])
            ? $this->_storeProfiles[$storeCode]
            : array('country' => $store->getName(), 'suffix' => '| Tertiary Courses', 'fundingKeywords' => array());

        $sampled = $this->_sampleProducts($storeId);
        $meta    = $this->_auditMeta($sampled, $storeCode, $profile);
        $content = $this->_auditContent($sampled);

        return array(
            'store'   => array(
                'id'      => $storeId,
                'code'    => $storeCode,
                'name'    => $store->getName(),
                'country' => $profile['country'],
                'suffix'  => $profile['suffix'],
                'baseUrl' => rtrim((string) $store->getBaseUrl(Mage_Core_Model_Store::URL_TYPE_WEB), '/'),
            ),
            'meta'    => $meta,
            'sitemap' => $this->_auditSitemap($storeId),
            'robots'  => $this->_auditRobots($store),
            'content' => $content,
            'inpage'  => $this->_auditInPage($store, $sampled),
        );
    }

    /**
     * Pull a sample of active, visible simple products for the store.
     * Loads the EAV attributes we need for the audit.
     *
     * @param int $storeId
     * @return Mage_Catalog_Model_Resource_Product_Collection
     */
    protected function _sampleProducts($storeId)
    {
        /** @var Mage_Catalog_Model_Resource_Product_Collection $col */
        $col = Mage::getModel('catalog/product')->getCollection()
            ->setStoreId($storeId)
            ->addStoreFilter($storeId)
            ->addAttributeToSelect(array('name', 'sku', 'meta_title', 'meta_description', 'short_description', 'description', 'url_key', 'status', 'visibility'))
            ->addAttributeToFilter('status', Mage_Catalog_Model_Product_Status::STATUS_ENABLED)
            ->addAttributeToFilter('visibility', array('neq' => Mage_Catalog_Model_Product_Visibility::VISIBILITY_NOT_VISIBLE))
            ->setPageSize(self::SAMPLE_LIMIT)
            ->setCurPage(1);
        return $col;
    }

    /**
     * Per-product meta title/description audit by segment.
     *
     * @return array { sampleSize, violations:int, byRule:array, examples:array[] }
     */
    protected function _auditMeta($products, $storeCode, array $profile)
    {
        $suffix          = $profile['suffix'];
        $fundingKeywords = $profile['fundingKeywords'];
        $isSg            = ($storeCode === 'default');
        $rules = array(
            'missing_title'           => array('label' => 'Missing meta title',                       'count' => 0, 'examples' => array()),
            'missing_description'     => array('label' => 'Missing meta description',                 'count' => 0, 'examples' => array()),
            'wrong_suffix'            => array('label' => 'Title missing brand suffix (' . $suffix . ')', 'count' => 0, 'examples' => array()),
            'title_too_long'          => array('label' => 'Title > 60 chars',                         'count' => 0, 'examples' => array()),
            'desc_wrong_length'       => array('label' => 'Description length outside 120–170 chars', 'count' => 0, 'examples' => array()),
            'wsq_title_missing'       => array('label' => 'SG WSQ (TGS-) title missing "WSQ" token',  'count' => 0, 'examples' => array()),
            'wsq_desc_no_funding'     => array('label' => 'SG WSQ description missing funding hook',  'count' => 0, 'examples' => array()),
            'sg_non_wsq_funding_leak' => array('label' => 'SG non-WSQ (C-prefix) mentions WSQ / SkillsFuture',  'count' => 0, 'examples' => array()),
        );

        $sampleSize = 0;
        foreach ($products as $p) {
            $sampleSize++;
            $sku   = (string) $p->getSku();
            $name  = (string) $p->getName();
            $title = trim((string) $p->getMetaTitle());
            $desc  = trim((string) $p->getMetaDescription());

            $segment = $this->_segmentFor($sku, $storeCode);
            $hit = function ($key, $note = '') use (&$rules, $sku, $name) {
                $rules[$key]['count']++;
                if (count($rules[$key]['examples']) < 5) {
                    $rules[$key]['examples'][] = array('sku' => $sku, 'name' => $name, 'note' => $note);
                }
            };

            if ($title === '') {
                $hit('missing_title');
                continue; // remaining title checks irrelevant
            }
            if ($desc === '') {
                $hit('missing_description');
            }
            if (mb_strlen($title) > 60) {
                $hit('title_too_long', mb_strlen($title) . ' chars');
            }
            if (substr_compare($title, $suffix, -strlen($suffix)) !== 0) {
                $hit('wrong_suffix', 'ends with: …' . mb_substr($title, -40));
            }
            if ($desc !== '' && (mb_strlen($desc) < 120 || mb_strlen($desc) > 170)) {
                $hit('desc_wrong_length', mb_strlen($desc) . ' chars');
            }

            if ($segment === 'sg_wsq') {
                if (stripos($title, 'WSQ') === false) {
                    $hit('wsq_title_missing');
                }
                if ($desc !== '' && !$this->_containsAny($desc, $fundingKeywords)) {
                    $hit('wsq_desc_no_funding');
                }
            } elseif ($segment === 'sg_non_wsq') {
                if ($this->_containsAny($title . ' ' . $desc, array('WSQ', 'SkillsFuture', 'SFEC'))) {
                    $hit('sg_non_wsq_funding_leak');
                }
            }
        }

        $violations = 0;
        foreach ($rules as $r) { $violations += $r['count']; }

        return array(
            'sampleSize' => $sampleSize,
            'limit'      => self::SAMPLE_LIMIT,
            'violations' => $violations,
            'byRule'     => $rules,
        );
    }

    /**
     * @param string $sku
     * @param string $storeCode
     * @return string  sg_wsq | sg_non_wsq | my | other
     */
    protected function _segmentFor($sku, $storeCode)
    {
        if ($storeCode === 'singapore') {
            if (stripos($sku, 'TGS-') === 0) {
                return 'sg_wsq';
            }
            if (strncasecmp($sku, 'C', 1) === 0) {
                return 'sg_non_wsq';
            }
            return 'sg_non_wsq'; // treat anything else on SG conservatively
        }
        return 'other';
    }

    protected function _containsAny($haystack, array $needles)
    {
        foreach ($needles as $n) {
            if ($n !== '' && stripos($haystack, $n) !== false) {
                return true;
            }
        }
        return false;
    }

    /**
     * Sitemap audit — checks core/sitemap rows scoped to this store and
     * whether the generated file is on disk.
     *
     * @return array
     */
    protected function _auditSitemap($storeId)
    {
        $rows  = array();
        $stale = 0;
        $missingFile = 0;
        try {
            /** @var Mage_Sitemap_Model_Resource_Sitemap_Collection $col */
            $col = Mage::getModel('sitemap/sitemap')->getCollection()
                ->addFieldToFilter('store_id', array('eq' => (int) $storeId));
            foreach ($col as $row) {
                $path = rtrim((string) $row->getSitemapPath(), '/') . '/' . $row->getSitemapFilename();
                $abs  = Mage::getBaseDir() . str_replace('/', DIRECTORY_SEPARATOR, $path);
                $exists = is_file($abs);
                $lastGen = (string) $row->getSitemapTime();
                $ageDays = $lastGen !== '' && $lastGen !== '0000-00-00 00:00:00'
                    ? (int) floor((time() - strtotime($lastGen)) / 86400)
                    : null;
                if (!$exists) { $missingFile++; }
                if ($ageDays === null || $ageDays > 7) { $stale++; }
                $rows[] = array(
                    'filename' => $row->getSitemapFilename(),
                    'path'     => $row->getSitemapPath(),
                    'lastGen'  => $lastGen,
                    'ageDays'  => $ageDays,
                    'exists'   => $exists,
                );
            }
        } catch (Exception $e) {
            // sitemap module disabled
        }
        return array(
            'rows'        => $rows,
            'count'       => count($rows),
            'stale'       => $stale,
            'missingFile' => $missingFile,
        );
    }

    /**
     * Robots.txt audit. Reads the store-scoped admin robots field
     * (design/head/default_robots equivalent) and fetches the live
     * robots.txt from the store base URL when possible.
     *
     * @return array
     */
    protected function _auditRobots($store)
    {
        $live = '';
        $liveError = '';
        $url  = rtrim((string) $store->getBaseUrl(Mage_Core_Model_Store::URL_TYPE_WEB), '/') . '/robots.txt';
        try {
            $ctx = stream_context_create(array('http' => array('timeout' => 3, 'ignore_errors' => true)));
            $body = @file_get_contents($url, false, $ctx);
            if ($body !== false) {
                $live = $body;
            } else {
                $liveError = 'unable to fetch ' . $url;
            }
        } catch (Exception $e) {
            $liveError = $e->getMessage();
        }

        $hasSitemap   = (bool) preg_match('/^\s*Sitemap:\s*\S+/mi', $live);
        $blocksAdmin  = (bool) preg_match('/^\s*Disallow:\s*\/tigerdragon/mi', $live);
        $blocksCustomer = (bool) preg_match('/^\s*Disallow:\s*\/customer/mi', $live);
        $blocksCheckout = (bool) preg_match('/^\s*Disallow:\s*\/checkout/mi', $live);

        return array(
            'url'             => $url,
            'live'            => $live,
            'liveError'       => $liveError,
            'hasSitemap'      => $hasSitemap,
            'blocksAdmin'     => $blocksAdmin,
            'blocksCustomer'  => $blocksCustomer,
            'blocksCheckout'  => $blocksCheckout,
        );
    }

    /**
     * Content quality audit. Counts products in the sample missing
     * short_description / description; flags meta inherited from default
     * scope (no per-store override).
     */
    protected function _auditContent($products)
    {
        $missingShort = 0; $missingLong = 0; $sample = 0;
        foreach ($products as $p) {
            $sample++;
            if (trim(strip_tags((string) $p->getShortDescription())) === '') { $missingShort++; }
            if (trim(strip_tags((string) $p->getDescription()))      === '') { $missingLong++; }
        }
        $defaultScopeOnly = $this->_countMetaInheritedFromDefault((int) $products->getStoreId());
        return array(
            'sample'           => $sample,
            'missingShort'     => $missingShort,
            'missingLong'      => $missingLong,
            'defaultScopeOnly' => $defaultScopeOnly,
        );
    }

    /**
     * How many products have meta_title at default scope only (no override
     * for this store). Surfaces the "saveAttribute writes at SG scope"
     * memory in action: if every MY/GH product reports as default-only,
     * the country store is showing SG copy.
     */
    protected function _countMetaInheritedFromDefault($storeId)
    {
        if ($storeId <= 1) {
            return null; // SG is the source-of-truth; not meaningful here.
        }
        try {
            $resource = Mage::getSingleton('core/resource');
            $read     = $resource->getConnection('core_read');
            $eav      = Mage::getModel('eav/entity_attribute');
            $attr     = Mage::getModel('catalog/product')->getResource()->getAttribute('meta_title');
            if (!$attr || !$attr->getId()) {
                return null;
            }
            $table = $attr->getBackend()->getTable();
            $sql = "SELECT COUNT(*) FROM {$table} d
                    LEFT JOIN {$table} s
                        ON s.entity_id = d.entity_id
                       AND s.attribute_id = d.attribute_id
                       AND s.store_id = :store_id
                    WHERE d.attribute_id = :attribute_id
                      AND d.store_id = 0
                      AND s.value_id IS NULL";
            return (int) $read->fetchOne($sql, array(
                'store_id'     => (int) $storeId,
                'attribute_id' => (int) $attr->getId(),
            ));
        } catch (Exception $e) {
            return null;
        }
    }

    /**
     * In-page audit — fetches the store homepage and one sample product
     * URL, checks for <h1>, <link rel="canonical">, hreflang cluster.
     */
    protected function _auditInPage($store, $products)
    {
        $sampleUrl = null;
        foreach ($products as $p) {
            $sampleUrl = $p->getProductUrl();
            break;
        }
        $home = rtrim((string) $store->getBaseUrl(Mage_Core_Model_Store::URL_TYPE_WEB), '/') . '/';

        return array(
            'home'    => $this->_inspectUrl($home),
            'product' => $sampleUrl ? $this->_inspectUrl($sampleUrl) : null,
        );
    }

    protected function _inspectUrl($url)
    {
        $out = array(
            'url'        => $url,
            'fetched'    => false,
            'status'     => 0,
            'title'      => '',
            'h1'         => '',
            'canonical'  => '',
            'metaDesc'   => '',
            'hreflangs'  => array(),
            'jsonLd'     => 0,
            'error'      => '',
        );
        try {
            $ctx = stream_context_create(array(
                'http' => array('timeout' => 4, 'ignore_errors' => true,
                    'header' => "User-Agent: TertiaryCoursesSeoAuditor/1.0\r\n"),
            ));
            $body = @file_get_contents($url, false, $ctx);
            if ($body === false) {
                $out['error'] = 'fetch failed';
                return $out;
            }
            $out['fetched'] = true;
            if (!empty($http_response_header)) {
                if (preg_match('#HTTP/\S+\s+(\d{3})#', $http_response_header[0], $m)) {
                    $out['status'] = (int) $m[1];
                }
            }
            if (preg_match('#<title>(.*?)</title>#is', $body, $m)) { $out['title'] = trim(html_entity_decode(strip_tags($m[1]))); }
            if (preg_match('#<h1[^>]*>(.*?)</h1>#is', $body, $m)) { $out['h1'] = trim(html_entity_decode(strip_tags($m[1]))); }
            if (preg_match('#<link[^>]+rel=["\']canonical["\'][^>]+href=["\']([^"\']+)["\']#i', $body, $m)) { $out['canonical'] = $m[1]; }
            if (preg_match('#<meta[^>]+name=["\']description["\'][^>]+content=["\']([^"\']*)["\']#i', $body, $m)) { $out['metaDesc'] = $m[1]; }
            if (preg_match_all('#<link[^>]+rel=["\']alternate["\'][^>]+hreflang=["\']([^"\']+)["\'][^>]+href=["\']([^"\']+)["\']#i', $body, $matches, PREG_SET_ORDER)) {
                foreach ($matches as $m) { $out['hreflangs'][] = array('hreflang' => $m[1], 'href' => $m[2]); }
            }
            $out['jsonLd'] = preg_match_all('#<script[^>]+type=["\']application/ld\+json["\']#i', $body);
        } catch (Exception $e) {
            $out['error'] = $e->getMessage();
        }
        return $out;
    }
}
