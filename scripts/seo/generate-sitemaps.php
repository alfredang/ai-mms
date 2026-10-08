<?php
/**
 * One-shot sitemap generator. Runs all sitemap rows in the `sitemap` table
 * sequentially, the same way the daily cron does — so per-store sitemap files
 * exist as soon as migration 163 has been applied, instead of waiting up to
 * 24 hours for the next cron tick.
 *
 * Country/partner instances (MMS_MODE=country) serve exactly one store, so
 * there only that store gets a sitemap, written to /sitemap.xml with
 * MMS_BASE_URL as the host (see below).
 *
 * Usage:
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/seo/generate-sitemaps.php
 */

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app('admin');

$collection = Mage::getModel('sitemap/sitemap')->getCollection();

// Partner box: the DB is a clone of SG, so it still carries sitemap rows for
// stores this site never serves — including SG store 1, which migration 249
// named sitemap.xml. Left in place, the boot run and the daily sitemap cron
// overwrite /sitemap.xml with com.sg URLs. Keep one row for the served store
// (same MMS_COUNTRY_CODE -> website map as index.php), point it at
// /sitemap.xml, and drop the rest.
if (getenv('MMS_MODE') === 'country') {
    $countryWebsiteMap = ['MY' => 'malaysia', 'GH' => 'ghana', 'NG' => 'nigeria', 'BT' => 'bhutan', 'IN' => 'india'];
    $code    = $countryWebsiteMap[strtoupper((string) getenv('MMS_COUNTRY_CODE'))] ?? '';
    $website = $code ? Mage::getModel('core/website')->load($code, 'code') : null;
    $storeId = ($website && $website->getId()) ? (int) $website->getDefaultStore()->getId() : 0;
    if (!$storeId) {
        printf("[skip] no store for MMS_COUNTRY_CODE=%s\n", getenv('MMS_COUNTRY_CODE'));
        exit(0);
    }

    // entrypoint saves MMS_BASE_URL to core_config_data just before this runs,
    // but this process can still read a config cache from before that save.
    // base_link_url too: its {{unsecure_base_url}} placeholder is already
    // substituted at config load, so it would keep the stale host.
    if (getenv('MMS_BASE_URL')) {
        $url   = rtrim(getenv('MMS_BASE_URL'), '/') . '/';
        $store = Mage::app()->getStore($storeId);
        foreach (['unsecure', 'secure'] as $scheme) {
            $store->setConfig("web/$scheme/base_url", $url);
            $store->setConfig("web/$scheme/base_link_url", $url);
        }
    }

    $keep = null;
    foreach ($collection as $sitemap) {
        if (!$keep && (int) $sitemap->getStoreId() === $storeId) {
            $keep = $sitemap;
            continue;
        }
        printf("[del]  store=%s file=%s (store not served on this site)\n", $sitemap->getStoreId(), $sitemap->getSitemapFilename());
        $sitemap->delete();
    }
    $keep = $keep ?: Mage::getModel('sitemap/sitemap')->setStoreId($storeId);
    $keep->setSitemapFilename('sitemap.xml')->setSitemapPath('/');
    $collection = [$keep];
}

$count = 0;
foreach ($collection as $sitemap) {
    $id = $sitemap->getId();
    $store = $sitemap->getStoreId();
    $file = $sitemap->getSitemapFilename();
    try {
        $sitemap->generateXml();
        $count++;
        printf("[ok]   store=%s file=%s\n", $store, $file);
    } catch (Throwable $e) {
        printf("[fail] store=%s file=%s err=%s\n", $store, $file, $e->getMessage());
    }
}
printf("Generated %d sitemap(s).\n", $count);
