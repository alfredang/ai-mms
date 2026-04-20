<?php
class MMD_RoleManager_Adminhtml_CoursesaveController extends Mage_Adminhtml_Controller_Action
{
    public function saveAction()
    {
        try {
            $req      = $this->getRequest();
            $courseId = (int) $req->getParam('course_id');
            if (!$courseId) {
                throw new Exception('No course ID provided');
            }

            $product = Mage::getModel('catalog/product')->load($courseId);
            if (!$product->getId()) {
                throw new Exception('Course not found');
            }

            // Basic fields
            if (($v = $req->getParam('course_name'))  !== null && $v !== '') $product->setName($v);
            if (($v = $req->getParam('course_code'))  !== null && $v !== '') $product->setSku($v);
            if (($v = $req->getParam('image_url'))    !== null)              $product->setData('course_image_url', $v);
            if (($v = $req->getParam('brochure_url')) !== null)              $product->setData('course_brochure_url', $v);
            if (($v = $req->getParam('duration'))     !== null && $v !== '') $product->setData('duration', $v);
            if (($v = $req->getParam('price'))        !== null && $v !== '') $product->setPrice((float)$v);

            // Rich HTML fields
            if (($v = $req->getParam('trainer_names'))     !== null) {
                $lines = array_filter(array_map('trim', preg_split('/\r?\n/', $v)));
                $html  = '';
                foreach ($lines as $line) {
                    $html .= '<p><strong>' . htmlspecialchars($line) . ':</strong></p>' . "\n";
                }
                $product->setData('trainerprofile', $html);
            }
            if (($v = $req->getParam('learning_outcomes')) !== null) $product->setData('description', $v);
            if (($v = $req->getParam('who_should_attend')) !== null) $product->setData('whoshouldattend', $v);
            if (($v = $req->getParam('prerequisite'))      !== null) $product->setData('prerequisite', $v);

            // SEO
            if (($v = $req->getParam('meta_title'))        !== null) $product->setMetaTitle($v);
            if (($v = $req->getParam('meta_description'))  !== null) $product->setMetaDescription($v);
            if (($v = $req->getParam('meta_keyword'))      !== null) $product->setMetaKeyword($v);

            $product->save();

            $continueEdit = $req->getParam('continue_edit');
            $dashboardUrl = Mage::helper('adminhtml')->getUrl('adminhtml/dashboard');

            if ($continueEdit) {
                $editUrl = Mage::helper('adminhtml')->getUrl('adminhtml/dashboard', array(
                    'course_id' => $courseId,
                    'mode' => 'editing',
                ));
                $this->_redirectUrl($editUrl);
            } else {
                $viewUrl = Mage::helper('adminhtml')->getUrl('adminhtml/dashboard', array(
                    'course_id' => $courseId,
                    'mode' => 'edit',
                ));
                $this->_redirectUrl($viewUrl);
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
