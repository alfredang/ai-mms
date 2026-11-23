<?php
/**
 * The signed-in trainer's classes: the list, one class (sessions, roster,
 * courseware, check-in link) and taking attendance. Limited to classes the
 * trainer is assigned to. The App Review account gets sample data only.
 */
class MMD_MobileApi_TrainerController extends MMD_MobileApi_Controller_Base
{
    public function classesAction()
    {
        if (!$this->_requireTrainer()) return;
        return $this->_guard(function () {
            $classes = $this->_isDemo() ? $this->_demo()->trainerClasses() : $this->_trainer()->classes($this->_email());
            return $this->_ok(array('today' => $this->_helper()->today()) + $classes);
        });
    }

    /** GET ?run_id= */
    public function classAction()
    {
        if (!$this->_requireTrainer()) return;
        return $this->_guard(function () {
            $runId  = (int) $this->_input('run_id');
            $detail = $this->_isDemo() ? $this->_demo()->trainerClassDetail($runId) : $this->_trainer()->classDetail($this->_email(), $runId);
            if (!$detail) {
                return $this->_error(404, 'This class is not on your account.', 'not_found');
            }
            return $this->_ok(array('class' => $detail));
        });
    }

    /** POST {run_id, session_key, records:[{email, present}]} */
    public function attendanceAction()
    {
        if (!$this->_requirePost() || !$this->_requireTrainer()) return;
        return $this->_guard(function () {
            $runId   = (int) $this->_input('run_id');
            $session = (string) $this->_input('session_key', '');
            $records = $this->_input('records', array());
            if (!is_array($records)) $records = array();
            $res = $this->_isDemo()
                ? $this->_demo()->saveTrainerAttendance($runId)
                : $this->_trainer()->saveAttendance($this->_email(), $runId, $session, $records);
            if (!$res['success']) {
                return $this->_error(409, $res['message'], 'attendance_rejected');
            }
            return $this->_ok(array('message' => $res['message']));
        });
    }

    /**
     * POST {run_id, message} posts a text announcement to the class;
     * POST {run_id, delete_id} deletes one. Answers the class's posts.
     */
    public function announcementAction()
    {
        if (!$this->_requirePost() || !$this->_requireTrainer()) return;
        return $this->_guard(function () {
            $runId = (int) $this->_input('run_id');
            if ($this->_isDemo()) {
                return $this->_ok(array('announcements' => $this->_demo()->announcements(), 'message' => 'Sample class: nothing was posted.'));
            }
            if (!$this->_trainer()->teaches($this->_email(), $runId)) {
                return $this->_error(404, 'This class is not on your account.', 'not_found');
            }
            $page = Mage::helper('mmd_mobileapi/classPage');
            try {
                $deleteId = (int) $this->_input('delete_id', 0);
                $items = $deleteId > 0
                    ? $page->deleteAnnouncement($runId, $deleteId)
                    : $page->postAnnouncement($this->_email(), $runId, (string) $this->_input('message', ''));
            } catch (Exception $e) {
                return $this->_error(422, $e->getMessage(), 'invalid');
            }
            return $this->_ok(array('announcements' => $items, 'message' => $deleteId > 0 ? 'Announcement deleted.' : 'Posted to the class.'));
        });
    }

    /** @return MMD_MobileApi_Helper_Trainer */
    protected function _trainer()
    {
        return Mage::helper('mmd_mobileapi/trainer');
    }

    /** @return MMD_MobileApi_Helper_Demo */
    protected function _demo()
    {
        return Mage::helper('mmd_mobileapi/demo');
    }

    /** GET: the trainer's certifications. POST {items: [{name, issuer, year}]} replaces the list (the same list the web My Profile edits). */
    public function certificationsAction()
    {
        if (!$this->_requireTrainer()) return;
        return $this->_guard(function () {
            $h = $this->_helper();
            if (!$this->getRequest()->isPost()) {
                return $this->_ok(array('certifications' => $h->trainerCertifications($this->_email())));
            }
            $items = $this->_input('items');
            if (!is_array($items)) {
                return $this->_error(422, 'Please send your certifications.', 'invalid_certifications');
            }
            try {
                $list = $h->saveTrainerCertifications($this->_email(), $items);
            } catch (Exception $e) {
                return $this->_error(422, $e->getMessage(), 'invalid_certifications');
            }
            return $this->_ok(array('certifications' => $list, 'message' => 'Certifications saved.'));
        });
    }

    /** The trainer's completed payouts (read from the LMS/TMS). */
    public function payoutsAction()
    {
        if (!$this->_requireTrainer()) return;
        return $this->_guard(function () {
            if ($this->_isDemo()) {
                return $this->_ok(Mage::helper('mmd_mobileapi/demo')->payouts());
            }
            return $this->_ok(Mage::helper('mmd_mobileapi/trainer')->payouts($this->_email()));
        });
    }

    /** Training hours delivered: per class and per month. */
    public function hoursAction()
    {
        if (!$this->_requireTrainer()) return;
        return $this->_guard(function () {
            if ($this->_isDemo()) {
                return $this->_ok(Mage::helper('mmd_mobileapi/demo')->trainingHours());
            }
            return $this->_ok(Mage::helper('mmd_mobileapi/trainer')->trainingHours($this->_email()));
        });
    }
}
