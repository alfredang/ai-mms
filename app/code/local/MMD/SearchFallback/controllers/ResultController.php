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
    /** @var MMD_SearchFallback_Model_Matcher|null */
    protected $_matcher = null;

    public function indexAction()
    {
        /** @var Mage_CatalogSearch_Model_Query $query */
        $query = Mage::helper('catalogsearch')->getQuery();
        $query->setStoreId(Mage::app()->getStore()->getId());
        $this->_applyTokenSynonyms($query);

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
                // Stale redirect (course disabled, category removed) — drop it
                // so the auto-redirect below can pick a live target instead.
                if ($redirectUrl !== '' && !$this->_redirectTargetResolves($redirectUrl)) {
                    $query->setRedirect(null);
                    $redirectUrl = '';
                }
                $redirectUrl = $this->_autoRedirect($query, $redirectUrl);
                if ($redirectUrl !== '') {
                    $query->save();
                    $this->_logDailyHit($query);
                    $this->getResponse()->setRedirect($redirectUrl);
                    return;
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
                $this->_logDailyHit($query);
            }
        } else {
            $this->_redirectReferer();
        }
    }

    /**
     * Per-day hit log (mmd_search_term_daily, migration 1931) behind the dashboard's
     * Popular Search Terms period filter — catalogsearch_query only keeps a cumulative
     * popularity. A logging failure must never break a storefront search.
     */
    protected function _logDailyHit(Mage_CatalogSearch_Model_Query $query)
    {
        if (!$query->getId()) {
            return;
        }
        try {
            $res = Mage::getSingleton('core/resource');
            $res->getConnection('core_write')->query(
                'INSERT INTO ' . $res->getTableName('mmd_search_term_daily')
                . ' (query_id, day, hits) VALUES (?, ?, 1) ON DUPLICATE KEY UPDATE hits = hits + 1',
                array((int) $query->getId(), Mage::getSingleton('core/date')->date('Y-m-d'))
            );
        } catch (Exception $e) {
            Mage::logException($e);
        }
    }

    /**
     * Word-level synonym expansion: course names use both "GenAI" and
     * "Generative AI", so a search phrased with either spelling must return
     * both sets (e.g. "business presentation with genai" ≡ "business
     * presentations with generative ai"). Stock synonym_for only fires on a
     * WHOLE-query match, so a "genai" synonym row never helps a longer
     * phrase — instead we expand the token in-place at search time and let
     * Fulltext::prepareResult's synonym_for hook search the expanded text.
     * The expansion carries BOTH spellings so neither name set drops out.
     * A synonym_for already curated in admin always wins; the expanded text
     * persists on the row via the controller's existing $query->save().
     */
    protected function _applyTokenSynonyms(Mage_CatalogSearch_Model_Query $query)
    {
        if ((string) $query->getSynonymFor() !== '') {
            return;
        }
        $text = (string) $query->getQueryText();
        $hasGenai = (bool) preg_match('/\bgenai\b/i', $text);
        $hasGenerativeAi = (bool) preg_match('/\bgenerative\s+ai\b/i', $text);
        if ($hasGenai === $hasGenerativeAi) {
            return; // neither spelling present, or both already are
        }
        $pattern = $hasGenai ? '/\bgenai\b/i' : '/\bgenerative\s+ai\b/i';
        $query->setSynonymFor(preg_replace($pattern, 'generative ai genai', $text, 1));
    }

    /**
     * If the search text is exactly a course code (product SKU), return the
     * course page URL for the current store; null otherwise.
     *
     * Only redirects when the course page would actually render (canShow():
     * enabled and visible, or a TGS- course the TMS availability sync hid from
     * listings but keeps reachable) and is assigned to this store's website — a
     * disabled course falls through to normal search results instead of
     * bouncing the learner to a 404.
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
            || !Mage::helper('catalog/product')->canShow($product)
            || !in_array($store->getWebsiteId(), array_map('intval', (array) $product->getWebsiteIds()), true)
        ) {
            return null;
        }

        return $product->getProductUrl();
    }

    /**
     * Does the redirect target actually render on the current store?
     * Logic lives in the matcher so the backfill script validates identically.
     */
    protected function _redirectTargetResolves($url)
    {
        return $this->_matcher()->targetResolves($url, Mage::app()->getStore()->getId());
    }

    /**
     * Instantiated by class name, not Mage::getSingleton(): the model alias
     * lives in config.xml, and a deploy serves the OLD cached config until the
     * config cache is flushed — an alias lookup would fatal every search.
     */
    protected function _matcher()
    {
        if ($this->_matcher === null) {
            $this->_matcher = new MMD_SearchFallback_Model_Matcher();
        }
        return $this->_matcher;
    }

    /**
     * No redirect on this term (or only the generic catalog fallback, which a
     * newer course may now beat): ask the matcher for one and store it on the
     * row, so the term never ends on a zero-result page. Returns '' when the
     * feature is off, the text is junk, or matching fails — the caller then
     * serves the normal results page.
     */
    protected function _autoRedirect(Mage_CatalogSearch_Model_Query $query, $current)
    {
        try {
            $storeId = Mage::app()->getStore()->getId();
            $matcher = $this->_matcher();
            if (!$matcher->isEnabled($storeId)) {
                return $current;
            }
            if ($current !== '' && $current !== $matcher->fallbackUrl($storeId)) {
                return $current;
            }
            $match = $matcher->match($query->getQueryText(), $storeId);
            if ($match === null || $match['url'] === $current) {
                return $current;
            }
            $query->setRedirect($match['url'])->setNumResults(1)->setIsProcessed(1);
            return $match['url'];
        } catch (Throwable $e) {
            Mage::log('search auto-redirect failed: ' . $e->getMessage(), Zend_Log::ERR);
            return $current;
        }
    }
}
