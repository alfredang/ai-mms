<?php
/**
 * Admin certificate actions: manually issue/send certificates for a class,
 * and toggle the auto-send fail-safe flag.
 */
class MMD_Certificate_Adminhtml_CertificateController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::helper('mmd_certificate')->isAllowed();
    }

    /**
     * POST JSON — issue + send certificates to all present learners of a class
     * who don't already have one. body: { run_id }
     */
    public function sendForClassAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();

            $runId = (int) $this->getRequest()->getParam('run_id');
            if (!$runId) throw new Exception('run_id is required');

            /** @var MMD_Certificate_Helper_Data $h */
            $h   = Mage::helper('mmd_certificate');
            $run = $h->loadRun($runId);
            if (!$run) throw new Exception('Class not found.');

            $adminId  = Mage::getSingleton('admin/session')->getUser() ? (int)Mage::getSingleton('admin/session')->getUser()->getId() : null;
            $learners = $h->getEligibleLearners($runId);

            $sent = 0; $skipped = 0; $errors = 0; $msgs = array();
            foreach ($learners as $l) {
                $r = $h->issueAndSend($run, $l, $adminId);
                if ($r['status'] === 'sent') $sent++;
                elseif ($r['status'] === 'skipped') $skipped++;
                else { $errors++; $msgs[] = $l['learner_email'] . ': ' . $r['message']; }
            }

            $message = $learners
                ? sprintf('Sent %d, skipped %d, errors %d.', $sent, $skipped, $errors)
                : 'No present learners awaiting a certificate for this class.';
            if ($msgs) $message .= ' ' . implode('; ', array_slice($msgs, 0, 3));

            $this->_json(array('success' => $errors === 0, 'message' => $message,
                'sent' => $sent, 'skipped' => $skipped, 'errors' => $errors));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    /**
     * POST JSON — manually issue + send certificates to SELECTED learners of a
     * class (trainer multi-select on the Certificate of Achievement panel).
     * Manual send is a deliberate trainer override: no 70% attendance gate and
     * not affected by the auto_enabled flag. Only roster members are accepted.
     * params: run_id, emails[] (or comma-separated emails)
     */
    public function sendSelectedAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();

            $runId  = (int) $this->getRequest()->getParam('run_id');
            $emails = $this->getRequest()->getParam('emails');
            if (!$runId) throw new Exception('run_id is required');
            if (is_string($emails)) $emails = array_filter(array_map('trim', explode(',', $emails)));
            if (!is_array($emails) || empty($emails)) throw new Exception('Select at least one learner.');

            /** @var MMD_Certificate_Helper_Data $h */
            $h   = Mage::helper('mmd_certificate');
            $run = $h->loadRun($runId);
            if (!$run) throw new Exception('Class not found.');

            $roster  = $h->getClassCertRoster($run);
            $byEmail = array();
            foreach ($roster['learners'] as $l) $byEmail[$l['learner_email']] = $l;

            $adminId = Mage::getSingleton('admin/session')->getUser() ? (int)Mage::getSingleton('admin/session')->getUser()->getId() : null;
            $sent = 0; $skipped = 0; $errors = 0; $msgs = array();
            foreach ($emails as $email) {
                $email = strtolower(trim((string)$email));
                if ($email === '' || !isset($byEmail[$email])) continue;
                $r = $h->issueAndSend($run, $byEmail[$email], $adminId);
                if ($r['status'] === 'sent') $sent++;
                elseif ($r['status'] === 'skipped') $skipped++;
                else { $errors++; $msgs[] = $email . ': ' . $r['message']; }
            }

            $message = sprintf('Sent %d, skipped %d, errors %d.', $sent, $skipped, $errors);
            if ($msgs) $message .= ' ' . implode('; ', array_slice($msgs, 0, 3));
            $this->_json(array('success' => $errors === 0, 'message' => $message,
                'sent' => $sent, 'skipped' => $skipped, 'errors' => $errors));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    /**
     * POST — toggle the auto-send fail-safe flag. Admin-level only.
     * params: value (0|1)
     */
    public function setAutoEnabledAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();
            if (!Mage::helper('mmd_rolemanager')->isRoleAllowed(array('admin', 'training_provider', 'developer'))) {
                throw new Exception('Not authorized to change this setting.');
            }
            $value = (int) $this->getRequest()->getParam('value') ? 1 : 0;
            Mage::getConfig()->saveConfig('mmd/certificate/auto_enabled', $value, 'default', 0);
            Mage::getConfig()->reinit();
            $this->_json(array('success' => true, 'value' => $value,
                'message' => $value ? 'Auto-send certificates enabled.' : 'Auto-send certificates disabled.'));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    protected function _json(array $data)
    {
        $this->getResponse()->setHeader('Content-Type', 'application/json', true)->setBody(json_encode($data));
    }
}
