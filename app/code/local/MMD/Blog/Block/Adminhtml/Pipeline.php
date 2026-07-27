<?php
/**
 * Agentic Blog Pipeline panel — rendered above the Blog Posts grid. Same
 * timeline design as the newsletter panel's Agentic Flyer Pipeline (flow
 * steppers + caps + next-course queue); data prep lives in the template,
 * matching the dashboard panel convention.
 */
class MMD_Blog_Block_Adminhtml_Pipeline extends Mage_Adminhtml_Block_Template
{
    protected function _construct()
    {
        parent::_construct();
        $this->setTemplate('blog/pipeline.phtml');
    }
}
