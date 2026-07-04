<?php
/**
 * Blog Posts grid container (Marketing -> Blog Posts).
 * Standard widget container so it inherits the global admin chrome
 * (dcf-mag card auto-wrap, §18 buttons) — no per-page CSS.
 */
class MMD_Blog_Block_Adminhtml_Post extends Mage_Adminhtml_Block_Widget_Grid_Container
{
    public function __construct()
    {
        $this->_controller     = 'adminhtml_post';
        $this->_blockGroup     = 'mmd_blog';
        $this->_headerText     = Mage::helper('mmd_blog')->__('Blog Posts');
        $this->_addButtonLabel = Mage::helper('mmd_blog')->__('Add New Post');
        parent::__construct();

        // Manual trigger for the Monday auto-blog pipeline (Claude writer +
        // optional LinkedIn share) — same code path as the cron.
        $this->_addButton('generate_now', array(
            'label'   => Mage::helper('mmd_blog')->__('Generate Now (AI)'),
            'onclick' => "if (confirm('Generate a blog post with AI now? It will be "
                . "auto-published (and shared on LinkedIn when configured).')) setLocation('"
                . $this->getUrl('*/*/generate') . "')",
        ), 0, 10);
    }
}
