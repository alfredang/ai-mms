<?php
class MMD_Blog_Block_Adminhtml_Post_Edit extends Mage_Adminhtml_Block_Widget_Form_Container
{
    public function __construct()
    {
        $this->_objectId   = 'id';
        $this->_controller = 'adminhtml_post';
        $this->_blockGroup = 'mmd_blog';
        parent::__construct();

        $this->_updateButton('save', 'label', Mage::helper('mmd_blog')->__('Save Post'));
        $this->_addButton('saveandcontinue', array(
            'label'   => Mage::helper('mmd_blog')->__('Save and Continue Edit'),
            'onclick' => 'saveAndContinueEdit()',
            'class'   => 'save',
        ), -100);
        $this->_formScripts[] = "
            function saveAndContinueEdit() {
                editForm.submit($('edit_form').action + 'back/edit/');
            }
        ";

        $post = Mage::registry('current_blog_post');
        if ($post && $post->getId() && $post->isPublished()) {
            $url = Mage::helper('mmd_blog')->getPostUrl($post);
            $this->_addButton('view_on_site', array(
                'label'   => Mage::helper('mmd_blog')->__('View on Site'),
                'onclick' => "window.open('" . $url . "', '_blank')",
            ), 0, 20);
        }
    }

    public function getHeaderText()
    {
        $post = Mage::registry('current_blog_post');
        if ($post && $post->getId()) {
            return Mage::helper('mmd_blog')->__("Edit Post '%s'", $this->escapeHtml($post->getTitle()));
        }
        return Mage::helper('mmd_blog')->__('New Blog Post');
    }
}
