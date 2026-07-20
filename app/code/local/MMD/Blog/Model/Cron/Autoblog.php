<?php
/**
 * Auto-blog pipeline — 2 lead-magnet posts per week with manager approval,
 * modelled on the newsletter blast pipeline (MMD_Marketing_Model_Cron_Flyer):
 *
 *   propose (cron daily 09:00, run()):
 *     1. Pick the best-selling course (last 180 days) with no post yet
 *        (tracked via mmd_blog_post.source_sku). On the SG site only WSQ
 *        (TGS-) courses qualify.
 *     2. Ask Claude for a complete SEO lead-magnet post as strict JSON.
 *     3. Review flow (SG, auto_publish=0): save as PENDING REVIEW and email
 *        the two managers approve/request-changes token links. One approval
 *        books the next free Monday/Thursday 09:00 publish slot.
 *        Legacy flow (partners, auto_publish=1): publish + share immediately.
 *     4. While a post is pending: 24h reminder (once), expiry to draft after
 *        5 days — same anti-spam contract as the newsletter followUp().
 *
 *   publishDue (cron every 10 min): flip SCHEDULED posts whose Mon/Thu slot
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
    /** Mon/Thu 09:00 SGT publish slots — the blog counterpart of Blastguard's 08:00 blast slots. */
    const PUBLISH_HOUR = 9;
    const TZ_LOCAL     = 'Asia/Singapore';

    public function run($trigger = 'cron')
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
                // Only generate when an upcoming Mon/Thu slot actually needs
                // content — this is what paces the pipeline to 2 posts/week.
                if ($this->nextPublishSlot(7) === null) {
                    return $this->_log('skipped: both upcoming Mon/Thu publish slots are filled');
                }
            }
            if (!$review && $trigger === 'cron' && $this->_recentAutoPostExists()) {
                return $this->_log('skipped: an auto post was already created in the last 5 days');
            }

            $course = $this->_pickCourse();
            if (!$course) {
                return $this->_log('skipped: no unblogged course with a URL found');
            }

            $raw = $this->_invokeClaude($this->_writerSystemPrompt(), $this->_writerInput($course), 8000);
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
     * The soonest future Monday/Thursday 09:00 (SGT) whose calendar day is not
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
            if ($dow !== 1 && $dow !== 4) {
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
        $slotTxt = $slot ? $slot->format('l, j M Y \a\t g:ia') : 'the next free Monday/Thursday 9:00am slot';

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

        $sentAny = false;
        foreach ($guard->reviewers() as $email) {
            if (is_array($onlyEmails) && !in_array(strtolower($email), $onlyEmails, true)) { continue; }
            $tok     = $helper->signReviewToken($post->getId(), $email);
            $approve = $base . '/blog/index/decide/id/' . $post->getId() . '/d/approve/e/' . rawurlencode($email) . '/t/' . $tok;
            $changes = $base . '/blog/index/decide/id/' . $post->getId() . '/d/changes/e/' . rawurlencode($email) . '/t/' . $tok;

            $html = '<div style="font-family:-apple-system,Segoe UI,Arial,sans-serif;max-width:720px;margin:0 auto;">'
                . '<p style="font-size:15px;color:#0a1020;">Hi — a new blog post is ready for your approval. If approved, it will be published on <b>' . $slotTxt . '</b> (2 posts/week, Mondays &amp; Thursdays), then shared to LinkedIn and the Facebook page.</p>'
                . $courseLine
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
     * A single manager approval books the next free Mon/Thu 09:00 publish slot
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
            return array(false, 'No free Monday/Thursday publish slot in the next 3 weeks.');
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
     * Cron (every 10 min): publish SCHEDULED posts whose Mon/Thu slot has
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
        $parts   = array();
        $helper  = Mage::helper('mmd_blog');
        $postUrl = $helper->getPostUrl($post);
        $commentary = $post->getTitle()
            . ($post->getExcerpt() ? "\n\n" . $post->getExcerpt() : '')
            . "\n\nWSQ funding + SkillsFuture Credit claimable — full guide and course sign-up:";

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

    // ---------------------------------------------------------------- course pick

    /**
     * Best-selling course of the last 180 days that (a) is enabled + visible,
     * (b) has a storefront URL rewrite, (c) hasn't been auto-blogged before.
     * On the SG site only WSQ (TGS-) courses qualify — see _wsqOnly().
     *
     * @return array{sku:string,name:string,url:string,description:string}|null
     */
    private function _pickCourse()
    {
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

    private function _writerInput(array $course)
    {
        $isWsq = strpos($course['sku'], 'TGS-') === 0;
        return "Write a lead-magnet blog post promoting this course:\n"
            . "COURSE: {$course['name']}\n"
            . "COURSE_URL: {$course['url']}\n"
            . "COURSE_SUMMARY: " . substr($course['description'], 0, 1200) . "\n\n"
            . "Requirements:\n"
            . "- 800-1200 words of genuinely useful, practical content on the course topic (not a sales page).\n"
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
     */
    private function _invokeClaude($system, $prompt, $maxTokens)
    {
        $cfg    = Mage::helper('mmd_rolemanager')->getMarketingApiConfig();
        $apiKey = trim((string) ($cfg['anthropic_key'] ?? ''));
        $model  = trim((string) ($cfg['anthropic_model'] ?? '')) ?: 'claude-sonnet-4-6';

        if (stripos($apiKey, 'sk-ant-api') === 0) {
            try {
                $body = json_encode(array(
                    'model'      => $model,
                    'max_tokens' => (int) $maxTokens,
                    'system'     => $system,
                    'messages'   => array(array('role' => 'user', 'content' => $prompt)),
                ));
                $ch = curl_init('https://api.anthropic.com/v1/messages');
                curl_setopt_array($ch, array(
                    CURLOPT_POST           => true,
                    CURLOPT_POSTFIELDS     => $body,
                    CURLOPT_RETURNTRANSFER => true,
                    CURLOPT_TIMEOUT        => 180,
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
                if ($code < 400 && isset($rsp['content'][0]['text'])) {
                    return (string) $rsp['content'][0]['text'];
                }
            } catch (Exception $e) { /* fall through to CLI */ }
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
        if (!is_array($data) || empty($data['title']) || empty($data['contentHtml'])) {
            Mage::throwException('Autoblog: invalid JSON from Claude (head: ' . substr($cleaned, 0, 120) . ')');
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
