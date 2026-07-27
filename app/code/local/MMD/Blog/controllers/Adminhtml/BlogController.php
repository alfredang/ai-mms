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
        $this->_addContent($this->getLayout()->createBlock('mmd_blog/adminhtml_pipeline'));
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
            $wasPublished = $post->getId() && (int) $post->getStatus() === MMD_Blog_Model_Post::STATUS_PUBLISHED;

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

            // Ad hoc publish path: flipping a post to Published by hand shares it
            // to LinkedIn + Facebook exactly like the scheduled pipeline does
            // (deduped inside shareEverywhere, so a re-save never double-posts).
            // The "Share on LinkedIn" checkbox just forces an extra attempt.
            if ($post->isPublished() && (!$wasPublished || !empty($data['share_linkedin']))) {
                $result = Mage::getModel('mmd_blog/cron_autoblog')->shareEverywhere($post);
                $session->addNotice($this->__('Social share: %s', $result));
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
                    $becomesPublished = $status === MMD_Blog_Model_Post::STATUS_PUBLISHED && !$post->isPublished();
                    $post->setStatus($status)->save();
                    if ($becomesPublished) {
                        // Same ad hoc publish contract as saveAction (deduped shares).
                        Mage::getModel('mmd_blog/cron_autoblog')->shareEverywhere($post);
                    }
                }
            }
            $session->addSuccess($this->__('%d blog post(s) updated.', count($ids)));
        } catch (Exception $e) {
            $session->addError($e->getMessage());
        }
        $this->_redirect('*/*/');
    }

    /**
     * "Generate Now (AI)" / queue "Run Now" — runs the agentic pipeline on
     * demand (research agent -> writer -> review email). Optional course_id
     * targets a specific course (the queue row), bypassing the pickers.
     */
    public function generateAction()
    {
        $session = Mage::getSingleton('adminhtml/session');
        try {
            @set_time_limit(600);
            $pid    = (int) $this->getRequest()->getParam('course_id');
            $result = Mage::getModel('mmd_blog/cron_autoblog')->run('manual', $pid ?: null);
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

    // ------------------------------------------------------------------
    // Agentic pipeline endpoints (Blog Posts page — pipeline + queue UI)
    // ------------------------------------------------------------------

    /**
     * Admin-side approve / request-changes — same effect as the emailed token
     * links (blog/index/decide) but authorised by the admin session.
     * POST: post_id, decision=approve|changes[, feedback]
     */
    public function reviewDecisionAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            $id       = (int) $this->getRequest()->getParam('post_id');
            $decision = (string) $this->getRequest()->getParam('decision');
            $post     = Mage::getModel('mmd_blog/post')->load($id);
            if (!$post->getId()) {
                throw new Exception('This post no longer exists.');
            }
            $admin     = Mage::getSingleton('admin/session')->getUser();
            $who       = $admin ? strtolower((string) $admin->getEmail()) : 'admin';
            $decisions = json_decode((string) $post->getReviewDecisions(), true);
            if (!is_array($decisions)) {
                $decisions = array();
            }

            if ($decision === 'approve') {
                $decisions[$who] = 'approve';
                $post->setReviewDecisions(json_encode($decisions))->save();
                list($ok, $msg) = Mage::getModel('mmd_blog/cron_autoblog')->scheduleApproved($id);
                $result['success'] = $ok;
                $result['message'] = $msg;
            } elseif ($decision === 'changes') {
                $fb = trim((string) $this->getRequest()->getParam('feedback'));
                $decisions[$who] = 'changes';
                $post->setReviewDecisions(json_encode($decisions))
                     ->setReviewFeedback($fb)
                     ->setStatus(MMD_Blog_Model_Post::STATUS_CHANGES_REQUESTED)
                     ->save();
                @set_time_limit(600);
                $ok = Mage::getModel('mmd_blog/cron_autoblog')->regenerateOnChanges($id);
                $result['success'] = true;
                $result['message'] = $ok
                    ? 'Feedback recorded — a revised article was regenerated and re-sent for approval.'
                    : 'Feedback recorded. Regeneration will be retried by the next cron run.';
            } else {
                throw new Exception('Unknown decision');
            }
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    /** Course finder for the queue (any enabled course — title or SKU match). */
    public function searchCoursesAction()
    {
        $result = array('success' => false, 'courses' => array());
        try {
            $q = strtolower(trim((string) $this->getRequest()->getParam('q')));
            if (mb_strlen($q) < 2) {
                $result['success'] = true;
                return $this->_json($result);
            }
            $like = '%' . $q . '%';
            $result['courses'] = $this->_db('read')->fetchAll(
                "SELECT e.entity_id AS id, e.sku, v.value AS name
                 FROM catalog_product_entity e
                 INNER JOIN catalog_product_entity_varchar v
                         ON v.entity_id = e.entity_id AND v.attribute_id = 71 AND v.store_id = 0 AND v.value <> ''
                 WHERE (LOWER(v.value) LIKE ? OR LOWER(e.sku) LIKE ?)
                 ORDER BY v.value ASC LIMIT 30",
                array($like, $like)
            );
            $result['success'] = true;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    public function queueListAction()
    {
        $result = array('success' => false, 'queue' => array());
        try {
            $result['queue'] = $this->_db('read')->fetchAll(
                "SELECT q.queue_id, q.product_id, e.sku,
                        (SELECT v.value FROM catalog_product_entity_varchar v
                          WHERE v.entity_id = e.entity_id AND v.attribute_id = 71 AND v.store_id = 0 LIMIT 1) AS name
                   FROM mmd_blog_queue q
                   JOIN catalog_product_entity e ON e.entity_id = q.product_id
                  ORDER BY q.position ASC, q.queue_id ASC"
            );
            $result['success'] = true;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    public function queueAddAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            $pid = (int) $this->getRequest()->getParam('course_id');
            if (!$pid) {
                throw new Exception('course_id required');
            }
            $sku = (string) $this->_db('read')->fetchOne(
                'SELECT sku FROM catalog_product_entity WHERE entity_id = ?', array($pid));
            if ($sku === '') {
                throw new Exception('Course not found');
            }
            $pos = (int) $this->_db('read')->fetchOne('SELECT COALESCE(MAX(position),0)+1 FROM mmd_blog_queue');
            // UNIQUE(product_id) makes re-adding a no-op instead of a duplicate
            $this->_db('write')->query(
                'INSERT IGNORE INTO mmd_blog_queue (product_id, position) VALUES (?, ?)',
                array($pid, $pos));
            $result['success'] = true;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    public function queueRemoveAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            $qid = (int) $this->getRequest()->getParam('queue_id');
            if (!$qid) {
                throw new Exception('queue_id required');
            }
            $this->_db('write')->delete('mmd_blog_queue', array('queue_id = ?' => $qid));
            $result['success'] = true;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    /** POST order=<csv of queue_ids in the new order> (from drag-and-drop). */
    public function queueReorderAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            $ids = array();
            foreach (explode(',', (string) $this->getRequest()->getParam('order')) as $v) {
                $v = (int) trim($v);
                if ($v > 0) {
                    $ids[] = $v;
                }
            }
            if (empty($ids)) {
                throw new Exception('order required');
            }
            $w = $this->_db('write');
            foreach ($ids as $i => $qid) {
                $w->update('mmd_blog_queue', array('position' => $i + 1), array('queue_id = ?' => $qid));
            }
            $result['success'] = true;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    private function _db($mode)
    {
        return Mage::getSingleton('core/resource')->getConnection('core_' . $mode);
    }

    private function _json(array $payload)
    {
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(json_encode($payload));
        return $this;
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
