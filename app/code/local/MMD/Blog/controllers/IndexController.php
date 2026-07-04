<?php
/**
 * Storefront blog controller.
 *   /blog                      -> indexAction (list)
 *   /blog/<url_key>            -> viewAction  (via MMD_Blog_Controller_Router)
 *   /blog/tag/<name>           -> tagAction   (via MMD_Blog_Controller_Router)
 *   POST /blog/index/rate      -> rateAction  (AJAX star rating, JSON)
 */
class MMD_Blog_IndexController extends Mage_Core_Controller_Front_Action
{
    public function indexAction()
    {
        $this->loadLayout();
        $head = $this->getLayout()->getBlock('head');
        if ($head) {
            $head->setTitle('Blog | ' . Mage::getStoreConfig('general/store_information/name'));
            $head->setDescription('Practical guides on AI, tech and professional upskilling — with WSQ funding and SkillsFuture Credit tips from ' . Mage::getStoreConfig('general/store_information/name') . '.');
        }
        $this->renderLayout();
    }

    public function tagAction()
    {
        $tag = trim((string) $this->getRequest()->getParam('tag'));
        if ($tag === '') {
            return $this->_redirect('blog');
        }
        $this->loadLayout();
        $head = $this->getLayout()->getBlock('head');
        if ($head) {
            $head->setTitle($tag . ' Articles | Blog');
            // Tag listings are thin near-duplicates of /blog — keep them out of the index.
            $head->setRobots('NOINDEX,FOLLOW');
        }
        $list = $this->getLayout()->getBlock('blog.list');
        if ($list) {
            $list->setTagName($tag);
        }
        $this->renderLayout();
    }

    public function viewAction()
    {
        $post = Mage::getModel('mmd_blog/post')->load((int) $this->getRequest()->getParam('id'));
        if (!$post->getId() || !$post->isPublished()) {
            return $this->_forward('noRoute');
        }
        Mage::register('current_blog_post', $post);

        $this->loadLayout();
        $head = $this->getLayout()->getBlock('head');
        if ($head) {
            $head->setTitle($post->getMetaTitle() ?: $post->getTitle());
            if ($post->getMetaDescription()) {
                $head->setDescription($post->getMetaDescription());
            } elseif ($post->getExcerpt()) {
                $head->setDescription(trim(strip_tags($post->getExcerpt())));
            }
            if ($post->getMetaKeywords()) {
                $head->setKeywords($post->getMetaKeywords());
            }
            $postUrl = Mage::helper('mmd_blog')->getPostUrl($post);
            $head->addLinkRel('canonical', $postUrl);

            // OpenGraph — also what LinkedIn renders as the link card.
            $ogImage = $post->getHeroImageUrl()
                ?: Mage::getDesign()->getSkinUrl('images/logo.png', array('_area' => 'frontend'));
            $og = '<meta property="og:type" content="article" />' . "\n"
                . '<meta property="og:title" content="' . $this->_esc($post->getMetaTitle() ?: $post->getTitle()) . '" />' . "\n"
                . '<meta property="og:description" content="' . $this->_esc(trim(strip_tags((string) ($post->getMetaDescription() ?: $post->getExcerpt())))) . '" />' . "\n"
                . '<meta property="og:url" content="' . $this->_esc($postUrl) . '" />' . "\n"
                . '<meta property="og:image" content="' . $this->_esc($ogImage) . '" />' . "\n"
                . '<meta name="twitter:card" content="summary_large_image" />';
            $head->setIncludes(($head->getIncludes() ?: '') . "\n" . $og);
        }
        $this->renderLayout();
    }

    public function rateAction()
    {
        $this->getResponse()->setHeader('Content-Type', 'application/json', true);
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST only');
            }
            $postId = (int) $this->getRequest()->getPost('post_id');
            $rating = (int) $this->getRequest()->getPost('rating');
            $post   = Mage::getModel('mmd_blog/post')->load($postId);
            if (!$post->getId() || !$post->isPublished() || $rating < 1 || $rating > 5) {
                throw new Exception('Invalid rating request');
            }
            $result = Mage::helper('mmd_blog')->ratePost($postId, $rating);
            $this->getResponse()->setBody(json_encode(array('ok' => true) + $result));
        } catch (Exception $e) {
            $this->getResponse()->setHttpResponseCode(400);
            $this->getResponse()->setBody(json_encode(array('ok' => false, 'error' => $e->getMessage())));
        }
    }

    private function _esc($text)
    {
        return htmlspecialchars((string) $text, ENT_QUOTES, 'UTF-8');
    }
}
