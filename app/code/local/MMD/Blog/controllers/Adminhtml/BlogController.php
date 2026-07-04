<?php
/**
 * Marketing -> Blog Posts. URL helper key: adminhtml/blog.
 */
class MMD_Blog_Adminhtml_BlogController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/mmd_blog');
    }

    public function indexAction()
    {
        $this->loadLayout();
        $this->_setActiveMenu('admin/mmd_blog');
        $this->_title($this->__('Marketing'))->_title($this->__('Blog Posts'));
        $this->_addContent($this->getLayout()->createBlock('mmd_blog/adminhtml_post'));
        $this->renderLayout();
    }

    public function newAction()
    {
        $this->_forward('edit');
    }

    public function editAction()
    {
        $post = Mage::getModel('mmd_blog/post');
        $id   = (int) $this->getRequest()->getParam('id');
        if ($id) {
            $post->load($id);
            if (!$post->getId()) {
                Mage::getSingleton('adminhtml/session')->addError($this->__('This blog post no longer exists.'));
                return $this->_redirect('*/*/');
            }
        }
        Mage::register('current_blog_post', $post);

        $this->loadLayout();
        $this->_setActiveMenu('admin/mmd_blog');
        $this->_title($this->__('Marketing'))->_title($this->__('Blog Posts'))
             ->_title($post->getId() ? $post->getTitle() : $this->__('New Post'));
        if ($this->getLayout()->getBlock('head')) {
            $this->getLayout()->getBlock('head')->setCanLoadTinyMce(true);
        }
        $this->_addContent($this->getLayout()->createBlock('mmd_blog/adminhtml_post_edit'));
        $this->renderLayout();
    }

    public function saveAction()
    {
        $this->_validateFormKey();
        $data = $this->getRequest()->getPost();
        if (!$data) {
            return $this->_redirect('*/*/');
        }
        $session = Mage::getSingleton('adminhtml/session');
        $helper  = Mage::helper('mmd_blog');
        $post    = Mage::getModel('mmd_blog/post');
        $id      = (int) $this->getRequest()->getParam('id');
        if ($id) {
            $post->load($id);
        }

        try {
            if (trim((string) ($data['title'] ?? '')) === '') {
                Mage::throwException($this->__('Title is required.'));
            }

            $urlKey = $helper->slugify($data['url_key'] !== '' ? $data['url_key'] : $data['title']);
            $urlKey = $helper->ensureUniqueUrlKey($urlKey, $post->getId());

            $post->addData(array(
                'title'            => trim($data['title']),
                'url_key'          => $urlKey,
                'status'           => (int) ($data['status'] ?? MMD_Blog_Model_Post::STATUS_DRAFT),
                'published_at'     => $this->_parseDate($data['published_at'] ?? ''),
                'author'           => trim((string) ($data['author'] ?? '')),
                'excerpt'          => trim((string) ($data['excerpt'] ?? '')),
                'content'          => (string) ($data['content'] ?? ''),
                'related_skus'     => trim((string) ($data['related_skus'] ?? '')),
                'meta_title'       => trim((string) ($data['meta_title'] ?? '')),
                'meta_description' => trim((string) ($data['meta_description'] ?? '')),
                'meta_keywords'    => trim((string) ($data['meta_keywords'] ?? '')),
            ));

            if (!empty($_FILES['hero_image']['tmp_name']) && is_uploaded_file($_FILES['hero_image']['tmp_name'])) {
                $url = Mage::helper('mmd_blog/image')->storeHeroImage(
                    $_FILES['hero_image']['tmp_name'],
                    $_FILES['hero_image']['name']
                );
                $post->setHeroImageUrl($url);
            }

            $post->save();
            $helper->syncTags($post->getId(), array_map('trim', explode(',', (string) ($data['tags'] ?? ''))));

            if (!empty($data['share_linkedin']) && $post->isPublished()) {
                $this->_shareOnLinkedin($post, $session);
            }

            $session->addSuccess($this->__('Blog post saved.'));
            if ($this->getRequest()->getParam('back') === 'edit') {
                return $this->_redirect('*/*/edit', array('id' => $post->getId()));
            }
            return $this->_redirect('*/*/');
        } catch (Exception $e) {
            $session->addError($e->getMessage());
            $session->setFormData($data);
            return $this->_redirect('*/*/edit', array('id' => $id));
        }
    }

    public function deleteAction()
    {
        $session = Mage::getSingleton('adminhtml/session');
        try {
            $post = Mage::getModel('mmd_blog/post')->load((int) $this->getRequest()->getParam('id'));
            if (!$post->getId()) {
                Mage::throwException($this->__('This blog post no longer exists.'));
            }
            $post->delete();
            $session->addSuccess($this->__('Blog post deleted.'));
        } catch (Exception $e) {
            $session->addError($e->getMessage());
        }
        $this->_redirect('*/*/');
    }

    public function massDeleteAction()
    {
        $session = Mage::getSingleton('adminhtml/session');
        $ids     = (array) $this->getRequest()->getParam('post_ids', array());
        try {
            foreach ($ids as $id) {
                Mage::getModel('mmd_blog/post')->load((int) $id)->delete();
            }
            $session->addSuccess($this->__('%d blog post(s) deleted.', count($ids)));
        } catch (Exception $e) {
            $session->addError($e->getMessage());
        }
        $this->_redirect('*/*/');
    }

    public function massStatusAction()
    {
        $session = Mage::getSingleton('adminhtml/session');
        $ids     = (array) $this->getRequest()->getParam('post_ids', array());
        $status  = (int) $this->getRequest()->getParam('status');
        try {
            foreach ($ids as $id) {
                $post = Mage::getModel('mmd_blog/post')->load((int) $id);
                if ($post->getId()) {
                    $post->setStatus($status)->save();
                }
            }
            $session->addSuccess($this->__('%d blog post(s) updated.', count($ids)));
        } catch (Exception $e) {
            $session->addError($e->getMessage());
        }
        $this->_redirect('*/*/');
    }

    /** "Generate Now (AI)" — runs the Monday auto-blog pipeline on demand. */
    public function generateAction()
    {
        $session = Mage::getSingleton('adminhtml/session');
        try {
            @set_time_limit(300);
            $result = Mage::getModel('mmd_blog/cron_autoblog')->run('manual');
            if (strpos($result, 'ok:') === 0) {
                $session->addSuccess($this->__('Auto-blog: %s', $result));
            } else {
                $session->addNotice($this->__('Auto-blog: %s', $result));
            }
        } catch (Exception $e) {
            $session->addError($e->getMessage());
        }
        $this->_redirect('*/*/');
    }

    private function _shareOnLinkedin($post, $session)
    {
        try {
            $commentary = $post->getTitle()
                . ($post->getExcerpt() ? "\n\n" . $post->getExcerpt() : '')
                . "\n\nWSQ funding + SkillsFuture Credit claimable — read the full guide:";
            $result = Mage::helper('mmd_blog/linkedin')->share(
                $commentary,
                Mage::helper('mmd_blog')->getPostUrl($post),
                $post->getHeroImageUrl() ?: null
            );
            $post->setLinkedinUrn($result['externalId'])->save();
            $session->addSuccess($this->__('Shared on LinkedIn: %s', $result['externalUrl']));
        } catch (Exception $e) {
            $session->addError($this->__('LinkedIn share failed: %s', $e->getMessage()));
        }
    }

    /** Locale-formatted date picker value -> Y-m-d (or today when empty). */
    private function _parseDate($value)
    {
        $value = trim((string) $value);
        if ($value === '') {
            return date('Y-m-d');
        }
        try {
            $date = Mage::app()->getLocale()->date(
                $value,
                Mage::app()->getLocale()->getDateFormat(Mage_Core_Model_Locale::FORMAT_TYPE_SHORT),
                null,
                false
            );
            return $date->toString('yyyy-MM-dd');
        } catch (Exception $e) {
            return date('Y-m-d');
        }
    }
}
