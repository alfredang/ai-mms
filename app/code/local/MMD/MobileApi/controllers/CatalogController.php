<?php
/**
 * GET /mobileapi/catalog — the public non-WSQ (C-prefix) course catalog of
 * this site, the same courses anyone can browse on the website. No key: it
 * carries nothing that is not already on the public course pages.
 */
class MMD_MobileApi_CatalogController extends MMD_MobileApi_Controller_Base
{
    public function indexAction()
    {
        return $this->_guard(function () {
            $catalog = Mage::helper('mmd_mobileapi/catalog')->courses();
            return $this->_ok(array(
                'site'    => $this->_helper()->siteInfo(),
                'count'   => count($catalog['courses']),
                'built_at'=> $catalog['built_at'],
                'courses' => $catalog['courses'],
            ));
        });
    }
}
