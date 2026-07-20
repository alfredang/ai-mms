<?php
/**
 * POST /agent/api_content - marketing / content updates (copy, badges).
 * See docs/agent-api-spec.md.
 */
class MMD_AgentApi_Api_ContentController extends Mage_Core_Controller_Front_Action
{
    public function indexAction()
    {
        Mage::helper('mmd_agentapi')->dispatch($this, 'content');
    }
}
