<?php
/**
 * POST /agent/api_classes - edit course schedule (ad-hoc, per course).
 *
 * Named "classes" (not "schedule") to avoid confusion with the pre-existing
 * read-only WSQ feed at /courses/api_schedule. Ops: add_class, update_class,
 * remove_class, assign_trainer. See docs/agent-api-spec.md. All logic lives in
 * the dispatch helper + the schedule capability model; this controller is thin.
 */
class MMD_AgentApi_Api_ClassesController extends Mage_Core_Controller_Front_Action
{
    public function indexAction()
    {
        Mage::helper('mmd_agentapi')->dispatch($this, 'schedule');
    }
}
