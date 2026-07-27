<?php
/**
 * Storefront blog controller.
 *   /blog                      -> indexAction (list)
 *   /blog/<url_key>            -> viewAction  (via MMD_Blog_Controller_Router)
 *   /blog/tag/<name>           -> tagAction   (via MMD_Blog_Controller_Router)
 *   POST /blog/index/rate      -> rateAction  (AJAX star rating, JSON)
 *   /blog/index/decide/id/<n>/d/<approve|changes>/e/<email>/t/<token>
 *                              -> decideAction (public no-login manager review,
 *                                 authorised by the HMAC token — same contract
 *                                 as the newsletter's /newsletter-review endpoint)
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

    /**
     * Manager review endpoint (no login — the HMAC token bound to post+email is
     * the authorisation; review emails only ever go to the two fixed reviewers).
     * Approve: one approval books the next free Tue/Fri 09:00 publish slot.
     * Changes: GET shows a feedback form; POST records it and synchronously
     * regenerates the article + re-sends for approval.
     */
    public function decideAction()
    {
        $req      = $this->getRequest();
        $id       = (int) $req->getParam('id');
        $decision = (string) $req->getParam('d');
        $email    = strtolower(trim((string) $req->getParam('e')));
        $token    = (string) $req->getParam('t');
        $helper   = Mage::helper('mmd_blog');

        if (!$helper->verifyReviewToken($id, $email, $token)) {
            return $this->_reviewPage('Invalid or expired link', '<p style="color:#475569;">This approval link is not valid. Please use the buttons in the latest review email.</p>', '#ef4444');
        }
        $post = Mage::getModel('mmd_blog/post')->load($id);
        if (!$post->getId()) {
            return $this->_reviewPage('Not found', '<p style="color:#475569;">This blog post no longer exists.</p>', '#ef4444');
        }
        if (in_array((int) $post->getStatus(), array(
            MMD_Blog_Model_Post::STATUS_SCHEDULED, MMD_Blog_Model_Post::STATUS_PUBLISHED), true)) {
            return $this->_reviewPage('Already handled', '<p style="color:#475569;">This post has already been approved and scheduled — nothing more to do.</p>', '#059669');
        }

        $decisions = json_decode((string) $post->getReviewDecisions(), true);
        if (!is_array($decisions)) { $decisions = array(); }

        // ---- Request changes: show a feedback form (GET), record on POST ----
        if ($decision === 'changes') {
            if ($req->isPost()) {
                $fb = trim((string) $req->getPost('feedback'));
                $decisions[$email] = 'changes';
                $post->setReviewDecisions(json_encode($decisions))
                     ->setReviewFeedback($fb)
                     ->setStatus(MMD_Blog_Model_Post::STATUS_CHANGES_REQUESTED)
                     ->save();
                // Rewrite + re-send NOW so a fresh approval email arrives
                // immediately (the daily cron is only the retry safety net).
                @set_time_limit(300);
                $ok = false;
                try {
                    $ok = Mage::getModel('mmd_blog/cron_autoblog')->regenerateOnChanges($id);
                } catch (Exception $e) {
                    Mage::logException($e);
                }
                return $this->_reviewPage('Thanks — we’ll revise it',
                    '<p style="color:#475569;">' . ($ok
                        ? 'Your feedback was recorded and a revised article has just been emailed to the managers for approval.'
                        : 'Your feedback was recorded. The system will regenerate the article and email a fresh version to review shortly.')
                    . '</p>', '#f59e0b');
            }
            $postUrl = Mage::getUrl('blog/index/decide', array('id' => $id, 'd' => 'changes', 'e' => rawurlencode($email), 't' => $token));
            return $this->_reviewPage('Request changes',
                '<form method="post" action="' . $this->_esc($postUrl) . '">'
                . '<p style="color:#475569;">What would you like changed? (angle, wording, structure, funding emphasis, etc.)</p>'
                . '<textarea name="feedback" rows="5" style="width:100%;box-sizing:border-box;border:1px solid #cbd5e1;border-radius:10px;padding:12px;font:14px inherit;" placeholder="e.g. Lead with the career-switcher angle and mention the SME subsidy earlier."></textarea>'
                . '<button type="submit" style="margin-top:14px;background:#f59e0b;color:#fff;border:0;font-weight:700;font-size:14px;padding:11px 22px;border-radius:10px;cursor:pointer;">Send feedback</button>'
                . '</form>', '#f59e0b');
        }

        // ---- Approve: single approval schedules (same rule as the newsletter) ----
        $decisions[$email] = 'approve';
        $post->setReviewDecisions(json_encode($decisions))->save();

        list($ok, $msg) = Mage::getModel('mmd_blog/cron_autoblog')->scheduleApproved($id);
        if ($ok) {
            return $this->_reviewPage('Approved & scheduled ✓',
                '<p style="color:#475569;">Approved. <b>' . $this->_esc($msg) . '</b> — it will then be shared to LinkedIn and the Facebook page automatically.</p>', '#059669');
        }
        return $this->_reviewPage('Approved — scheduling held',
            '<p style="color:#475569;">Your approval is recorded, but it could not be scheduled yet: ' . $this->_esc($msg) . '</p>', '#f59e0b');
    }

    /** Minimal standalone result page for the review links (matches the newsletter's). */
    private function _reviewPage($title, $body, $accent = '#2563eb')
    {
        $html = '<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
            . '<title>' . $this->_esc($title) . '</title></head>'
            . '<body style="margin:0;background:#eef2f7;font-family:-apple-system,Segoe UI,Arial,sans-serif;">'
            . '<div style="max-width:520px;margin:8vh auto;background:#fff;border:1px solid #e4e9f0;border-radius:16px;padding:32px 30px;box-shadow:0 20px 50px -20px rgba(15,23,42,.35);">'
            . '<div style="width:44px;height:44px;border-radius:12px;background:' . $accent . ';margin-bottom:18px;"></div>'
            . '<h1 style="margin:0 0 10px;font-size:22px;color:#0a1020;">' . $this->_esc($title) . '</h1>'
            . $body . '</div></body></html>';
        $this->getResponse()->setHeader('Content-Type', 'text/html; charset=utf-8', true)->setBody($html);
    }

    private function _esc($text)
    {
        return htmlspecialchars((string) $text, ENT_QUOTES, 'UTF-8');
    }
}
