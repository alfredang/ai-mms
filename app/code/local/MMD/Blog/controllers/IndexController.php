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
            // Canonical + OpenGraph/Twitter are emitted once by the theme's
            // head.phtml SEO block (it reads current_blog_post from the registry
            // to set og:type=article + the hero image). Emitting them here too
            // produced DUPLICATE canonical/og tags — don't re-add them.
        }
        $this->renderLayout();
    }

    public function likeAction()
    {
        $this->getResponse()->setHeader('Content-Type', 'application/json', true);
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST only');
            }
            $postId = (int) $this->getRequest()->getPost('post_id');
            $post   = Mage::getModel('mmd_blog/post')->load($postId);
            if (!$post->getId() || !$post->isPublished()) {
                throw new Exception('Invalid like request');
            }
            $result = Mage::helper('mmd_blog')->likePost($postId);
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
