<?php
/**
 * Central source of truth for the active admin "branch" (= store view).
 *
 * The branch tab in the admin UI is just Magento's native store switcher,
 * restyled as pills. We honour Magento's existing ?store=N URL convention
 * so every store-scoped grid filters for free. The helper resolves which
 * store is active via:  URL param  >  admin session  >  Singapore (1).
 */
class MMD_Branchscope_Helper_Data extends Mage_Core_Helper_Abstract
{
    const SESSION_KEY      = 'mmd_branchscope_current_store_id';
    const DEFAULT_STORE_ID = 1; // Singapore
    const URL_PARAM        = 'store';
    const ALL_STORES_ID    = 0; // matches Magento's "All Store Views"

    /**
     * Has the user (URL or session) explicitly picked a branch? Used by
     * RoleManager to decide whether the pill choice should override the
     * email-derived country default. Returns false during fresh login
     * before any session seed.
     *
     * @return bool
     */
    public function hasExplicitChoice()
    {
        $req = Mage::app()->getRequest();
        $url = $req->getParam(self::URL_PARAM, null);
        if ($url !== null && ctype_digit((string) $url)) {
            return true;
        }
        $session = $this->_session();
        if ($session) {
            $val = $session->getData(self::SESSION_KEY);
            if ($val !== null && ctype_digit((string) $val)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Resolved store id used for filtering. 0 = All Store Views.
     *
     * @return int
     */
    public function getActiveStoreId()
    {
        $req = Mage::app()->getRequest();
        $raw = $req->getParam(self::URL_PARAM, null);
        if ($raw !== null && $raw !== '' && ctype_digit((string) $raw)) {
            return (int) $raw;
        }
        // Always default to Singapore when no explicit ?store= is in the
        // URL. We intentionally do NOT honour session-stickiness here —
        // every fresh page load reverts to Singapore so the active branch
        // never silently follows the user across unrelated pages.
        return self::DEFAULT_STORE_ID;
    }

    /**
     * Persist the store id from the current request to the admin session.
     * Called from the predispatch observer so a URL pill click sticks for
     * the rest of the navigation. Also handles legacy aliases:
     *   ?branch=N        (Registrations grid) — pre-Branchscope param
     *   ?branch=all      → ?store=0
     *   ?dev_country=NAME (Dashboard) — pre-Branchscope param
     */
    public function persistFromRequest()
    {
        $req = Mage::app()->getRequest();

        // Legacy alias: ?branch= → ?store=
        $branch = $req->getParam('branch', null);
        if ($branch !== null && $req->getParam(self::URL_PARAM, null) === null) {
            if ((string) $branch === 'all') {
                $req->setParam(self::URL_PARAM, self::ALL_STORES_ID);
            } elseif (ctype_digit((string) $branch)) {
                $req->setParam(self::URL_PARAM, (int) $branch);
            }
        }

        // Legacy alias: ?dev_country=Singapore → ?store=1
        $devCountry = (string) $req->getParam('dev_country', '');
        if ($devCountry !== '' && $req->getParam(self::URL_PARAM, null) === null) {
            $map = array(
                'All' => 0, 'Singapore' => 1, 'Nigeria' => 4,
            );
            if (isset($map[$devCountry])) {
                $req->setParam(self::URL_PARAM, $map[$devCountry]);
            }
        }

        $raw = $req->getParam(self::URL_PARAM, null);
        if ($raw === null || !ctype_digit((string) $raw)) {
            return;
        }
        $session = $this->_session();
        if ($session) {
            $session->setData(self::SESSION_KEY, (int) $raw);
        }
    }

    /**
     * Pill option list: [ ['id'=>0,'name'=>'All'], ['id'=>1,'name'=>'Singapore'], ... ]
     * Ordered by store_id ASC which by design maps to SG, NG.
     *
     * @return array
     */
    public function getStorePillOptions()
    {
        $options = array(
            array('id' => self::ALL_STORES_ID, 'name' => $this->__('All')),
        );
        $stores = Mage::getModel('core/store')->getCollection()->setOrder('store_id', 'ASC');
        foreach ($stores as $store) {
            if ((int) $store->getId() === 0) {
                continue; // skip admin store
            }
            $name = preg_replace('/\s*Store View\s*$/i', '', $store->getName());
            $options[] = array(
                'id'   => (int) $store->getId(),
                'name' => $name,
            );
        }
        return $options;
    }

    /**
     * Canonical pill set used by the global Store View bar (mirrors the
     * Edit Course inline design). Two active country stores
     * (SG/NG). Excludes admin (store_id=0) only.
     * Each option carries a 2-letter `code` for the
     * pill badge, matching the class_id prefix scheme (SG000042 etc.).
     *
     * @return array
     */
    public function getCountryStorePillOptions()
    {
        // Map preserves the desired pill order.
        $codeMap = array(
            1 => 'SG',
            4 => 'NG',
        );

        // In country mode (standalone NG/etc. instance) only show SG +
        // the instance's own country pill. All other stores live in the DB
        // (copied from the SG seed) but are irrelevant to this operator.
        if (strtolower((string) getenv('MMS_MODE')) === 'country') {
            $countryCode  = strtoupper((string) getenv('MMS_COUNTRY_CODE'));
            $codeToId     = array_flip($codeMap); // e.g. 'NG' => 4
            $countryStoreId = isset($codeToId[$countryCode]) ? (int) $codeToId[$countryCode] : null;
            $allowed = array(1); // SG always shown
            if ($countryStoreId && $countryStoreId !== 1) {
                $allowed[] = $countryStoreId;
            }
            foreach (array_keys($codeMap) as $sid) {
                if (!in_array($sid, $allowed, true)) {
                    unset($codeMap[$sid]);
                }
            }
        }

        $options = array();
        foreach ($codeMap as $sid => $code) {
            $store = Mage::app()->getStore($sid);
            if (!$store || !$store->getId()) {
                continue; // skip if a store row is missing in this env
            }
            $name = preg_replace('/\s*Store View\s*$/i', '', (string) $store->getName());
            $options[] = array(
                'id'   => $sid,
                'name' => $name,
                'code' => $code,
            );
        }
        return $options;
    }

    /**
     * Build the pill URL for a given store id. Anchored on the current
     * route ONLY (module/controller/action) — strips path params like
     * /store/X/section/Y from the previous URL so we don't end up with
     * both ?store=1 in the query AND /store/2/ in the path fighting.
     *
     * @param int $storeId
     * @return string
     */
    public function buildPillUrl($storeId)
    {
        $req   = Mage::app()->getRequest();
        $route = $req->getRouteName() . '/' . $req->getControllerName() . '/' . $req->getActionName();
        $extra = array();
        // Preserve path-segment params that are meaningful on specific controllers
        // (e.g. bucket=ongoing on the Classes grid) so a store-pill click keeps
        // the user on the same sub-view rather than silently resetting it.
        if (($bucket = (string) $req->getParam('bucket', '')) !== '') {
            $extra['bucket'] = $bucket;
        }
        return Mage::helper('adminhtml')->getUrl(
            $route,
            $extra + array('_query' => array(self::URL_PARAM => (int) $storeId))
        );
    }

    /**
     * Should pills render on the current admin route?
     *
     * "Store-scoped" means the page presents store-specific data: catalogs,
     * orders, customers, CMS, reports, dashboard, newsletter. Pages that
     * are inherently global (Permissions, Cache, Manage Stores, Role
     * Management UI, Configuration) return false → pills suppressed.
     *
     * @return bool
     */
    public function isStoreScopedRoute()
    {
        $req         = Mage::app()->getRequest();
        $module      = strtolower((string) $req->getModuleName());
        $controller  = strtolower((string) $req->getControllerName());
        $action      = strtolower((string) $req->getActionName());

        // Only ever applies under the adminhtml frontend.
        if ($module === '' || $controller === '') {
            return false;
        }

        // Pills belong on LIST / GRID pages only. View / edit / new / form
        // pages are scoped to a single record (one invoice, one product,
        // one customer) — clicking a branch on a detail page doesn't make
        // sense and risks breaking record-specific layouts that don't
        // play nicely with arbitrary blocks injected via <default>.
        static $detailActions = array(
            'view'     => true, 'edit'      => true, 'new'    => true,
            'save'     => true, 'delete'    => true, 'print'  => true,
            'pdfinvoices'   => true, 'pdfshipments' => true,
            'pdfcreditmemos'=> true, 'pdfprintinvoice' => true,
            'addcomment'    => true, 'creditmemos'   => true,
            'cancel'        => true, 'hold'    => true, 'unhold' => true,
            'transactions'  => true, 'reorder' => true, 'invoice' => true,
            'shipment'      => true, 'creditmemo'    => true,
            'updateqty'     => true, 'updatecomment' => true,
            'voidpayment'   => true, 'capture' => true, 'void' => true,
            'massassign'    => true,
        );
        if (isset($detailActions[$action])) {
            return false;
        }

        // Explicit allow-list of controllers that show store-scoped data.
        // Anything not listed is treated as non-store-scoped (pills hidden).
        // Allow-list contract: a controller belongs here ONLY if its grid
        // / page actually honours the ?store= URL param. Showing the
        // Store View bar but ignoring the param violates the "Filtering
        // contract (MANDATORY)" rule in the backend-design skill. When
        // wiring a new controller, also wire its grid (see Reviews fix
        // pattern in MMD_Adminhtml_Block_Review_Grid::_beforeLoadCollection).
        //
        // Suppressed by design:
        //   - newsletter_template, newsletter_problem: templates are
        //     global; problems join indirectly through queue/subscriber.
        //   - tax_class, tax_rate, tax_rule: tax rules are global /
        //     website-scoped, not per-store.
        //   - report_sales, report_product, report_customer, report_review,
        //     report_tag, report_search: stock reports use their own
        //     date/store filter form (getFilterData()->getStoreIds()).
        //     Wiring them needs setStoreIds() BEFORE parent _prepareCollection,
        //     not the _beforeLoadCollection pattern. Re-add here only
        //     after the override ships.
        static $allow = array(
            'dashboard'         => true,
            'catalog_product'   => true,
            'catalog_category'  => true,
            'sales_order'       => true,
            'sales_invoice'     => true,
            'sales_shipment'    => true,
            'sales_creditmemo'  => true,
            'sales_transactions'=> true,
            'sales_billing_agreement' => true,
            'sales_recurring_profile' => true,
            'customer'          => true,
            'cms_page'          => true,
            'cms_block'         => true,
            'newsletter_queue'  => true,
            'newsletter_subscriber' => true,
            'promo_catalog'     => true,
            'promo_quote'       => true,
            'report_shopcart'   => true, // Abandoned/Grid reads ?store= natively
            'seoaudit'          => true,
            'leads'             => true,
        );

        return isset($allow[$controller]);
    }

    /**
     * @return Mage_Admin_Model_Session|null
     */
    protected function _session()
    {
        try {
            return Mage::getSingleton('admin/session');
        } catch (Exception $e) {
            return null;
        }
    }
}
