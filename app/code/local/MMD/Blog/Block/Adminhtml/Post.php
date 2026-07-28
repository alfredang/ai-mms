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

        // Manual trigger for the agentic pipeline (research agent -> writer ->
        // manager approval; auto-publish sites publish + share immediately) —
        // same code path as the daily cron.
        $this->_addButton('generate_now', array(
            'label'   => Mage::helper('mmd_blog')->__('Generate Now (AI)'),
            'onclick' => "if (confirm('Run the blog agent team now? It researches the "
                . "latest AI topics, writes an in-depth lead-magnet post with a hero image, "
                . "then emails the managers for approval (takes a few minutes).')) setLocation('"
                . $this->getUrl('*/*/generate') . "')",
        ), 0, 10);
    }
}
