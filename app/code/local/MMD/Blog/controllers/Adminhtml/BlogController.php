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
            $pid   = (int) $this->getRequest()->getParam('course_id');
            $brief = null;
            $qid   = (int) $this->getRequest()->getParam('queue_id');
            if ($qid) {
                // Queue "Run Now": read the row's admin brief (topics/links) so
                // the direction reaches the agents. The row is consumed only
                // AFTER a successful run — a failed run (no API key, Claude
                // error) must not silently swallow the queued course + brief.
                $row = $this->_db('read')->fetchRow(
                    'SELECT product_id, topics, links FROM mmd_blog_queue WHERE queue_id = ?', array($qid));
                if ($row) {
                    $pid   = $pid ?: (int) $row['product_id'];
                    $brief = array('topics' => (string) ($row['topics'] ?? ''), 'links' => (string) ($row['links'] ?? ''));
                }
            }
            $result = Mage::getModel('mmd_blog/cron_autoblog')->run('manual', $pid ?: null, $brief);
            if (strpos($result, 'ok:') === 0) {
                if ($qid) {
                    $this->_db('write')->delete('mmd_blog_queue', array('queue_id = ?' => $qid));
                }
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

    /**
     * Rich preview of a post for the pipeline grid's eye button — returns the
     * article as a self-contained HTML document for an iframe srcdoc, the same
     * contract the newsletter preview uses ({success, html}). Unpublished posts
     * are previewable here (the frontend view route 404s them), which is the
     * whole point: the reviewer sees the article before approving it.
     * POST: post_id
     */
    public function previewAction()
    {
        $result = array('success' => false);
        try {
            $id   = (int) $this->getRequest()->getParam('post_id');
            $post = Mage::getModel('mmd_blog/post')->load($id);
            if (!$post->getId()) {
                throw new Exception('This post no longer exists.');
            }
            $result['success'] = true;
            $result['title']   = (string) $post->getTitle();
            $result['meta']    = $this->_previewMeta($post);
            // Legacy rows can carry non-UTF-8 bytes; json_encode() would return
            // false and hand the browser an empty body (blank modal).
            $result['html']    = @iconv('UTF-8', 'UTF-8//IGNORE', $this->_renderPreviewHtml($post));
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    /** One-line "Draft · 5 min read · TGS-1234" strip for the modal header. */
    protected function _previewMeta($post)
    {
        $labels = array(
            MMD_Blog_Model_Post::STATUS_DRAFT             => 'Draft',
            MMD_Blog_Model_Post::STATUS_PUBLISHED         => 'Published',
            MMD_Blog_Model_Post::STATUS_PENDING_REVIEW    => 'Pending approval',
            MMD_Blog_Model_Post::STATUS_SCHEDULED         => 'Scheduled',
            MMD_Blog_Model_Post::STATUS_CHANGES_REQUESTED => 'Changes requested',
        );
        $bits = array($labels[(int) $post->getStatus()] ?? 'Draft');
        $words = str_word_count(strip_tags((string) $post->getContent()));
        $bits[] = max(1, (int) ceil($words / 200)) . ' min read';
        if ($post->getRelatedSkus()) {
            $bits[] = (string) $post->getRelatedSkus();
        }
        return implode(' · ', $bits);
    }

    /**
     * Build the standalone article document. Mirrors the frontend view template
     * (hero, meta row, body, lead-magnet CTA, tags) but with every style inlined
     * — the admin page never loads the Ultimo frontend CSS, so an iframe that
     * linked to it would render unstyled.
     */
    protected function _renderPreviewHtml($post)
    {
        $helper  = Mage::helper('mmd_blog');
        $esc     = function ($s) { return htmlspecialchars((string) $s, ENT_QUOTES, 'UTF-8'); };
        $hero    = $helper->getHeroImage($post);
        $tags    = $helper->getPostTags($post->getId());
        $courses = $helper->getRelatedCourses($post);
        $store   = Mage::getStoreConfig('general/store_information/name') ?: 'Tertiary Infotech Academy';
        $date    = $post->getPublishedAt()
            ? date('d M Y', strtotime((string) $post->getPublishedAt()))
            : ($post->getScheduledPublishAt()
                ? 'Scheduled ' . date('d M Y', strtotime((string) $post->getScheduledPublishAt()))
                : 'Not yet published');
        $words   = str_word_count(strip_tags((string) $post->getContent()));

        try {
            $body = $helper->filterContent($post->getContent());
        } catch (Exception $e) {
            $body = (string) $post->getContent();   // preview must never fatal on a bad directive
        }

        $css = <<<CSS
*{box-sizing:border-box}
body{margin:0;background:#fff;color:#1e2833;
     font:400 16.5px/1.75 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Arial,sans-serif;
     -webkit-font-smoothing:antialiased}
.wrap{max-width:820px;margin:0 auto;padding:0 24px 56px}
.hero{display:block;width:100%;aspect-ratio:32/9;max-height:300px;object-fit:cover;background:#e8eef5}
.hero-fb{display:flex;align-items:center;justify-content:center;text-align:center;padding:24px;
         aspect-ratio:32/9;max-height:300px;color:#fff;font-weight:800;font-size:26px;
         background:linear-gradient(135deg,#0f172a,#1d4ed8)}
h1{font-size:34px;line-height:1.25;margin:28px 0 14px;color:#0a1020;letter-spacing:-.4px}
.meta{display:flex;flex-wrap:wrap;gap:18px;padding-bottom:18px;margin-bottom:26px;
      border-bottom:1px solid #e4e9f0;color:#64748b;font-size:13.5px;font-weight:600}
.excerpt{font-size:18px;line-height:1.7;color:#475569;font-style:italic;margin:0 0 26px;
         padding-left:16px;border-left:3px solid #cbd5e1}
.body h2{font-size:25px;line-height:1.3;margin:34px 0 12px;color:#0a1020}
.body h3{font-size:20px;line-height:1.35;margin:26px 0 10px;color:#0a1020}
.body p{margin:0 0 18px}
.body ul,.body ol{margin:0 0 18px;padding-left:26px}
.body li{margin:0 0 9px;list-style:revert}
.body a{color:#1d4ed8}
.body img{max-width:100%;height:auto;border-radius:10px;margin:8px 0}
.body table{width:100%;border-collapse:collapse;margin:0 0 20px;font-size:15px}
.body th,.body td{border:1px solid #dbe3ec;padding:9px 12px;text-align:left;vertical-align:top}
.body th{background:#f1f5f9;font-weight:700}
.body pre{background:#0f172a;color:#e2e8f0;padding:16px;border-radius:10px;overflow-x:auto;
          font-size:14px;line-height:1.6;white-space:pre-wrap}
.body code{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:14px}
.body blockquote{margin:0 0 20px;padding:2px 0 2px 18px;border-left:4px solid #93c5fd;color:#475569}
.body details{border:1px solid #e4e9f0;border-radius:10px;padding:12px 16px;margin:0 0 12px}
.body summary{font-weight:700;cursor:pointer;color:#0a1020}
.cta{margin:38px 0 0;padding:24px 26px;border-radius:14px;background:#f5f8fc;border:1px solid #e0e8f2}
.cta h2{margin:0 0 8px;font-size:21px;color:#0a1020}
.cta p{margin:0 0 14px;font-size:15px;color:#475569}
.cta a{display:block;background:#fff;border:1px solid #d6e0ec;border-radius:10px;padding:13px 16px;
       margin:0 0 9px;text-decoration:none;color:#0a1020;font-weight:700;font-size:15px}
.cta a span{display:block;margin-top:3px;color:#1d4ed8;font-weight:600;font-size:13px}
.tags{margin:30px 0 0;padding-top:18px;border-top:1px solid #e4e9f0;
      display:flex;flex-wrap:wrap;gap:8px;align-items:center}
.tags b{font-size:13px;color:#64748b;text-transform:uppercase;letter-spacing:.5px}
.tag{background:#eef2f7;color:#475569;border-radius:999px;padding:5px 12px;font-size:13px;font-weight:600}
CSS;

        $html = '<!doctype html><html lang="en"><head><meta charset="utf-8">'
              . '<meta name="viewport" content="width=device-width,initial-scale=1">'
              . '<title>' . $esc($post->getTitle()) . '</title><style>' . $css . '</style></head><body>';

        $html .= $hero
            ? '<img class="hero" src="' . $esc($hero) . '" alt="' . $esc($post->getTitle()) . '">'
            : '<div class="hero-fb">' . $esc($post->getTitle()) . '</div>';

        $html .= '<div class="wrap"><h1>' . $esc($post->getTitle()) . '</h1><div class="meta">'
              . '<span>' . $esc($post->getAuthor() ?: $store) . '</span>'
              . '<span>' . $esc($date) . '</span>'
              . '<span>' . max(1, (int) ceil($words / 200)) . ' min read</span>'
              . '<span>' . number_format($words) . ' words</span>'
              . '</div>';

        if (trim((string) $post->getExcerpt()) !== '') {
            $html .= '<p class="excerpt">' . $esc($post->getExcerpt()) . '</p>';
        }
        $html .= '<div class="body">' . $body . '</div>';

        $html .= '<aside class="cta"><h2>Ready to build this skill? &#127891;</h2>'
              . '<p>Every post funnels readers to the course below &mdash; this is the lead-magnet CTA '
              . 'the published article will show.</p>';
        if ($courses) {
            foreach ($courses as $course) {
                $html .= '<a href="' . $esc($course->getProductUrl()) . '" target="_blank" rel="noopener">'
                      . $esc($course->getName())
                      . '<span>View schedule &amp; register &rarr;</span></a>';
            }
        } else {
            $html .= '<a href="#">No related course linked yet '
                  . '<span>Set "Related SKUs" on the post so the CTA has a course</span></a>';
        }
        $html .= '</aside>';

        if ($tags) {
            $html .= '<div class="tags"><b>Tags</b>';
            foreach ($tags as $t) {
                $html .= '<span class="tag">#' . $esc($t) . '</span>';
            }
            $html .= '</div>';
        }

        return $html . '</div></body></html>';
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
                "SELECT q.queue_id, q.product_id, q.topics, q.links, e.sku,
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
            $pos    = (int) $this->_db('read')->fetchOne('SELECT COALESCE(MAX(position),0)+1 FROM mmd_blog_queue');
            $topics = $this->_briefParam('topics', 1000);
            $links  = $this->_briefParam('links', 3000);
            // UNIQUE(product_id): re-adding keeps the row's position but
            // refreshes the admin brief when new topics/links were supplied.
            $this->_db('write')->query(
                'INSERT INTO mmd_blog_queue (product_id, position, topics, links) VALUES (?, ?, ?, ?)
                 ON DUPLICATE KEY UPDATE
                     topics = IF(VALUES(topics) IS NULL, topics, VALUES(topics)),
                     links  = IF(VALUES(links)  IS NULL, links,  VALUES(links))',
                array($pid, $pos, $topics, $links));
            $result['success'] = true;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    /** POST queue_id + topics/links — save the admin brief on a queued row. */
    public function queueBriefAction()
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
            $this->_db('write')->update('mmd_blog_queue', array(
                'topics' => $this->_briefParam('topics', 1000),
                'links'  => $this->_briefParam('links', 3000),
            ), array('queue_id = ?' => $qid));
            $result['success'] = true;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    /** Trimmed + length-capped brief field; null when absent/empty (keeps existing on re-add). */
    private function _briefParam($key, $maxLen)
    {
        $val = $this->getRequest()->getParam($key);
        if ($val === null) {
            return null;
        }
        $val = trim((string) $val);
        return $val === '' ? null : mb_substr($val, 0, $maxLen);
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
