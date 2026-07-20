<?php
/**
 * POST /agent/api_course - update course info (allowlisted fields).
 * See docs/agent-api-spec.md.
 */
class MMD_AgentApi_Api_CourseController extends Mage_Core_Controller_Front_Action
{
    public function indexAction()
    {
        Mage::helper('mmd_agentapi')->dispatch($this, 'course');
    }
}
