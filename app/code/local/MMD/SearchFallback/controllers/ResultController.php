<?php
require_once 'Mage/CatalogSearch/controllers/ResultController.php';

/**
 * Overrides Mage_CatalogSearch_ResultController::indexAction so that
 * when catalogsearch_query.redirect points at a slug that no longer
 * resolves (category renamed / deleted / wrong store), we ignore the
 * stale redirect and fall through to the normal search-results page
 * instead of bouncing the learner to a 404.
 *
 * Why this exists: queries like "statistics" / "photoshop" had a
 * redirect column pointing at <topic>-courses-in-singapore.html, a
 * page that was removed in a category cleanup. Magento blindly 302'd
 * to it, learner saw "Whoops, our bad..." 404. Now we check the
 * target against core_url_rewrite + cms_page first; redirect only
 * when the destination actually resolves on the current store.
 */
class MMD_SearchFallback_ResultController extends Mage_CatalogSearch_ResultController
{
    public function indexAction()
    {
        /** @var Mage_CatalogSearch_Model_Query $query */
        $query = Mage::helper('catalogsearch')->getQuery();
        $query->setStoreId(Mage::app()->getStore()->getId());

        if ($query->getQueryText() != '') {
            // Course-code search: a query that exactly matches the SKU of an
            // enabled, visible course goes straight to the course page
            // (e.g. "TGS-2026061583" → /wsq-information-security-....html).
            // Checked before the min-length branch so short codes like "C6"
            // work too.
            $skuUrl = $this->_courseCodeUrl($query->getQueryText());
            if ($skuUrl !== null) {
                $this->getResponse()->setRedirect($skuUrl);
                return;
            }

            if (Mage::helper('catalogsearch')->isMinQueryLength()) {
                $query->setId(0)
                    ->setIsActive(1)
                    ->setIsProcessed(1);
            } else {
                if ($query->getId()) {
                    $query->setPopularity($query->getPopularity() + 1);
                } else {
                    $query->setPopularity(1);
                }

                $redirectUrl = (string) $query->getRedirect();
                if ($redirectUrl !== '' && $this->_redirectTargetResolves($redirectUrl)) {
                    $query->save();
                    $this->getResponse()->setRedirect($redirectUrl);
                    return;
                }
                // Stale redirect — clear it so future hits don't repeat
                // the lookup, then fall through to the search results.
                if ($redirectUrl !== '') {
                    try {
                        $query->setRedirect(null);
                    } catch (Exception $e) {
                        Mage::logException($e);
                    }
                }
                $query->prepare();
            }

            Mage::helper('catalogsearch')->checkNotes();

            $this->loadLayout();
            $this->_initLayoutMessages('catalog/session');
            $this->_initLayoutMessages('checkout/session');
            $this->renderLayout();

            if (!Mage::helper('catalogsearch')->isMinQueryLength()) {
                $query->save();
            }
        } else {
            $this->_redirectReferer();
        }
    }

    /**
     * If the search text is exactly a course code (product SKU), return the
     * course page URL for the current store; null otherwise.
     *
     * Only redirects when the course would actually render: enabled, visible
     * as a standalone page, and assigned to this store's website — a disabled
     * course falls through to normal search results instead of bouncing the
     * learner to a 404.
     */
    protected function _courseCodeUrl($queryText)
    {
        $sku = trim((string) $queryText);
        if ($sku === '') {
            return null;
        }

        // Indexed exact lookup (case-insensitive via column collation).
        $productId = Mage::getModel('catalog/product')->getResource()->getIdBySku($sku);
        if (!$productId) {
            return null;
        }

        $store = Mage::app()->getStore();
        $product = Mage::getModel('catalog/product')
            ->setStoreId($store->getId())
            ->load($productId);
        if (!$product->getId()
            || (int) $product->getStatus() !== Mage_Catalog_Model_Product_Status::STATUS_ENABLED
            || !$product->isVisibleInSiteVisibility()
            || !in_array($store->getWebsiteId(), array_map('intval', (array) $product->getWebsiteIds()), true)
        ) {
            return null;
        }

        return $product->getProductUrl();
    }

    /**
     * Does the redirect target actually resolve on the current store?
     *
     * Accepts:
     *   - absolute URLs on the current store base (host match required)
     *   - relative paths like "/foo.html" or "foo.html"
     *
     * Returns true if the target maps to a known core_url_rewrite row
     * (product / category / custom rewrite) OR a published cms_page
     * with identifier == the path's slug, OR an http(s) URL whose host
     * isn't ours (external — let it through, not our problem). Returns
     * false for stale .html slugs that don't resolve to anything.
     */
    protected function _redirectTargetResolves($url)
    {
        $url = trim($url);
        if ($url === '') return false;

        // External URL — trust it; user explicitly typed a non-local
        // redirect into the search-query admin.
        if (preg_match('#^https?://#i', $url)) {
            $host = parse_url($url, PHP_URL_HOST);
            $storeHost = parse_url(Mage::app()->getStore()->getBaseUrl(), PHP_URL_HOST);
            if ($host && $storeHost && strcasecmp($host, $storeHost) !== 0) {
                return true;
            }
            // Same host — fall through to path-resolution below.
            $url = (string) parse_url($url, PHP_URL_PATH);
        }

        $path = ltrim((string) $url, '/');
        if ($path === '') return false;

        // Strip leading "index.php/" if present (URL rewrite key).
        if (strpos($path, 'index.php/') === 0) {
            $path = substr($path, strlen('index.php/'));
        }

        $storeId = (int) Mage::app()->getStore()->getId();

        // core_url_rewrite covers product, category, and arbitrary
        // request_path → target_path rows. Validate that the row's
        // target_path itself isn't also a missing-page (chase one hop
        // for the common case where redirect points at a 301 alias).
        $rewrite = Mage::getModel('core/url_rewrite');
        $rewrite->setStoreId($storeId)->loadByRequestPath($path);
        if ($rewrite->getId()) {
            $target = (string) $rewrite->getTargetPath();
            if ($target === '' || strcasecmp($target, $path) === 0) {
                return true;
            }
            // Don't recurse forever — just verify the immediate target
            // is also rewriteable OR is a built-in front controller
            // route (contains a "/" but isn't a leftover slug).
            $hop = Mage::getModel('core/url_rewrite');
            $hop->setStoreId($storeId)->loadByRequestPath($target);
            if ($hop->getId()) return true;
            // Built-in route (catalog/category/view/id/N, cms/page/view, etc.)
            if (strpos($target, '/') !== false && !preg_match('#\.html$#i', $target)) {
                return true;
            }
            return false;
        }

        // CMS page fallback — the slug might be a CMS page identifier
        // (with the .html suffix stripped).
        $cmsId = preg_replace('#\.html$#i', '', $path);
        if ($cmsId !== '') {
            $cms = Mage::getModel('cms/page')->load($cmsId, 'identifier');
            if ($cms->getId() && (int) $cms->getIsActive() === 1) {
                $stores = $cms->getStores();
                if (in_array(0, (array) $stores) || in_array($storeId, (array) $stores)) {
                    return true;
                }
            }
        }

        return false;
    }
}
