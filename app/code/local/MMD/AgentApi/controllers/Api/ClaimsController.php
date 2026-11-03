<?php
/**
 * POST /agent/api_claims - HRD Corp claim documents (T3, JD14, Zoom report), Malaysia only.
 * GET  /agent/api_claims/download?t=<token> - one generated document (expiring link, no API key).
 * See docs/agent-api-spec.md.
 */
class MMD_AgentApi_Api_ClaimsController extends Mage_Core_Controller_Front_Action
{
    public function indexAction()
    {
        Mage::helper('mmd_agentapi')->dispatch($this, 'claims');
    }

    public function downloadAction()
    {
        $res   = $this->getResponse();
        $token = (string) $this->getRequest()->getParam('t');
        $res->setHeader('Cache-Control', 'no-store', true)->setHeader('X-Robots-Tag', 'noindex, nofollow', true);

        $dir  = Mage::getBaseDir('var') . DS . 'claim-docs' . DS;
        $meta = preg_match('/^[a-f0-9]{32}$/', $token) && is_file($dir . $token . '.json')
            ? json_decode((string) file_get_contents($dir . $token . '.json'), true) : null;
        if (!is_array($meta) || (int) $meta['expires'] < time() || !is_file($dir . $token . '.docx')) {
            $res->setHttpResponseCode(404)->setHeader('Content-Type', 'text/plain; charset=utf-8', true)
                ->setBody('This document link has expired or does not exist. Ask Kaveh to prepare the document again.');
            return;
        }
        $res->setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', true)
            ->setHeader('Content-Disposition', 'attachment; filename="' . $meta['file'] . '"', true)
            ->setBody(file_get_contents($dir . $token . '.docx'));
    }
}
