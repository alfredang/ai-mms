<?php
/**
 * Auto-blog pipeline — 2 lead-magnet posts per week with manager approval,
 * modelled on the newsletter blast pipeline (MMD_Marketing_Model_Cron_Flyer).
 * The propose step is an agent team, each stage degrading gracefully:
 *
 *   propose (cron daily 09:00, run()):
 *     1. COURSE PICK — the admin-curated mmd_blog_queue head wins (same
 *        contract as the newsletter flyer queue: consumed on pop). Only when
 *        the queue is empty does the auto-pick run: best-selling course
 *        (last 180 days) with no post yet (tracked via source_sku). On the
 *        SG site only WSQ (TGS-) courses qualify for the auto-pick.
 *     2. RESEARCH AGENT — Claude + web search scouts the latest developments
 *        (AI agents, agentic AI, n8n, new models, AI security, ... — pool in
 *        mmd_blog/autoblog/topics) relevant to the course and returns a
 *        topic/angle/key-points/sources brief. Skipped silently when web
 *        search is unavailable.
 *     3. WRITER AGENT — Claude turns the brief into an in-depth (1200-1800
 *        word), up-to-date SEO lead-magnet post as strict JSON, plus a
 *        branded hero image (CourseImage GD cover -> R2).
 *     4. Review flow (SG, auto_publish=0): save as PENDING REVIEW and email
 *        the two managers approve/request-changes token links. One approval
 *        books the next free Tuesday/Friday 09:00 publish slot.
 *        Legacy flow (partners, auto_publish=1): publish + share immediately.
 *     5. While a post is pending: 24h reminder (once), expiry to draft after
 *        5 days — same anti-spam contract as the newsletter followUp().
 *
 *   publishDue (cron every 10 min): flip SCHEDULED posts whose Tue/Fri slot
 *   has arrived to PUBLISHED, then share once each to LinkedIn + the Facebook
 *   page (deduped via linkedin_urn / facebook_post_id).
 *
 * Ad hoc posts stay first-class: the admin grid's "Generate Now" button calls
 * run('manual') (bypasses the weekly pacing guards), and any post an admin
 * flips to Published by hand is shared through the same shareEverywhere().
 *
 * Every step degrades gracefully: disabled -> skip, no Claude credentials ->
 * skip, social share failure -> post still publishes, errors -> mmd_blog.log.
 */
class MMD_Blog_Model_Cron_Autoblog
{
    /** Tue/Fri 09:00 SGT publish slots — the blog counterpart of Blastguard's 08:00 blast slots. */
    const PUBLISH_HOUR = 9;
    const TZ_LOCAL     = 'Asia/Singapore';

    /**
     * @param string     $trigger   'cron' | 'manual' (admin Generate Now / queue Run Now)
     * @param int|null   $productId explicit course (queue "Run Now") — bypasses the pickers
     * @param array|null $brief     admin direction from the queue row:
     *                              array{topics?:string,links?:string} — becomes part
     *                              of the research + writer prompt input
     */
    public function run($trigger = 'cron', $productId = null, $brief = null)
    {
        try {
            if (!Mage::getStoreConfigFlag('mmd_blog/autoblog/enabled')) {
                return $this->_log('skipped: autoblog disabled');
            }

            $review = $this->_reviewFlowEnabled();
            if ($review && $trigger === 'cron') {
                // One review at a time: remind/expire the pending post instead
                // of stacking a second proposal on the managers.
                if ($this->_tendPendingReview()) {
                    return $this->_log('skipped: a post is already awaiting review');
                }
                // Only generate when an upcoming Tue/Fri slot actually needs
                // content — this is what paces the pipeline to 2 posts/week.
                if ($this->nextPublishSlot(7) === null) {
                    return $this->_log('skipped: both upcoming Tue/Fri publish slots are filled');
                }
            }
            if (!$review && $trigger === 'cron' && $this->_recentAutoPostExists()) {
                return $this->_log('skipped: an auto post was already created in the last 5 days');
            }

            $course = $productId ? $this->_courseById((int) $productId) : $this->_pickCourse();
            if (!$course) {
                return $this->_log('skipped: no unblogged course with a URL found');
            }
            if (is_array($brief)) {
                $course['topics'] = trim((string) ($brief['topics'] ?? ''));
                $course['links']  = trim((string) ($brief['links'] ?? ''));
            }

            // Agent 1 — topic research (web search). Null when unavailable; the
            // writer then falls back to evergreen course-topic content.
            $research = $this->_researchTopic($course);
            if ($research) {
                $this->_log('research: topic "' . $research['topic'] . '" with '
                    . count($research['sources']) . ' source(s)');
            }

            // Agent 2 — the writer.
            $raw = $this->_invokeClaude($this->_writerSystemPrompt(), $this->_writerInput($course, $research), 10000);
            if ($raw === '') {
                return $this->_log('skipped: Claude returned nothing (no API key / CLI available?)');
            }
            $draft = $this->_parseJson($raw);

            $helper  = Mage::helper('mmd_blog');
            $urlKey  = $helper->ensureUniqueUrlKey($helper->slugify($draft['slug'] ?: $draft['title']));
            $publish = !$review && Mage::getStoreConfigFlag('mmd_blog/autoblog/auto_publish');

            $status = MMD_Blog_Model_Post::STATUS_DRAFT;
            if ($review) {
                $status = MMD_Blog_Model_Post::STATUS_PENDING_REVIEW;
            } elseif ($publish) {
                $status = MMD_Blog_Model_Post::STATUS_PUBLISHED;
            }

            $post = Mage::getModel('mmd_blog/post')->setData(array(
                'title'            => $draft['title'],
                'url_key'          => $urlKey,
                'excerpt'          => $draft['excerpt'],
                'content'          => $draft['contentHtml'],
                'author'           => Mage::getStoreConfig('general/store_information/name') ?: 'Tertiary Infotech Academy',
                'status'           => $status,
                'published_at'     => $publish ? $this->_nowLocal()->format('Y-m-d') : null,
                'related_skus'     => $course['sku'],
                'source_sku'       => $course['sku'],
                'meta_title'       => $draft['seoTitle'],
                'meta_description' => $draft['seoDescription'],
                'meta_keywords'    => $draft['seoKeywords'],
            ));
            $post->save();
            if (!empty($draft['tags'])) {
                $helper->syncTags($post->getId(), $draft['tags']);
            }
            $this->_attachHero($post, $course['sku']);

            $tail = '';
            if ($review) {
                $tail = $this->sendForReview($post)
                    ? ' | review email sent'
                    : ' | review email NOT sent (see log) — approve from the admin editor';
            } elseif ($publish) {
                $tail = ' | ' . $this->shareEverywhere($post);
            }

            return $this->_log(sprintf(
                'ok: post %d (%s) from course %s [%s]%s',
                $post->getId(), $urlKey, $course['sku'], $trigger, $tail
            ));
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_log('error: ' . $e->getMessage());
        }
    }

    // ---------------------------------------------------------------- flow gates

    /**
     * Review flow = auto_publish OFF (migration 450 turns it off on the SG
     * instance only; partner sites keep the legacy immediate-publish path).
     */
    private function _reviewFlowEnabled()
    {
        return !Mage::getStoreConfigFlag('mmd_blog/autoblog/auto_publish');
    }

    /**
     * SG-only rule: blog courses must be WSQ (TGS- SKU). Applied by HOST so the
     * same code on a partner server (.com.my/.com.gh — no TGS- catalog) keeps
     * its unrestricted picker. Localhost counts as SG (dev mirrors the SG DB).
     */
    private function _wsqOnly()
    {
        $host = strtolower((string) parse_url(
            (string) Mage::getStoreConfig('web/unsecure/base_url'), PHP_URL_HOST
        ));
        return !preg_match('/tertiarycourses\.com\.(my|gh|ng|bt|in)$/', $host);
    }

    /** Never email the real managers from a non-production env (same contract as the newsletter). */
    private function _mayEmailReviewers()
    {
        $host = strtolower((string) parse_url(
            (string) Mage::getStoreConfig('web/unsecure/base_url'), PHP_URL_HOST
        ));
        // Blog reviews are an SG-only flow — partner hosts must never mail the
        // SG managers even though they'd pass the newsletter's wider regex.
        if (preg_match('/(^|\.)tertiarycourses\.com\.sg$/', $host)) {
            return true;
        }
        return (bool) Mage::getStoreConfig('mmd_marketing/newsletter/allow_local_review_email');
    }

    private function _recentAutoPostExists()
    {
        $read  = Mage::getSingleton('core/resource')->getConnection('core_read');
        $table = Mage::getSingleton('core/resource')->getTableName('mmd_blog/post');
        return (bool) $read->fetchOne(
            "SELECT post_id FROM {$table}
             WHERE source_sku IS NOT NULL AND created_at >= DATE_SUB(NOW(), INTERVAL 5 DAY) LIMIT 1"
        );
    }

    // ---------------------------------------------------------------- slot maths

    /**
     * "Now" on the SGT wall clock. Magento bootstraps PHP to UTC, while the
     * publish slots and every human expectation run on Asia/Singapore — same
     * lesson as Blastguard::nowLocal().
     */
    private function _nowLocal()
    {
        return new DateTime('now', new DateTimeZone(self::TZ_LOCAL));
    }

    /**
     * The soonest future Tuesday/Friday 09:00 (SGT) whose calendar day is not
     * already claimed by a scheduled or published auto post. Ad hoc admin posts
     * (no scheduled_publish_at) never block a slot. Returns DateTime or null.
     */
    public function nextPublishSlot($maxDaysAhead = 21)
    {
        $now = $this->_nowLocal();
        for ($i = 0; $i <= $maxDaysAhead; $i++) {
            $day = clone $now;
            $day->modify('+' . $i . ' days');
            $dow = (int) $day->format('N');
            if ($dow !== 2 && $dow !== 5) {
                continue;
            }
            $slot = clone $day;
            $slot->setTime(self::PUBLISH_HOUR, 0, 0);
            if ($slot <= $now) {
                continue;
            }
            if (!$this->_slotTaken($slot)) {
                return $slot;
            }
        }
        return null;
    }

    private function _slotTaken(DateTime $slot)
    {
        $read  = Mage::getSingleton('core/resource')->getConnection('core_read');
        $table = Mage::getSingleton('core/resource')->getTableName('mmd_blog/post');
        return (bool) $read->fetchOne(
            "SELECT post_id FROM {$table}
             WHERE scheduled_publish_at BETWEEN ? AND ?
               AND status IN (" . MMD_Blog_Model_Post::STATUS_SCHEDULED . ',' . MMD_Blog_Model_Post::STATUS_PUBLISHED . ')
             LIMIT 1',
            array($slot->format('Y-m-d 00:00:00'), $slot->format('Y-m-d 23:59:59'))
        );
    }

    // ---------------------------------------------------------------- review flow

    /**
     * Email both managers the pending post with approve / request-changes token
     * links (no login — the HMAC token is the authorisation). Gmail OAuth first,
     * SMTPPro then bare Zend_Mail as fallbacks, exactly like the newsletter.
     * Anti-spam markers (_sent_at / _reminder_sent_at) are only stamped when a
     * send actually succeeded, so transport failures retry on the next cron.
     */
    public function sendForReview($post, $onlyEmails = null, $isReminder = false)
    {
        if (!$this->_mayEmailReviewers()) {
            $this->_log('sendForReview: SKIPPED for post #' . $post->getId()
                . ' — non-SG-production base_url. Set mmd_marketing/newsletter/allow_local_review_email=1 to test.');
            return false;
        }

        $helper = Mage::helper('mmd_blog');
        $guard  = Mage::helper('mmd_marketing/blastguard');   // reviewers list is shared with the newsletter
        $base   = rtrim((string) Mage::getStoreConfig('web/unsecure/base_url'), '/');
        $slot   = $this->nextPublishSlot();
        $slotTxt = $slot ? $slot->format('l, j M Y \a\t g:ia') : 'the next free Tuesday/Friday 9:00am slot';

        $gmail = null;
        try {
            $gh = Mage::helper('mmd_email/gmail');
            if ($gh && $gh->isConfigured()) { $gmail = $gh; }
        } catch (Exception $e) { $this->_log('sendForReview: Gmail OAuth helper unavailable: ' . $e->getMessage()); }
        $transport = null;
        if (!$gmail) {
            try {
                if (Mage::helper('core')->isModuleEnabled('Aschroder_SMTPPro')) {
                    $t = Mage::helper('smtppro')->getTransport();
                    if ($t) { $transport = $t; }
                }
            } catch (Exception $e) { $this->_log('sendForReview: SMTPPro transport unavailable: ' . $e->getMessage()); }
        }

        $courseLine = '';
        if ($post->getRelatedSkus()) {
            $courseLine = '<p style="font-size:13px;color:#475569;margin:6px 0 0;">Lead-magnet CTA course(s): <b>'
                . htmlspecialchars($post->getRelatedSkus()) . '</b></p>';
        }
        $heroLine = '';
        if ($post->getHeroImageUrl()) {
            $heroLine = '<img src="' . htmlspecialchars($post->getHeroImageUrl())
                . '" alt="Hero image" width="360" style="display:block;max-width:100%;border-radius:10px;margin:14px 0 0;" />';
        }

        $sentAny = false;
        foreach ($guard->reviewers() as $email) {
            if (is_array($onlyEmails) && !in_array(strtolower($email), $onlyEmails, true)) { continue; }
            $tok     = $helper->signReviewToken($post->getId(), $email);
            $approve = $base . '/blog/index/decide/id/' . $post->getId() . '/d/approve/e/' . rawurlencode($email) . '/t/' . $tok;
            $changes = $base . '/blog/index/decide/id/' . $post->getId() . '/d/changes/e/' . rawurlencode($email) . '/t/' . $tok;

            $html = '<div style="font-family:-apple-system,Segoe UI,Arial,sans-serif;max-width:720px;margin:0 auto;">'
                . '<p style="font-size:15px;color:#0a1020;">Hi — a new blog post is ready for your approval. If approved, it will be published on <b>' . $slotTxt . '</b> (2 posts/week, Tuesdays &amp; Fridays), then shared to LinkedIn and the Facebook page.</p>'
                . $courseLine
                . $heroLine
                . '<table role="presentation" style="margin:18px 0;"><tr>'
                . '<td style="padding-right:10px;"><a href="' . htmlspecialchars($approve) . '" style="background:#059669;color:#fff;text-decoration:none;font-weight:700;font-size:14px;padding:11px 22px;border-radius:8px;display:inline-block;">&#10003; Approve &amp; schedule</a></td>'
                . '<td><a href="' . htmlspecialchars($changes) . '" style="background:#e2e8f0;color:#0a1020;text-decoration:none;font-weight:700;font-size:14px;padding:11px 22px;border-radius:8px;display:inline-block;">&#9998; Request changes</a></td>'
                . '</tr></table>'
                . '<p style="font-size:12px;color:#7c8aa3;">"Request changes" lets you describe what to rewrite; the article is regenerated and re-sent for approval.</p>'
                . '<hr style="border:0;border-top:1px solid #e4e9f0;margin:18px 0;">'
                . '<h1 style="font-size:24px;color:#0a1020;margin:0 0 6px;">' . htmlspecialchars($post->getTitle()) . '</h1>'
                . '<p style="font-size:14px;color:#475569;font-style:italic;margin:0 0 16px;">' . htmlspecialchars($post->getExcerpt()) . '</p>'
                . $post->getContent()
                . '</div>';
            $subject = ($isReminder ? '[Reminder] ' : '') . '[Approval needed] Blog: ' . $post->getTitle();

            try {
                if ($gmail) {
                    $gmail->send($email, $subject, $html, 'Tertiary Marketing');
                } else {
                    $mail = new Zend_Mail('utf-8');
                    $mail->setBodyHtml($html)
                         ->setFrom(Mage::getStoreConfig('trans_email/ident_general/email'), 'Tertiary Marketing')
                         ->addTo($email)
                         ->setSubject($subject);
                    $transport ? $mail->send($transport) : $mail->send();
                }
                $sentAny = true;
                $this->_log('sendForReview: emailed ' . $email . ' for post #' . $post->getId() . ' via ' . ($gmail ? 'gmail-oauth' : 'smtp'));
            } catch (Exception $e) {
                $this->_log('sendForReview mail to ' . $email . ' failed: ' . $e->getMessage());
            }
        }

        if (!$sentAny) {
            $this->_log('sendForReview: no email sent for post #' . $post->getId() . ' — leaving unstamped for retry');
            return false;
        }
        $dec = $this->_decisions($post);
        if (empty($dec['_sent_at'])) { $dec['_sent_at'] = $this->_nowLocal()->format('Y-m-d H:i:s'); }
        if ($isReminder) { $dec['_reminder_sent_at'] = $this->_nowLocal()->format('Y-m-d H:i:s'); }
        $post->setReviewDecisions(json_encode($dec))->save();
        return true;
    }

    /**
     * A single manager approval books the next free Tue/Fri 09:00 publish slot
     * (same one-approval rule as the newsletter). Atomic claim: only the request
     * that flips PENDING/CHANGES -> SCHEDULED wins; a concurrent second approval
     * sees 0 rows updated and reports "already scheduled".
     *
     * @return array{0:bool,1:string}
     */
    public function scheduleApproved($postId)
    {
        $post = Mage::getModel('mmd_blog/post')->load((int) $postId);
        if (!$post->getId()) {
            return array(false, 'This post no longer exists.');
        }
        if (in_array((int) $post->getStatus(), array(
            MMD_Blog_Model_Post::STATUS_SCHEDULED, MMD_Blog_Model_Post::STATUS_PUBLISHED), true)) {
            return array(true, 'Already scheduled.');
        }
        $slot = $this->nextPublishSlot();
        if ($slot === null) {
            return array(false, 'No free Tuesday/Friday publish slot in the next 3 weeks.');
        }

        $write   = Mage::getSingleton('core/resource')->getConnection('core_write');
        $table   = Mage::getSingleton('core/resource')->getTableName('mmd_blog/post');
        $claimed = $write->update($table, array(
            'status'               => MMD_Blog_Model_Post::STATUS_SCHEDULED,
            'scheduled_publish_at' => $slot->format('Y-m-d H:i:s'),
        ), array(
            'post_id = ?' => (int) $postId,
            'status IN (' . MMD_Blog_Model_Post::STATUS_PENDING_REVIEW . ',' . MMD_Blog_Model_Post::STATUS_CHANGES_REQUESTED . ')',
        ));
        if (!$claimed) {
            return array(true, 'Already scheduled.');
        }
        $this->_log('scheduleApproved: post #' . $postId . ' -> publish ' . $slot->format('Y-m-d H:i'));
        return array(true, 'Publishing on ' . $slot->format('l, j M Y \a\t g:ia'));
    }

    /**
     * Manager requested changes: rewrite the article with Claude using their
     * feedback, then re-send for approval. Runs synchronously from the decide
     * endpoint (like the newsletter's regenerateOnChanges) — the caller sets a
     * generous time limit. Returns true when a revised version was re-sent.
     */
    public function regenerateOnChanges($postId)
    {
        $post = Mage::getModel('mmd_blog/post')->load((int) $postId);
        if (!$post->getId()) {
            return false;
        }
        $feedback = trim((string) $post->getReviewFeedback());
        $course   = $this->_courseBySku((string) $post->getSourceSku());

        $input = "You previously wrote this lead-magnet blog post draft:\n"
            . "TITLE: " . $post->getTitle() . "\n"
            . "HTML:\n" . $post->getContent() . "\n\n"
            . ($course
                ? "It promotes this course:\nCOURSE: {$course['name']}\nCOURSE_URL: {$course['url']}\n\n"
                : '')
            . "A manager reviewed it and requested changes:\n\"" . ($feedback !== '' ? $feedback : 'Improve the draft.') . "\"\n\n"
            . "Rewrite the post applying the feedback. Keep it a lead magnet (inline sign-up links to the course URL, "
            . "funding/SkillsFuture hooks, FAQ, 'What to do next' CTA) and keep it strongly SEO-optimised. "
            . "Respond with the SAME single JSON object shape as before.";

        $raw = $this->_invokeClaude($this->_writerSystemPrompt(), $input, 8000);
        if ($raw === '') {
            $this->_log('regenerateOnChanges: Claude returned nothing for post #' . $postId);
            return false;
        }
        $draft  = $this->_parseJson($raw);
        $helper = Mage::helper('mmd_blog');
        $urlKey = $helper->ensureUniqueUrlKey(
            $helper->slugify($draft['slug'] ?: $draft['title']),
            $post->getId()
        );

        // Fresh approval round: wipe per-reviewer decisions, keep the feedback for audit.
        $post->addData(array(
            'title'            => $draft['title'],
            'url_key'          => $urlKey,
            'excerpt'          => $draft['excerpt'],
            'content'          => $draft['contentHtml'],
            'meta_title'       => $draft['seoTitle'],
            'meta_description' => $draft['seoDescription'],
            'meta_keywords'    => $draft['seoKeywords'],
            'status'           => MMD_Blog_Model_Post::STATUS_PENDING_REVIEW,
            'review_decisions' => json_encode(array()),
        ));
        $post->save();
        if (!empty($draft['tags'])) {
            $helper->syncTags($post->getId(), $draft['tags']);
        }
        $this->_attachHero($post, (string) $post->getSourceSku());   // title changed -> re-render
        $this->_log('regenerateOnChanges: post #' . $postId . ' rewritten from feedback');
        return $this->sendForReview($post);
    }

    /**
     * Reminder / expiry babysitter for the post awaiting review. Returns true
     * when something is pending (so the propose step must not stack another).
     */
    private function _tendPendingReview()
    {
        $read  = Mage::getSingleton('core/resource')->getConnection('core_read');
        $table = Mage::getSingleton('core/resource')->getTableName('mmd_blog/post');
        $id    = $read->fetchOne(
            "SELECT post_id FROM {$table} WHERE status IN ("
            . MMD_Blog_Model_Post::STATUS_PENDING_REVIEW . ',' . MMD_Blog_Model_Post::STATUS_CHANGES_REQUESTED
            . ') ORDER BY post_id DESC LIMIT 1'
        );
        if (!$id) {
            return false;
        }
        $post = Mage::getModel('mmd_blog/post')->load((int) $id);

        if ((int) $post->getStatus() === MMD_Blog_Model_Post::STATUS_CHANGES_REQUESTED) {
            // The synchronous rewrite at decide-time failed (Claude hiccup) —
            // retry once per cron run until it re-enters review.
            $this->regenerateOnChanges($post->getId());
            return true;
        }

        $dec    = $this->_decisions($post);
        $sentAt = isset($dec['_sent_at']) ? strtotime($dec['_sent_at']) : false;
        $nowTs  = strtotime($this->_nowLocal()->format('Y-m-d H:i:s'));
        if ($sentAt === false) {
            $this->sendForReview($post);                        // original email never went out — retry
        } elseif ($nowTs - $sentAt > 5 * 86400) {
            $post->setStatus(MMD_Blog_Model_Post::STATUS_DRAFT)->save();
            $this->_log('review expired: post #' . $post->getId() . ' back to draft after 5 days');
            return false;                                       // slot freed — propose may run again
        } elseif ($nowTs - $sentAt > 86400 && empty($dec['_reminder_sent_at'])) {
            $this->sendForReview($post, null, true);            // the ONE 24h reminder
        }
        return true;
    }

    private function _decisions($post)
    {
        $dec = json_decode((string) $post->getReviewDecisions(), true);
        return is_array($dec) ? $dec : array();
    }

    // ---------------------------------------------------------------- publishing

    /**
     * Cron (every 10 min): publish SCHEDULED posts whose Tue/Fri slot has
     * arrived, then share each once to LinkedIn + Facebook.
     */
    public function publishDue()
    {
        try {
            $read  = Mage::getSingleton('core/resource')->getConnection('core_read');
            $table = Mage::getSingleton('core/resource')->getTableName('mmd_blog/post');
            $ids   = $read->fetchCol(
                "SELECT post_id FROM {$table}
                 WHERE status = " . MMD_Blog_Model_Post::STATUS_SCHEDULED . '
                   AND scheduled_publish_at IS NOT NULL AND scheduled_publish_at <= ?',
                array($this->_nowLocal()->format('Y-m-d H:i:s'))
            );
            if (!$ids) {
                return 'nothing due';
            }
            $done = array();
            foreach ($ids as $id) {
                $post = Mage::getModel('mmd_blog/post')->load((int) $id);
                if (!$post->getId()) { continue; }
                $post->setStatus(MMD_Blog_Model_Post::STATUS_PUBLISHED)
                     ->setPublishedAt(substr((string) $post->getScheduledPublishAt(), 0, 10))
                     ->save();
                $share  = $this->shareEverywhere($post);
                $done[] = $post->getId();
                $this->_log('publishDue: post #' . $post->getId() . ' (' . $post->getUrlKey() . ') published | ' . $share);
            }
            return 'published: ' . implode(',', $done);
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_log('publishDue error: ' . $e->getMessage());
        }
    }

    /**
     * Share a published post once to LinkedIn and once to the Facebook page.
     * Deduped by linkedin_urn / facebook_post_id, so repeat calls (cron retry,
     * admin re-save) are no-ops. Never throws — the post must stay published
     * even if both networks fail. Returns a log-friendly summary.
     */
    public function shareEverywhere($post)
    {
        $parts      = array();
        $helper     = Mage::helper('mmd_blog');
        $postUrl    = $helper->getPostUrl($post);
        $commentary = $this->_linkedinCommentary($post, $postUrl);

        // LinkedIn (og card auto-rendered from the URL)
        try {
            $linkedin = Mage::helper('mmd_blog/linkedin');
            if (!Mage::getStoreConfigFlag('mmd_blog/autoblog/linkedin_enabled')) {
                $parts[] = 'linkedin: off';
            } elseif ($post->getLinkedinUrn()) {
                $parts[] = 'linkedin: already shared';
            } elseif (!$linkedin->isConfigured()) {
                $parts[] = 'linkedin: skipped (credentials not set)';
            } else {
                $result = $linkedin->share($commentary, $postUrl, $post->getHeroImageUrl() ?: null);
                $post->setLinkedinUrn($result['externalId'])->save();
                $parts[] = 'linkedin: ok ' . $result['externalId'];
            }
        } catch (Exception $e) {
            Mage::log('Blog LinkedIn share failed: ' . $e->getMessage(), null, 'mmd_blog.log');
            $parts[] = 'linkedin: ERROR ' . $e->getMessage();
        }

        // LinkedIn company page (same commentary + hero, author = org URN).
        // Dormant until mmd_marketing/linkedin/org_urn is set AND the token
        // carries w_organization_social; deduped by linkedin_org_urn.
        try {
            $linkedin = Mage::helper('mmd_blog/linkedin');
            $orgUrn   = $linkedin->orgUrn();
            if (!Mage::getStoreConfigFlag('mmd_blog/autoblog/linkedin_enabled') || !$orgUrn) {
                $parts[] = 'linkedin-org: off';
            } elseif ($post->getLinkedinOrgUrn()) {
                $parts[] = 'linkedin-org: already shared';
            } elseif (!$linkedin->isConfigured()) {
                $parts[] = 'linkedin-org: skipped (credentials not set)';
            } else {
                $result = $linkedin->share($commentary, $postUrl, $post->getHeroImageUrl() ?: null, $orgUrn);
                $post->setLinkedinOrgUrn($result['externalId'])->save();
                $parts[] = 'linkedin-org: ok ' . $result['externalId'];
            }
        } catch (Exception $e) {
            Mage::log('Blog LinkedIn org share failed: ' . $e->getMessage(), null, 'mmd_blog.log');
            $parts[] = 'linkedin-org: ERROR ' . $e->getMessage();
        }

        // Facebook page (link post; the og card carries the visual)
        try {
            $facebook = Mage::helper('mmd_marketing/facebook');
            if (!Mage::getStoreConfigFlag('mmd_blog/autoblog/facebook_enabled')) {
                $parts[] = 'facebook: off';
            } elseif ($post->getFacebookPostId()) {
                $parts[] = 'facebook: already shared';
            } elseif (!$facebook->isConfigured()) {
                $parts[] = 'facebook: skipped (credentials not set)';
            } else {
                $result = $facebook->postLink($commentary, $postUrl);
                if (!empty($result['ok'])) {
                    $post->setFacebookPostId($result['id'])->save();
                    $parts[] = 'facebook: ok ' . $result['id'];
                } else {
                    $parts[] = 'facebook: FAILED ' . $result['msg'];
                }
            }
        } catch (Exception $e) {
            Mage::log('Blog Facebook share failed: ' . $e->getMessage(), null, 'mmd_blog.log');
            $parts[] = 'facebook: ERROR ' . $e->getMessage();
        }

        return implode(' | ', $parts);
    }

    /**
     * LinkedIn lead-magnet copy (linkedin-posts skill; structure mirrors the
     * newsletter's _defaultCommentary): emoji hook line, the excerpt, then an
     * IN-DEPTH "inside the guide" outline pulled from the article's own h2/h3
     * headings, funding value line, the blog guide link plus the SPECIFIC
     * course sign-up deep link as the CTA, and hashtags at the end. Funding
     * copy is gated on the related course's SKU prefix (TGS- = WSQ) — never
     * assume every course is funded. Reserved-char escaping happens in
     * MMD_Blog_Helper_Linkedin::escapeLittleText() at share time.
     */
    private function _linkedinCommentary($post, $postUrl)
    {
        $helper  = Mage::helper('mmd_blog');
        $courses = $helper->getRelatedCourses($post, 1);
        $course  = $courses ? $courses[0] : null;

        $courseUrl = '';
        if ($course && $course->getUrlKey()) {
            // Same base-URL resolution as getPostUrl(); products live at /<url_key>.html
            $courseUrl = rtrim(Mage::getUrl('', array('_direct' => '')), '/')
                . '/' . $course->getUrlKey() . '.html';
        }
        $isWsq = $course && strpos((string) $course->getSku(), 'TGS-') === 0;

        $excerpt = trim((string) $post->getExcerpt());
        if (mb_strlen($excerpt) > 300) {
            $excerpt = mb_substr($excerpt, 0, 297);
            $cut     = mb_strrpos($excerpt, ' ');
            $excerpt = ($cut ? mb_substr($excerpt, 0, $cut) : $excerpt) . '…';
        }

        $lines   = array('🚀 ' . $post->getTitle());
        if ($excerpt !== '') {
            $lines[] = '';
            $lines[] = $excerpt;
        }

        $outline = $this->_contentOutline($post);
        if ($outline) {
            $lines[] = '';
            $lines[] = '🔍 Inside the full guide:';
            foreach ($outline as $point) {
                $lines[] = '▪ ' . $point;
            }
        }

        $lines[] = '';
        if ($isWsq) {
            $lines[] = '💰 Up to 70% SkillsFuture funding — WSQ course, SkillsFuture Credit claimable';
        }
        $lines[] = '📖 Full analysis: ' . $postUrl;
        if ($courseUrl !== '') {
            $lines[] = '👉 Register for the hands-on course: ' . $courseUrl;
        }
        $lines[] = '';
        $lines[] = implode(' ', $this->_hashtags($post, $isWsq));

        return implode("\n", $lines);
    }

    /**
     * The article's own h2/h3 headings as an outline (max 6); falls back to the
     * first sentences of the opening paragraphs when the writer used no headings.
     */
    private function _contentOutline($post)
    {
        $html = (string) $post->getContent();
        $out  = array();
        if (preg_match_all('/<h[23][^>]*>(.*?)<\/h[23]>/is', $html, $m)) {
            foreach ($m[1] as $h) {
                $h = trim(html_entity_decode(strip_tags($h), ENT_QUOTES, 'UTF-8'));
                if (mb_strlen($h) >= 4 && count($out) < 6) {
                    $out[] = $h;
                }
            }
        }
        if (!$out && preg_match_all('/<p[^>]*>(.*?)<\/p>/is', $html, $m)) {
            foreach (array_slice($m[1], 0, 3) as $p) {
                $p = trim(html_entity_decode(strip_tags($p), ENT_QUOTES, 'UTF-8'));
                if (mb_strlen($p) > 140) {
                    $p   = mb_substr($p, 0, 137);
                    $cut = mb_strrpos($p, ' ');
                    $p   = ($cut ? mb_substr($p, 0, $cut) : $p) . '…';
                }
                if ($p !== '') {
                    $out[] = $p;
                }
            }
        }
        return $out;
    }

    /** A few relevant hashtags: funding staples + the post's own tags, capped at 6. */
    private function _hashtags($post, $isWsq)
    {
        $tags = $isWsq
            ? array('#WSQ', '#SkillsFuture', '#SkillsFutureCredit')
            : array('#TertiaryCourses');
        foreach (Mage::helper('mmd_blog')->getPostTags($post->getId()) as $name) {
            if (count($tags) >= 6) {
                break;
            }
            $tag = '#' . preg_replace('/[^A-Za-z0-9]/', '', ucwords((string) $name));
            if (strlen($tag) > 1 && !in_array($tag, $tags, true)) {
                $tags[] = $tag;
            }
        }
        return $tags;
    }

    // ---------------------------------------------------------------- course pick

    /**
     * Admin-curated queue first (Blog Posts page "Next blog queue" — the row is
     * DELETED on consumption, same contract as the newsletter flyer queue), then
     * the auto-pick: best-selling course of the last 180 days that (a) is
     * enabled + visible, (b) has a storefront URL rewrite, (c) hasn't been
     * auto-blogged before. On the SG site only WSQ (TGS-) courses qualify for
     * the auto-pick — a queued course is an explicit admin choice and is exempt.
     *
     * @return array{sku:string,name:string,url:string,description:string}|null
     */
    private function _pickCourse()
    {
        $queued = $this->_popQueueHead();
        if ($queued) {
            return $queued;
        }
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $wsqSql   = $this->_wsqOnly() ? " AND oi.sku LIKE 'TGS-%'" : '';
        $rows = $read->fetchAll(
            "SELECT oi.sku, oi.name, COUNT(*) AS orders
             FROM {$resource->getTableName('sales/order_item')} oi
             WHERE oi.created_at >= DATE_SUB(NOW(), INTERVAL 180 DAY)
               AND oi.parent_item_id IS NULL AND oi.sku IS NOT NULL AND oi.sku <> ''{$wsqSql}
               AND oi.sku NOT IN (
                   SELECT bp.source_sku FROM {$resource->getTableName('mmd_blog/post')} bp
                   WHERE bp.source_sku IS NOT NULL
               )
             GROUP BY oi.sku, oi.name
             ORDER BY orders DESC
             LIMIT 20"
        );
        foreach ($rows as $row) {
            $course = $this->_courseBySku($row['sku']);
            if ($course) {
                return $course;
            }
        }
        return null;
    }

    /**
     * Pop the head of the admin-curated blog queue (lowest position). The row is
     * deleted on consumption so each queued course produces exactly one post.
     * Unusable heads (course deleted/disabled since queueing) are skipped.
     * Tolerates the table not existing yet (pre-migration partner DBs).
     */
    private function _popQueueHead()
    {
        try {
            $read  = Mage::getSingleton('core/resource')->getConnection('core_read');
            $write = Mage::getSingleton('core/resource')->getConnection('core_write');
            for ($i = 0; $i < 20; $i++) {
                $row = $read->fetchRow(
                    'SELECT queue_id, product_id, topics, links FROM mmd_blog_queue ORDER BY position ASC, queue_id ASC LIMIT 1');
                if (!$row) {
                    return null;
                }
                $write->delete('mmd_blog_queue', array('queue_id = ?' => (int) $row['queue_id']));
                $course = $this->_courseById((int) $row['product_id']);
                if ($course) {
                    $course['topics'] = trim((string) ($row['topics'] ?? ''));
                    $course['links']  = trim((string) ($row['links'] ?? ''));
                    $this->_log('picked queued course ' . $course['sku'] . ' (product ' . (int) $row['product_id'] . ')'
                        . ($course['topics'] !== '' ? ' with admin topics' : ''));
                    return $course;
                }
                $this->_log('queue head product ' . (int) $row['product_id'] . ' unusable — trying next');
            }
        } catch (Exception $e) {
            $this->_log('queue read failed (table missing?): ' . $e->getMessage());
        }
        return null;
    }

    /** Load a course by product id into the writer's shape (null if unusable). */
    private function _courseById($productId)
    {
        $resource = Mage::getSingleton('core/resource');
        $sku = (string) $resource->getConnection('core_read')->fetchOne(
            'SELECT sku FROM ' . $resource->getTableName('catalog/product') . ' WHERE entity_id = ?',
            array((int) $productId)
        );
        return $sku !== '' ? $this->_courseBySku($sku) : null;
    }

    /** Load + validate one course by SKU into the writer's shape (null if unusable). */
    private function _courseBySku($sku)
    {
        if ($sku === '') {
            return null;
        }
        $product = Mage::getModel('catalog/product');
        $id      = $product->getIdBySku($sku);
        if (!$id) {
            return null;
        }
        $product->setStoreId(Mage::app()->getStore()->getId())->load($id);
        if (!$product->getId()
            || $product->getStatus() != Mage_Catalog_Model_Product_Status::STATUS_ENABLED
            || $product->getVisibility() == Mage_Catalog_Model_Product_Visibility::VISIBILITY_NOT_VISIBLE
        ) {
            return null;
        }
        $url = $product->getUrlPath();
        if (!$url) {
            return null;
        }
        return array(
            'sku'         => $sku,
            'name'        => $product->getName(),
            'url'         => rtrim(Mage::getBaseUrl(), '/') . '/' . ltrim($url, '/'),
            'description' => trim(strip_tags((string) $product->getShortDescription())),
        );
    }

    // ---------------------------------------------------------------- research agent

    /**
     * Agent 1 — topic scout. Uses Claude's server-side web search to find the
     * freshest developments (default focus pool in mmd_blog/autoblog/topics)
     * relevant to the course, avoiding angles already covered by recent posts.
     * Returns null when web search / the API key is unavailable or the reply
     * doesn't parse — the writer then produces evergreen content instead.
     *
     * @return array{topic:string,angle:string,whyNow:string,keyPoints:array,sources:array}|null
     */
    private function _researchTopic(array $course)
    {
        try {
            $topics = trim((string) Mage::getStoreConfig('mmd_blog/autoblog/topics'));
            $read   = Mage::getSingleton('core/resource')->getConnection('core_read');
            $recent = $read->fetchCol(
                'SELECT title FROM ' . Mage::getSingleton('core/resource')->getTableName('mmd_blog/post')
                . ' ORDER BY post_id DESC LIMIT 8'
            );

            $system = 'You are a technology-trends research agent for a Singapore training academy. '
                . 'Use web search to find what is genuinely NEW and newsworthy (last 60 days). '
                . 'After researching, respond with ONE JSON object only — no markdown fences, no preamble. Keys: '
                . 'topic (string, the chosen topic), angle (string, the specific fresh angle for a blog post), '
                . 'whyNow (string, 1-2 sentences on why this is timely, naming concrete recent events/releases with dates), '
                . 'keyPoints (array of 4-7 strings — specific facts, numbers, product names, versions, dates found in research), '
                . 'sources (array of {title, url} for the 3-5 most authoritative pages consulted).';

            $adminTopics = trim((string) ($course['topics'] ?? ''));
            $adminLinks  = trim((string) ($course['links'] ?? ''));
            $adminBlock  = '';
            if ($adminTopics !== '') {
                $adminBlock .= "ADMIN-SPECIFIED TOPICS (these take PRIORITY over the generic focus areas — research THESE):\n{$adminTopics}\n\n";
            }
            if ($adminLinks !== '') {
                $adminBlock .= "ADMIN-PROVIDED REFERENCE LINKS (use web search to read what these pages cover and build on their content):\n{$adminLinks}\n\n";
            }

            $input = "Research the latest developments relevant to this instructor-led course so a blog post about it feels current:\n"
                . "COURSE: {$course['name']}\n"
                . "COURSE_SUMMARY: " . substr($course['description'], 0, 600) . "\n\n"
                . $adminBlock
                . ($topics !== '' && $adminTopics === '' ? "FOCUS AREAS (pick whichever best fits the course): {$topics}\n\n" : '')
                . "Recent posts already covered these angles — find something DIFFERENT:\n- "
                . implode("\n- ", array_map('strval', $recent)) . "\n\n"
                . "Search the web for the newest releases, benchmarks, incidents, or industry moves tied to the course topic"
                . ($adminTopics !== '' ? ' — staying within the admin-specified topics above' : '') . '.';

            $raw = $this->_invokeClaude($system, $input, 3000, true);
            if ($raw === '') {
                return null;
            }
            $cleaned = trim(preg_replace('/^```(?:json)?\s*|```\s*$/i', '', trim($raw)));
            if ($cleaned !== '' && $cleaned[0] !== '{') {
                $start = strpos($cleaned, '{');
                $end   = strrpos($cleaned, '}');
                if ($start === false || $end === false || $end <= $start) {
                    return null;
                }
                $cleaned = substr($cleaned, $start, $end - $start + 1);
            }
            $data = json_decode($cleaned, true);
            if (!is_array($data) || empty($data['topic'])) {
                return null;
            }
            return array(
                'topic'     => trim((string) $data['topic']),
                'angle'     => trim((string) ($data['angle'] ?? '')),
                'whyNow'    => trim((string) ($data['whyNow'] ?? '')),
                'keyPoints' => is_array($data['keyPoints'] ?? null) ? $data['keyPoints'] : array(),
                'sources'   => is_array($data['sources'] ?? null) ? $data['sources'] : array(),
            );
        } catch (Exception $e) {
            $this->_log('research agent failed (continuing without): ' . $e->getMessage());
            return null;
        }
    }

    // ---------------------------------------------------------------- hero image

    /**
     * Render + attach the branded hero (CourseImage GD cover -> R2). Only
     * touches auto-generated heroes (key prefix blog/auto-) — an admin-uploaded
     * hero is never overwritten. The post must survive any image failure.
     */
    private function _attachHero($post, $sku)
    {
        try {
            $current = (string) $post->getHeroImageUrl();
            if ($current !== '' && strpos($current, 'blog/auto-') === false) {
                return;
            }
            $url = Mage::helper('mmd_blog/image')->generateHero((string) $post->getTitle(), (string) $sku);
            if ($url !== '') {
                $post->setHeroImageUrl($url)->save();
                $this->_log('hero image attached to post #' . $post->getId());
            }
        } catch (Exception $e) {
            $this->_log('hero image generation failed (post kept without): ' . $e->getMessage());
        }
    }

    // ---------------------------------------------------------------- claude

    private function _writerSystemPrompt()
    {
        return 'You are the content marketer for a Singapore SkillsFuture-approved training academy. '
            . 'You write conversion-focused blog posts that act as lead magnets for instructor-led courses, '
            . 'and every post is aggressively SEO-optimised: one clear target keyphrase used in the title, '
            . 'the first paragraph, at least two h2 headings and the meta fields; scannable h2/h3 structure; '
            . 'natural long-tail variations of the keyphrase throughout. '
            . 'Respond with ONE JSON object only — no markdown fences, no preamble. Keys: '
            . 'title (string, <=70 chars), slug (kebab-case), excerpt (string, <=160 chars), '
            . 'contentHtml (string: clean HTML using h2/h3/p/ul/ol/li/strong/table only), '
            . 'seoTitle (<=60 chars), seoDescription (<=155 chars), seoKeywords (comma-separated), '
            . 'tags (array of 3-5 short topic tags).';
    }

    private function _writerInput(array $course, $research = null)
    {
        $isWsq = strpos($course['sku'], 'TGS-') === 0;

        $researchBlock = '';
        if (is_array($research)) {
            $points = '';
            foreach ($research['keyPoints'] as $p) {
                $points .= '- ' . trim((string) $p) . "\n";
            }
            $sources = '';
            foreach ($research['sources'] as $s) {
                if (!empty($s['url'])) {
                    $sources .= '- ' . trim((string) ($s['title'] ?? $s['url'])) . ' — ' . trim((string) $s['url']) . "\n";
                }
            }
            $researchBlock = "FRESH RESEARCH BRIEF (from the topic-research agent — build the post around it so it reads current):\n"
                . "TOPIC: {$research['topic']}\n"
                . "ANGLE: {$research['angle']}\n"
                . "WHY NOW: {$research['whyNow']}\n"
                . ($points !== '' ? "KEY POINTS:\n{$points}" : '')
                . ($sources !== '' ? "SOURCES:\n{$sources}" : '')
                . "\n";
        }

        $adminTopics = trim((string) ($course['topics'] ?? ''));
        $adminLinks  = trim((string) ($course['links'] ?? ''));
        $adminBlock  = '';
        if ($adminTopics !== '' || $adminLinks !== '') {
            $adminBlock = "ADMIN BRIEF (the editor's direction — the post MUST be built around this):\n"
                . ($adminTopics !== '' ? "TOPICS: {$adminTopics}\n" : '')
                . ($adminLinks !== '' ? "REFERENCE LINKS (cite at least 2 of these as inline links with descriptive anchor text):\n{$adminLinks}\n" : '')
                . "\n";
        }

        return "Write an in-depth lead-magnet blog post promoting this course:\n"
            . "COURSE: {$course['name']}\n"
            . "COURSE_URL: {$course['url']}\n"
            . "COURSE_SUMMARY: " . substr($course['description'], 0, 1200) . "\n\n"
            . $adminBlock
            . $researchBlock
            . "Requirements:\n"
            . ($adminBlock !== ''
                ? "- The ADMIN BRIEF is the assignment: cover its topics as the core of the article, not as an aside.\n"
                : '')
            . "- 1200-1800 words of genuinely useful, IN-DEPTH analysis of the topic (not a sales page): "
            . "explain what changed, why it matters, and what practitioners should do about it.\n"
            . ($researchBlock !== ''
                ? "- Reference the latest developments from the research brief with specifics (product names, versions, dates) and cite at least 2 of the SOURCES as inline links (rel-follow, descriptive anchor text).\n"
                : '')
            . "- Weave in at least 2 inline links to COURSE_URL with action anchor text (e.g. sign up, register).\n"
            . ($isWsq
                ? "- This is a WSQ course: explicitly mention up to 70% WSQ funding for eligible Singaporeans/PRs, that SkillsFuture Credit can be used to offset the fee, and SME subsidy support.\n"
                : "- Explicitly mention that SkillsFuture Credit can be claimed for this course and highlight WSQ funding availability across our WSQ course catalogue.\n")
            . "- End with a 'What to do next' section whose final call-to-action links to COURSE_URL.\n"
            . "- Include a short FAQ (3 questions) with an answer about funding/SkillsFuture claims.\n"
            . "- Singapore audience, professional but energetic tone.";
    }

    /**
     * Same 3-tier strategy as MMD_RoleManager_Model_AiSeo::invokeClaude, with a
     * custom system prompt + larger max_tokens (a full article doesn't fit the
     * SEO helper's 2000-token cap): API key -> claude CLI -> ''.
     *
     * $webSearch=true enables Claude's server-side web_search tool (research
     * agent). Only the API-key path supports it; a search response interleaves
     * tool-use blocks with text blocks, so all text blocks are concatenated.
     */
    private function _invokeClaude($system, $prompt, $maxTokens, $webSearch = false)
    {
        $cfg    = Mage::helper('mmd_rolemanager')->getMarketingApiConfig();
        $apiKey = trim((string) ($cfg['anthropic_key'] ?? ''));
        $model  = trim((string) ($cfg['anthropic_model'] ?? '')) ?: 'claude-sonnet-4-6';

        if (stripos($apiKey, 'sk-ant-api') === 0) {
            try {
                $payload = array(
                    'model'      => $model,
                    'max_tokens' => (int) $maxTokens,
                    'system'     => $system,
                    'messages'   => array(array('role' => 'user', 'content' => $prompt)),
                );
                if ($webSearch) {
                    $payload['tools'] = array(array(
                        'type'     => 'web_search_20250305',
                        'name'     => 'web_search',
                        'max_uses' => 5,
                    ));
                }
                $body = json_encode($payload);
                $ch = curl_init('https://api.anthropic.com/v1/messages');
                curl_setopt_array($ch, array(
                    CURLOPT_POST           => true,
                    CURLOPT_POSTFIELDS     => $body,
                    CURLOPT_RETURNTRANSFER => true,
                    CURLOPT_TIMEOUT        => $webSearch ? 280 : 180,
                    CURLOPT_CONNECTTIMEOUT => 10,
                    CURLOPT_HTTPHEADER     => array(
                        'anthropic-version: 2023-06-01',
                        'content-type: application/json',
                        'x-api-key: ' . $apiKey,
                    ),
                ));
                $raw  = curl_exec($ch);
                $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
                curl_close($ch);
                $rsp = json_decode($raw, true);
                if ($code < 400 && isset($rsp['content']) && is_array($rsp['content'])) {
                    $text = '';
                    foreach ($rsp['content'] as $block) {
                        if (isset($block['type'], $block['text']) && $block['type'] === 'text') {
                            $text .= $block['text'];
                        }
                    }
                    if (trim($text) !== '') {
                        return $text;
                    }
                }
                if ($webSearch) {
                    // The org may not have web search enabled — report and let
                    // the caller degrade to evergreen content (no CLI retry:
                    // the CLI path can't search either).
                    $this->_log('web-search call failed (HTTP ' . $code . '): ' . substr((string) $raw, 0, 200));
                    return '';
                }
            } catch (Exception $e) { /* fall through to CLI */ }
        } elseif ($webSearch) {
            return '';
        }

        // claude CLI fallback (same environment dance as AiSeo::invokeClaude).
        $descriptors = array(0 => array('pipe', 'r'), 1 => array('pipe', 'w'), 2 => array('pipe', 'w'));
        $env = array();
        foreach ($_ENV as $k => $v) if ($k !== 'CLAUDECODE') $env[$k] = $v;
        foreach (array('PATH', 'HOME') as $k) {
            if (!isset($env[$k]) && getenv($k) !== false) $env[$k] = getenv($k);
        }
        if (is_dir('/var/www/.claude'))                          $env['HOME'] = '/var/www';
        elseif (is_dir('/root/.claude') && is_readable('/root')) $env['HOME'] = '/root';
        // Subscription OAuth tokens (sk-ant-oat*) skip the direct API path
        // above but DO authenticate the CLI headlessly — without this export
        // the CLI answers "Not logged in · Please run /login" and the run dies.
        if (stripos($apiKey, 'sk-ant-oat') === 0) {
            $env['CLAUDE_CODE_OAUTH_TOKEN'] = $apiKey;
        }
        $env['DISABLE_AUTOUPDATER'] = '1';

        $proc = @proc_open('timeout 280 claude -p --output-format text', $descriptors, $pipes, null, $env);
        if (!is_resource($proc)) return '';
        fwrite($pipes[0], $system . "\n\n" . $prompt);
        fclose($pipes[0]);
        stream_set_blocking($pipes[1], false);
        stream_set_blocking($pipes[2], false);
        $deadline = time() + 285;
        $out = '';
        while (time() < $deadline) {
            $status = proc_get_status($proc);
            $out .= stream_get_contents($pipes[1]);
            stream_get_contents($pipes[2]);
            if (!$status['running']) break;
            usleep(200000);
        }
        $status = proc_get_status($proc);
        if ($status['running']) { proc_terminate($proc, 9); }
        $out .= stream_get_contents($pipes[1]);
        fclose($pipes[1]);
        fclose($pipes[2]);
        proc_close($proc);
        return trim($out);
    }

    /** @return array with title/slug/excerpt/contentHtml/seoTitle/seoDescription/seoKeywords/tags */
    private function _parseJson($raw)
    {
        $cleaned = trim(preg_replace('/^```(?:json)?\s*|```\s*$/i', '', trim($raw)));
        // Tolerate stray prose around the object.
        if ($cleaned !== '' && $cleaned[0] !== '{') {
            $start = strpos($cleaned, '{');
            $end   = strrpos($cleaned, '}');
            if ($start === false || $end === false || $end <= $start) {
                Mage::throwException('Autoblog: no JSON object in Claude output (head: ' . substr($cleaned, 0, 120) . ')');
            }
            $cleaned = substr($cleaned, $start, $end - $start + 1);
        }
        $data = json_decode($cleaned, true);
        if (!is_array($data)) {
            // The CLI sometimes emits literal newlines/tabs INSIDE string
            // values (invalid JSON, intermittent). Escape control chars within
            // quoted strings only — whitespace between tokens stays untouched.
            $repaired = preg_replace_callback('/"(?:[^"\\\\]|\\\\.)*"/s', function ($m) {
                return str_replace(array("\r\n", "\r", "\n", "\t"), array('\n', '\n', '\n', '\t'), $m[0]);
            }, $cleaned);
            $data = json_decode($repaired, true);
        }
        if (!is_array($data) || empty($data['title']) || empty($data['contentHtml'])) {
            Mage::throwException('Autoblog: invalid JSON from Claude (' . json_last_error_msg()
                . '; head: ' . substr($cleaned, 0, 120) . ' | tail: ' . substr($cleaned, -80) . ')');
        }
        return array(
            'title'          => trim((string) $data['title']),
            'slug'           => trim((string) ($data['slug'] ?? '')),
            'excerpt'        => trim((string) ($data['excerpt'] ?? '')),
            'contentHtml'    => trim((string) $data['contentHtml']),
            'seoTitle'       => trim((string) ($data['seoTitle'] ?? $data['title'])),
            'seoDescription' => trim((string) ($data['seoDescription'] ?? ($data['excerpt'] ?? ''))),
            'seoKeywords'    => trim((string) ($data['seoKeywords'] ?? '')),
            'tags'           => is_array($data['tags'] ?? null) ? $data['tags'] : array(),
        );
    }

    private function _log($msg)
    {
        Mage::log('[autoblog] ' . $msg, null, 'mmd_blog.log');
        return $msg;
    }
}
