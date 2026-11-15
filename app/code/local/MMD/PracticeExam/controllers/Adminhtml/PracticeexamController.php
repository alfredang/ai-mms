<?php
/**
 * Practice Exam admin endpoints (JSON), used by the dashboard class page and Edit Course.
 *
 *   GET  practiceexam/status?run_id=     -> exam, people + registration state, self-register URL
 *   POST practiceexam/register           -> run_id [, emails[]]: register everyone (or just emails)
 *   GET  practiceexam/course?product_id= -> staff: current link + exam catalogue
 *   POST practiceexam/saveCourse         -> staff: product_id, exam_slug ('' = off)
 */
class MMD_PracticeExam_Adminhtml_PracticeexamController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::helper('mmd_rolemanager')->isRoleAllowed(Mage::helper('mmd_practiceexam')->classRoles());
    }

    protected function _json(array $data, $code = 200)
    {
        $this->getResponse()->setHttpResponseCode($code)
             ->setHeader('Content-Type', 'application/json', true)
             ->setBody(json_encode($data));
    }

    /** @return array|null [run, exam] or null after sending the error response */
    protected function _context()
    {
        $h = Mage::helper('mmd_practiceexam');
        if (!$h->isConfigured()) {
            $this->_json(array('success' => false, 'error' => 'The Tertiary Exams integration is not configured.'), 503);
            return null;
        }
        $run = $h->loadRun((int) $this->getRequest()->getParam('run_id'));
        if (!$run || !$h->canAccessRun($run)) {
            $this->_json(array('success' => false, 'error' => 'Class not found.'), 404);
            return null;
        }
        $exam = $h->getCourseExam($run['product_id']);
        if (!$exam) {
            $this->_json(array('success' => false, 'error' => 'This course has no practice exam.'), 400);
            return null;
        }
        return array($run, $exam);
    }

    public function statusAction()
    {
        $ctx = $this->_context();
        if (!$ctx) return;
        list($run, $exam) = $ctx;
        $h = Mage::helper('mmd_practiceexam');

        $warning = null;
        $regs    = array();
        try {
            $regs = $h->listRegistrations($run['class_id'], $exam['exam_slug']);
        } catch (Exception $e) {
            $warning = 'Could not load registrations from Tertiary Exams: ' . $e->getMessage();
        }
        $people = $h->getPeople($run);
        $seen   = array();
        foreach ($people as &$p) {
            $r = isset($regs[$p['email']]) ? $regs[$p['email']] : null;
            $p['registeredAt'] = $r ? $r['registeredAt'] : null;
            $p['signedIn']     = $r ? $r['signedIn'] : false;
            $seen[$p['email']] = true;
        }
        unset($p);
        // People who self-registered with an email that is not on the roster.
        $extra = 0;
        foreach ($regs as $email => $r) {
            if (!isset($seen[$email])) $extra++;
        }
        $title = '';
        try {
            foreach ($h->listExams() as $e) {
                if ($e['slug'] === $exam['exam_slug']) { $title = $e['title']; break; }
            }
        } catch (Exception $e) {
            // the code alone is shown
        }
        $this->_json(array(
            'success'      => true,
            'classId'      => $run['class_id'],
            'examCode'     => $exam['exam_code'],
            'examTitle'    => $title,
            'people'       => $people,
            'selfRegistered' => $extra,
            'selfRegisterUrl' => $h->selfRegisterUrl($run['run_id']),
            'warning'      => $warning,
        ));
    }

    public function registerAction()
    {
        if (!$this->getRequest()->isPost() || !$this->_validateFormKey()) {
            return $this->_json(array('success' => false, 'error' => 'Invalid request.'), 400);
        }
        $ctx = $this->_context();
        if (!$ctx) return;
        list($run, $exam) = $ctx;
        $h = Mage::helper('mmd_practiceexam');

        $only = $this->getRequest()->getParam('emails');
        $only = is_array($only) ? array_map('strtolower', array_map('trim', $only)) : null;
        $ok = 0; $emailed = 0; $failed = array();
        foreach ($h->getPeople($run) as $p) {
            if ($only !== null && !in_array($p['email'], $only, true)) continue;
            $r = $h->registerPerson($p['name'], $p['email'], $exam['exam_slug'], $run['class_id']);
            if ($r['ok']) { $ok++; if ($r['emailSent']) $emailed++; }
            else { $failed[$p['email']] = $r['error']; }
        }
        $user = Mage::getSingleton('admin/session')->getUser();
        Mage::log(sprintf('class %s -> %s: %d ok, %d failed (by admin %d)', $run['class_id'], $exam['exam_code'], $ok, count($failed), $user ? $user->getId() : 0), null, 'mmd_practiceexam.log', true);
        $this->_json(array(
            'success' => empty($failed) && $ok > 0,
            'registered' => $ok, 'emailed' => $emailed, 'failed' => $failed,
            'error' => $ok + count($failed) === 0 ? 'No one to register.' : null,
        ));
    }

    public function courseAction()
    {
        $h = Mage::helper('mmd_practiceexam');
        if (!Mage::helper('mmd_rolemanager')->isRoleAllowed($h->staffRoles())) {
            return $this->_json(array('success' => false, 'error' => 'Forbidden'), 403);
        }
        if (!$h->isConfigured()) {
            return $this->_json(array('success' => true, 'configured' => false));
        }
        $exam = $h->getCourseExam((int) $this->getRequest()->getParam('product_id'));
        $catalog = array(); $warning = null;
        try { $catalog = $h->listExams(); }
        catch (Exception $e) { $warning = 'Could not reach Tertiary Exams: ' . $e->getMessage(); }
        $this->_json(array(
            'success' => true, 'configured' => true,
            'examSlug' => $exam ? $exam['exam_slug'] : '', 'examCode' => $exam ? $exam['exam_code'] : '',
            'catalog' => $catalog, 'warning' => $warning,
        ));
    }

    public function saveCourseAction()
    {
        $h = Mage::helper('mmd_practiceexam');
        if (!Mage::helper('mmd_rolemanager')->isRoleAllowed($h->staffRoles())) {
            return $this->_json(array('success' => false, 'error' => 'Forbidden'), 403);
        }
        if (!$this->getRequest()->isPost() || !$this->_validateFormKey()) {
            return $this->_json(array('success' => false, 'error' => 'Invalid request.'), 400);
        }
        $pid = (int) $this->getRequest()->getParam('product_id');
        try {
            if ($pid <= 0 || !Mage::getResourceModel('catalog/product')->getProductsSku(array($pid))) {
                throw new Exception('Course not found.');
            }
            $saved = $h->setCourseExam($pid, (string) $this->getRequest()->getParam('exam_slug'));
            $this->_json(array('success' => true, 'examSlug' => $saved ? $saved['exam_slug'] : '', 'examCode' => $saved ? $saved['exam_code'] : ''));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'error' => $e->getMessage()), 400);
        }
    }
}
