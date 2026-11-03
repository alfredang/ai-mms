<?php
/**
 * Public non-WSQ catalog for the learner apps: every enabled, visible
 * C-prefix course on THIS site, grouped into ~12 phone-friendly categories.
 *
 * Products load one at a time (store-scoped attributes only resolve on a
 * store-loaded model; hydrating hundreds at once exhausts memory), so the
 * built list is cached for a few hours.
 */
class MMD_MobileApi_Helper_Catalog extends Mage_Core_Helper_Abstract
{
    const CACHE_ID       = 'MMD_MOBILEAPI_CATALOG_V1';
    const CACHE_LIFETIME = 10800;
    const SKU_REGEX      = '/^C\d/i';   // same rule as class formation

    /**
     * First match wins, so specific signals (named security certs, Office
     * apps, ISO) sit BEFORE the broad AI/Data patterns, and the generic
     * security wording sits after Cloud. Ported from the iOS app's catalog
     * scraper, where this order was tuned against the full catalog.
     */
    protected $_groups = array(
        array('Cybersecurity',           '/\b(comptia|cissp|cisa|cism|ethical hack|penetration|forensic|cyber ?security|secai)\b/i'),
        array('Microsoft Office',        '/\b(excel|word|powerpoint|outlook|microsoft 365|sharepoint|power automate|power apps|power platform|power bi)\b/i'),
        array('Quality & Compliance',    '/\b(iso \d|internal auditor|quality assurance|greenhouse gas|sustainab|esg|carbon)\b/i'),
        array('Artificial Intelligence', '/\b(ai|artificial intelligence|genai|generative|chatgpt|llm|agentic|machine learning|deep learning|prompt|copilot|claude|gemini)\b/i'),
        array('Data & Analytics',        '/\b(data|analytics|analysis|visualisation|visualization|tableau|statistic|big data|sql|database)\b/i'),
        array('Programming',             '/\b(programming|python|java|javascript|c\+\+|c#|coding|developer|web development|app development|vibe coding|software development|wordpress)\b/i'),
        array('Cloud & DevOps',          '/\b(cloud|aws|azure|devops|docker|kubernetes|linux|server|networking|network)\b/i'),
        array('Cybersecurity',           '/\b(security|cyber|pentest|threat|malware|firewall|encryption|privacy|compliance)\b/i'),
        array('Digital Marketing',       '/\b(marketing|seo|social media|advertis|e-commerce|ecommerce|content creation|copywriting)\b/i'),
        array('Design & Media',          '/\b(design|graphic|media|video|photo|adobe|photoshop|illustrator|premiere|animation|3d|blender|autodesk|drawing|cad)\b/i'),
        array('Business & Soft Skills',  '/\b(business|soft skill|critical core|leadership|management|project management|communication|presentation|finance|accounting|hr|human resource|productivity|service)\b/i'),
        array('Engineering & IoT',       '/\b(electronic|semiconductor|iot|arduino|raspberry|robotic|engineering|manufactur|mechatronic|plc|hydroponic)\b/i'),
    );

    /** @return array{built_at:string, courses:array} */
    public function courses()
    {
        $cache = Mage::app()->getCache();
        $hit   = $cache->load(self::CACHE_ID);
        if ($hit !== false) {
            $data = json_decode($hit, true);
            if (is_array($data) && !empty($data['courses'])) {
                return $data;
            }
        }
        $data = array('built_at' => gmdate('c'), 'courses' => $this->build());
        if ($data['courses']) {
            $cache->save(json_encode($data), self::CACHE_ID, array('MMD_MOBILEAPI'), self::CACHE_LIFETIME);
        }
        return $data;
    }

    public function build()
    {
        $store   = Mage::app()->getDefaultStoreView();
        $storeId = (int) $store->getId();
        $feed    = Mage::helper('courses/catalogfeed');
        $currency = Mage::helper('mmd_mobileapi')->currencyCode();

        $ids = Mage::getModel('catalog/product')->getCollection()
            ->setStoreId($storeId)
            ->addStoreFilter($storeId)
            ->addAttributeToFilter('status', Mage_Catalog_Model_Product_Status::STATUS_ENABLED)
            ->addAttributeToFilter('visibility', array('neq' => Mage_Catalog_Model_Product_Visibility::VISIBILITY_NOT_VISIBLE))
            ->getAllIds();

        $rows = array();
        foreach ($ids as $id) {
            try {
                $p   = Mage::getModel('catalog/product')->setStoreId($storeId)->load($id);
                $sku = trim((string) $p->getSku());
                if (!$p->getId() || !preg_match(self::SKU_REGEX, $sku)) {
                    continue;
                }
                $summary = $feed->stripText((string) $p->getShortDescription(), 400);
                if ($summary === '') {
                    $summary = $feed->stripText((string) $p->getDescription(), 400);
                }
                $hours = (float) $feed->attr($p, 'duration', '0');
                $cats  = $feed->categoryNames($p);
                $rows[] = array(
                    'id'          => (int) $p->getId(),
                    'sku'         => $sku,
                    'title'       => trim((string) $p->getName()),
                    'summary'     => $summary,
                    'category'    => $this->groupFor((string) $p->getName(), $cats),
                    'hours'       => $hours,
                    'duration'    => $this->durationText($hours),
                    'price'       => round((float) $p->getPrice(), 2),
                    'currency'    => $currency,
                    'url'         => $feed->productUrl($p),
                    'image_url'   => $feed->productImageUrl($p),
                );
                unset($p);
            } catch (Exception $e) {
                Mage::logException($e);   // one bad product never sinks the catalog
            }
        }
        usort($rows, function ($a, $b) {
            return strcasecmp($a['title'], $b['title']);
        });
        return $feed->sanitizeUtf8($rows);
    }

    /** Title first (most specific), then the site's own category names. */
    public function groupFor($title, array $categoryNames)
    {
        foreach (array_merge(array($title), $categoryNames) as $text) {
            foreach ($this->_groups as $g) {
                if (preg_match($g[1], $text)) {
                    return $g[0];
                }
            }
        }
        return 'Other Courses';
    }

    /** Site workload is in hours; learners think in training days (~7.5 h). */
    public function durationText($hours)
    {
        if ($hours <= 0) {
            return '';
        }
        $days = max(1, (int) round($hours / 7.5));
        $h    = rtrim(rtrim(number_format($hours, 1, '.', ''), '0'), '.');
        return $days . ' day' . ($days === 1 ? '' : 's') . ' (' . $h . ' hrs)';
    }
}
