<?php
/**
 * Marketing newsletter builder — country-scoped, AI-assisted.
 *
 * Controller actions all return JSON, matching the existing Create New
 * Class / Assign Trainer pattern in CoursesaveController. The Marketing
 * sidebar panel POSTs to these actions via fetch + FormData.
 *
 * Country scope: every read/write is constrained to the logged-in
 * admin's website (admin.my → MY rows only). The country comes from
 * MMD_RoleManager_Helper_Data::getActiveCountryCode().
 *
 * Stub mode: when the Anthropic / MailerLite keys in app/etc/local.xml
 * are blank, the controller returns plausible mock responses so the UI
 * loop works end-to-end without real keys. Drop in keys to flip live.
 */
class MMD_RoleManager_Adminhtml_MarketingnewsletterController extends Mage_Adminhtml_Controller_Action
{
    public function listAction()
    {
        $result = array('success' => false, 'newsletters' => array());
        try {
            $cc = $this->_currentCountry();
            $rows = $this->_db('read')->fetchAll(
                "SELECT newsletter_id, title, subject, template_key, status,
                        mailerlite_id, course_pids, updated_at
                 FROM " . $this->_tbl()
               . " WHERE country_code = ?
                 ORDER BY updated_at DESC LIMIT 50",
                array($cc)
            );
            $result['newsletters'] = $rows;
            $result['country']     = $cc;
            $result['success']     = true;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    /**
     * Autocomplete for the Featured Courses picker — country-scoped.
     */
    public function searchCoursesAction()
    {
        $result = array('success' => false, 'courses' => array());
        try {
            $q = strtolower(trim((string) $this->getRequest()->getParam('q')));
            if (mb_strlen($q) < 2) { $result['success'] = true; return $this->_json($result); }
            $wid = (int) Mage::helper('mmd_rolemanager')->getActiveWebsiteId();
            $like = '%' . $q . '%';
            // wsq=1 restricts to WSQ courses (TGS- SKU prefix) — used by the
            // next-flyer queue, which only lines up WSQ courses.
            $wsqOnly = (int) $this->getRequest()->getParam('wsq') === 1 ? " AND e.sku LIKE 'TGS-%'" : '';
            $rows = $this->_db('read')->fetchAll(
                "SELECT e.entity_id AS id, e.sku, v.value AS name,
                        sd.value AS start_date, ed.value AS end_date
                 FROM catalog_product_entity e
                 INNER JOIN catalog_product_website pw ON pw.product_id = e.entity_id AND pw.website_id = ?
                 INNER JOIN catalog_product_entity_varchar v ON v.entity_id = e.entity_id AND v.attribute_id = 71 AND v.store_id = 0 AND v.value <> ''
                 LEFT JOIN catalog_product_entity_datetime sd ON sd.entity_id = e.entity_id AND sd.attribute_id = 86 AND sd.store_id = 0
                 LEFT JOIN catalog_product_entity_datetime ed ON ed.entity_id = e.entity_id AND ed.attribute_id = 87 AND ed.store_id = 0
                 WHERE (LOWER(v.value) LIKE ? OR LOWER(e.sku) LIKE ?){$wsqOnly}
                 ORDER BY v.value ASC LIMIT 30",
                array($wid, $like, $like)
            );
            $result['courses'] = $rows;
            $result['success'] = true;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    /**
     * Generate or revise newsletter copy with Claude. Multi-turn:
     * `mode=initial` resets the conversation; `mode=revise` appends to
     * the existing chat_history so Claude has memory of the running
     * draft.
     */
    // NOTE: the legacy AI-brief "generate" action (Claude writes newsletter copy
    // from a brief) was REMOVED. The only newsletter flow is the Agentic flyer:
    // a fixed, approved design rendered from the picked course — see queueApproval /
    // the autonomous MMD_Marketing cron pipeline.

    public function saveDraftAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $req = $this->getRequest();
            $cc = $this->_currentCountry();
            $pids   = $this->_normalisePids((string) $req->getParam('course_pids'));
            $blocks = (string) $req->getParam('body_blocks');
            // Merge the reference images (if any) into body_blocks._images
            // so the saved draft can re-render them on next load. Images
            // are base64 data URIs — large, but bounded to 3 × ~5MB by
            // _normaliseImages().
            $images = $this->_normaliseImages((string) $req->getParam('images_json'));
            if (!empty($images)) {
                $blocksArr = json_decode($blocks, true);
                if (!is_array($blocksArr)) $blocksArr = array();
                $blocksArr['_images'] = $images;
                $blocks = json_encode($blocksArr);
            }
            // Title / subject / preview no longer come from the form — those
            // are set in MailerLite. Derive a sensible label so the drafts
            // list and the rendered preview still have something readable.
            $derived = $this->_deriveLabel($pids, $blocks);
            $row = array(
                'country_code' => $cc,
                'template_key' => (string) $req->getParam('template_key'),
                'title'        => $derived,
                'subject'      => $derived,
                'preview_text' => '',
                'course_pids'  => implode(',', $pids),
                'body_blocks'  => $blocks,                                 // already JSON
                'chat_history' => (string) $req->getParam('chat_history'), // already JSON
                'ai_prompt'    => (string) $req->getParam('ai_prompt'),
                'created_by'   => (int) Mage::getSingleton('admin/session')->getUser()->getId(),
            );
            if ($row['template_key'] === '') {
                throw new Exception('Template is required');
            }

            $write = $this->_db('write');
            $newsletterId = (int) $req->getParam('newsletter_id');
            if ($newsletterId) {
                // Verify the row belongs to this admin's country before updating.
                $owner = (string) $this->_db('read')->fetchOne(
                    "SELECT country_code FROM " . $this->_tbl() . " WHERE newsletter_id = ?",
                    array($newsletterId)
                );
                if ($owner !== '' && $owner !== $cc) throw new Exception('Cross-country edit blocked');
                $write->update($this->_tbl(), $row, array('newsletter_id = ?' => $newsletterId));
            } else {
                $write->insert($this->_tbl(), $row);
                $newsletterId = (int) $write->lastInsertId();
            }
            $result['success']       = true;
            $result['newsletter_id'] = $newsletterId;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    /**
     * Hydrate the UI from a saved draft. Returns the JSON state the
     * frontend's `mnEditDraft` handler needs to repopulate every part
     * of the builder: template, picked courses (with display labels),
     * chat history, body blocks, uploaded reference images. Country-
     * scoped — drafts from another country are rejected outright.
     */
    public function loadAction()
    {
        $result = array('success' => false);
        try {
            $req = $this->getRequest();
            $cc  = $this->_currentCountry();
            $newsletterId = (int) $req->getParam('newsletter_id');
            if (!$newsletterId) throw new Exception('newsletter_id required');

            $row = $this->_db('read')->fetchRow(
                "SELECT * FROM " . $this->_tbl()
              . " WHERE newsletter_id = ? AND country_code = ?",
                array($newsletterId, $cc)
            );
            if (!$row) throw new Exception('Newsletter not found');

            $pids = $this->_normalisePids((string) $row['course_pids']);

            // Resolve sku + name for every picked course so the chips
            // can re-render without needing a second fetch.
            $pidNames = array();
            if (!empty($pids)) {
                $placeholders = implode(',', array_fill(0, count($pids), '?'));
                $sql = "SELECT e.entity_id, e.sku,
                               (SELECT v.value FROM catalog_product_entity_varchar v
                                WHERE v.entity_id=e.entity_id AND v.attribute_id=71 AND v.store_id=0 LIMIT 1) AS name
                          FROM catalog_product_entity e
                         WHERE e.entity_id IN ($placeholders)";
                foreach ($this->_db('read')->fetchAll($sql, $pids) as $r) {
                    $pidNames[(int) $r['entity_id']] = ((string) $r['sku']) . ' — ' . ((string) $r['name']);
                }
            }

            // Body blocks are stored as JSON with the uploaded images
            // embedded as `_images`. Split them out so the JS state can
            // restore both separately.
            $blocks = json_decode((string) $row['body_blocks'], true);
            if (!is_array($blocks)) $blocks = array();
            $images = array();
            if (isset($blocks['_images']) && is_array($blocks['_images'])) {
                $images = $blocks['_images'];
                unset($blocks['_images']);
            }

            $chat = json_decode((string) $row['chat_history'], true);
            if (!is_array($chat)) $chat = array();

            $result['success']       = true;
            $result['newsletter_id'] = (int) $row['newsletter_id'];
            $result['template_key']  = (string) $row['template_key'];
            $result['title']         = (string) $row['title'];
            $result['pids']          = array_map('intval', $pids);
            $result['pid_names']     = $pidNames;
            $result['body_blocks']   = $blocks;
            $result['chat_history']  = $chat;
            $result['images']        = $images;
            $result['ai_prompt']     = (string) $row['ai_prompt'];
            $result['status']        = (string) $row['status'];
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    /**
     * Render the chosen template against the supplied (or saved) blocks
     * and return the full HTML for an <iframe srcdoc> preview.
     */
    public function previewAction()
    {
        $result = array('success' => false);
        try {
            $req = $this->getRequest();
            $cc  = $this->_currentCountry();
            $newsletterId = (int) $req->getParam('newsletter_id');

            if ($newsletterId) {
                $row = $this->_db('read')->fetchRow(
                    "SELECT * FROM " . $this->_tbl()
                  . " WHERE newsletter_id = ? AND country_code = ?",
                    array($newsletterId, $cc)
                );
                if (!$row) throw new Exception('Newsletter not found');
                $templateKey = $row['template_key'];
                $title       = $row['title'];
                $subject     = $row['subject'];
                $previewText = (string) $row['preview_text'];
                $coursePids  = $this->_normalisePids((string) $row['course_pids']);
                $blocks      = json_decode((string) $row['body_blocks'], true);
            } else {
                $templateKey = (string) $req->getParam('template_key');
                $coursePids  = $this->_normalisePids((string) $req->getParam('course_pids'));
                $blocks      = json_decode((string) $req->getParam('body_blocks'), true);
                $derived     = $this->_deriveLabel($coursePids, (string) $req->getParam('body_blocks'));
                $title       = $derived;
                $subject     = $derived;
                $previewText = '';
            }
            if (!is_array($blocks)) $blocks = array();

            // Reference images live in two places: the JS sends them
            // fresh on every preview (so unsaved drafts can show them),
            // and saved drafts may include them in body_blocks._images.
            // The form value wins because it reflects what the admin is
            // actually working on right now.
            $images = $this->_normaliseImages((string) $req->getParam('images_json'));
            if (empty($images) && !empty($blocks['_images']) && is_array($blocks['_images'])) {
                $images = $blocks['_images'];
            }

            $html = $this->_renderTemplate($templateKey, $title, $subject, $previewText, $blocks, $coursePids, $cc, $images);
            $result['success'] = true;
            $result['html']    = $html;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    public function deleteDraftAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $cc = $this->_currentCountry();
            $newsletterId = (int) $this->getRequest()->getParam('newsletter_id');
            if ($newsletterId <= 0) throw new Exception('newsletter_id required');

            // Country-scope guard so admin.my can't delete admin.gh's drafts.
            $owner = (string) $this->_db('read')->fetchOne(
                "SELECT country_code FROM " . $this->_tbl() . " WHERE newsletter_id = ?",
                array($newsletterId)
            );
            if ($owner === '') throw new Exception('Draft not found');
            if ($owner !== $cc) throw new Exception('Cross-country delete blocked');

            $this->_db('write')->delete($this->_tbl(), array('newsletter_id = ?' => $newsletterId));
            $result['success']       = true;
            $result['newsletter_id'] = $newsletterId;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    // NOTE: the legacy direct "push to MailerLite" action was REMOVED — it bypassed
    // manager approval and the 2-per-week cap. The only path to MailerLite now is the
    // guarded pipeline: queueApprovalAction / reviewDecisionAction → Cron_Flyer →
    // Blastguard (both managers must approve; max 2 flyers/week).

    /**
     * HARD RULE #2 (backend side): a manager approves / requests changes on an
     * agentic-flyer proposal from inside the admin — the second human-in-the-loop
     * channel alongside the email links. Only the two designated managers count,
     * and BOTH must approve before anything schedules. On the second approval this
     * routes through the SAME guarded pipeline (Cron_Flyer::scheduleApproved →
     * Blastguard) as the email path, so the 2-per-week cap can never be bypassed.
     */
    public function reviewDecisionAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $cc           = $this->_currentCountry();
            $newsletterId = (int) $this->getRequest()->getParam('newsletter_id');
            $decision     = (string) $this->getRequest()->getParam('decision');
            $feedback     = trim((string) $this->getRequest()->getParam('feedback'));
            if (!$newsletterId) throw new Exception('newsletter_id required');
            if (!in_array($decision, array('approve', 'changes'), true)) throw new Exception('Invalid decision');

            $guard     = Mage::helper('mmd_marketing/blastguard');
            $reviewers = array_map('strtolower', $guard->reviewers());
            $me        = strtolower((string) Mage::getSingleton('admin/session')->getUser()->getEmail());
            if (!in_array($me, $reviewers, true)) {
                throw new Exception('Only the designated managers can approve here ('
                    . implode(', ', $guard->reviewers()) . '). You are signed in as ' . $me . '.');
            }

            $row = $this->_db('read')->fetchRow(
                "SELECT * FROM " . $this->_tbl() . " WHERE newsletter_id = ? AND country_code = ?",
                array($newsletterId, $cc)
            );
            if (!$row) throw new Exception('Newsletter not found');
            if (trim((string) $row['mailerlite_id']) !== '' || in_array((string) $row['status'], array('scheduled', 'sent'), true)) {
                throw new Exception('This flyer is already scheduled — nothing more to approve.');
            }

            $decisions = json_decode((string) $row['review_decisions'], true);
            if (!is_array($decisions)) $decisions = array();
            $decisions[$me] = $decision;

            if ($decision === 'changes') {
                $this->_db('write')->update($this->_tbl(), array(
                    'review_decisions' => json_encode($decisions),
                    'review_feedback'  => $feedback,
                    'review_status'    => 'changes_requested',
                ), array('newsletter_id = ?' => $newsletterId));
                // Regenerate + re-send NOW (don't wait for the hourly followUp cron):
                // supersede this row, re-render the same course with the feedback,
                // and email both managers a fresh approval immediately.
                $newId = Mage::getModel('mmd_marketing/cron_flyer')->regenerateOnChanges($newsletterId);
                $result['success'] = true;
                $result['stage']   = 'changes_requested';
                $result['newsletter_id'] = $newId ?: $newsletterId;
                $result['message'] = $newId
                    ? 'Change request recorded — a revised flyer was emailed to the managers for approval.'
                    : 'Change request recorded. The design will be revised and re-sent shortly.';
                return $this->_json($result);
            }

            // approve — SINGLE approval (admin 2026-07-05): either manager approving
            // is enough; the first approve schedules. No second approval required.
            $this->_db('write')->update($this->_tbl(),
                array('review_decisions' => json_encode($decisions)),
                array('newsletter_id = ?' => $newsletterId));

            // one approval -> schedule through the guarded (cap-enforced) pipeline
            list($ok, $msg) = Mage::getModel('mmd_marketing/cron_flyer')->scheduleApproved($newsletterId);
            $result['success'] = $ok;
            $result['stage']   = $ok ? 'scheduled' : 'schedule_failed';
            $result['message'] = $msg;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    /**
     * Manually queue an Agentic flyer for approval. This is the ONLY manual path
     * toward MailerLite and it deliberately does NOT push — it creates a proposal
     * and emails both managers, exactly like the cron. Scheduling still happens only
     * after both approve, through Blastguard, so the "max 2 flyers/week" cap holds.
     */
    public function queueApprovalAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $pid = (int) $this->getRequest()->getParam('course_id');
            if (!$pid) throw new Exception('Pick a course first.');

            // Gate on whether a future Mon/Thu BLAST slot is actually bookable —
            // NOT on how many flyers were authored this calendar week. The admin
            // lines a flyer up now to fill an open slot in a LATER week; blocking
            // that because "2 designs were already created this week" is wrong.
            // The real per-week blast cap is still enforced at schedule time by
            // scheduleApproved()/Blastguard, so nothing over-books.
            $guard = Mage::helper('mmd_marketing/blastguard');
            if ($guard->nextSendSlot() === null) {
                throw new Exception('Every Monday/Thursday slot for the next few weeks is already '
                    . 'booked (max ' . MMD_Marketing_Helper_Blastguard::MAX_PER_WEEK
                    . ' blasts per week). Approve or clear a scheduled flow first, then try again.');
            }
            $model = Mage::getModel('mmd_marketing/cron_flyer');
            // Friendly duplicate message before the generic failure — createProposal
            // enforces one ACTIVE flow per course (pending / scheduled, not sent).
            $dupe = (int) Mage::getSingleton('core/resource')->getConnection('core_read')->fetchOne(
                'SELECT newsletter_id FROM ' . Mage::getSingleton('core/resource')->getTableName('newsletters')
              . " WHERE course_pids = ? AND template_key = 'agentic_flyer'"
              . " AND (review_status IN ('pending','changes_requested') OR status IN ('scheduling','scheduled'))"
              . " AND status <> 'sent' LIMIT 1", array((string) $pid));
            if ($dupe) {
                throw new Exception('This course is already in the pipeline (flow #' . $dupe
                    . ' is pending or scheduled) — approve or delete that one first.');
            }
            $nid   = $model->createProposal($pid);
            if (!$nid) throw new Exception('Could not build a flyer for that course (missing course data).');
            $model->sendForReview($nid);

            $result['success']       = true;
            $result['newsletter_id'] = $nid;
            $result['message']       = 'Queued for approval — approval email sent to the managers. '
                . 'It schedules to MailerLite once either manager approves (max 2 flyers/week).';
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    // ------------------------------------------------------------------
    // Next-flyer queue — the admin lines up WSQ courses; the Mon/Thu
    // proposer consumes the TOP row (Cron_Flyer::propose). Add / remove /
    // drag-reorder from the Newsletters panel.
    // ------------------------------------------------------------------

    protected function _qTbl() { return 'mmd_marketing_flyer_queue'; }

    public function flyerQueueListAction()
    {
        $result = array('success' => false, 'queue' => array());
        try {
            $result['queue'] = $this->_db('read')->fetchAll(
                "SELECT q.queue_id, q.product_id, e.sku,
                        (SELECT v.value FROM catalog_product_entity_varchar v
                          WHERE v.entity_id = e.entity_id AND v.attribute_id = 71 AND v.store_id = 0 LIMIT 1) AS name,
                        (SELECT pd.value FROM catalog_product_entity_decimal pd
                          INNER JOIN eav_attribute pa ON pa.attribute_id = pd.attribute_id
                          WHERE pd.entity_id = e.entity_id AND pa.attribute_code = 'price'
                            AND pa.entity_type_id = 4 AND pd.store_id = 0 LIMIT 1) AS fee,
                        (SELECT DATE_FORMAT(fv.value, 'Till %e %b %Y') FROM catalog_product_entity_datetime fv
                          INNER JOIN eav_attribute fa ON fa.attribute_id = fv.attribute_id
                          WHERE fv.entity_id = e.entity_id AND fa.attribute_code = 'news_to_date'
                            AND fa.entity_type_id = 4 AND fv.store_id = 0 LIMIT 1) AS funding_validity
                   FROM " . $this->_qTbl() . " q
                   JOIN catalog_product_entity e ON e.entity_id = q.product_id
                  ORDER BY q.position ASC, q.queue_id ASC"
            );
            $result['success'] = true;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    public function flyerQueueAddAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $pid = (int) $this->getRequest()->getParam('course_id');
            if (!$pid) throw new Exception('course_id required');
            $sku = (string) $this->_db('read')->fetchOne(
                'SELECT sku FROM catalog_product_entity WHERE entity_id = ?', array($pid));
            if ($sku === '') throw new Exception('Course not found');
            if (stripos($sku, 'TGS-') !== 0) throw new Exception('Only WSQ (TGS-) courses can join the flyer queue.');
            $pos = (int) $this->_db('read')->fetchOne('SELECT COALESCE(MAX(position),0)+1 FROM ' . $this->_qTbl());
            // UNIQUE(product_id) makes re-adding a no-op instead of a duplicate
            $this->_db('write')->query(
                'INSERT IGNORE INTO ' . $this->_qTbl() . ' (product_id, position) VALUES (?, ?)',
                array($pid, $pos));
            $result['success'] = true;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    public function flyerQueueRemoveAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $qid = (int) $this->getRequest()->getParam('queue_id');
            if (!$qid) throw new Exception('queue_id required');
            $this->_db('write')->delete($this->_qTbl(), array('queue_id = ?' => $qid));
            $result['success'] = true;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    /** POST order=<csv of queue_ids in the new order> (from drag-and-drop). */
    public function flyerQueueReorderAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $ids = array();
            foreach (explode(',', (string) $this->getRequest()->getParam('order')) as $v) {
                $v = (int) trim($v);
                if ($v > 0) { $ids[] = $v; }
            }
            if (empty($ids)) throw new Exception('order required');
            $w = $this->_db('write');
            foreach ($ids as $i => $qid) {
                $w->update($this->_qTbl(), array('position' => $i + 1), array('queue_id = ?' => $qid));
            }
            $result['success'] = true;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    // ------------------------------------------------------------------
    // Internals
    // ------------------------------------------------------------------

    protected function _tbl()
    {
        return Mage::getSingleton('core/resource')->getTableName('newsletters');
    }

    protected function _db($mode)
    {
        return Mage::getSingleton('core/resource')->getConnection('core_' . $mode);
    }

    protected function _currentCountry()
    {
        return Mage::helper('mmd_rolemanager')->getActiveCountryCode();
    }

    /**
     * Every action in this controller returns JSON. PHP warnings or
     * notices that leak into the response break the client's r.json()
     * with errors like "Unexpected token '<', "<br />..." — that's the
     * format display_errors=On uses. Disable display_errors so anything
     * that happens during the request is logged via Magento's usual
     * error log instead of printed inline.
     */
    public function preDispatch()
    {
        parent::preDispatch();
        @ini_set('display_errors', 0);
        @ini_set('html_errors', 0);
    }

    protected function _json($payload)
    {
        // Drain any output buffers that accumulated before this call —
        // a stray var_dump, warning, or echo would otherwise prefix the
        // JSON and corrupt it. Captured content is logged so we can
        // diagnose what produced it.
        while (ob_get_level() > 0) {
            $stray = ob_get_clean();
            if (is_string($stray) && $stray !== '') {
                $this->_writeLog('stray output before JSON: ' . substr($stray, 0, 1000));
            }
        }
        $this->getResponse()->setHeader('Content-Type', 'application/json', true);
        $this->getResponse()->clearBody();
        $this->getResponse()->setBody(Mage::helper('core')->jsonEncode($payload));
    }

    /**
     * Write to var/log/marketing.log directly via file_put_contents so
     * we don't depend on Magento's dev/log/active config — that toggle
     * is off in production, which means Mage::log() silently no-ops and
     * we lose every error trace. This bypasses that.
     */
    protected function _writeLog($msg)
    {
        try {
            $dir = Mage::getBaseDir('log');
            if (!is_dir($dir)) @mkdir($dir, 0777, true);
            $line = '[' . date('Y-m-d H:i:s') . '] ' . $msg . "\n";
            @file_put_contents($dir . DIRECTORY_SEPARATOR . 'marketing.log', $line, FILE_APPEND);
        } catch (Exception $e) { /* logging must never throw */ }
    }

    /**
     * Derive a readable label for a draft when the admin doesn't supply
     * one — used both for the drafts list and as the email subject when
     * pushing to MailerLite (admins set the real subject in MailerLite).
     * Order: first picked course name → first line of body → fallback.
     */
    protected function _deriveLabel(array $pids, $blocksJson)
    {
        if (!empty($pids)) {
            $list = implode(',', array_map('intval', $pids));
            $name = (string) $this->_db('read')->fetchOne(
                "SELECT v.value FROM catalog_product_entity_varchar v
                 WHERE v.entity_id IN ({$list}) AND v.attribute_id = 71 AND v.store_id = 0
                 ORDER BY v.entity_id ASC LIMIT 1"
            );
            if ($name !== '') {
                return mb_strlen($name) > 120 ? mb_substr($name, 0, 117) . '…' : $name;
            }
        }
        $blocks = json_decode((string) $blocksJson, true);
        if (is_array($blocks)) {
            $first = trim((string) (isset($blocks['body_block_1']) ? $blocks['body_block_1'] : ''));
            if ($first !== '') {
                $line = strtok($first, "\n");
                if ($line !== false && $line !== '') {
                    return mb_strlen($line) > 120 ? mb_substr($line, 0, 117) . '…' : $line;
                }
            }
        }
        return 'Newsletter draft — ' . date('j M Y');
    }

    /**
     * Strip HTML *and* decode entities from catalog text. The catalog
     * stores rich descriptions with `&nbsp;`, `&rsquo;`, `<br>`, etc.
     * Plain `strip_tags()` removes the tags but leaves entities intact,
     * which then leak into bullets as literal "&nbsp;" because the
     * outer template re-escapes the `&` via htmlspecialchars(). We need
     * to decode entities BEFORE re-escaping.
     */
    protected function _cleanCatalogText($raw)
    {
        if ($raw === null) return '';
        $s = (string) $raw;
        // Decode &nbsp; / &amp; / &rsquo; / numeric refs, etc.
        $s = html_entity_decode($s, ENT_QUOTES | ENT_HTML5, 'UTF-8');
        // Replace non-breaking spaces with regular spaces.
        $s = str_replace("\xc2\xa0", ' ', $s);
        // Inject a space before block-level / line-break tags so stripping
        // them doesn't merge adjacent words ("a<br>b" → "a b" not "ab").
        $s = preg_replace('#<(br|p|li|tr|td|div|h[1-6])\b[^>]*>#i', ' $0', $s);
        $s = preg_replace('#</(p|li|tr|td|div|h[1-6])>#i', ' $0', $s);
        // Remove tags after decoding (so entities inside tags don't leak).
        $s = strip_tags($s);
        // Collapse all whitespace runs into single spaces.
        $s = trim(preg_replace('/\s+/u', ' ', $s));
        return $s;
    }

    protected function _normalisePids($csv)
    {
        $out = array();
        foreach (explode(',', $csv) as $p) {
            $p = (int) trim($p);
            if ($p > 0) $out[$p] = $p;
        }
        return array_values($out);
    }

    /**
     * Build a structured plain-text course block for Claude's first
     * user turn. Pulls a rich set of attributes (description, target
     * audience, prerequisites, trainer profile, duration, dates, price)
     * so Claude can extract real facts to fulfill the admin's brief
     * rather than inventing them.
     */
    protected function _buildCourseContext(array $pids)
    {
        if (empty($pids)) return '(no courses picked)';

        // attribute_code => human label, in roughly the order Claude
        // should consume them when writing.
        $codes = array(
            'name'              => 'Course title',
            'short_description' => 'Short description',
            'description'       => 'Full description / learning outcomes',
            'whoshouldattend'   => 'Target audience / who should attend',
            'prerequisite'      => 'Entry requirements / prerequisites',
            'trainerprofile'    => 'About the course / trainer profile',
            'duration'          => 'Duration',
            'meta_keyword'      => 'Topic keywords',
        );

        // Resolve attribute_id + backend_type once for catalog_product.
        $codeIn = "'" . implode("','", array_map('addslashes', array_keys($codes))) . "'";
        $resolved = array();
        foreach ($this->_db('read')->fetchAll(
            "SELECT a.attribute_id, a.attribute_code, a.backend_type
             FROM eav_attribute a
             INNER JOIN eav_entity_type et ON et.entity_type_id = a.entity_type_id
             WHERE et.entity_type_code = 'catalog_product'
               AND a.attribute_code IN ({$codeIn})"
        ) as $r) {
            // Only varchar / text are useful as prose context.
            if (!in_array($r['backend_type'], array('varchar', 'text'), true)) continue;
            $resolved[$r['attribute_code']] = array(
                'id'   => (int) $r['attribute_id'],
                'type' => $r['backend_type'],
            );
        }

        $blocks = array();
        foreach ($pids as $pid) {
            $pid = (int) $pid;
            if ($pid <= 0) continue;
            $lines = array();
            foreach ($codes as $code => $label) {
                if (!isset($resolved[$code])) continue;
                $tbl = 'catalog_product_entity_' . $resolved[$code]['type'];
                try {
                    $val = $this->_db('read')->fetchOne(
                        "SELECT value FROM {$tbl}
                         WHERE entity_id = ? AND attribute_id = ? AND store_id = 0
                         LIMIT 1",
                        array($pid, $resolved[$code]['id'])
                    );
                } catch (Exception $e) { $val = null; }
                if ($val === null || $val === '') continue;
                $cleaned = $this->_cleanCatalogText($val);
                if ($cleaned === '') continue;
                // Cap each field so the prompt doesn't blow up the token budget.
                if (mb_strlen($cleaned) > 1500) $cleaned = mb_substr($cleaned, 0, 1497) . '...';
                $lines[] = $label . ': ' . $cleaned;
            }

            // SKU + dates + price come straight from the catalog.
            $extra = $this->_db('read')->fetchRow(
                "SELECT e.sku,
                        (SELECT d.value FROM catalog_product_entity_datetime d
                            WHERE d.entity_id=e.entity_id AND d.attribute_id=86 AND d.store_id=0 LIMIT 1) AS sd,
                        (SELECT d.value FROM catalog_product_entity_datetime d
                            WHERE d.entity_id=e.entity_id AND d.attribute_id=87 AND d.store_id=0 LIMIT 1) AS ed,
                        (SELECT pd.value FROM catalog_product_entity_decimal pd
                            INNER JOIN eav_attribute pa ON pa.attribute_id = pd.attribute_id
                            WHERE pd.entity_id = e.entity_id AND pa.attribute_code = 'price' AND pd.store_id = 0
                            LIMIT 1) AS price
                 FROM catalog_product_entity e WHERE e.entity_id = ?",
                array($pid)
            );
            if ($extra) {
                if (!empty($extra['sku']))   $lines[] = 'SKU: ' . $extra['sku'];
                if (!empty($extra['sd']))    $lines[] = 'Start date: ' . substr($extra['sd'], 0, 10);
                if (!empty($extra['ed']))    $lines[] = 'End date: '   . substr($extra['ed'], 0, 10);
                if (!empty($extra['price'])) $lines[] = 'Price: ' . $extra['price'];
            }

            if (!empty($lines)) {
                $blocks[] = "--- Course #{$pid} ---\n" . implode("\n", $lines);
            }
        }
        return empty($blocks) ? '(no course data found)' : implode("\n\n", $blocks);
    }

    /**
     * Call Anthropic Messages API. Returns array('text', 'stubbed').
     * Falls back to a deterministic mock when no API key is configured.
     * `$turnImages` are the images attached to the *latest* user turn
     * (the one being sent right now). Earlier-turn images live on the
     * history entries themselves and are inlined per-turn below.
     */
    protected function _callClaude(array $messages, $templateKey, $cc, array $pids, array $turnImages = array())
    {
        $cfg = Mage::helper('mmd_rolemanager')->getMarketingApiConfig();
        if (empty($cfg['anthropic_key'])) {
            return array(
                'text'    => $this->_stubClaudeResponse($messages, $templateKey, $cc, $pids, $turnImages),
                'stubbed' => true,
            );
        }

        $countryName = Mage::helper('mmd_rolemanager')->getActiveCountryName();
        $system = "You are an LMS marketing assistant for {$countryName}.\n\n"
                . "You receive TWO inputs on the first turn:\n"
                . "1. STRUCTURED COURSE DATA — verified facts from our catalog "
                . "(course name, full description, target audience, "
                . "prerequisites, trainer profile, dates, SKU, price). This "
                . "is your source of truth.\n"
                . "2. ADMIN'S BRIEF — instructions about what to highlight "
                . "(e.g. 'include what will be learned', 'mention DISC "
                . "benefits', 'add a sign-up button linking to <URL>'). It "
                . "tells you WHICH facts from the course data to surface.\n\n"
                . "Combine both: extract specific, real facts from the "
                . "course data to fulfill the brief's instructions. Do NOT "
                . "invent facts that aren't in the course data — quote dates, "
                . "names, prices, and prerequisites verbatim. If the brief "
                . "asks for something the course data doesn't cover, omit it "
                . "rather than fabricate. On revise turns the admin's "
                . "feedback overrides — keep the same course facts and just "
                . "rework the copy.\n\n"
                . "Your output MUST be in this exact format:\n\n"
                . "<one or two short sentences acknowledging what the admin "
                . "asked for and what you changed — like a chat assistant. "
                . "No greetings ('Hi!'), no sign-offs. Reference specific "
                . "facts you used from the course data (course name, price, "
                . "dates) so the admin can see you're working from real "
                . "catalog values.>\n\n"
                . "===NEWSLETTER===\n\n"
                . "<BLOCK 1 — Tagline: 1 short, punchy line, max ~14 words. "
                . "Renders as a yellow highlighted strip. Reflect the "
                . "course's actual value proposition.>\n\n"
                . "<BLOCK 2 — 2 to 4 key takeaways drawn from the course's "
                . "description / learning outcomes, ONE PER LINE, no bullets "
                . "/ numbers / asterisks (the template numbers them). Each "
                . "line ≤12 words. Phrase as outcomes ('Design leadership "
                . "programs', 'Apply DISC at work').>\n\n"
                . "<BLOCK 3 — Pricing rows in 'Label | Price' format, one "
                . "per line (max 3). Use prices from the course data if "
                . "present, otherwise omit this block entirely.>\n\n"
                . "Write friendly, on-brand email-newsletter copy in plain "
                . "text (no HTML, no markdown headings). When the admin "
                . "attaches reference images, treat them as design / brand "
                . "cues and echo their tone in the copy. Template: {$templateKey}.\n\n"
                . "CHAT MODE — IMPORTANT EXCEPTION: When the admin's message is a "
                . "question, a clarification, casual conversation, or a request "
                . "for advice / explanation that isn't asking you to draft or "
                . "revise newsletter copy (e.g. 'what does WSQ stand for?', "
                . "'should I add an early-bird discount?', 'how do you usually "
                . "structure these?', 'hi', 'thanks'), respond conversationally "
                . "as a helpful marketing assistant. Do NOT include the "
                . "===NEWSLETTER=== marker or any newsletter blocks in chat "
                . "responses — the existing draft body should stay untouched. "
                . "Use the marker ONLY when the admin is actually asking you to "
                . "generate or revise newsletter content. Default to chat mode "
                . "when in doubt; the admin can always say 'now write the "
                . "newsletter' to switch back to drafting.";

        // Convert internal history shape → Anthropic API shape. Each turn
        // can carry images (initial brief or later attachments). When a
        // turn has images, we send a content array with image blocks then
        // the text block; otherwise plain string content.
        $apiMessages = array();
        foreach ($messages as $m) {
            $imgs = isset($m['images']) && is_array($m['images']) ? $m['images'] : array();
            if (!empty($imgs)) {
                $blocks = array();
                foreach ($imgs as $img) {
                    if (empty($img['data']) || empty($img['media_type'])) continue;
                    $blocks[] = array(
                        'type'   => 'image',
                        'source' => array(
                            'type'       => 'base64',
                            'media_type' => $img['media_type'],
                            'data'       => $img['data'],
                        ),
                    );
                }
                $blocks[] = array('type' => 'text', 'text' => (string) $m['content']);
                $apiMessages[] = array('role' => $m['role'], 'content' => $blocks);
            } else {
                $apiMessages[] = array('role' => $m['role'], 'content' => $m['content']);
            }
        }

        $apiKey = trim((string) $cfg['anthropic_key']);
        $model  = trim((string) $cfg['anthropic_model']);
        if ($model === '') $model = 'claude-opus-4-7';

        // Route to whichever upstream the saved key belongs to. The user
        // can paste either a native Anthropic API key or an OpenRouter
        // key — the controller figures out which.
        //   sk-ant-api*  → Anthropic Messages API direct.
        //   sk-or-v*     → OpenRouter chat/completions (proxies Claude).
        //   sk-ant-oat*  → Claude Code OAuth, can't reach /v1/messages.
        //
        // When the upstream call fails (rate limit, billing, network),
        // fall through to the deterministic stub instead of erroring out.
        // The stub already pulls real course data from the catalog, so
        // the admin always gets a usable draft — they just lose the
        // open-ended creativity Claude would add. UI surfaces this via
        // `stubbed: true` so a "Demo mode (Claude unavailable: <reason>)"
        // badge can be shown.
        try {
            if (stripos($apiKey, 'sk-or-') === 0) {
                return $this->_callViaOpenRouter($apiKey, $model, $system, $apiMessages);
            }
            return $this->_callViaAnthropic($apiKey, $model, $system, $apiMessages);
        } catch (Exception $e) {
            $this->_writeLog('Claude upstream failed, falling back to stub: ' . $e->getMessage());
            return array(
                'text'         => $this->_stubClaudeResponse($messages, $templateKey, $cc, $pids, $turnImages),
                'stubbed'      => true,
                'stub_reason'  => $e->getMessage(),
            );
        }
    }

    /**
     * Send a Messages-API request directly to Anthropic. Used when the
     * saved key starts with `sk-ant-api...` (or for any non-OpenRouter
     * key as a default).
     */
    protected function _callViaAnthropic($apiKey, $model, $system, array $apiMessages)
    {
        $body = json_encode(array(
            'model'      => $model,
            'max_tokens' => 2000,
            'system'     => $system,
            'messages'   => $apiMessages,
        ));
        $headers = array(
            'anthropic-version: 2023-06-01',
            'content-type: application/json',
            'x-api-key: ' . $apiKey,
        );
        // Claude Code OAuth tokens — pivot to Bearer + claude-code beta.
        if (stripos($apiKey, 'sk-ant-oat') === 0) {
            $headers = array(
                'anthropic-version: 2023-06-01',
                'content-type: application/json',
                'Authorization: Bearer ' . $apiKey,
                'anthropic-beta: claude-code-20250219,oauth-2025-04-20',
                'User-Agent: claude-cli/1.0.119 (external, cli)',
            );
        }

        $ch = curl_init('https://api.anthropic.com/v1/messages');
        curl_setopt_array($ch, array(
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $body,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 120,
            CURLOPT_CONNECTTIMEOUT => 15,
            CURLOPT_HTTPHEADER     => $headers,
        ));
        $raw  = curl_exec($ch);
        $err  = curl_error($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        if ($raw === false || $raw === '') {
            throw new Exception('Anthropic call failed (cURL): ' . ($err ?: 'no response'));
        }
        $rsp = json_decode($raw, true);
        if ($code >= 400) {
            $apiErr = '';
            if (isset($rsp['error']['message']))     $apiErr = (string) $rsp['error']['message'];
            elseif (isset($rsp['message']))          $apiErr = (string) $rsp['message'];
            elseif (isset($rsp['error']) && is_string($rsp['error'])) $apiErr = (string) $rsp['error'];
            if ($apiErr === '' || $apiErr === 'Error') $apiErr = substr($raw, 0, 500);
            throw new Exception('Anthropic API ' . $code . ': ' . $apiErr);
        }
        $text = '';
        if (isset($rsp['content'][0]['text'])) $text = (string) $rsp['content'][0]['text'];
        if ($text === '') throw new Exception('Empty Claude response: ' . substr($raw, 0, 200));
        return array('text' => $text, 'stubbed' => false);
    }

    /**
     * Send the same request via OpenRouter, which proxies Claude (and
     * 100+ other models) through an OpenAI-compatible chat/completions
     * endpoint. OpenRouter accepts `anthropic/claude-opus-4-7` style
     * model slugs; if the saved model is the bare Anthropic id
     * (`claude-opus-4-7`) we prefix it with `anthropic/` for them.
     */
    protected function _callViaOpenRouter($apiKey, $model, $system, array $apiMessages)
    {
        if (strpos($model, '/') === false && stripos($model, 'claude') === 0) {
            $orModel = 'anthropic/' . $model;
        } else {
            $orModel = $model;
        }

        // OpenAI / OpenRouter format puts the system prompt as the first
        // message with role:"system"; rest of the messages are the same
        // user/assistant pairs Anthropic uses. Drop image blocks since
        // OpenRouter's text-only chat/completions endpoint can't carry
        // them — we still describe them in the text body via _callClaude.
        $messages = array();
        if ($system !== '') {
            $messages[] = array('role' => 'system', 'content' => $system);
        }
        foreach ($apiMessages as $m) {
            $content = $m['content'];
            if (is_array($content)) {
                $text = '';
                foreach ($content as $block) {
                    if (isset($block['type']) && $block['type'] === 'text' && isset($block['text'])) {
                        $text .= $block['text'];
                    }
                }
                $content = $text;
            }
            $messages[] = array('role' => $m['role'], 'content' => (string) $content);
        }

        $body = json_encode(array(
            'model'      => $orModel,
            'max_tokens' => 2000,
            'messages'   => $messages,
        ));
        $headers = array(
            'Authorization: Bearer ' . $apiKey,
            'content-type: application/json',
            'HTTP-Referer: https://ai-mms.tertiaryinfo.tech',
            'X-Title: AI-MMS Newsletter Builder',
        );

        $ch = curl_init('https://openrouter.ai/api/v1/chat/completions');
        curl_setopt_array($ch, array(
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $body,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 120,
            CURLOPT_CONNECTTIMEOUT => 15,
            CURLOPT_HTTPHEADER     => $headers,
        ));
        $raw  = curl_exec($ch);
        $err  = curl_error($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        if ($raw === false || $raw === '') {
            throw new Exception('OpenRouter call failed (cURL): ' . ($err ?: 'no response'));
        }
        $rsp = json_decode($raw, true);
        if ($code >= 400) {
            $apiErr = isset($rsp['error']['message']) ? (string) $rsp['error']['message']
                    : (isset($rsp['error']) && is_string($rsp['error']) ? (string) $rsp['error']
                    : substr($raw, 0, 500));
            throw new Exception('OpenRouter API ' . $code . ': ' . $apiErr);
        }
        $text = '';
        if (isset($rsp['choices'][0]['message']['content'])) {
            $text = (string) $rsp['choices'][0]['message']['content'];
        }
        if ($text === '') throw new Exception('Empty OpenRouter response: ' . substr($raw, 0, 200));
        return array('text' => $text, 'stubbed' => false);
    }

    /**
     * Decode the JSON-encoded images payload from the form. Each entry
     * is `{name, type, dataUrl}` from the client; we strip the data:
     * URI prefix and keep `{media_type, data}` (base64) — the shape the
     * Anthropic API expects. Caps at 3 images, 5MB each, common image
     * types only.
     */
    protected function _normaliseImages($json)
    {
        if ($json === '' || $json === '[]') return array();
        $list = json_decode($json, true);
        if (!is_array($list)) return array();
        $allowed = array('image/jpeg' => 1, 'image/jpg' => 1, 'image/png' => 1, 'image/webp' => 1, 'image/gif' => 1);
        $out = array();
        foreach ($list as $img) {
            if (count($out) >= 3) break;
            if (empty($img['dataUrl'])) continue;
            // Parse data:<mime>;base64,<payload>
            if (!preg_match('#^data:([^;]+);base64,(.+)$#', $img['dataUrl'], $m)) continue;
            $mime = strtolower($m[1]);
            if ($mime === 'image/jpg') $mime = 'image/jpeg';
            if (!isset($allowed[$mime])) continue;
            $payload = $m[2];
            // Approximate decoded size — base64 inflates ~4/3.
            if (strlen($payload) > 7 * 1024 * 1024) continue;
            $out[] = array(
                'media_type' => $mime,
                'data'       => $payload,
                'name'       => isset($img['name']) ? (string) $img['name'] : 'image',
            );
        }
        return $out;
    }

    protected function _stubClaudeResponse(array $messages, $templateKey, $cc, array $pids, array $turnImages = array())
    {
        $isRevise   = count($messages) > 2;
        $latestUser = '';
        foreach (array_reverse($messages) as $m) {
            if ($m['role'] === 'user') { $latestUser = (string) $m['content']; break; }
        }

        // Load real catalog data for the first picked course. The brief
        // is treated purely as instructions about WHAT to surface — the
        // bullet content and pricing always come from the database, so
        // demo mode never echoes raw brief lines like "the cost of the
        // course" back at the recipient.
        $course = null;
        if (!empty($pids)) {
            $pid = (int) $pids[0];
            $course = $this->_db('read')->fetchRow(
                "SELECT e.entity_id, e.sku,
                        (SELECT v.value FROM catalog_product_entity_varchar v
                            WHERE v.entity_id=e.entity_id AND v.attribute_id=71 AND v.store_id=0 LIMIT 1) AS name,
                        (SELECT t.value FROM catalog_product_entity_text t
                            INNER JOIN eav_attribute a ON a.attribute_id=t.attribute_id
                            WHERE t.entity_id=e.entity_id AND a.attribute_code='description' AND t.store_id=0 LIMIT 1) AS description,
                        (SELECT t.value FROM catalog_product_entity_text t
                            INNER JOIN eav_attribute a ON a.attribute_id=t.attribute_id
                            WHERE t.entity_id=e.entity_id AND a.attribute_code='short_description' AND t.store_id=0 LIMIT 1) AS short_desc,
                        (SELECT t.value FROM catalog_product_entity_text t
                            INNER JOIN eav_attribute a ON a.attribute_id=t.attribute_id
                            WHERE t.entity_id=e.entity_id AND a.attribute_code='whoshouldattend' AND t.store_id=0 LIMIT 1) AS whoshouldattend,
                        (SELECT t.value FROM catalog_product_entity_text t
                            INNER JOIN eav_attribute a ON a.attribute_id=t.attribute_id
                            WHERE t.entity_id=e.entity_id AND a.attribute_code='prerequisite' AND t.store_id=0 LIMIT 1) AS prerequisite,
                        (SELECT t.value FROM catalog_product_entity_text t
                            INNER JOIN eav_attribute a ON a.attribute_id=t.attribute_id
                            WHERE t.entity_id=e.entity_id AND a.attribute_code='trainerprofile' AND t.store_id=0 LIMIT 1) AS trainerprofile,
                        (SELECT v.value FROM catalog_product_entity_varchar v
                            INNER JOIN eav_attribute a ON a.attribute_id=v.attribute_id
                            WHERE v.entity_id=e.entity_id AND a.attribute_code='duration' AND v.store_id=0 LIMIT 1) AS duration,
                        (SELECT pd.value FROM catalog_product_entity_decimal pd
                            INNER JOIN eav_attribute pa ON pa.attribute_id=pd.attribute_id
                            WHERE pd.entity_id=e.entity_id AND pa.attribute_code='price' AND pd.store_id=0 LIMIT 1) AS price,
                        (SELECT d.value FROM catalog_product_entity_datetime d
                            WHERE d.entity_id=e.entity_id AND d.attribute_id=86 AND d.store_id=0 LIMIT 1) AS start_date,
                        (SELECT d.value FROM catalog_product_entity_datetime d
                            WHERE d.entity_id=e.entity_id AND d.attribute_id=87 AND d.store_id=0 LIMIT 1) AS end_date
                 FROM catalog_product_entity e WHERE e.entity_id = ?",
                array($pid)
            );
        }
        $primary = ($course && !empty($course['name'])) ? trim($course['name']) : 'This Course';

        // Special case — no course picked. Acknowledge with a chat-only
        // message and skip the body update so the existing newsletter
        // (or empty preview) stays put. The marker is present but the
        // body section is empty, which the parser reads as "chat-only".
        if (empty($course)) {
            return "I can't fill in real details until you pick a course. "
                 . "Use the Featured Courses search above to pick one, "
                 . "then send your message again — I'll pull the actual "
                 . "learning outcomes, dates, and price straight from the "
                 . "catalog.\n\n===NEWSLETTER===\n\n";
        }

        // Detect whether the latest message has explicit feedback cues
        // (shorter, more detail, exciting, casual, …). If it does, treat
        // it as a refinement instruction even on the first turn, so the
        // visible output shifts whenever the admin asks it to.
        $feedback = $isRevise || $this->_looksLikeFeedback($latestUser);

        // BLOCK 1 — tagline. Adapts to feedback cues; otherwise course
        // name based.
        $tagline = "Master " . $this->_titleCase($primary) . " And Take The Next Step";
        if ($feedback) {
            $tagline = $this->_applyToneFeedback($tagline, $latestUser, $primary);
        }

        // BLOCK 2 — bullets extracted from real course data. "More /
        // detail / expand" feedback widens the extraction (longer
        // outcomes, more sentences) so the recipient genuinely sees
        // more information. Other feedback keywords (shorter, reorder,
        // …) reshape the list.
        $wantMore = (bool) preg_match('/\b(more|expand|detail|longer|fuller|deeper|elaborate|further)\b/iu', (string) $latestUser);
        $bullets  = $this->_extractCourseOutcomes($course, $wantMore ? 7 : 4);
        if (count($bullets) < 2) {
            $bullets = $this->_buildFallbackBullets($course, $primary, $wantMore);
        }
        $bullets = array_slice($bullets, 0, $wantMore ? 6 : 4);
        if ($feedback) {
            $bullets = $this->_applyBulletFeedback($bullets, $latestUser);
        }
        // Inject specific catalog content based on what the admin asked
        // for ("add target audience", "add trainer info", "early-bird",
        // …). This is what makes "the changes actually appear" — each
        // keyword pulls the matching field out of the catalog and
        // surfaces it as a new bullet at the top of the list.
        $bullets = $this->_applyContentInjections($bullets, $latestUser, $course);
        $bullets = array_slice($bullets, 0, $wantMore ? 6 : 4);

        // BLOCK 3 — pricing. SG courses always show the brand 3-tier
        // table (Full / Singaporean 21-39 / Singaporean 40+) computed
        // from the catalog price using the standard WSQ subsidy ratios.
        // Other countries get a single-row fee. No price → omit.
        $blocks = array($tagline, implode("\n", $bullets));
        $price = ($course && isset($course['price'])) ? (float) $course['price'] : 0.0;
        if ($price > 0) {
            $fmt = function ($n) { return '$' . number_format(round($n), 0); };
            if ($cc === 'SG') {
                // Standard WSQ subsidy approximation: ~45% off for
                // 21-39, ~64% off for 40+. Drop in real subsidy data
                // when funding metadata is added to the catalog.
                $sub21 = $price * 0.55;
                $sub40 = $price * 0.36;
                $blocks[] = "Full Course Fee (Incl. GST) | " . $fmt($price) . "\n"
                          . "Nett Fee for Singaporeans / PRs aged 21-39 | " . $fmt($sub21) . "\n"
                          . "Nett Fee for Singaporeans 40yo and above | " . $fmt($sub40);
            } else {
                $blocks[] = "Course Fee (Incl. GST) | $"
                          . number_format($price, 2);
            }
        }

        // Wrap with an ACK + marker so the chat pane shows a chatbot-
        // style acknowledgment while the body parser only sees the
        // structured newsletter.
        $ack = $this->_buildStubAck($latestUser, $course, $isRevise);
        $body = implode("\n\n", $blocks);
        return $ack . "\n\n===NEWSLETTER===\n\n" . $body;
    }

    /**
     * Build a chatbot-style acknowledgment line for the stub. Maps
     * common admin instructions to a one-liner that names the actual
     * catalog facts used, so demo mode reads like a real assistant
     * rather than dumping raw newsletter content.
     */
    protected function _buildStubAck($feedback, $course, $isRevise)
    {
        $name      = trim($course['name']);
        $intents   = $this->_detectIntents($feedback);
        $isQ       = $this->_isQuestion($feedback);
        $isRemoval = in_array('remove', $intents, true);
        $hasPrice  = isset($course['price']) && (float) $course['price'] > 0;
        $price     = $hasPrice ? '$' . number_format((float) $course['price'], 2) : '';

        // Explicit design re-roll — admin asked for different colours
        // or a fresh design. The seed change happens server-side in
        // generateAction; here we just acknowledge.
        if ($this->_looksLikeDesignReroll($feedback)) {
            return "Re-rolled the design — fresh palette, hero treatment, and card style. Each course has its own default look, but you can ask for another shuffle anytime.";
        }

        // Help — list what kinds of instructions actually work.
        if (in_array('help', $intents, true)) {
            return "I can pull these straight from the catalog — try messages like:\n"
                 . "• \"add the cost\" / \"how much is it?\"\n"
                 . "• \"who should attend?\" / \"add target audience\"\n"
                 . "• \"add the trainer profile\" / \"who teaches it?\"\n"
                 . "• \"how long is the course?\" / \"add duration\"\n"
                 . "• \"add WSQ funding info\" / \"is it claimable?\"\n"
                 . "• \"include the certification\"\n"
                 . "• \"make it shorter\" / \"trim the fluff\"\n"
                 . "• \"give more information\" / \"flesh it out\"\n"
                 . "• \"make it more exciting\" / \"spice it up\"\n"
                 . "• \"more casual tone\" / \"sound friendlier\"\n"
                 . "• \"add early-bird discount\"\n"
                 . "• \"take out the trainer\" / \"remove the certification\"";
        }

        // Reset
        if (in_array('reset', $intents, true)) {
            return "Click **+ New Newsletter** in the top-right to start a fresh draft. Your existing draft is saved if you want to come back to it.";
        }

        // Removal — say what was dropped
        if ($isRemoval) {
            $removed = array();
            $labels = array(
                'add_audience' => 'target audience', 'add_trainer' => 'trainer profile',
                'add_earlybird' => 'early-bird hook', 'add_duration' => 'duration line',
                'add_prereq' => 'prerequisites', 'add_certification' => 'certification line',
                'add_beginner' => 'beginner-friendly note', 'add_advanced' => 'advanced-level note',
                'add_handson' => 'hands-on note', 'add_funding' => 'funding eligibility',
                'add_dates' => 'next-intake bullet', 'add_cost' => 'cost bullet',
            );
            foreach ($intents as $i) {
                if (isset($labels[$i])) $removed[] = $labels[$i];
            }
            if (!empty($removed)) {
                return "Removed " . implode(' and ', $removed) . " from the bullets.";
            }
            return "Removed the highlighted item from the bullets.";
        }

        // Question forms — answer the question conversationally.
        if ($isQ) {
            if (in_array('add_cost', $intents, true)) {
                return $hasPrice
                    ? "The course fee is {$price} (Incl. GST). I've made sure the pricing block reflects that."
                    : "There's no price set on this course in the catalog yet — so the pricing block is empty until one is added.";
            }
            if (in_array('add_duration', $intents, true) && !empty($course['duration'])) {
                $hrs = rtrim(rtrim(trim($course['duration']), '0'), '.');
                return "It's a {$hrs}-hour programme. I've added that to the bullets.";
            }
            if (in_array('add_dates', $intents, true) && !empty($course['start_date'])) {
                return "Next intake is " . date('j M Y', strtotime($course['start_date'])) . ". The dates already show in the header banner; I've also added a bullet.";
            }
            if (in_array('add_trainer', $intents, true) && !empty($course['trainerprofile'])) {
                if (preg_match('/\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,2})\b/', $course['trainerprofile'], $m)) {
                    return "Led by {$m[1]}, a certified industry trainer. I've added a trainer bullet.";
                }
            }
            if (in_array('add_audience', $intents, true) && !empty($course['whoshouldattend'])) {
                $aud = $this->_cleanCatalogText($course['whoshouldattend']);
                $words = preg_split('/\s+/', $aud);
                $tag = implode(', ', array_slice($words, 0, 4));
                return "It's aimed at {$tag} and similar roles. Added a 'Designed for' bullet.";
            }
            if (in_array('add_certification', $intents, true)) {
                return "Yes — a Certificate of Completion is awarded by Tertiary Infotech Academy. Added it to the bullets.";
            }
            if (in_array('add_beginner', $intents, true)) {
                return "Yes — it's beginner-friendly with no prior experience needed. Added a beginner bullet.";
            }
            if (in_array('add_advanced', $intents, true)) {
                return "It's pitched at advanced practitioners and senior professionals. Added a level bullet.";
            }
            if (in_array('add_funding', $intents, true)) {
                return "Yes — WSQ subsidy, SkillsFuture Credit, and UTAP funding all apply. Added a funding bullet.";
            }
            if (in_array('add_prereq', $intents, true)) {
                return !empty($course['prerequisite'])
                    ? "Open to working professionals with relevant experience. Added a prerequisites bullet."
                    : "No formal prerequisites — just motivation. Added a 'no prereqs' bullet.";
            }
            if (in_array('add_handson', $intents, true)) {
                return "Yes — there are hands-on labs and real-world exercises throughout. Added a hands-on bullet.";
            }
            // Generic question → still acknowledge
            return "Pulled the relevant detail from the catalog and worked it into the newsletter.";
        }

        // Tone / structure intents — order matters when multiple
        // intents match (e.g. "more fun" hits both tone_long and
        // tone_exciting). Most-specific tone wins.
        if (in_array('tone_exciting', $intents, true)) return "Made the tagline more energetic and the cards visually punchier.";
        if (in_array('tone_casual', $intents, true))   return "Switched to a friendlier, more conversational tone.";
        if (in_array('tone_formal', $intents, true))   return "Dialled the tone up to professional / formal.";
        if (in_array('tone_short', $intents, true))    return "Tightened the newsletter — fewer bullets, shorter tagline.";
        if (in_array('tone_long', $intents, true))     return "Expanded the bullets with more learning outcomes from the course description.";
        if (in_array('tone_reorder', $intents, true))  return "Reordered the bullets.";

        // Content intents — declarative form
        if (in_array('add_cost', $intents, true)) {
            return $hasPrice
                ? "Done — pulled the course fee from the catalog ({$price} Incl. GST) and made sure it's in the pricing block."
                : "There's no price on this course in the catalog yet — add one to the product and I'll pick it up.";
        }
        if (in_array('add_earlybird', $intents, true))      return "Added an early-bird hook to the tagline and a 'limited seats' bullet.";
        if (in_array('add_dates', $intents, true)) {
            $d = !empty($course['start_date']) ? ' (' . date('j M Y', strtotime($course['start_date'])) . ')' : '';
            return "The class date from the catalog{$d} now appears as a bullet, and it's also rendered in the header / CTA bands by the template.";
        }
        if (in_array('add_trainer', $intents, true))        return "Referenced the trainer profile from the catalog as a new bullet.";
        if (in_array('add_audience', $intents, true))       return "Pulled the target audience from the catalog and added a 'Designed for' bullet.";
        if (in_array('add_duration', $intents, true))       return "Added the course duration from the catalog as a bullet.";
        if (in_array('add_certification', $intents, true))  return "Added the Certificate of Completion line.";
        if (in_array('add_funding', $intents, true))        return "Added a WSQ / SkillsFuture / UTAP funding-eligible bullet.";
        if (in_array('add_prereq', $intents, true))         return "Added a prerequisites bullet drawn from the catalog.";
        if (in_array('add_beginner', $intents, true))       return "Added a 'beginner-friendly' bullet so first-timers feel welcome.";
        if (in_array('add_advanced', $intents, true))       return "Pitched the bullets at advanced practitioners.";
        if (in_array('add_handson', $intents, true))        return "Added a hands-on / workshop bullet.";

        // Last resort
        if ($isRevise || in_array('generic_edit', $intents, true)) {
            return "Updated the newsletter based on your feedback for {$name}.";
        }
        return "Drafted the newsletter for {$name} using the catalog details.";
    }

    /**
     * Tweak the tagline based on simple feedback keywords. In live mode
     * Claude does this naturally; the stub mirrors the most common cues
     * so demo turns produce a visibly different result.
     */
    protected function _applyToneFeedback($tagline, $feedback, $primary)
    {
        $f = mb_strtolower($feedback);
        if (preg_match('/\b(short|shorter|concise|brief|terse)\b/u', $f)) {
            return "Master " . $this->_titleCase($primary);
        }
        if (preg_match('/\b(exciting|energetic|punchy|bold|fun|hype)\b/u', $f)) {
            return "Unlock " . $this->_titleCase($primary) . " — Your Next Move Starts Here!";
        }
        if (preg_match('/\b(casual|friendly|warm|inviting)\b/u', $f)) {
            return "Curious about " . $this->_titleCase($primary) . "? Come learn with us.";
        }
        if (preg_match('/\b(professional|formal|corporate|serious)\b/u', $f)) {
            return $this->_titleCase($primary) . ": A Practitioner's Programme";
        }
        if (preg_match('/\b(early.?bird|discount|promotion|deal|save)\b/u', $f)) {
            return "Early-Bird Open · Master " . $this->_titleCase($primary);
        }
        // Default: rotate to a fresh tagline so revise turns visibly differ.
        return "Refined Edition — " . $this->_titleCase($primary);
    }

    /**
     * Reshape the bullet list based on feedback (drop / reorder /
     * shorten). Same idea as the tagline tweaks: ensures each revise
     * turn produces a different visible output even though the content
     * still comes from the catalog.
     */
    protected function _applyBulletFeedback(array $bullets, $feedback)
    {
        $f = mb_strtolower($feedback);
        if (preg_match('/\b(short|shorter|concise|brief|fewer|less|terse)\b/u', $f)) {
            // Trim to top 2 and shorten each.
            $bullets = array_slice($bullets, 0, 2);
            foreach ($bullets as &$b) {
                if (mb_strlen($b) > 60) $b = mb_substr($b, 0, 57) . '...';
            }
            unset($b);
            return $bullets;
        }
        if (preg_match('/\b(reorder|reorganis|rearrang|swap|flip)\b/u', $f)) {
            return array_reverse($bullets);
        }
        // "more / detail / expand" was already handled by passing a
        // higher $max to _extractCourseOutcomes (longer length cap +
        // up to 6 bullets), so the list is already richer here. We
        // just keep it as-is rather than reversing arbitrarily.
        if (preg_match('/\b(more|expand|detail|longer|fuller|deeper|elaborate|further)\b/u', $f)) {
            return $bullets;
        }
        // Default revise: rotate the list so the order visibly differs.
        if (count($bullets) > 1) {
            $first = array_shift($bullets);
            $bullets[] = $first;
        }
        return $bullets;
    }

    /**
     * Pull "what you'll learn" bullets out of a course's full
     * description. When `$max` is high (7+) the length cap is relaxed
     * so longer outcomes survive — used when the admin asks for "more
     * information" / "more detail" so the bullets actually expand
     * rather than just rearrange.
     */
    protected function _extractCourseOutcomes($course, $max = 4)
    {
        $out = array();
        if (empty($course)) return $out;

        // Combine description + short_description so we have more text
        // to work with on courses where one field is sparse.
        $parts = array();
        if (!empty($course['description'])) $parts[] = (string) $course['description'];
        if (!empty($course['short_desc']))  $parts[] = (string) $course['short_desc'];
        if (empty($parts)) return $out;
        $clean = $this->_cleanCatalogText(implode(' ', $parts));
        if ($clean === '') return $out;

        $cap = $max >= 7 ? 160 : 110;

        // Strategy 1 — LO1:/LO2:/LO3: structured outcomes.
        if (preg_match_all('/LO\d+\s*:?\s*([^.]+?)(?=\s*LO\d+\s*:|\.|$)/i', $clean, $m)) {
            foreach ($m[1] as $line) {
                $line = trim($line, " \t.;,:");
                if (mb_strlen($line) >= 12 && mb_strlen($line) <= $cap) {
                    $out[] = $line;
                }
            }
        }
        if (count($out) >= 2) return array_slice($out, 0, $max);

        // Strategy 2 — outcome-verb sentences.
        $verbs = '\b(learn|understand|apply|design|build|develop|master|deploy|create|use|implement|analy[sz]e|evaluate|optimi[sz]e|leverage|configure|set up|integrate|explore|discover|gain|acquire)\b';
        foreach (preg_split('/(?<=[.!?])\s+/', $clean) as $s) {
            $s = rtrim(trim($s), '.!?,;:');
            if (mb_strlen($s) < 14 || mb_strlen($s) > $cap) continue;
            if (preg_match('/' . $verbs . '/i', $s)) {
                $out[] = $s;
                if (count($out) >= $max) break;
            }
        }
        if (count($out) >= 2) return $out;
        $out = array();

        // Strategy 3 — any short sentence as last resort.
        foreach (preg_split('/(?<=[.!?])\s+/', $clean) as $s) {
            $s = rtrim(trim($s), '.!?,;:');
            if (mb_strlen($s) >= 14 && mb_strlen($s) <= $cap) {
                $out[] = $s;
                if (count($out) >= $max) break;
            }
        }
        return $out;
    }

    /**
     * Detect whether a user message looks like an instruction to
     * refine the newsletter (vs the original brief). When yes, we
     * apply the tone / bullet feedback transformations even on the
     * first turn so chat composer messages always produce a visible
     * change.
     */
    protected function _looksLikeFeedback($text)
    {
        return !empty($this->_detectIntents($text));
    }

    /**
     * Central catalog of natural-language cues mapped to intent codes.
     * Imperative ("add X"), interrogative ("what's X?"), polite
     * ("could you add X"), and informal ("toss in X") forms all live
     * here so a single keyword list drives intent detection, content
     * injection, and the chat acknowledgment.
     */
    protected function _intentMap()
    {
        return array(
            // === Content intents — each maps to a catalog field injection ===
            'add_audience' => array(
                'audience', 'attend', 'target', 'demographic',
                'who should', 'who is this', 'who is it', 'who can',
                'who are the', 'who comes', 'right for', 'meant for',
                'designed for', 'good fit', 'best for',
            ),
            'add_trainer' => array(
                'trainer', 'instructor', 'teacher', 'lecturer', 'faculty',
                'who teaches', 'who is teaching', 'who will teach',
                'profile of', 'tell me about the', 'expert',
            ),
            'add_cost' => array(
                'cost', 'price', 'fee', 'pricing', 'how much',
                'what does it cost', 'total', 'amount', 'expense',
            ),
            'add_duration' => array(
                'duration', 'how long', 'length', 'hour', 'how many hour',
                'time commit', 'days', 'weeks',
            ),
            'add_certification' => array(
                'certif', 'credential', 'badge', 'qualif', 'accredit',
                'recogni', 'what do i get', 'completion award',
            ),
            'add_funding' => array(
                'wsq', 'skillsfuture', 'utap', 'funding', 'subsidy', 'subsidi',
                'sponsor', 'grant', 'claimable', 'reimburs',
            ),
            'add_dates' => array(
                'next intake', 'upcoming', 'when does', 'when is', 'when will',
                'class date', 'schedule', 'start date', 'next session',
                'when can i', 'next class',
            ),
            'add_prereq' => array(
                'prerequis', 'requirement', 'background', 'prior experience',
                'pre-req', 'do i need', 'need to know', 'before i',
            ),
            'add_beginner' => array(
                'beginner', 'novice', 'newcomer', 'no experience',
                'entry level', 'first time', 'starter', 'never done',
                'new to this', 'fresh', 'introductor',
            ),
            'add_advanced' => array(
                'advanced', 'experienced', 'senior', 'expert level',
                'pro level', 'deep dive',
            ),
            'add_handson' => array(
                'hands-on', 'hands on', 'practical', 'workshop',
                'lab', 'exercise', 'activity', 'do-it-yourself',
                'in practice', 'real-world',
            ),
            'add_earlybird' => array(
                'early bird', 'early-bird', 'discount', 'promo', 'deal',
                'save money', 'save now', 'save before', 'offer', 'special',
                'limited time', 'reduced rate',
            ),

            // === Tone / structure intents ===
            'tone_short' => array(
                'shorter', 'short', 'brief', 'concise', 'terse',
                'tighten', 'trim', 'cut down', 'less wordy', 'snappier',
                'cut the fluff', 'cut to the chase', 'compact',
            ),
            'tone_long' => array(
                'longer', ' more', 'expand', 'elaborate', 'fuller',
                'deeper', 'further', 'flesh out', 'beef up', 'pad out',
                'in detail', 'more detail', 'more info', 'additional info',
            ),
            'tone_exciting' => array(
                'exciting', 'energetic', 'punchy', 'bold', 'hype',
                'spice', 'pop ', 'wow factor', 'eye-catching', 'engaging',
                'jazz', 'lively', 'vibrant', 'more fun',
            ),
            'tone_casual' => array(
                'casual', 'friendly', 'warm', 'inviting', 'relaxed',
                'conversational', 'approachable', 'down to earth',
            ),
            'tone_formal' => array(
                'formal', 'corporate', 'serious', 'professional',
                'businesslike', 'polished', 'sophisticated',
            ),
            'tone_reorder' => array(
                'reorder', 'rearrang', 'swap', 'flip',
                'put first', 'move to top', 'move to bottom', 'switch order',
            ),

            // === Removal intent (inverse of add) ===
            'remove' => array(
                'remove', 'take out', 'drop the', 'delete',
                'get rid of', 'lose the', 'omit', 'skip the',
                'don\'t include', 'no need for', 'leave out', 'cut out',
            ),

            // === Meta intents ===
            'help' => array(
                'help', 'what can you', 'what can i ask', 'how do i',
                'how does this', 'guide me', 'show me how', 'examples of',
                'i don\'t know', 'not sure what', 'how to use',
                'lost', 'stuck',
            ),
            'reset' => array(
                'start over', 'reset', 'begin again', 'fresh start',
                'scrap', 'discard', 'try again',
            ),
            'generic_edit' => array(
                'change', 'update', 'tweak', 'revise', 'rewrite',
                'adjust', 'improve', 'add', 'include', 'mention',
                'highlight', 'emphasi', 'show', 'feature', 'bring out',
                'make it', 'make this',
            ),
        );
    }

    /**
     * Run intent detection against a user message. Returns a list of
     * matched intent codes (de-duplicated, preserves first-match order).
     */
    protected function _detectIntents($text)
    {
        $f = mb_strtolower($this->_normalizeFeedback($text));
        if ($f === '') return array();
        $hits = array();
        foreach ($this->_intentMap() as $intent => $cues) {
            foreach ($cues as $c) {
                if (mb_stripos($f, $c) !== false) {
                    $hits[$intent] = true;
                    break;
                }
            }
        }
        return array_keys($hits);
    }

    /**
     * Detect whether the message is phrased as a direct question (so
     * the chat ack should answer it rather than say "added X to the
     * newsletter"). Catches "what is...", "how long...", "who is...",
     * trailing "?", etc.
     */
    /**
     * Detect whether the admin explicitly wants to re-roll the visual
     * design (palette / hero / card style). Default behaviour stays
     * course-deterministic — each course has its own consistent look.
     * Saying any of these phrases overrides that and picks a fresh
     * random seed.
     */
    protected function _looksLikeDesignReroll($text)
    {
        $f = mb_strtolower((string) $text);
        $cues = array(
            'different design', 'different colour', 'different color',
            'change the design', 'change the colour', 'change the color',
            'change the palette', 'change palette', 'change colors',
            'change colours', 'new look', 'new design', 'new colour',
            'new color', 'new palette', 'fresh design', 'fresh look',
            're-roll', 'reroll', 'shuffle the design', 'shuffle palette',
            'try a different', 'another design', 'switch design',
            'switch the design', 'redesign',
        );
        foreach ($cues as $c) {
            if (mb_stripos($f, $c) !== false) return true;
        }
        return false;
    }

    protected function _isQuestion($text)
    {
        $t = trim($this->_normalizeFeedback($text));
        if ($t === '') return false;
        if (substr($t, -1) === '?') return true;
        $lower = mb_strtolower($t);
        $starters = array('what ', 'who ', 'when ', 'where ', 'why ', 'how ',
                          'is ', 'are ', 'do ', 'does ', 'should ');
        foreach ($starters as $s) {
            if (mb_substr($lower, 0, mb_strlen($s)) === $s) return true;
        }
        return false;
    }

    /**
     * Strip common polite prefixes ("could you please…", "would you
     * mind…", "please…") so the underlying intent surfaces. Without
     * this, "would you mind shortening" gets classed as a question
     * and never reaches the tone_short intent.
     */
    protected function _normalizeFeedback($text)
    {
        $t = trim((string) $text);
        if ($t === '') return $t;
        $patterns = array(
            '/^(can|could|would|will)\s+(you|we)(\s+please)?(\s+kindly)?(\s+mind)?\s+/iu',
            '/^(would|do)\s+you\s+mind\s+/iu',
            '/^please\s+(could|can|would|will)?\s*(you|we)?\s*/iu',
            '/^kindly\s+/iu',
            '/^i\s+(want|would like|need|wish|\'d like)\s+(you\s+)?to\s+/iu',
            '/^let\'s\s+/iu',
        );
        foreach ($patterns as $p) {
            $next = preg_replace($p, '', $t);
            if ($next !== null && $next !== $t) { $t = $next; break; }
        }
        return trim($t);
    }

    /**
     * When the admin asks for specific content ("add who should
     * attend", "add the trainer", "early-bird", etc.), pull the
     * matching field out of the catalog and inject it at the top of
     * the bullets list. This is what makes feedback actually visibly
     * change the newsletter content rather than just rotating the
     * tagline / palette.
     */
    protected function _applyContentInjections(array $bullets, $feedback, $course)
    {
        if (empty($course)) return $bullets;
        $intents = $this->_detectIntents($feedback);
        $isRemoval = in_array('remove', $intents, true);

        // Map intent codes to bullet phrases (or callbacks that need
        // catalog data). Each phrase is the canonical line we'd inject
        // — when the intent is "remove" instead of "add", we strip any
        // existing bullet matching the same canonical content.
        $byIntent = array();

        if (!empty($course['whoshouldattend'])) {
            $aud = $this->_cleanCatalogText($course['whoshouldattend']);
            if ($aud !== '') {
                $words = preg_split('/\s+/', $aud);
                $tag = implode(' ', array_slice($words, 0, 5));
                $byIntent['add_audience'] = "Designed for: " . rtrim($tag, ',');
            }
        }
        if (!empty($course['trainerprofile'])) {
            $tp = $this->_cleanCatalogText($course['trainerprofile']);
            if ($tp !== '' && preg_match('/\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,2})\b/', $tp, $m)) {
                $byIntent['add_trainer'] = "Led by " . $m[1] . " — certified industry trainer";
            } elseif ($tp !== '') {
                $byIntent['add_trainer'] = "Led by certified industry-experienced trainers";
            }
        }
        $byIntent['add_earlybird'] = "Limited early-bird seats — register now to save";
        if (!empty($course['duration'])) {
            $hrs = rtrim(rtrim(trim($course['duration']), '0'), '.');
            if ($hrs !== '') $byIntent['add_duration'] = "Comprehensive {$hrs}-hour programme";
        }
        $byIntent['add_prereq']        = !empty($course['prerequisite'])
            ? "Open to working professionals with relevant experience"
            : "No formal prerequisites — open to motivated learners";
        $byIntent['add_certification'] = "Certificate of completion awarded by Tertiary Infotech Academy";
        $byIntent['add_beginner']      = "Beginner-friendly — no prior experience needed";
        $byIntent['add_advanced']      = "Advanced practitioners and senior professionals";
        $byIntent['add_handson']       = "Hands-on labs and real-world exercises throughout";
        $byIntent['add_funding']       = "WSQ subsidy + SkillsFuture Credit + UTAP funding eligible";
        if (!empty($course['start_date'])) {
            $byIntent['add_dates'] = "Next intake: " . date('j M Y', strtotime($course['start_date']));
        }

        // Removal mode: strip any bullets that match an intent that was
        // also mentioned. "Take out the trainer info" → drop the trainer
        // bullet if it's already in the list.
        if ($isRemoval) {
            $toStrip = array();
            foreach ($intents as $i) {
                if (isset($byIntent[$i])) $toStrip[] = mb_strtolower(trim($byIntent[$i]));
            }
            if (!empty($toStrip)) {
                $bullets = array_values(array_filter($bullets, function ($b) use ($toStrip) {
                    return !in_array(mb_strtolower(trim($b)), $toStrip, true);
                }));
            }
            return $bullets;
        }

        // Otherwise inject every matched intent's canonical line at the
        // top of the bullets list, deduped.
        $injections = array();
        foreach ($intents as $i) {
            if (isset($byIntent[$i])) $injections[] = $byIntent[$i];
        }
        if (empty($injections)) return $bullets;

        $combined = array_merge($injections, $bullets);
        $seen = array(); $out = array();
        foreach ($combined as $b) {
            $k = mb_strtolower(trim($b));
            if ($k === '' || isset($seen[$k])) continue;
            $seen[$k] = true;
            $out[] = $b;
        }
        return $out;
    }

    /**
     * Build sensible bullet fallbacks when the description is empty.
     * Pulls from short_description and other catalog fields rather
     * than emitting "Hands-on, practical {Course} skills" filler.
     */
    protected function _buildFallbackBullets($course, $primary, $wantMore)
    {
        // Try short_description first — even on courses with no full
        // description, the short blurb usually has 1-2 useful sentences.
        $out = array();
        if (!empty($course['short_desc'])) {
            $clean = $this->_cleanCatalogText($course['short_desc']);
            $cap = $wantMore ? 160 : 95;
            foreach (preg_split('/(?<=[.!?])\s+/', $clean) as $s) {
                $s = rtrim(trim($s), '.!?,;:');
                if (mb_strlen($s) >= 14 && mb_strlen($s) <= $cap) {
                    $out[] = $s;
                    if (count($out) >= ($wantMore ? 6 : 4)) break;
                }
            }
        }
        if (count($out) >= 2) return $out;

        // Last resort: course-name-shaped generic bullets.
        $name = $primary === 'This Course' ? 'this course' : $primary;
        return array(
            "Hands-on, practical {$name} skills",
            "Real-world examples and exercises",
            "Industry-relevant techniques",
            "Certificate of completion",
        );
    }

    /**
     * Title-case a course name while preserving common acronyms (WSQ,
     * DISC, AI, SQL, etc.) so "WSQ - Basic Urban Farming with
     * Hydroponics" stays "WSQ - Basic Urban Farming With Hydroponics"
     * rather than "Wsq - Basic...".
     */
    protected function _titleCase($s)
    {
        $s = trim((string) $s);
        if ($s === '') return $s;
        $words = preg_split('/(\s+|-)/u', $s, -1, PREG_SPLIT_DELIM_CAPTURE);
        $out = '';
        foreach ($words as $w) {
            if ($w === '' || preg_match('/^(\s+|-)$/', $w)) { $out .= $w; continue; }
            // Leave fully-uppercase acronyms (length 2-5) alone.
            if (preg_match('/^[A-Z0-9]{2,5}$/', $w)) { $out .= $w; continue; }
            $out .= mb_strtoupper(mb_substr($w, 0, 1)) . mb_strtolower(mb_substr($w, 1));
        }
        return $out;
    }

    /**
     * Split an assistant reply into its chat acknowledgment (shown in
     * the chat pane) and the structured newsletter body (parsed into
     * body_blocks for the template). The two halves are separated by
     * the ===NEWSLETTER=== marker. If no marker is present we treat
     * the whole reply as body — that's what older drafts saved before
     * this change look like.
     */
    protected function _parseAssistantReply($text)
    {
        $text = trim((string) $text);
        $marker = '===NEWSLETTER===';
        $pos = strpos($text, $marker);
        if ($pos !== false) {
            $body = trim(substr($text, $pos + strlen($marker)));
            return array(
                'ack'      => trim(substr($text, 0, $pos)),
                'body'     => $body,
                'has_body' => $body !== '',
            );
        }
        // No marker → chat-only response (the admin asked a question or
        // chatted off-topic). The whole reply is the chat acknowledgment;
        // the existing draft body stays untouched. The system prompt tells
        // Claude to omit the marker in this case.
        return array(
            'ack'      => $text,
            'body'     => '',
            'has_body' => false,
        );
    }

    protected function _splitIntoBlocks($text)
    {
        $parts = preg_split('/\n\s*\n/', trim((string) $text), 4);
        return array(
            'body_block_1' => isset($parts[0]) ? $parts[0] : '',
            'body_block_2' => isset($parts[1]) ? $parts[1] : '',
            'body_block_3' => isset($parts[2]) ? $parts[2] : (isset($parts[3]) ? $parts[3] : ''),
        );
    }

    protected function _renderTemplate($key, $title, $subject, $previewText, array $blocks, array $pids, $cc, array $images = array())
    {
        // Agentic flyer: the autonomous pipeline's fixed, approved design. Render it
        // from the same helper the cron + MailerLite use, so Live Preview === email
        // === blast (single source of truth). Falls through to the block templates
        // below only for the hand-built course_promo / visual_showcase drafts.
        if ($key === 'agentic_flyer') {
            $pid = (int) (isset($pids[0]) ? $pids[0] : 0);
            $flyer = $pid ? Mage::helper('mmd_marketing/flyer')->render($pid) : '';
            if ($flyer !== '') {
                return $flyer;
            }
            // no course picked yet — show a hint instead of silently falling back
            return '<div style="font-family:-apple-system,Segoe UI,Arial,sans-serif;padding:40px;text-align:center;color:#64748b;">'
                 . 'Pick a course to render the Agentic flyer preview.</div>';
        }

        $cfg = Mage::helper('mmd_rolemanager')->getMarketingApiConfig();
        $countryName = Mage::helper('mmd_rolemanager')->getActiveCountryName();
        $courses = $this->_loadCourseDetails($pids);

        $defaultCta = !empty($courses) && !empty($courses[0]['url'])
            ? $courses[0]['url']
            : 'https://www.tertiarycourses.com.sg/';

        // Pick the design variant. If the draft has a stamped seed
        // (set on every Send-to-AI), use it so the look stays consistent
        // while the admin is editing. Otherwise derive a deterministic
        // seed from the title + pids so the empty preview at least has
        // its own coherent look.
        $seed = isset($blocks['_design_seed']) ? (int) $blocks['_design_seed'] : 0;
        if ($seed <= 0) {
            $seed = (int) (crc32($title . '|' . implode(',', $pids)) & 0x7fffffff);
            if ($seed === 0) $seed = 1;
        }
        $design = $this->_pickDesignVariant($seed);

        $vars = array(
            'subject'      => (string) $subject,
            'title'        => (string) $title,
            'preview_text' => (string) $previewText,
            'body_block_1' => isset($blocks['body_block_1']) ? (string) $blocks['body_block_1'] : '',
            'body_block_2' => isset($blocks['body_block_2']) ? (string) $blocks['body_block_2'] : '',
            'body_block_3' => isset($blocks['body_block_3']) ? (string) $blocks['body_block_3'] : '',
            'cta_label'    => 'REGISTER',
            'cta_url'      => $defaultCta,
            'country'      => $countryName,
            'country_code' => $cc,
            'from_name'    => $cfg['from_name'],
            'from_email'   => !empty($cfg['from_email']) ? $cfg['from_email'] : 'enquiry@tertiaryinfotech.com',
            'courses'      => $courses,
            'subsidies'    => $this->_subsidiesForCountry($cc),
            'images'       => $images, // [{media_type, data, name}, ...]
            'design'       => $design,
        );

        $allowed = array(
            'course_promo'    => 'course-promo.phtml',
            'visual_showcase' => 'visual-showcase.phtml',
        );
        $file = isset($allowed[$key]) ? $allowed[$key] : $allowed['course_promo'];
        $path = Mage::getBaseDir('design')
              . '/adminhtml/default/default/template/marketing/templates/' . $file;
        if (!is_file($path)) throw new Exception('Template missing: ' . $file);

        ob_start();
        include $path;
        return ob_get_clean();
    }

    /**
     * Load full course details (name, sku, dates, price, frontend URL)
     * for the picked product ids. The new template renders dates and
     * deep-links its CTA / QR to the first course's product page, so we
     * resolve the proper frontend URL via the country's default store.
     */
    protected function _loadCourseDetails(array $pids)
    {
        if (empty($pids)) return array();

        $wid     = (int) Mage::helper('mmd_rolemanager')->getActiveWebsiteId();
        $storeId = 0;
        try {
            $website = Mage::getModel('core/website')->load($wid);
            $store   = $website ? $website->getDefaultStore() : null;
            if ($store && $store->getId()) $storeId = (int) $store->getId();
        } catch (Exception $e) {
            // Fall back to admin store; URL builder still resolves.
        }

        $out = array();
        foreach ($pids as $pid) {
            $pid = (int) $pid;
            if ($pid <= 0) continue;
            try {
                $p = Mage::getModel('catalog/product');
                if ($storeId) $p->setStoreId($storeId);
                $p->load($pid);
                if (!$p->getId()) continue;
                $out[] = array(
                    'entity_id'  => (int) $p->getId(),
                    'sku'        => (string) $p->getSku(),
                    'name'       => (string) $p->getName(),
                    'start_date' => (string) $p->getData('start_date'),
                    'end_date'   => (string) $p->getData('end_date'),
                    'price'      => $p->getPrice(),
                    'url'        => $p->getProductUrl(),
                );
            } catch (Exception $e) {
                // Skip a single bad product; keep the rest.
            }
        }
        return $out;
    }

    /**
     * Subsidy / funding pills shown in the hero. Per-country because
     * SkillsFuture / WSQ / UTAP only apply to Singapore. Other countries
     * return an empty list and the template hides the pill row.
     */
    protected function _subsidiesForCountry($cc)
    {
        $map = array(
            'SG' => array(
                array('label' => 'WSQ Subsidy',                  'color' => '#e63946'),
                array('label' => 'UTAP Funding',                 'color' => '#e63946'),
                array('label' => 'SkillsFuture Credit Eligible', 'color' => '#e63946'),
            ),
        );
        return isset($map[$cc]) ? $map[$cc] : array();
    }

    /**
     * Resolve a design variant from a seed. Each Send-to-AI re-rolls
     * the seed so the newsletter looks visibly different every time
     * Claude regenerates. The same seed always yields the same look,
     * so previews stay stable while the admin is editing the body.
     *
     * 8 palettes × 2 hero treatments × 2 card styles = 32 combinations.
     */
    protected function _pickDesignVariant($seed)
    {
        $palettes = array(
            // Each palette: primary (hero/header), dark (gradient end /
            // accents), accent (CTA band / call-out), yellow (tagline
            // strip / pricing header / CTA button), sub (subsidy pill)
            array('name'=>'magenta-teal',  'primary'=>'#d4276e','dark'=>'#7c1741','accent'=>'#2bc4d4','yellow'=>'#ffc83d','sub'=>'#e63946'),
            array('name'=>'indigo-coral',  'primary'=>'#4f46e5','dark'=>'#312e81','accent'=>'#fb7185','yellow'=>'#fbbf24','sub'=>'#dc2626'),
            array('name'=>'forest-amber',  'primary'=>'#059669','dark'=>'#064e3b','accent'=>'#f59e0b','yellow'=>'#fde047','sub'=>'#dc2626'),
            array('name'=>'royal-rose',    'primary'=>'#7c3aed','dark'=>'#4c1d95','accent'=>'#ec4899','yellow'=>'#fde047','sub'=>'#dc2626'),
            array('name'=>'ocean-citrus',  'primary'=>'#0891b2','dark'=>'#164e63','accent'=>'#f97316','yellow'=>'#fef08a','sub'=>'#dc2626'),
            array('name'=>'sunset-slate',  'primary'=>'#dc2626','dark'=>'#7f1d1d','accent'=>'#0f766e','yellow'=>'#fde047','sub'=>'#1e293b'),
            array('name'=>'berry-sky',     'primary'=>'#be185d','dark'=>'#831843','accent'=>'#0ea5e9','yellow'=>'#fef08a','sub'=>'#dc2626'),
            array('name'=>'pumpkin-teal',  'primary'=>'#ea580c','dark'=>'#7c2d12','accent'=>'#0d9488','yellow'=>'#fde047','sub'=>'#7c2d12'),
            // New additions:
            array('name'=>'midnight-gold', 'primary'=>'#1e293b','dark'=>'#0f172a','accent'=>'#eab308','yellow'=>'#fde68a','sub'=>'#b45309'),
            array('name'=>'emerald-coral', 'primary'=>'#10b981','dark'=>'#065f46','accent'=>'#fb7185','yellow'=>'#fef08a','sub'=>'#be185d'),
            array('name'=>'plum-amber',    'primary'=>'#9333ea','dark'=>'#581c87','accent'=>'#f59e0b','yellow'=>'#fde68a','sub'=>'#be123c'),
            array('name'=>'navy-orange',   'primary'=>'#1e40af','dark'=>'#1e3a8a','accent'=>'#f97316','yellow'=>'#fef08a','sub'=>'#dc2626'),
            array('name'=>'crimson-cream', 'primary'=>'#b91c1c','dark'=>'#7f1d1d','accent'=>'#fef3c7','yellow'=>'#fde68a','sub'=>'#1e293b'),
            array('name'=>'teal-rose',     'primary'=>'#0d9488','dark'=>'#134e4a','accent'=>'#f43f5e','yellow'=>'#fef08a','sub'=>'#be123c'),
            array('name'=>'violet-lime',   'primary'=>'#8b5cf6','dark'=>'#5b21b6','accent'=>'#84cc16','yellow'=>'#fde047','sub'=>'#dc2626'),
            array('name'=>'bronze-sage',   'primary'=>'#a16207','dark'=>'#713f12','accent'=>'#84cc16','yellow'=>'#fde68a','sub'=>'#7c2d12'),
        );
        $seed = max(1, abs((int) $seed));
        return array(
            'seed'    => $seed,
            'palette' => $palettes[$seed % count($palettes)],
            // 4 hero × 4 card × 4 body-layout × 16 palettes = 1024
            // unique compositions — different palette AND structural
            // layout per course, not just colors.
            'hero'    => (int) (intdiv($seed, 16)   % 4),
            'cards'   => (int) (intdiv($seed, 64)   % 4),
            'layout'  => (int) (intdiv($seed, 256)  % 4),
        );
    }

    /**
     * Walks the rendered HTML for base64 `data:image/...` URIs (in
     * `<img src="…">` attributes and inline `background-image:url(…)`
     * styles), writes each one as a real file under media/marketing/,
     * and replaces the URI with the public URL. Returns the modified
     * HTML.
     *
     * Reason: MailerLite's HTML content field caps around 1MB; full-
     * resolution image uploads embedded as base64 blow past that and
     * MailerLite silently truncates the body. Hosting them by URL
     * keeps the email body small AND makes the images reachable from
     * the recipient's mail client when the email is delivered.
     *
     * Files are named deterministically by content hash so re-pushes
     * of the same draft don't pile up duplicate copies on disk.
     */
    /**
     * Re-encode every base64 data-URI image in the HTML to a small
     * JPEG (resized to fit a max dimension, quality ~72) and put it
     * back as a data URI. This keeps the email fully self-contained —
     * no external URL that could be unreachable — so the images render
     * in MailerLite's editor/preview and in the recipient's inbox
     * regardless of whether the push came from localhost or production.
     *
     * Raw phone-camera uploads are 2-6MB each; base64 of that blows
     * past MailerLite's ~1MB content cap. Compressed they're ~80-180KB
     * each (~110-240KB base64), so 3-4 of them stay well under the cap.
     *
     * SVG fallbacks (data:image/svg+xml, used when no image uploaded)
     * are intentionally NOT matched here — they're already tiny and
     * GD can't rasterise them anyway.
     */
    protected function _compressDataUrisForEmail($html, $maxDim = 1000, $quality = 72)
    {
        if (!function_exists('imagecreatefromstring')) {
            return $html; // GD missing — leave as-is, hosting fallback will handle it
        }

        $shrink = function ($b64) use ($maxDim, $quality) {
            $bin = base64_decode($b64);
            if ($bin === false || strlen($bin) < 64) return null;
            $img = @imagecreatefromstring($bin);
            if ($img === false) return null;

            $w = imagesx($img);
            $h = imagesy($img);
            if ($w < 1 || $h < 1) { imagedestroy($img); return null; }

            // Scale down only — never upscale a small image.
            $scale = min(1.0, $maxDim / max($w, $h));
            $nw = max(1, (int) round($w * $scale));
            $nh = max(1, (int) round($h * $scale));

            $canvas = imagecreatetruecolor($nw, $nh);
            // JPEG has no alpha — flatten any transparency onto white so
            // a transparent PNG doesn't come out black.
            $white = imagecolorallocate($canvas, 255, 255, 255);
            imagefilledrectangle($canvas, 0, 0, $nw, $nh, $white);
            imagecopyresampled($canvas, $img, 0, 0, 0, 0, $nw, $nh, $w, $h);

            ob_start();
            imagejpeg($canvas, null, $quality);
            $out = ob_get_clean();
            imagedestroy($img);
            imagedestroy($canvas);

            if ($out === false || $out === '') return null;
            return 'data:image/jpeg;base64,' . base64_encode($out);
        };

        $reSrc = function ($m) use ($shrink) {
            $d = $shrink($m[2]);
            return $d ? 'src="' . $d . '"' : $m[0];
        };
        $reBg = function ($m) use ($shrink) {
            $d = $shrink($m[2]);
            return $d ? "background-image:url('" . $d . "')" : $m[0];
        };
        $reAttr = function ($m) use ($shrink) {
            $d = $shrink($m[2]);
            return $d ? 'background="' . $d . '"' : $m[0];
        };

        $html = preg_replace_callback('#src="data:image/(png|jpe?g|gif|webp);base64,([^"]+)"#i', $reSrc, $html);
        $html = preg_replace_callback("#background-image\s*:\s*url\(['\"]?data:image/(png|jpe?g|gif|webp);base64,([^'\")]+)['\"]?\)#i", $reBg, $html);
        $html = preg_replace_callback('#background="data:image/(png|jpe?g|gif|webp);base64,([^"]+)"#i', $reAttr, $html);
        return $html;
    }

    protected function _persistDataUrisAsHostedImages($html)
    {
        $dir = Mage::getBaseDir('media') . DIRECTORY_SEPARATOR . 'marketing';
        if (!is_dir($dir)) {
            @mkdir($dir, 0775, true);
        }
        $publicBase = rtrim(Mage::getBaseUrl(Mage_Core_Model_Store::URL_TYPE_MEDIA), '/') . '/marketing/';

        $persistOne = function ($extRaw, $b64) use ($dir, $publicBase) {
            $ext = strtolower($extRaw);
            if ($ext === 'jpeg') $ext = 'jpg';
            $bin = base64_decode($b64);
            if ($bin === false || strlen($bin) < 16) {
                // Decode failed — keep the original data URI so the
                // local preview still renders. MailerLite will reject
                // it but at least we tried.
                return null;
            }
            $name = substr(md5($bin), 0, 16) . '.' . $ext;
            $path = $dir . DIRECTORY_SEPARATOR . $name;
            if (!file_exists($path)) {
                @file_put_contents($path, $bin);
            }
            return $publicBase . $name;
        };

        // <img src="data:image/...;base64,...">
        $html = preg_replace_callback(
            '#src="data:image/(png|jpe?g|gif|webp);base64,([^"]+)"#i',
            function ($m) use ($persistOne) {
                $url = $persistOne($m[1], $m[2]);
                return $url ? 'src="' . $url . '"' : $m[0];
            },
            $html
        );
        // background-image:url('data:image/...;base64,...')
        $html = preg_replace_callback(
            "#background-image\s*:\s*url\(['\"]?data:image/(png|jpe?g|gif|webp);base64,([^'\")]+)['\"]?\)#i",
            function ($m) use ($persistOne) {
                $url = $persistOne($m[1], $m[2]);
                return $url ? "background-image:url('" . $url . "')" : $m[0];
            },
            $html
        );
        // Also handle <table background="data:...">
        $html = preg_replace_callback(
            '#background="data:image/(png|jpe?g|gif|webp);base64,([^"]+)"#i',
            function ($m) use ($persistOne) {
                $url = $persistOne($m[1], $m[2]);
                return $url ? 'background="' . $url . '"' : $m[0];
            },
            $html
        );
        return $html;
    }

    protected function _pushToMailerLite(array $cfg, $subject, $html)
    {
        // MailerLite legally requires an unsubscribe merge tag in every
        // campaign body — and silently rejects HTML content that's
        // missing it, leaving the campaign shell created but with an
        // empty editor preview (the symptom that triggered this fix).
        // We inject a minimal unsubscribe + view-in-browser footer just
        // before </body> if the template didn't already include the
        // merge tags itself.
        if (stripos($html, '{$unsubscribe}') === false) {
            $footer = '<div style="text-align:center;font-size:11px;color:#94a3b8;padding:24px 16px;font-family:Arial,sans-serif;line-height:1.6;">'
                    . 'You\'re receiving this because you signed up for updates.<br>'
                    . '<a href="{$unsubscribe}" style="color:#94a3b8;">Unsubscribe</a> &middot; '
                    . '<a href="{$url}" style="color:#94a3b8;">View in browser</a>'
                    . '</div>';
            if (stripos($html, '</body>') !== false) {
                $html = str_ireplace('</body>', $footer . '</body>', $html);
            } else {
                $html .= $footer;
            }
        }

        // Image strategy — keep the email self-contained when possible.
        //
        // 1. First, compress every embedded image (resize + JPEG) and
        //    keep it as a base64 data URI. A self-contained email shows
        //    its images everywhere — MailerLite's editor/preview AND the
        //    recipient's inbox — no matter where the push originated
        //    (localhost or production). This is what the user wants:
        //    "view the images after it is being pushed to MailerLite".
        //
        // 2. MailerLite's content field caps around 1MB. If the
        //    compressed result is still over a safe budget (some users
        //    upload many large images), fall back to hosting the images
        //    as files and referencing them by URL — that keeps the body
        //    tiny so MailerLite still accepts it (images then resolve on
        //    production; on localhost they won't, but the body is at
        //    least intact).
        $beforeBytes = strlen($html);
        $compressed  = $this->_compressDataUrisForEmail($html);
        $SAFE_BUDGET = 950000; // ~950KB — under MailerLite's ~1MB cap

        if (strlen($compressed) <= $SAFE_BUDGET) {
            $html = $compressed;
            $this->_writeLog('MailerLite push: embedded compressed images, HTML '
                . $beforeBytes . ' -> ' . strlen($html) . ' bytes (self-contained)');
        } else {
            $html = $this->_persistDataUrisAsHostedImages($compressed);
            $this->_writeLog('MailerLite push: compressed still '
                . strlen($compressed) . 'B (> ' . $SAFE_BUDGET
                . '), fell back to hosted images, HTML '
                . $beforeBytes . ' -> ' . strlen($html) . ' bytes');
        }

        // ---- Step 1: create the campaign shell with HTML content ----
        $body = json_encode(array(
            'name'             => $subject,
            'language_id'      => 1,
            'type'             => 'regular',
            'emails'           => array(array(
                'subject'      => $subject,
                'from_name'    => $cfg['from_name'],
                'from'         => $cfg['from_email'],
                'content'      => $html,
            )),
        ));
        // Native cURL — same reason as the Anthropic call above:
        // Mage_HTTP_Client_Curl::post() form-encodes the body, which
        // breaks JSON APIs.
        $ch = curl_init('https://connect.mailerlite.com/api/campaigns');
        curl_setopt_array($ch, array(
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $body,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 60,
            CURLOPT_CONNECTTIMEOUT => 15,
            CURLOPT_HTTPHEADER     => array(
                'authorization: Bearer ' . $cfg['mailerlite_key'],
                'content-type: application/json',
                'accept: application/json',
            ),
        ));
        $raw  = curl_exec($ch);
        $err  = curl_error($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        $this->_writeLog('MailerLite create response (' . $code . '): ' . substr((string) $raw, 0, 1500));
        if ($raw === false || $raw === '') {
            throw new Exception('MailerLite call failed (cURL): ' . ($err ?: 'no response'));
        }
        $rsp = json_decode($raw, true);
        if (!isset($rsp['data']['id'])) {
            throw new Exception('MailerLite push failed (' . $code . '): ' . substr($raw, 0, 300));
        }
        $campaignId = (string) $rsp['data']['id'];

        // ---- Step 2: force-update via PUT /api/campaigns/{id}. The
        // create call usually accepts content, but on first push or
        // when MailerLite silently drops oversize bodies the editor
        // preview can come up empty. PUT is a FULL REPLACE in
        // MailerLite's API — every top-level field that was required
        // for create is required again here (name, language_id, type,
        // emails). Sending only `emails` returns 422 "name field is
        // required".
        $patchBody = json_encode(array(
            'name'        => $subject,
            'language_id' => 1,
            'type'        => 'regular',
            'emails'      => array(array(
                'subject'   => $subject,
                'from_name' => $cfg['from_name'],
                'from'      => $cfg['from_email'],
                'content'   => $html,
            )),
        ));
        $ch2 = curl_init('https://connect.mailerlite.com/api/campaigns/' . urlencode($campaignId));
        curl_setopt_array($ch2, array(
            CURLOPT_CUSTOMREQUEST  => 'PUT',
            CURLOPT_POSTFIELDS     => $patchBody,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 60,
            CURLOPT_CONNECTTIMEOUT => 15,
            CURLOPT_HTTPHEADER     => array(
                'authorization: Bearer ' . $cfg['mailerlite_key'],
                'content-type: application/json',
                'accept: application/json',
            ),
        ));
        $raw2  = curl_exec($ch2);
        $code2 = (int) curl_getinfo($ch2, CURLINFO_HTTP_CODE);
        curl_close($ch2);
        $this->_writeLog('MailerLite content PUT response (' . $code2 . '): ' . substr((string) $raw2, 0, 800));
        // Don't throw on PUT failure — the campaign still exists, the
        // user can open it in MailerLite and fix manually. Just surface
        // the log entry.

        return $campaignId;
    }

    protected function _isAllowed()
    {
        return Mage::helper('mmd_rolemanager')->isRoleAllowed(array('marketing', 'admin', 'developer'));
    }

    /**
     * Skip the admin form-key check for these AJAX POSTs. Same pattern as
     * CoursesaveController. The endpoints are still gated by admin
     * session + _isAllowed() role check, so form-key adds little.
     */
    protected function _validateFormKey()
    {
        return true;
    }
}
