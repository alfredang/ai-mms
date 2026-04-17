<?php
class MMD_RoleManager_Adminhtml_CoursesaveController extends Mage_Adminhtml_Controller_Action
{
    public function saveAction()
    {
        $result = array('success' => false);

        try {
            $courseId = (int) $this->getRequest()->getParam('course_id');
            if (!$courseId) {
                throw new Exception('No course ID provided');
            }

            $product = Mage::getModel('catalog/product')->load($courseId);
            if (!$product->getId()) {
                throw new Exception('Course not found');
            }

            // Update product fields from POST
            $name = $this->getRequest()->getParam('course_name');
            if ($name !== null && $name !== '') {
                $product->setName($name);
            }

            $imageUrl = $this->getRequest()->getParam('image_url');
            if ($imageUrl !== null) {
                $product->setData('course_image_url', $imageUrl);
            }

            $description = $this->getRequest()->getParam('learning_outcomes');
            if ($description !== null) {
                $product->setDescription($description);
            }

            $shortDesc = $this->getRequest()->getParam('tsc_title');
            if ($shortDesc !== null) {
                $product->setShortDescription($shortDesc);
            }

            // Save the product
            $product->save();

            // Redirect based on which button was clicked
            $continueEdit = $this->getRequest()->getParam('continue_edit');
            $dashboardUrl = Mage::helper('adminhtml')->getUrl('adminhtml/dashboard');

            if ($continueEdit) {
                $editUrl = Mage::helper('adminhtml')->getUrl('adminhtml/dashboard', array(
                    'course_id' => $courseId,
                    'mode' => 'editing',
                ));
                $this->_redirectUrl($editUrl);
            } else {
                $this->_redirectUrl($dashboardUrl);
            }
            return;
        } catch (Exception $e) {
            Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
            $dashboardUrl = Mage::helper('adminhtml')->getUrl('adminhtml/dashboard');
            $this->_redirectUrl($dashboardUrl);
        }
    }

    protected function _isAllowed()
    {
        return true;
    }
}
