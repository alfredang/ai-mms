<?php
/**
 * Class calendar — month / day / year views over course_runs.
 *
 * Three audiences, one route (adminhtml/calendar/index):
 *   - Trainer role: "My Calendar" — only classes assigned to the signed-in
 *     trainer.
 *   - Learner role: "My Calendar" — only classes the signed-in learner is
 *     enrolled in (course_run_enrolments.learner_email match).
 *   - Admin / Super Admin / Training Provider: "Training Calendar" — every
 *     trainer's classes.
 *
 * Shows CONFIRMED classes only (a trainer is assigned: trainer_user_id or
 * trainer_option_id set) and C-prefix course codes only (TGS-/M- runs never
 * belong in this portal's class calendar).
 *
 * Backend-only. The storefront never hits this controller.
 */
class MMD_RoleManager_Adminhtml_CalendarController extends Mage_Adminhtml_Controller_Action
{
    public function indexAction()
    {
        $role = (string) Mage::helper('mmd_rolemanager')->getActiveRoleCode();
        if ($role === 'trainer') {
            $mode = 'trainer';
        } elseif ($role === 'learner') {
            $mode = 'learner';
        } else {
            $mode = 'admin';
        }

        $this->loadLayout();
        $this->_setActiveMenu('catalog');
        $this->_title($mode === 'admin' ? 'Training Calendar' : 'My Calendar');

        $block = $this->getLayout()->createBlock('core/template')
            ->setTemplate('rolemanager/calendar.phtml')
            ->setData('mode', $mode);
        $this->getLayout()->getBlock('content')->append($block);
        $this->renderLayout();
    }

    /**
     * ACL: trainers and learners see their own calendar; admin-level roles
     * see every trainer's classes.
     */
    protected function _isAllowed()
    {
        $helper = Mage::helper('mmd_rolemanager');
        if (!$helper) return false;
        $role = (string) $helper->getActiveRoleCode();
        return in_array($role, array('trainer', 'learner', 'admin', 'super_admin', 'training_provider'), true);
    }
}
