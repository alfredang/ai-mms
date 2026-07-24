<?php
/**
 * POST /agent/api_template - schedule-template bulk operations.
 *
 * Op: generate_and_apply { template, start_date, end_date, slot_code? }
 *   Generates class dates from the template's slot code (GAS-ported logic) over
 *   [start_date, end_date], APPENDS the new ones to the template, and applies
 *   the template to EVERY course using it. Append-only (existing dates kept;
 *   admin-added per-course dates are never touched - see admin_managed).
 *
 * This is the ONLY bulk/all-products path. Adding dates to a single course is
 * done per-class with api_classes add_class. All logic lives in the dispatch
 * helper + the template capability model; this controller is thin.
 */
class MMD_AgentApi_Api_TemplateController extends Mage_Core_Controller_Front_Action
{
    public function indexAction()
    {
        Mage::helper('mmd_agentapi')->dispatch($this, 'template');
    }
}
