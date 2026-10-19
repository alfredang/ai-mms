<?php
/**
 * Full Page Cache (MMD) — site speed Step 5. Whole public pages for anonymous visitors, served before the page is
 * built, from the normal Magento cache backend (tag MMD_FPC, cache type mmd_fpc).
 *
 * CACHED only when ALL hold: frontend, switched on (config mmd_fpc/general/enabled + cache type enabled), GET, not AJAX,
 * one of the public page types below, visitor NOT logged in, NO cart/quote, NO pending messages, default currency,
 * no NO_CACHE cookie, only allowed URL parameters ($_allowedParams + tracking). Only HTTP 200 HTML pages are stored.
 * NEVER cached: admin, login/account, LMS, cart, checkout/booking, any POST/form submission, confirmation pages,
 * anything personalised (all of these are simply not in the page-type list, and visitor state bypasses the cache).
 * The per-visitor form key in a cached page is replaced at serving time with the visitor's own key.
 *
 * CLEARED (whole MMD_FPC tag — ~500 pages, so all-or-nothing is simple and safe):
 *  - when a course, custom option/schedule, category, CMS page/block, blog post, config value, catalogue price rule or
 *    index process is saved/deleted (admin, API, cron, sync, CLI) — at the first change AND again at the end of the
 *    request, so a long job (e.g. the SG->MY sync) never leaves a half-updated page cached
 *  - after any admin POST (screens that write with SQL) and any POST to the write APIs (agent, courses)
 *  - every day at 00:00 and 08:00 (class dates past their cut-off drop off at 08:00 — see etc/config.xml crontab)
 *  - System > Cache Management > Flush, and after lifetime seconds (mmd_fpc/general/lifetime, default 1800) anyway
 * Response header X-MMD-FPC: HIT / MISS shows what happened (for the staging report).
 */
class MMD_FullPageCache_Model_Observer
{
    const TAG = 'MMD_FPC';
    const TYPE = 'mmd_fpc';
    const FORM_KEY_PLACEHOLDER = '{{MMD_FPC_FORM_KEY}}';
    const TRACKING_PARAMS = '/^(utm_|gclid$|fbclid$|_ga$|msclkid$)/';

    /** the only URL parameters a cached page may have, with the values allowed for each */
    protected $_allowedParams = array(
        'p'     => '/^\d{1,3}$/',                                       // page number
        'dir'   => '/^(asc|desc)$/',
        'order' => '/^(position|name|sku|price)$/',
        'limit' => '/^(\d{1,3}|all)$/',
        'mode'  => '/^(grid|list)$/',
    );

    /** full action names whose pages are public and identical for every anonymous visitor */
    protected $_pages = array(
        'cms_index_index',          // homepage
        'cms_page_view',            // CMS pages (About Us, FAQ, HRD Corp hub, ...)
        'catalog_category_view',    // category pages
        'catalog_product_view',     // course pages
        'mmd_blog_index_index',     // blog list
        'mmd_blog_index_tag',       // blog tag list
        'mmd_blog_index_view',      // blog post
    );

    /** models whose save/delete can change a public page */
    protected $_watched = array(
        'Mage_Catalog_Model_Product', 'Mage_Catalog_Model_Category', 'Mage_Catalog_Model_Product_Option',
        'Mage_Catalog_Model_Product_Option_Value', 'Mage_Cms_Model_Page', 'Mage_Cms_Model_Block',
        'Mage_Core_Model_Config_Data', 'Mage_CatalogRule_Model_Rule', 'Mage_Index_Model_Process', 'MMD_Blog_Model_Post',
    );

    protected static $_shutdownCleanRegistered = false;

    // ---------------------------------------------------------------- serve (before the page is built)

    public function serve(Varien_Event_Observer $observer)
    {
        $action = $observer->getEvent()->getControllerAction();
        $request = $action->getRequest();
        if (!$this->_isCacheable($action)) {
            return;
        }
        $key = $this->_key($request);
        $html = Mage::app()->loadCache($key);
        if ($html === false || $html === '') {
            Mage::register('mmd_fpc_key', $key, true);   // MISS: store() saves the finished page
            return;
        }
        $html = str_replace(self::FORM_KEY_PLACEHOLDER, Mage::getSingleton('core/session')->getFormKey(), $html);
        $action->getResponse()
            ->setHeader('Content-Type', 'text/html; charset=UTF-8', true)
            ->setHeader('X-MMD-FPC', 'HIT', true)
            ->setBody($html);
        $action->setFlag('', Mage_Core_Controller_Varien_Action::FLAG_NO_DISPATCH, true);
        Mage::register('mmd_fpc_hit', true, true);
    }

    // ---------------------------------------------------------------- store (after the page is built)

    public function store(Varien_Event_Observer $observer)
    {
        $key = Mage::registry('mmd_fpc_key');
        if (!$key || Mage::registry('mmd_fpc_hit')) {
            return;
        }
        $response = $observer->getEvent()->getFront()->getResponse();
        if ($response->getHttpResponseCode() != 200 || $response->isRedirect() || $response->isException()) {
            return;
        }
        foreach ($response->getHeaders() as $h) {
            if (strcasecmp($h['name'], 'Content-Type') === 0 && stripos($h['value'], 'text/html') === false) {
                return;
            }
        }
        $body = $response->getBody();
        if (strlen($body) < 1000 || stripos($body, '</html>') === false || $this->_visitorHasState()) {
            return;   // incomplete page, or the visitor gained a login/cart/message while it was built
        }
        $formKey = Mage::getSingleton('core/session')->getFormKey();
        if ($formKey !== '') {
            $body = str_replace($formKey, self::FORM_KEY_PLACEHOLDER, $body);
        }
        Mage::app()->saveCache($body, $key, array(self::TAG), (int) Mage::getStoreConfig('mmd_fpc/general/lifetime') ?: 1800);
        $response->setHeader('X-MMD-FPC', 'MISS', true);
    }

    // ---------------------------------------------------------------- clearing

    public function cleanOnModelChange(Varien_Event_Observer $observer)
    {
        $object = $observer->getEvent()->getObject();
        if (!$object) {
            return;
        }
        foreach ($this->_watched as $class) {
            if ($object instanceof $class) {
                $this->_cleanNowAndAtEnd(get_class($object) . ' #' . $object->getId() . ' ' . $observer->getEvent()->getName());
                return;
            }
        }
    }

    public function cleanOnWriteRequest(Varien_Event_Observer $observer)
    {
        $action = $observer->getEvent()->getControllerAction();
        if (!$action || !$action->getRequest()->isPost()) {
            return;
        }
        $module = $action->getRequest()->getModuleName();
        if ($action instanceof Mage_Adminhtml_Controller_Action || in_array($module, array('agent', 'courses'), true)) {
            $this->cleanAll('POST ' . $action->getFullActionName());
        }
    }

    /**
     * whole page cache (cron job, sync, scripts). Every clear is logged to var/log/mmd_fpc.log with its reason, so the
     * hit rate can be explained on live. (Cron passes a schedule object, not a string.)
     */
    public function cleanAll($reason = 'manual / cron')
    {
        Mage::app()->cleanCache(array(self::TAG));   // always (cheap), so nothing stale survives a later re-enable
        if (Mage::app()->useCache(self::TYPE)) {       // log only while the cache type is switched on (no noise on SG)
            Mage::log('cleared: ' . (is_string($reason) ? $reason : 'nightly job'), Zend_Log::INFO, 'mmd_fpc.log');
        }
    }

    protected function _cleanNowAndAtEnd($reason)
    {
        $this->cleanAll($reason);
        if (!self::$_shutdownCleanRegistered) {
            self::$_shutdownCleanRegistered = true;
            $self = $this;
            register_shutdown_function(function () use ($self, $reason) { $self->cleanAll('end of request after ' . $reason); });
        }
    }

    // ---------------------------------------------------------------- rules

    protected function _isCacheable(Mage_Core_Controller_Varien_Action $action)
    {
        $request = $action->getRequest();
        if (Mage::app()->getStore()->isAdmin()
            || !Mage::getStoreConfigFlag('mmd_fpc/general/enabled')
            || !Mage::app()->useCache(self::TYPE)
            || !$request->isGet()
            || $request->isXmlHttpRequest()
            || !in_array($action->getFullActionName(), $this->_pages, true)
            || $request->getCookie('NO_CACHE')) {
            return false;
        }
        // only URL parameters the storefront really uses (paging / sorting / view) with sane values; anything else
        // (store switch ___store, SID, filters, made-up parameters) is served normally, never stored — so a bot
        // cannot fill Redis (shared with visitor sessions) with endless ?x=1, ?x=2 ... copies of one page
        foreach ($request->getQuery() as $param => $value) {
            if (preg_match(self::TRACKING_PARAMS, $param)) {
                continue;   // ignored in the key, so they never create extra copies
            }
            if (!isset($this->_allowedParams[$param]) || !is_string($value)
                || !preg_match($this->_allowedParams[$param], $value)) {
                return false;
            }
        }
        return !$this->_visitorHasState();
    }

    /** logged in, has a cart/quote, has pending messages, or chose a non-default currency */
    protected function _visitorHasState()
    {
        if (Mage::getSingleton('customer/session')->isLoggedIn() || Mage::getSingleton('checkout/session')->getQuoteId()) {
            return true;
        }
        foreach (array('core/session', 'catalog/session', 'checkout/session', 'customer/session') as $session) {
            if (Mage::getSingleton($session)->getMessages()->count() > 0) {
                return true;
            }
        }
        $store = Mage::app()->getStore();
        return $store->getCurrentCurrencyCode() !== $store->getDefaultCurrencyCode();
    }

    /** one entry per store + scheme + host + path + query (tracking parameters ignored) */
    protected function _key(Zend_Controller_Request_Http $request)
    {
        $query = $request->getQuery();
        foreach (array_keys($query) as $param) {
            if (preg_match(self::TRACKING_PARAMS, $param)) {
                unset($query[$param]);
            }
        }
        ksort($query);
        $path = strtok($request->getRequestUri(), '?');
        return 'MMD_FPC_' . md5(implode('|', array(Mage::app()->getStore()->getId(), $request->isSecure() ? 's' : 'p',
            $request->getHttpHost(), $path, http_build_query($query))));
    }
}
