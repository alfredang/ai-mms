<?php
/**
 * Class Announcements — post / delete, called from the class page
 * (template attendance/announcements.phtml). Reading is server-rendered there.
 *
 * Both actions are multipart/form POSTs that carry form_key, so the stock
 * admin form-key check applies.
 */
class MMD_Attendance_Adminhtml_AnnouncementController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::helper('mmd_attendance')->isAllowed();
    }

    /** POST run_id, message, file (optional). */
    public function postAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $helper = Mage::helper('mmd_attendance/announcement');
            $runId  = (int) $this->getRequest()->getPost('run_id');
            if ($runId <= 0 || !$helper->canPost($runId)) {
                throw new Exception('You cannot post to this class.');
            }
            $post = $helper->add(
                $runId,
                (string) $this->getRequest()->getPost('message'),
                isset($_FILES['file']) ? $_FILES['file'] : null
            );
            $this->_json(array('success' => true, 'announcement' => $post));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    /** POST id. */
    public function deleteAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $helper = Mage::helper('mmd_attendance/announcement');
            $row    = $helper->load((int) $this->getRequest()->getPost('id'));
            if (!$row) throw new Exception('Post not found.');
            if (!$helper->canPost((int) $row['run_id'])) {
                throw new Exception('You cannot delete posts of this class.');
            }
            $helper->delete($row);
            $this->_json(array('success' => true));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    protected function _json(array $data)
    {
        $this->getResponse()
             ->setHeader('Content-Type', 'application/json', true)
             ->setBody(json_encode($data));
    }
}
