<?php
/**
 * Single-post block. The post is registered by IndexController::viewAction.
 */
class MMD_Blog_Block_View extends Mage_Core_Block_Template
{
    /** @return MMD_Blog_Model_Post */
    public function getPost()
    {
        return Mage::registry('current_blog_post');
    }

    public function getPostUrl()
    {
        return Mage::helper('mmd_blog')->getPostUrl($this->getPost());
    }

    public function getContentHtml()
    {
        return Mage::helper('mmd_blog')->filterContent($this->getPost()->getContent());
    }

    /** @return string[] */
    public function getTags()
    {
        return Mage::helper('mmd_blog')->getPostTags($this->getPost()->getId());
    }

    /** @return Mage_Catalog_Model_Product[] */
    public function getRelatedCourses()
    {
        return Mage::helper('mmd_blog')->getRelatedCourses($this->getPost());
    }

    /** Share targets: label => href. Plain links, no third-party JS. */
    public function getShareLinks()
    {
        $url   = rawurlencode($this->getPostUrl());
        $title = rawurlencode($this->getPost()->getTitle());
        return array(
            'LinkedIn' => 'https://www.linkedin.com/sharing/share-offsite/?url=' . $url,
            'X'        => 'https://twitter.com/intent/tweet?url=' . $url . '&text=' . $title,
            'Facebook' => 'https://www.facebook.com/sharer/sharer.php?u=' . $url,
            'WhatsApp' => 'https://wa.me/?text=' . $title . '%20' . $url,
            'Email'    => 'mailto:?subject=' . $title . '&body=' . $url,
        );
    }

    /** Minutes, floor 1 — reading-time chip like the reference design. */
    public function getReadingMinutes()
    {
        $words = str_word_count(strip_tags((string) $this->getPost()->getContent()));
        return max(1, (int) round($words / 220));
    }

    public function getLikeUrl()
    {
        return Mage::getUrl('blog/index/like');
    }
}
