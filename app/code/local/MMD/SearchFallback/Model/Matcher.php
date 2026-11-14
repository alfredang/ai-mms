<?php
/**
 * Picks the redirect target for an on-site search term that has none.
 *
 * Every site (SG / MY / GH) runs this against its OWN catalogue and its OWN
 * base URL, so a term can never be sent to another partner's domain.
 *
 * Target order (user rule 2026-11-14): a funded course (TGS- SKU = WSQ / IBF /
 * CASL, SG only) -> a category (catalog) page -> a non-funded course -> the
 * site's catalog fallback page. Nothing ends on a zero-result page.
 *
 * The matcher is deliberately strict. The old fuzzy script
 * (scripts/maintenance/autopopulate-search-redirects.php) scored by loose
 * containment and wrote ~10k wrong redirects. Here a course is chosen only
 * when EVERY meaningful word of the query is in its name (or at least two
 * distinctive words and 60% of the query); anything weaker goes to a category
 * page, and failing that to the catalog fallback, never to a guessed course.
 */
class MMD_SearchFallback_Model_Matcher
{
    const CACHE_KEY_PREFIX = 'mmd_searchfallback_index_v4_';
    const CACHE_TAG        = 'MMD_SEARCHFALLBACK';
    const CACHE_LIFETIME   = 3600;

    const XML_ENABLED       = 'mmd_searchfallback/auto_redirect/enabled';
    const XML_FALLBACK_PATH = 'mmd_searchfallback/auto_redirect/fallback_path';

    /** Tried in order when no fallback path is configured; first one with courses wins. */
    protected $_defaultFallbackPaths = array('wsq-funded-courses.html', 'adult-training-courses.html');

    /** Words that say nothing about the topic. */
    protected $_stopwords = array(
        'a', 'an', 'the', 'and', 'or', 'for', 'with', 'using', 'to', 'in', 'on', 'of', 'by', 'at',
        'from', 'how', 'your', 'our', 'all', 'new', 'best', 'top', 'free', 'online', 'learn',
        'training', 'course', 'courses', 'class', 'classes', 'workshop', 'workshops', 'series',
        'day', 'days', 'hour', 'hours', 'certified', 'cert', 'certification', 'certifications',
        'certificate', 'exam', 'exams', 'prep', 'program', 'programme', 'masterclass', 'bootcamp',
        'guide', 'popular', 'latest', 'other', 'others', 'full', 'complete', 'practical', 'nicf',
        'singapore', 'malaysia', 'ghana', 'sg', 'my', 'gh',
        'wsq', 'tgs', 'ibf', 'casl', 'sts', 'skillsfuture', 'hrdc', 'hrdf', 'hrd', 'corp',
        'funded', 'funding',
    );

    /**
     * Level words => level group. Ignored for the match itself; a query and a
     * course that name DIFFERENT levels ("advanced" vs "for beginners") are
     * not treated as the same title.
     */
    protected $_softwords = array(
        'basic' => 'L1', 'basics' => 'L1', 'beginner' => 'L1', 'beginners' => 'L1',
        'introduction' => 'L1', 'intro' => 'L1', 'fundamental' => 'L1', 'fundamentals' => 'L1',
        'essential' => 'L1', 'essentials' => 'L1', 'foundation' => 'L1', 'foundations' => 'L1',
        'intermediate' => 'L2', 'advanced' => 'L2', 'advance' => 'L2', 'expert' => 'L2',
    );

    /** Phrases the catalogue spells another way (applied to queries AND names). */
    protected $_synonyms = array(
        '/\b(generative|gen)[\s-]+ai\b/'              => 'genai',
        '/\bartificial\s+intelligence\b/'             => 'ai',
        '/\bchat[\s-]+gpt\b/'                         => 'chatgpt',
        '/\bhuman\s+resources?\b/'                    => 'hr',
        '/\bms\b/'                                    => 'microsoft',
        '/\bpower\s+point\b/'                         => 'powerpoint',
        '/\bui\s+path\b/'                             => 'uipath',
        '/\buser\s+experience\b/'                     => 'ux',
        '/\bsearch\s+engine\s+optimi[sz]ation\b/'     => 'seo',
        '/\binternet\s+of\s+things\b/'                => 'iot',
        '/\brobotic\s+process\s+automation\b/'        => 'rpa',
        '/isation\b/'                                 => 'ization',
    );

    protected $_vendors = array('microsoft', 'adobe', 'autodesk', 'google', 'aws', 'amazon', 'apple', 'cisco', 'comptia');

    protected $_index = array();

    public function isEnabled($storeId)
    {
        return (bool) Mage::getStoreConfigFlag(self::XML_ENABLED, $storeId);
    }

    public function baseUrl($storeId)
    {
        return rtrim((string) Mage::getStoreConfig('web/secure/base_url', $storeId), '/') . '/';
    }

    /**
     * The site's catalog page used when nothing in the catalogue matches.
     * Returns '' when the site has no usable category (then no fallback redirect).
     */
    public function fallbackUrl($storeId)
    {
        $index = $this->_getIndex($storeId);
        return $index['fallback'] === '' ? '' : $this->baseUrl($storeId) . $index['fallback'];
    }

    /**
     * @param string   $queryText
     * @param int      $storeId
     * @param string[] $excludeUrls targets proven dead; never returned
     * @return array|null array('url' =>, 'tier' =>) or null when the text is junk
     *                    (injection probes, URLs) and must not get a redirect
     */
    public function match($queryText, $storeId, array $excludeUrls = array())
    {
        $text = trim((string) $queryText);
        if ($text === '' || $this->_isJunk($text)) {
            return null;
        }

        $index   = $this->_getIndex($storeId);
        $base    = $this->baseUrl($storeId);
        $exclude = array_flip($excludeUrls);

        list($q, $qSoft) = $this->_tokenize($text);
        $q = $this->_correct($q, $index);

        $result = null;
        if ($q) {
            $result = $this->_pick($q, $qSoft, $index, $base, $exclude);
            if ($result === null) {
                // Drop the words the catalogue has never heard of ("react js" -> react).
                $known = array();
                foreach ($q as $t) {
                    if (isset($index['vocab'][$t])) {
                        $known[] = $t;
                    }
                }
                if ($known && count($known) < count($q)) {
                    $result = $this->_pick($known, $qSoft, $index, $base, $exclude);
                }
            }
        } else {
            // Only scheme / filler words ("ibf", "wsq courses"): the category named after them.
            $result = $this->_categoryByName($text, $index, $base, $exclude);
        }
        if ($result === null && $index['fallback'] !== '' && !isset($exclude[$base . $index['fallback']])) {
            $result = array('url' => $base . $index['fallback'], 'tier' => 'fallback');
        }
        return $result;
    }

    protected function _pick(array $q, array $qSoft, array $index, $base, array $exclude)
    {
        $qSet   = array_flip($q);
        $qCount = count($q);
        $df     = $index['df'];
        $common = $index['common'];

        // A query word is "loose" when missing it proves nothing: the catalogue
        // has never heard of it, or it is in a large share of course names.
        $distinctive = array();
        $looseCount = 0;
        foreach ($q as $t) {
            if (!isset($index['vocab'][$t]) || (isset($df[$t]) && $df[$t] > $common)) {
                $looseCount++;
            }
            if (!isset($df[$t]) || $df[$t] <= $common) {
                $distinctive[$t] = true;
            }
        }

        // best[funded][kind] = array(score, path); kind: title | full | partial
        $best  = array(0 => array(), 1 => array());
        $fulls = array(0 => 0, 1 => 0); // how many courses contain the whole query
        foreach ($index['products'] as $p) {
            if (isset($exclude[$base . $p['u']])) {
                continue;
            }
            $hit = 0;
            $hitDistinctive = 0;
            foreach ($p['c'] as $t) {
                if (isset($qSet[$t])) {
                    $hit++;
                    if (isset($distinctive[$t])) {
                        $hitDistinctive++;
                    }
                }
            }
            if ($hit === 0) {
                continue;
            }
            $pCount = count($p['c']);
            $levelClash = $qSoft && $p['s'] && !array_intersect($qSoft, $p['s']);
            // Jaccard over topic words, nudged by a matching level word.
            $score = $hit / ($qCount + $pCount - $hit) + (($qSoft && !$levelClash && $p['s']) ? 0.05 : 0);

            if ($hit === $qCount) {
                $fulls[$p['f']]++;
                if ($qCount / $pCount >= 0.6 && !$levelClash) {
                    $kind = 'title';
                } elseif ($distinctive) {
                    $kind = 'full';
                } else {
                    continue; // only generic words ("ai", "data") -> a category takes it
                }
            } elseif ($hitDistinctive >= 2 && $hit / $qCount >= 0.6 && $qCount - $hit <= $looseCount
                && $this->_missedAreLoose($q, $p['c'], $index)) {
                $kind = 'partial';
            } else {
                continue;
            }
            if (!isset($best[$p['f']][$kind]) || $score > $best[$p['f']][$kind][0]) {
                $best[$p['f']][$kind] = array($score, $p['u']);
            }
        }

        // Categories: same words / category inside the query / query inside the
        // category / any shared word.
        $catEqual = null;
        $catSub   = null;
        $catSuper = null;
        $catAny   = null;
        $catAnyRank = null;
        foreach ($index['cats'] as $c) {
            if (isset($exclude[$base . $c['u']])) {
                continue;
            }
            $cCount = count($c['c']);
            $hit = 0;
            $hitDistinctive = 0;
            foreach ($c['c'] as $t) {
                if (isset($qSet[$t])) {
                    $hit++;
                    if (isset($distinctive[$t])) {
                        $hitDistinctive++;
                    }
                }
            }
            if ($hit === 0) {
                continue;
            }
            if ($hit === $cCount && $hit === $qCount) {
                if ($catEqual === null || $c['n'] > $catEqual['n']) {
                    $catEqual = $c;
                }
            } elseif ($hit === $cCount) {
                if ($catSub === null || $cCount > count($catSub['c'])
                    || ($cCount === count($catSub['c']) && $c['n'] > $catSub['n'])) {
                    $catSub = $c;
                }
            } elseif ($hit === $qCount) {
                if ($catSuper === null || $cCount < count($catSuper['c'])
                    || ($cCount === count($catSuper['c']) && $c['n'] > $catSuper['n'])) {
                    $catSuper = $c;
                }
            } elseif ($hitDistinctive >= 1 && !array_diff($c['c'], $q, $this->_vendors)
                && !array_intersect($q, $this->_vendors)) {
                // "macro excel" -> Microsoft Excel: the category only adds a vendor name
                // (and the query does not name a different vendor)
                $rank = array($hitDistinctive, $hit, -$cCount, $c['n']);
                if ($catAnyRank === null || $rank > $catAnyRank) {
                    $catAnyRank = $rank;
                    $catAny = $c;
                }
            }
        }

        $get = function ($funded, $kind) use ($best) {
            return isset($best[$funded][$kind]) ? $best[$funded][$kind][1] : null;
        };
        $multi = $qCount >= 2;
        $ladder = array(
            // a multi-word query that reads like a funded course title
            array('funded-title',     $multi ? $get(1, 'title') : null),
            array('category',         $catEqual ? $catEqual['u'] : null),
            array('funded-title',     $get(1, 'title')),
            // the only funded course that contains the whole query
            array('funded',           $fulls[1] === 1 ? $get(1, 'full') : null),
            array('course-title',     ($multi || $fulls[0] === 1) ? $get(0, 'title') : null),
            array('category-partial', $catSub ? $catSub['u'] : ($catSuper ? $catSuper['u'] : null)),
            array('funded',           $get(1, 'full')),
            array('funded-partial',   $get(1, 'partial')),
            array('course-title',     $get(0, 'title')),
            array('course',           $fulls[0] === 1 ? $get(0, 'full') : null),
            array('category-related', $catAny ? $catAny['u'] : null),
            array('course',           $get(0, 'full')),
            array('course-partial',   $get(0, 'partial')),
        );
        foreach ($ladder as $step) {
            if ($step[1] !== null) {
                return array('url' => $base . $step[1], 'tier' => $step[0]);
            }
        }
        return null;
    }

    protected function _categoryByName($text, array $index, $base, array $exclude)
    {
        $word = strtolower(trim(preg_replace('/\b(courses?|training|class(es)?)\b/i', '', $text)));
        if (!preg_match('/^[a-z0-9]{2,20}$/', $word)) {
            return null;
        }
        $pick = null;
        foreach ($index['catnames'] as $path => $c) {
            if (isset($exclude[$base . $path]) || !preg_match('/\b' . $word . '\b/', $c[0])) {
                continue;
            }
            if ($path === $index['fallback']) {
                return null; // the fallback page already is that category
            }
            // "IBF Funded Courses" before "WSQ and IBF courses", then the bigger one
            $rank = array(strpos($c[0], $word) === 0 ? 1 : 0, $c[1]);
            if ($pick === null || $rank > $pick[1]) {
                $pick = array($path, $rank);
            }
        }
        return $pick ? array('url' => $base . $pick[0], 'tier' => 'category') : null;
    }

    /** Every query word the course lacks must be loose (unknown or very common). */
    protected function _missedAreLoose(array $q, array $courseTokens, array $index)
    {
        $have = array_flip($courseTokens);
        foreach ($q as $t) {
            if (isset($have[$t])) {
                continue;
            }
            if (isset($index['vocab'][$t]) && !(isset($index['df'][$t]) && $index['df'][$t] > $index['common'])) {
                return false;
            }
        }
        return true;
    }

    /** Injection probes / URLs / oversized text never get a redirect. */
    protected function _isJunk($text)
    {
        if (strlen($text) > 120) {
            return true;
        }
        return (bool) preg_match('~[<>=;{}\\\\"`$|]|%[0-9a-f]{2}|https?:|www\.|\.\./|--|/\*|\bunion\s+(all\s+)?select\b|\b(sleep|benchmark)\s*\(|\bwaitfor\s+delay\b|\bonerror\b|gethostbyname~i', $text);
    }

    /**
     * @return array array(topic tokens, level tokens) — unique, stemmed
     */
    protected function _tokenize($text)
    {
        static $stop = null, $soft = null;
        if ($stop === null) {
            $stop = array_flip($this->_stopwords);
            $soft = $this->_softwords;
        }
        $text = strtolower((string) $text);
        $text = preg_replace('/\.html$/', '', $text);
        $text = str_replace(array('c++', 'c#', '.net'), array(' cpp ', ' csharp ', ' dotnet '), $text);
        foreach ($this->_synonyms as $pattern => $word) {
            $text = preg_replace($pattern, $word, $text);
        }

        $core = array();
        $level = array();
        foreach (preg_split('/[^a-z0-9]+/', $text) as $t) {
            if ($t === '' || isset($stop[$t])) {
                continue;
            }
            if (isset($soft[$t])) {
                $level[$soft[$t]] = true;
                continue;
            }
            $core[$this->_stem($t)] = true;
        }
        return array(array_map('strval', array_keys($core)), array_keys($level));
    }

    /** Plural folding only — enough for "videos"/"video", "agents"/"agent". */
    protected function _stem($t)
    {
        $n = strlen($t);
        if ($n > 4 && substr($t, -3) === 'ies') {
            return substr($t, 0, -3) . 'y';
        }
        if ($n > 3 && substr($t, -1) === 's' && !in_array(substr($t, -2), array('ss', 'us', 'is', 'as'), true)) {
            return substr($t, 0, -1);
        }
        return $t;
    }

    /**
     * Repair query words the catalogue does not know: a run-together pair
     * ("microdrama" -> micro + drama) or a small typo ("leaderhip").
     */
    protected function _correct(array $tokens, array $index)
    {
        $out = array();
        foreach ($tokens as $t) {
            if (isset($index['vocab'][$t])) {
                $out[$t] = true;
                continue;
            }
            if (isset($index['alias'][$t])) {
                foreach ($index['alias'][$t] as $part) {
                    $out[$part] = true;
                }
                continue;
            }
            $fixed = $this->_nearest($t, $index);
            if ($fixed === null) {
                $out[$t] = true;
            } elseif (isset($index['alias'][$fixed])) {
                foreach ($index['alias'][$fixed] as $part) {
                    $out[$part] = true;
                }
            } else {
                $out[$fixed] = true;
            }
        }
        return array_map('strval', array_keys($out));
    }

    protected function _nearest($t, array $index)
    {
        $n = strlen($t);
        if ($n < 5 || ctype_digit($t)) {
            return null;
        }
        $max = $n >= 6 ? 2 : 1;
        $letters = count_chars($t, 1);
        $bestWord = null;
        $bestDist = $max + 1;
        $tie = false;
        foreach (array($index['vocab'], $index['alias']) as $words) {
            foreach ($words as $w => $_) {
                $w = (string) $w;
                if (abs(strlen($w) - $n) > $max || $w[0] !== $t[0]) {
                    continue; // typos rarely change the first letter; keeps this cheap
                }
                $d = levenshtein($t, $w);
                // two edits only when it is the same letters swapped around ("presnetation")
                if ($d === 2 && count_chars($w, 1) != $letters) {
                    continue;
                }
                if ($d < $bestDist) {
                    $bestDist = $d;
                    $bestWord = $w;
                    $tie = false;
                } elseif ($d === $bestDist && $w !== $bestWord) {
                    $tie = true;
                }
            }
        }
        return ($bestWord !== null && !$tie) ? $bestWord : null;
    }

    protected function _getIndex($storeId)
    {
        $storeId = (int) $storeId;
        if (isset($this->_index[$storeId])) {
            return $this->_index[$storeId];
        }
        $key = self::CACHE_KEY_PREFIX . $storeId;
        $cached = Mage::app()->loadCache($key);
        $index = $cached ? @unserialize($cached) : false;
        if (!is_array($index)) {
            $index = $this->_buildIndex($storeId);
            Mage::app()->saveCache(serialize($index), $key, array(self::CACHE_TAG), self::CACHE_LIFETIME);
        }
        return $this->_index[$storeId] = $index;
    }

    protected function _buildIndex($storeId)
    {
        $res  = Mage::getSingleton('core/resource');
        $conn = $res->getConnection('core_read');
        $eav  = Mage::getSingleton('eav/config');
        $websiteId = (int) Mage::app()->getStore($storeId)->getWebsiteId();

        $pName   = (int) $eav->getAttribute('catalog_product', 'name')->getId();
        $pStatus = (int) $eav->getAttribute('catalog_product', 'status')->getId();
        $pVis    = (int) $eav->getAttribute('catalog_product', 'visibility')->getId();
        $cName   = (int) $eav->getAttribute('catalog_category', 'name')->getId();
        $cActive = (int) $eav->getAttribute('catalog_category', 'is_active')->getId();

        $pe  = $res->getTableName('catalog/product');
        $pw  = $res->getTableName('catalog/product_website');
        $pi  = $pe . '_int';
        $pv  = $pe . '_varchar';
        $ce  = $res->getTableName('catalog/category');
        $ci  = $ce . '_int';
        $cv  = $ce . '_varchar';
        $cpi = $res->getTableName('catalog/category_product_index');
        $rw  = $res->getTableName('core/url_rewrite');

        // Enabled, visible courses of this site with their canonical flat URL.
        $rows = $conn->fetchAll("
            SELECT e.sku, COALESCE(ns.value, n0.value) AS name, MIN(r.request_path) AS path
              FROM {$pe} e
              JOIN {$pw} w ON w.product_id = e.entity_id AND w.website_id = {$websiteId}
              JOIN {$rw} r ON r.product_id = e.entity_id AND r.store_id = {$storeId}
                          AND r.is_system = 1 AND r.category_id IS NULL
         LEFT JOIN {$pi} s0 ON s0.entity_id = e.entity_id AND s0.attribute_id = {$pStatus} AND s0.store_id = 0
         LEFT JOIN {$pi} ss ON ss.entity_id = e.entity_id AND ss.attribute_id = {$pStatus} AND ss.store_id = {$storeId}
         LEFT JOIN {$pi} v0 ON v0.entity_id = e.entity_id AND v0.attribute_id = {$pVis} AND v0.store_id = 0
         LEFT JOIN {$pi} vs ON vs.entity_id = e.entity_id AND vs.attribute_id = {$pVis} AND vs.store_id = {$storeId}
         LEFT JOIN {$pv} n0 ON n0.entity_id = e.entity_id AND n0.attribute_id = {$pName} AND n0.store_id = 0
         LEFT JOIN {$pv} ns ON ns.entity_id = e.entity_id AND ns.attribute_id = {$pName} AND ns.store_id = {$storeId}
             WHERE COALESCE(ss.value, s0.value) = 1
               AND COALESCE(vs.value, v0.value) IN (2, 3, 4)
          GROUP BY e.entity_id
        ");

        $products = array();
        $df = array();
        $vocab = array();
        $alias = array();
        foreach ($rows as $row) {
            list($core, $soft) = $this->_tokenize($row['name']);
            if (!$core || (string) $row['path'] === '') {
                continue;
            }
            $products[] = array(
                'u' => $row['path'],
                'f' => stripos((string) $row['sku'], 'TGS-') === 0 ? 1 : 0,
                'c' => $core,
                's' => $soft,
            );
            foreach ($core as $i => $t) {
                $df[$t] = isset($df[$t]) ? $df[$t] + 1 : 1;
                $vocab[$t] = 1;
                // "micro" + "drama" also answers to "microdrama"
                if (isset($core[$i + 1]) && !ctype_digit($t) && !ctype_digit($core[$i + 1])) {
                    $alias[$t . $core[$i + 1]] = array($t, $core[$i + 1]);
                }
            }
        }

        // Active categories that actually list courses on this site.
        $rows = $conn->fetchAll("
            SELECT COALESCE(ns.value, n0.value) AS name, MIN(r.request_path) AS path,
                   (SELECT COUNT(*) FROM {$cpi} x WHERE x.category_id = e.entity_id AND x.store_id = {$storeId}) AS n
              FROM {$ce} e
              JOIN {$rw} r ON r.category_id = e.entity_id AND r.product_id IS NULL
                          AND r.store_id = {$storeId} AND r.is_system = 1
         LEFT JOIN {$ci} a0 ON a0.entity_id = e.entity_id AND a0.attribute_id = {$cActive} AND a0.store_id = 0
         LEFT JOIN {$ci} a1 ON a1.entity_id = e.entity_id AND a1.attribute_id = {$cActive} AND a1.store_id = {$storeId}
         LEFT JOIN {$cv} n0 ON n0.entity_id = e.entity_id AND n0.attribute_id = {$cName} AND n0.store_id = 0
         LEFT JOIN {$cv} ns ON ns.entity_id = e.entity_id AND ns.attribute_id = {$cName} AND ns.store_id = {$storeId}
             WHERE e.level >= 2 AND COALESCE(a1.value, a0.value) = 1
          GROUP BY e.entity_id
            HAVING n > 0
        ");

        $cats = array();
        $catPaths = array();
        $catNames = array();
        foreach ($rows as $row) {
            $catPaths[$row['path']] = (int) $row['n'];
            $catNames[$row['path']] = array(strtolower((string) $row['name']), (int) $row['n']);
            list($core) = $this->_tokenize($row['name']);
            if (!$core) {
                continue;
            }
            $cats[] = array('u' => $row['path'], 'c' => $core, 'n' => (int) $row['n']);
            foreach ($core as $t) {
                $vocab[$t] = 1;
            }
        }
        foreach ($alias as $joined => $_) {
            if (isset($vocab[$joined])) {
                unset($alias[$joined]);
            }
        }

        $fallback = '';
        $configured = trim((string) Mage::getStoreConfig(self::XML_FALLBACK_PATH, $storeId), '/ ');
        foreach (array_merge($configured !== '' ? array($configured) : array(), $this->_defaultFallbackPaths) as $path) {
            if (isset($catPaths[$path])) {
                $fallback = $path;
                break;
            }
        }

        return array(
            'products' => $products,
            'cats'     => $cats,
            'catnames' => $catNames,
            'df'       => $df,
            'vocab'    => $vocab,
            'alias'    => $alias,
            'common'   => max(10, (int) floor(count($products) * 0.04)),
            'fallback' => $fallback,
        );
    }

    /**
     * Does a redirect target actually render on this store?
     *
     * External hosts are trusted. Own-host paths must map to a published blog
     * post, a core_url_rewrite chain ending on an enabled course / active
     * category, or an active CMS page.
     */
    public function targetResolves($url, $storeId)
    {
        $url = trim((string) $url);
        if ($url === '') {
            return false;
        }
        $storeId = (int) $storeId;

        if (preg_match('#^https?://#i', $url)) {
            $host = parse_url($url, PHP_URL_HOST);
            $storeHost = parse_url($this->baseUrl($storeId), PHP_URL_HOST);
            if ($host && $storeHost && strcasecmp($host, $storeHost) !== 0) {
                return true;
            }
            $url = (string) parse_url($url, PHP_URL_PATH);
        }

        $path = ltrim((string) $url, '/');
        if ($path === '') {
            return false;
        }
        if (strpos($path, 'index.php/') === 0) {
            $path = substr($path, strlen('index.php/'));
        }

        // /blog/<url_key> is served by MMD_Blog_Controller_Router: no rewrite row, not a cms_page.
        if (preg_match('#^blog/([^/]+)$#', $path, $m)) {
            $post = Mage::getModel('mmd_blog/post')->loadByUrlKey($m[1]);
            return (bool) ($post->getId() && $post->isPublished());
        }

        // Follow the rewrite chain (an old slug 301s to its successor, sometimes
        // twice) and judge the row that finally serves the page: only there does
        // the course / category status decide. Judging the first row would call a
        // retired slug dead although it 301s to a live course.
        $seen = array();
        for ($hop = 0; $hop < 6; $hop++) {
            $rewrite = Mage::getModel('core/url_rewrite');
            $rewrite->setStoreId($storeId)->loadByRequestPath($path);
            if (!$rewrite->getId()) {
                if ($hop === 0) {
                    break; // not a rewrite at all -> CMS lookup below
                }
                return false;
            }
            $target = ltrim((string) $rewrite->getTargetPath(), '/');
            if ($target === '' || strcasecmp($target, $path) === 0) {
                return $this->_rewriteEntityLive($rewrite, $storeId);
            }
            if (!preg_match('#\.html$#i', $target) && strpos($target, '/') !== false) {
                // built-in route (catalog/product/view/id/N, catalog/category/view/id/N, ...)
                return $this->_rewriteEntityLive($rewrite, $storeId);
            }
            if (preg_match('#^https?://#i', $target) || isset($seen[$target])) {
                return !isset($seen[$target]);
            }
            $seen[$path] = true;
            $path = $target;
        }
        if ($hop > 0) {
            return false;
        }

        // CMS identifiers on this site usually INCLUDE the .html suffix (sfec.html, utap.html).
        foreach (array_unique(array($path, preg_replace('#\.html$#i', '', $path))) as $cmsId) {
            if ($cmsId === '') {
                continue;
            }
            $cms = Mage::getModel('cms/page')->load($cmsId, 'identifier');
            if ($cms->getId() && (int) $cms->getIsActive() === 1) {
                // _afterLoad puts the store list in 'store_id' (array), not 'stores'.
                $stores = array_map('intval', array_merge(
                    (array) $cms->getData('store_id'),
                    (array) $cms->getData('stores')
                ));
                if (in_array(0, $stores, true) || in_array($storeId, $stores, true)) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * A rewrite row outlives its course: a disabled course / deactivated
     * category keeps the row but the page 404s.
     */
    protected function _rewriteEntityLive($rewrite, $storeId)
    {
        $res  = Mage::getSingleton('core/resource');
        $conn = $res->getConnection('core_read');
        $eav  = Mage::getSingleton('eav/config');

        if ($rewrite->getProductId()) {
            $table = $res->getTableName('catalog/product') . '_int';
            $attr  = (int) $eav->getAttribute('catalog_product', 'status')->getId();
            $id    = (int) $rewrite->getProductId();
        } elseif ($rewrite->getCategoryId()) {
            $table = $res->getTableName('catalog/category') . '_int';
            $attr  = (int) $eav->getAttribute('catalog_category', 'is_active')->getId();
            $id    = (int) $rewrite->getCategoryId();
        } else {
            return true; // custom rewrite, nothing to check
        }
        $value = $conn->fetchOne(
            "SELECT value FROM {$table} WHERE entity_id = ? AND attribute_id = ? AND store_id IN (0, ?)
              ORDER BY store_id DESC LIMIT 1",
            array($id, $attr, (int) $storeId)
        );
        return (int) $value === 1;
    }
}
