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
}
