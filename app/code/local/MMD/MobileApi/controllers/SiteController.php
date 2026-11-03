<?php
/** GET /mobileapi/site — public facts about this country site for the app. */
class MMD_MobileApi_SiteController extends MMD_MobileApi_Controller_Base
{
    public function indexAction()
    {
        return $this->_guard(function () {
            return $this->_ok(array('site' => $this->_helper()->siteInfo()));
        });
    }

    /** GET — the App Review account's sample certificate (no personal data). */
    public function samplecertificateAction()
    {
        return $this->_guard(function () {
            $pdf = Mage::helper('mmd_mobileapi/demo')->sampleCertificatePdf();
            $this->getResponse()
                ->setHttpResponseCode(200)
                ->setHeader('Content-Type', 'application/pdf', true)
                ->setHeader('Content-Disposition', 'inline; filename="sample-certificate.pdf"', true)
                ->setHeader('Cache-Control', 'no-store', true)
                ->setBody($pdf);
            return $this;
        });
    }
}
