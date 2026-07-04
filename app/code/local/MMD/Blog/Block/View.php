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

    /**
     * Share targets as circular icon buttons — key (for CSS colour), label,
     * href and an inline brand SVG. Matches the reference blog design.
     * @return array<int,array{key:string,label:string,href:string,svg:string}>
     */
    public function getShareIcons()
    {
        $url   = rawurlencode($this->getPostUrl());
        $title = rawurlencode($this->getPost()->getTitle());
        $svg = array(
            'linkedin' => '<svg width="17" height="17" viewBox="0 0 24 24" fill="currentColor"><path d="M4.98 3.5a2.5 2.5 0 1 1 0 5 2.5 2.5 0 0 1 0-5zM3 9h4v12H3zM9 9h3.8v1.7h.05c.53-1 1.83-2.05 3.77-2.05C20.3 8.65 21 10.9 21 14v7h-4v-6.2c0-1.48-.03-3.38-2.06-3.38-2.07 0-2.39 1.62-2.39 3.28V21H9z"/></svg>',
            'x'        => '<svg width="17" height="17" viewBox="0 0 24 24" fill="currentColor"><path d="M18.24 2h3.3l-7.2 8.24L22.9 22h-6.63l-5.2-6.8L5.12 22H1.8l7.7-8.8L1.4 2h6.8l4.7 6.2zm-1.16 18h1.83L7.02 3.9H5.05z"/></svg>',
            'facebook' => '<svg width="17" height="17" viewBox="0 0 24 24" fill="currentColor"><path d="M22 12a10 10 0 1 0-11.56 9.88v-6.99H7.9V12h2.54V9.8c0-2.5 1.49-3.89 3.77-3.89 1.09 0 2.24.2 2.24.2v2.46h-1.26c-1.24 0-1.63.77-1.63 1.56V12h2.78l-.44 2.89h-2.34v6.99A10 10 0 0 0 22 12z"/></svg>',
            'whatsapp' => '<svg width="17" height="17" viewBox="0 0 24 24" fill="currentColor"><path d="M17.47 14.38c-.3-.15-1.76-.87-2.03-.97-.27-.1-.47-.15-.67.15-.2.3-.77.97-.94 1.17-.17.2-.35.22-.65.07-.3-.15-1.26-.46-2.4-1.48-.89-.79-1.49-1.77-1.66-2.07-.17-.3-.02-.46.13-.61.13-.13.3-.35.45-.52.15-.17.2-.3.3-.5.1-.2.05-.37-.02-.52-.07-.15-.67-1.62-.92-2.22-.24-.58-.49-.5-.67-.51h-.57c-.2 0-.52.07-.8.37-.27.3-1.04 1.02-1.04 2.48 0 1.46 1.07 2.88 1.22 3.08.15.2 2.1 3.2 5.08 4.49.71.31 1.26.49 1.69.62.71.23 1.36.2 1.87.12.57-.08 1.76-.72 2.01-1.41.25-.7.25-1.29.17-1.42-.07-.13-.27-.2-.57-.35zM12 2a10 10 0 0 0-8.6 15.06L2 22l5.06-1.33A10 10 0 1 0 12 2z"/></svg>',
            'email'    => '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="m2 7 10 6 10-6"/></svg>',
        );
        return array(
            array('key' => 'linkedin', 'label' => 'LinkedIn', 'href' => 'https://www.linkedin.com/sharing/share-offsite/?url=' . $url,               'svg' => $svg['linkedin']),
            array('key' => 'x',        'label' => 'X',        'href' => 'https://twitter.com/intent/tweet?url=' . $url . '&text=' . $title,          'svg' => $svg['x']),
            array('key' => 'facebook', 'label' => 'Facebook', 'href' => 'https://www.facebook.com/sharer/sharer.php?u=' . $url,                       'svg' => $svg['facebook']),
            array('key' => 'whatsapp', 'label' => 'WhatsApp', 'href' => 'https://wa.me/?text=' . $title . '%20' . $url,                               'svg' => $svg['whatsapp']),
            array('key' => 'email',    'label' => 'Email',    'href' => 'mailto:?subject=' . $title . '&body=' . $url,                                 'svg' => $svg['email']),
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
