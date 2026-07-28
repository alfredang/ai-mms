<?php
class MMD_FeedbackForm_Adminhtml_FormbuilderController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/mmd/feedbackform/builder');
    }

    public function indexAction()
    {
        $this->loadLayout()
             ->_title($this->__('Feedback Form'))->_title($this->__('Form Builder'));
        $this->renderLayout();
    }

    /** GET — return template JSON for the builder UI. */
    public function loadAction()
    {
        try {
            /** @var MMD_FeedbackForm_Helper_Data $h */
            $h        = Mage::helper('mmd_feedbackform');
            $template = $h->getOrCreateTemplate();
            $this->_jsonResponse(array('success' => true, 'template' => $template));
        } catch (Exception $e) {
            $this->_jsonResponse(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    /** POST — save template JSON from the builder UI. */
    public function saveAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();

            $body = $this->getRequest()->getRawBody();
            $data = json_decode($body, true);
            if (!isset($data['title'], $data['sections'])) {
                throw new Exception('Invalid payload');
            }

            $resource = Mage::getSingleton('core/resource');
            $write    = $resource->getConnection('core_write');
            $tbl      = $resource->getTableName('mmd_feedback_form_template');

            $row = $resource->getConnection('core_read')
                ->fetchRow("SELECT template_id FROM `$tbl` WHERE is_active = 1 ORDER BY template_id ASC LIMIT 1");

            if ($row) {
                $write->update($tbl,
                    array('title' => $data['title'], 'sections' => json_encode($data['sections'])),
                    array('template_id = ?' => (int)$row['template_id'])
                );
            } else {
                $write->insert($tbl, array(
                    'title'    => $data['title'],
                    'sections' => json_encode($data['sections']),
                    'is_active'=> 1,
                ));
            }

            $this->_jsonResponse(array('success' => true, 'message' => 'Template saved.'));
        } catch (Exception $e) {
            $this->_jsonResponse(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    protected function _jsonResponse(array $data)
    {
        $this->getResponse()
             ->setHeader('Content-Type', 'application/json', true)
             ->setBody(json_encode($data));
    }
}
