<?php
/**
 * POST /agent/api_ops - website / MMS operations (reindex, flush, enable/disable).
 * See docs/agent-api-spec.md.
 */
class MMD_AgentApi_Api_OpsController extends Mage_Core_Controller_Front_Action
{
    public function indexAction()
    {
        Mage::helper('mmd_agentapi')->dispatch($this, 'ops');
    }
}
