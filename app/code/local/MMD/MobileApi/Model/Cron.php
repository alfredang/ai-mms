<?php
/**
 * Rebuild the learner apps' catalog cache before it expires, so no app user
 * waits on the ~10 s cold build (products load one at a time), and prune
 * spent OTPs and long-dead sessions.
 */
class MMD_MobileApi_Model_Cron
{
    public function warmCatalog()
    {
        $courses = Mage::helper('mmd_mobileapi/catalog')->build();
        if ($courses) {
            Mage::app()->getCache()->save(
                json_encode(array('built_at' => gmdate('c'), 'courses' => $courses)),
                MMD_MobileApi_Helper_Catalog::CACHE_ID,
                array('MMD_MOBILEAPI'),
                MMD_MobileApi_Helper_Catalog::CACHE_LIFETIME
            );
        }

        $h = Mage::helper('mmd_mobileapi');
        $w = $h->_write();
        $w->delete($h->_table('mmd_mobile_otp'), array('created_at < ?' => $h->utcNow(-86400)));
        $w->delete($h->_table('mmd_mobile_session'), array('expires_at < ?' => $h->utcNow(-30 * 86400)));
    }
}
