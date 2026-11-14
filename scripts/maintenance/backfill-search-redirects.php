<?php
/**
 * Backfill + repair catalogsearch_query.redirect on THIS site (SG / MY / GH —
 * run it inside each site's own web container; every URL it writes is on the
 * site's own domain).
 *
 *   php scripts/maintenance/backfill-search-redirects.php --dry-run
 *   php scripts/maintenance/backfill-search-redirects.php --apply
 *
 * Uses the same matcher as the storefront (MMD_SearchFallback_Model_Matcher):
 *   1. REPAIR  every own-domain redirect whose target no longer renders
 *              (course disabled, category removed, or the live URL answers
 *              404/410) is re-matched to a live target.
 *   2. FILL    every term with no redirect gets one: funded course ->
 *              category page -> course -> catalog fallback page.
 * A working redirect is never overwritten. Junk terms (injection probes,
 * URLs) are left alone.
 *
 * Every target is fetched over HTTP on the site's own domain before it is
 * written (a rewrite row is not proof of a live page on partner sites); pass
 * --no-http to skip that. Output is TSV: action, query_id, popularity,
 * query_text, old redirect, new redirect, tier. --apply first saves the
 * touched rows' old values to var/search-redirect-backfill-<store>-<time>.tsv.
 */
require_once __DIR__ . '/../../app/Mage.php';
ob_start(); // partner bootstraps can emit output that would break session headers
Mage::app();
ob_end_clean();

$args   = array_slice($argv, 1);
$apply  = in_array('--apply', $args, true);
$dryRun = in_array('--dry-run', $args, true);
$http   = !in_array('--no-http', $args, true);
if ($apply === $dryRun) {
    fwrite(STDERR, "Usage: backfill-search-redirects.php --dry-run | --apply [--no-http]\n");
    exit(1);
}

/**
 * Final HTTP status per URL (redirects followed). 0 = could not tell.
 */
function mmdHttpStatus(array $urls)
{
    $out = array();
    $body = array();
    foreach (array_chunk(array_values(array_unique($urls)), 10) as $batch) {
        $mh = curl_multi_init();
        $handles = array();
        foreach ($batch as $u) {
            $ch = curl_init($u);
            $body[$u] = '';
            curl_setopt_array($ch, array(
                CURLOPT_FOLLOWLOCATION => true,
                CURLOPT_MAXREDIRS      => 5,
                CURLOPT_TIMEOUT        => 25,
                CURLOPT_CONNECTTIMEOUT => 8,
                CURLOPT_USERAGENT      => 'Mozilla/5.0 (compatible; mmd-search-redirect-check/1.0)',
                // the <title> is all we need; stop reading after the head
                CURLOPT_WRITEFUNCTION  => function ($ch, $chunk) use (&$body, $u) {
                    $body[$u] .= $chunk;
                    return strlen($body[$u]) > 6000 ? -1 : strlen($chunk);
                },
            ));
            curl_multi_add_handle($mh, $ch);
            $handles[] = array($ch, $u);
        }
        do {
            curl_multi_exec($mh, $running);
            curl_multi_select($mh, 1.0);
        } while ($running > 0);
        foreach ($handles as $h) {
            $code = (int) curl_getinfo($h[0], CURLINFO_HTTP_CODE);
            // a page cache can replay the 404 page with status 200 (seen on MY)
            if ($code === 200 && stripos($body[$h[1]], '<title>404 Not Found') !== false) {
                $code = 404;
            }
            $out[$h[1]] = $code;
            curl_multi_remove_handle($mh, $h[0]);
            curl_close($h[0]);
        }
        curl_multi_close($mh);
    }
    return $out;
}

$conn    = Mage::getSingleton('core/resource')->getConnection('core_write');
$matcher = new MMD_SearchFallback_Model_Matcher();
Mage::app()->getCache()->clean(Zend_Cache::CLEANING_MODE_MATCHING_TAG, array(MMD_SearchFallback_Model_Matcher::CACHE_TAG));

foreach (Mage::app()->getStores() as $store) {
    if (!$store->getIsActive()) {
        continue;
    }
    $storeId = (int) $store->getId();
    $base    = $matcher->baseUrl($storeId);
    $host    = parse_url($base, PHP_URL_HOST);
    fwrite(STDERR, "store {$store->getCode()} (id {$storeId}) base {$base}\n");

    $rows = $conn->fetchAll(
        'SELECT query_id, query_text, popularity, redirect FROM catalogsearch_query WHERE store_id = ?',
        array($storeId)
    );

    // ---- 1. which existing own-domain targets are dead? ----
    $existing = array();
    foreach ($rows as $r) {
        $u = trim((string) $r['redirect']);
        if ($u !== '' && strcasecmp((string) parse_url($u, PHP_URL_HOST), $host) === 0) {
            $existing[$u] = true;
        }
    }
    $dead = array();
    foreach (array_keys($existing) as $u) {
        if (!$matcher->targetResolves($u, $storeId)) {
            $dead[$u] = 'unresolved';
        }
    }
    if ($http) {
        fwrite(STDERR, 'checking ' . count($existing) . " existing targets over HTTP...\n");
        foreach (mmdHttpStatus(array_keys($existing)) as $u => $code) {
            if ($code === 404 || $code === 410) {
                $dead[$u] = 'http ' . $code;
            }
        }
    }
    fwrite(STDERR, count($dead) . ' of ' . count($existing) . " existing targets are dead\n");

    // ---- 2. plan: repair dead, fill empty ----
    $plan = array();
    $junk = 0;
    foreach ($rows as $r) {
        $old = trim((string) $r['redirect']);
        if ($old !== '' && !isset($dead[$old])) {
            continue;
        }
        $m = $matcher->match($r['query_text'], $storeId, array_keys($dead));
        if ($m === null) {
            if ($old === '') {
                $junk++;
            } else {
                $plan[] = array('clear', $r, null, 'dead-no-match');
            }
            continue;
        }
        $plan[] = array($old === '' ? 'fill' : 'repair', $r, $m['url'], $m['tier']);
    }

    // ---- 3. prove every new target live; re-match around the dead ones ----
    if ($http) {
        for ($pass = 0; $pass < 3; $pass++) {
            $new = array();
            foreach ($plan as $p) {
                if ($p[2] !== null) {
                    $new[$p[2]] = true;
                }
            }
            fwrite(STDERR, 'checking ' . count($new) . " proposed targets over HTTP...\n");
            $bad = array();
            foreach (mmdHttpStatus(array_keys($new)) as $u => $code) {
                if ($code !== 200) {
                    $bad[$u] = $code;
                    $dead[$u] = 'http ' . $code;
                }
            }
            if (!$bad) {
                break;
            }
            fwrite(STDERR, 'not live, re-matching: ' . json_encode($bad) . "\n");
            foreach ($plan as $i => $p) {
                if ($p[2] !== null && isset($bad[$p[2]])) {
                    $m = $matcher->match($p[1]['query_text'], $storeId, array_keys($dead));
                    $plan[$i][2] = $m ? $m['url'] : null;
                    $plan[$i][3] = $m ? $m['tier'] : 'no-live-target';
                }
            }
        }
        foreach ($plan as $i => $p) {
            if ($p[2] !== null && isset($dead[$p[2]])) {
                $plan[$i][2] = null; // still not proven live after 3 passes
            }
        }
    }

    // ---- 4. report + write ----
    $final = array();
    foreach ($plan as $p) {
        list($action, $r, $url, $tier) = $p;
        if ($url === null) {
            if (trim((string) $r['redirect']) === '') {
                continue; // nothing to fill with
            }
            $action = 'clear';
        }
        $final[] = array($action, $r, $url, $tier);
    }
    if ($apply && $final) {
        $file = Mage::getBaseDir('var') . '/search-redirect-backfill-' . $store->getCode() . '-' . date('Ymd-His') . '.tsv';
        $lines = array();
        foreach ($final as $p) {
            $lines[] = $p[1]['query_id'] . "\t" . (string) $p[1]['redirect'];
        }
        file_put_contents($file, implode("\n", $lines) . "\n");
        fwrite(STDERR, "old values saved to {$file}\n");
    }
    $counts = array();
    foreach ($final as $p) {
        list($action, $r, $url, $tier) = $p;
        $counts[$action . ':' . $tier] = isset($counts[$action . ':' . $tier]) ? $counts[$action . ':' . $tier] + 1 : 1;
        $text = str_replace(array("\t", "\n", "\r"), ' ', $r['query_text']);
        echo implode("\t", array($action, $r['query_id'], $r['popularity'], $text, (string) $r['redirect'], (string) $url, $tier)), "\n";
        if ($apply) {
            $conn->update(
                'catalogsearch_query',
                $url === null ? array('redirect' => null) : array('redirect' => $url, 'num_results' => 1, 'is_processed' => 1),
                array('query_id = ?' => (int) $r['query_id'])
            );
        }
    }
    ksort($counts);
    fwrite(STDERR, ($apply ? 'APPLIED ' : 'DRY RUN ') . json_encode($counts) . " junk-left-alone={$junk}\n");
}
