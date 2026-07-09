<?php
/**
 * Renders the approved course-flyer design (the one signed off in the sample)
 * for a given product. Used by the backend preview, the reviewer email, and the
 * MailerLite blast so all three show the identical design.
 *
 * The QR points at the live course page. In EMAIL, embedded data-URI images are
 * stripped by Gmail, so the QR is referenced as a hosted image URL served by the
 * public review route (newsletter-review/qr) which streams a PNG for the given
 * course URL. That keeps the QR dynamic per-course with no external dependency.
 */
class MMD_Marketing_Helper_Flyer extends Mage_Core_Helper_Abstract
{
    /** Course data the flyer needs — lightweight attribute reads (no full
     *  product load, which pulls the options collection and fails on CLI). */
    public function courseData($productId)
    {
        $productId = (int) $productId;
        $res  = Mage::getResourceModel('catalog/product');
        $raw  = function ($attr) use ($res, $productId) {
            return (string) $res->getAttributeRawValue($productId, $attr, 0);
        };
        $sku = (string) Mage::getSingleton('core/resource')->getConnection('core_read')
            ->fetchOne('SELECT sku FROM ' . Mage::getSingleton('core/resource')->getTableName('catalog/product')
                     . ' WHERE entity_id = ?', array($productId));
        if ($sku === '') {
            return null;
        }
        $name = $raw('name');
        $base = rtrim(Mage::getStoreConfig('web/unsecure/base_url'), '/');
        $urlKey = $raw('url_key');
        $courseUrl = $urlKey ? $base . '/' . $urlKey . '.html' : $base;

        // funding badges are Magento tags on the product (memory: funding_badges_via_tags)
        $badges = array();
        try {
            $res  = Mage::getSingleton('core/resource');
            $conn = $res->getConnection('core_read');
            $rows = $conn->fetchCol(
                'SELECT DISTINCT t.name FROM ' . $res->getTableName('tag') . ' t'
              . ' JOIN ' . $res->getTableName('tag/relation') . ' r ON r.tag_id = t.tag_id'
              . ' WHERE r.product_id = ?', array((int) $productId)
            );
            $allowed = array('WSQ','SkillsFuture Credit','PSEA','UTAP','SFEC','MCES','Absentee Payroll','IBF','HRDF');
            foreach ($rows as $n) { if (in_array($n, $allowed, true)) $badges[] = $n; }
        } catch (Exception $e) { /* badges are optional */ }

        // Persuasive "why take this" blurb — real per-course marketing copy, not
        // the factual syllabus. Prefer short_description, fall back to meta_description.
        // Decode entities AFTER strip_tags (catalog copy carries &rsquo;/&nbsp; which
        // would otherwise be re-escaped at render and show literally), then collapse
        // Unicode whitespace (Microsoft-paste NBSP/U+202F — see memory
        // feedback_short_description_unicode_whitespace) so the trim is clean.
        $blurb = html_entity_decode(strip_tags((string) ($raw('short_description') ?: $raw('meta_description'))), ENT_QUOTES | ENT_HTML5, 'UTF-8');
        $blurb = trim(preg_replace('/\s+/u', ' ', str_replace("\xc2\xa0", ' ', $blurb)));

        // Next 2 upcoming class intakes — drives urgency + signup. PRIMARY source is
        // the LMS "Course Date" custom-option values (the confirmed published schedule
        // a learner picks at checkout); course_runs only fills once orders form a class,
        // so it is empty for a course whose next dates haven't been ordered yet. Parse
        // each option title ("8 Jul 2026 (Wed)", "5/6 Aug 2026 Evening (Wed/Thu)"),
        // keep future dates, take the soonest 2.
        $runs = array();
        try {
            $rc   = Mage::getSingleton('core/resource');
            $conn = $rc->getConnection('core_read');
            $titles = $conn->fetchCol(
                'SELECT tt.title FROM ' . $rc->getTableName('catalog/product_option') . ' o'
              . ' JOIN ' . $rc->getTableName('catalog/product_option_type_value') . ' v ON v.option_id = o.option_id'
              . ' JOIN ' . $rc->getTableName('catalog/product_option_type_title') . ' tt ON tt.option_type_id = v.option_type_id AND tt.store_id = 0'
              . ' JOIN ' . $rc->getTableName('catalog/product_option_title') . ' ot ON ot.option_id = o.option_id AND ot.store_id = 0'
              . " WHERE o.product_id = ? AND ot.title = 'Course Date'"
              . ' ORDER BY v.sort_order ASC, v.option_type_id ASC',
                array((int) $productId)
            );
            $today = strtotime('today');
            $picked = array();
            $seen = array();
            foreach ($titles as $t) {
                // Take the leading "<day>[/<day2>] <Mon> <Year>" — first day of a range.
                if (!preg_match('/(\d{1,2})(?:\s*\/\s*\d{1,2})?\s+([A-Za-z]{3,})\s+(\d{4})/', (string) $t, $m)) { continue; }
                $ts = strtotime($m[1] . ' ' . $m[2] . ' ' . $m[3]);
                if (!$ts || $ts < $today) { continue; }
                $date = date('Y-m-d', $ts);
                if (isset($seen[$date])) { continue; }   // one row per calendar date
                $seen[$date] = true;
                $picked[] = array('ts' => $ts, 'date' => $date, 'evening' => (stripos((string) $t, 'evening') !== false));
                if (count($picked) >= 2) { break; }
            }
            foreach ($picked as $p) {
                $runs[] = array(
                    'course_start_date' => $p['date'],
                    'course_start_time' => $p['evening'] ? '19:00:00' : '09:00:00',
                    'course_end_date'   => $p['date'],
                );
            }
            // Fallback: if the course has no date options, use materialised course_runs.
            if (empty($runs)) {
                $runs = $conn->fetchAll(
                    'SELECT course_start_date, course_start_time, course_end_date FROM '
                  . $rc->getTableName('course_runs')
                  . ' WHERE product_id = ? AND course_start_date >= CURDATE()'
                  . ' ORDER BY course_start_date ASC LIMIT 2',
                    array((int) $productId)
                );
            }
        } catch (Exception $e) { /* runs optional */ }

        // "What you'll walk out able to do" — outcome-framed value stack. We do NOT
        // copy the course-page syllabus verbatim; the flyer is a funnel, so each line
        // is a pain-point -> tangible result the reader can picture, in plain English.
        // Curated per flagship course; otherwise reframed from THIS course's own
        // topics so every flyer reads differently (no repeated generic lines).
        $topics   = $this->parseTopics((string) $raw('description'));
        $outcomes = $this->courseOutcomes($sku, $name, $topics);

        // Per-course visual identity: a flagship course gets its own accent
        // palette (+ optional logo); everything else keeps the default blue.
        $pitch  = $this->_curatedPitch();
        $key    = trim((string) $sku);
        $accent = (isset($pitch[$key]['accent']) && is_array($pitch[$key]['accent']))
            ? $pitch[$key]['accent']
            : array('#2563eb', '#eaf0fe', '#c7d7fe');

        return array(
            'id'        => $productId,
            'sku'       => $sku,
            'name'      => preg_replace('/^\s*WSQ\s*[-\x{2013}]\s*/iu', '', $name),
            'raw_name'  => $name,
            'price'     => (float) $raw('price'),
            'duration'  => $raw('duration'),
            'url'       => $courseUrl,
            'badges'    => $badges,
            'blurb'     => $blurb,
            'is_wsq'    => (stripos($sku, 'TGS-') === 0) || in_array('WSQ', $badges, true),
            'runs'      => $runs,
            'outcomes'  => $outcomes,
            'accent'    => $accent[0],
            'accent_bg' => $accent[1],
            'accent_br' => $accent[2],
            'logo'      => isset($pitch[$key]['logo']) ? $pitch[$key]['logo'] : '',
        );
    }

    /** Curated per-flagship-SKU flyer voice: [hook, outcomes[]]. See the
     *  `newsletter-design` skill for how to write and add these. */
    protected function _curatedPitch()
    {
        return array(
            // WSQ Agentic AI Applications with Claude Code — "build your own apps".
            'TGS-2025052468' => array(
                // Claude brand terracotta — a distinct identity vs the default blue.
                'accent' => array('#c2410c', '#fdeede', '#f5cfa8'),
                'hook' => 'Build your own apps with Claude Code — describe what you want in plain English and ship a working tool the same day, no coding background needed.',
                'outcomes' => array(
                    'Turn a plain-English idea into a working app &mdash; no computer-science degree needed.',
                    'Ship your first useful tool before lunch, then build a second one after.',
                    'Hand the boring, repetitive parts of your job to AI instead of doing them by hand.',
                    'Let Claude write, test and fix the code while you stay in charge and steer.',
                    'Put what you built online so your team can actually use it &mdash; not just a demo.',
                ),
            ),
            // WSQ Agentic AI Automation with n8n — webhooks + RAG -> real agentic apps.
            'TGS-2023035977' => array(
                // n8n brand pink/red.
                'accent' => array('#ea4b71', '#fdeaef', '#f7c9d5'),
                'logo'   => 'n8n',
                'hook' => 'Wire up real agentic AI with n8n — use webhooks and RAG to build assistants and automations that act on your own data, no heavy coding.',
                'outcomes' => array(
                    'Trigger AI workflows from anything with webhooks &mdash; a form, a chat, an app, an incoming email.',
                    'Ground your AI in your own documents with RAG, so it answers from your data, not guesswork.',
                    'Build a working agentic app end-to-end in class &mdash; not a slide, a running workflow.',
                    'Automate real business tasks &mdash; lead capture, support replies, report generation &mdash; while you sleep.',
                    'Leave with an n8n workflow you can plug into your own tools the very next day.',
                ),
            ),
        );
    }

    /**
     * Outcome-framed "what you'll walk out able to do" lines for the flyer funnel.
     * Each is a benefit the reader can picture, in plain English — NEVER a verbatim
     * lift of the syllabus, and NEVER the same generic lines on every flyer:
     *   1. curated flagship voice (best), else
     *   2. this course's OWN topics reframed into varied benefit lines, else
     *   3. a benefit-led generic frame (only when a course has no parseable topics).
     */
    protected function courseOutcomes($sku, $name, $topics = array())
    {
        $curated = $this->_curatedPitch();
        $key = trim((string) $sku);
        if (isset($curated[$key])) {
            return $curated[$key]['outcomes'];
        }

        // Reframe THIS course's topics — rotating frames so lines vary, and the
        // topic text is escaped (frames carry the only intentional entities).
        $frames = array(
            'Get properly hands-on with %s &mdash; you build it in class, not just watch a demo.',
            'Put %s to work on real scenarios in class, so it actually sticks.',
            'Walk out able to apply %s to your own projects the very next day.',
            'Go from &ldquo;heard of %s&rdquo; to &ldquo;done it&rdquo; in a single day.',
            'Turn %s from a buzzword into a skill you can show your manager.',
        );
        $h = function ($s) { return htmlspecialchars((string) $s, ENT_QUOTES, 'UTF-8'); };
        $lines = array();
        foreach (array_slice($topics, 0, 4) as $i => $t) {
            $lines[] = sprintf($frames[$i % count($frames)], $h($t));
        }
        if (count($lines) >= 3) {
            return $lines;
        }

        // Last resort — no usable topics. Still benefit-led (not the raw syllabus).
        return array(
            'Start from zero &mdash; no prior experience assumed, we build up from the basics.',
            'Learn by doing from hour one &mdash; hands-on practice, not slides you forget by Friday.',
            'Build something real in class you can put to work the very next day.',
            'Walk out with the confidence, the workflow and a project to keep going on your own.',
        );
    }

    /**
     * Persuasive hook line for the flyer hero. Curated flagship voice wins;
     * otherwise the course's own catalog blurb (already course-specific).
     */
    protected function courseHook($sku, $blurb)
    {
        $curated = $this->_curatedPitch();
        $key = trim((string) $sku);
        return isset($curated[$key]) ? $curated[$key]['hook'] : (string) $blurb;
    }

    /**
     * Parse the course-page topic titles (the `<h3 class="course-topic-h3">Topic N:
     * Title</h3>` structure) into short, clean noun phrases — the raw material the
     * outcome frames reshape into benefits. Strips the "Topic N:" prefix and common
     * filler openers so a frame reads naturally ("hands-on with Prompt Engineering",
     * not "hands-on with Introduction to Prompt Engineering").
     */
    protected function parseTopics($desc)
    {
        $topics = array();
        if ($desc !== '' && preg_match_all('#<h3[^>]*>(.*?)</h3>#is', $desc, $m)) {
            foreach ($m[1] as $t) {
                $t = html_entity_decode(strip_tags($t), ENT_QUOTES | ENT_HTML5, 'UTF-8');
                $t = trim(preg_replace('/^\s*Topic\s*\d+\s*[:.\-\x{2013}]?\s*/iu', '', $t));
                $t = trim(preg_replace('/^(Introduction to|Intro to|Getting Started with|Overview of|Understanding|Basics of|Fundamentals of|Working with)\s+/iu', '', $t));
                $t = preg_replace('/\s+/u', ' ', $t);
                if ($t !== '' && function_exists('mb_strlen') && mb_strlen($t) >= 3 && mb_strlen($t) <= 48) {
                    $topics[] = $t;
                }
            }
        }
        return $topics;
    }

    /** URL of the hosted QR image for this course (served by the public route). */
    public function qrUrl($courseUrl)
    {
        $base = rtrim(Mage::getStoreConfig('web/unsecure/base_url'), '/');
        return $base . '/newsletter-review/index/qr/u/' . rawurlencode(base64_encode($courseUrl));
    }

    /**
     * Full flyer HTML for one course. $mode = 'email' (table-safe, hosted QR) or
     * 'preview' (same markup — email clients degrade gracefully).
     */
    public function render($productId)
    {
        $c = $this->courseData($productId);
        if (!$c) {
            return '';
        }
        $h = function ($s) { return htmlspecialchars((string) $s, ENT_QUOTES, 'UTF-8'); };
        $price   = number_format($c['price'], 0);
        $qr      = $this->qrUrl($c['url']);
        $host    = preg_replace('#^www\.#', '', (string) parse_url(rtrim(Mage::getStoreConfig('web/unsecure/base_url'), '/'), PHP_URL_HOST));
        $duration = $c['duration'] ? $h($c['duration']) . ' hrs' : '1 day &middot; 8 hrs';
        $sans    = "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif";
        $mono    = "ui-monospace,Menlo,Consolas,monospace";
        // Per-course accent (default blue; flagship courses override — see _curatedPitch).
        $accent   = isset($c['accent'])    ? $c['accent']    : '#2563eb';
        $accentBg = isset($c['accent_bg']) ? $c['accent_bg'] : '#eaf0fe';
        $accentBr = isset($c['accent_br']) ? $c['accent_br'] : '#c7d7fe';

        // Persuasive hook — real per-course marketing copy. Flagship SKUs get a
        // curated angle (kept in one place with the outcomes); everything else uses
        // the first ~2 sentences of the course blurb, NOT the factual syllabus.
        $hook = $this->courseHook($c['sku'], (string) $c['blurb']);
        if (function_exists('mb_strlen') && mb_strlen($hook) > 210) {
            $cut = mb_substr($hook, 0, 210);
            $lastDot = mb_strrpos($cut, '. ');
            $hook = ($lastDot !== false && $lastDot > 90) ? mb_substr($cut, 0, $lastDot + 1) : rtrim($cut, " ,;:") . '&hellip;';
        }

        // ---- FUNNEL: the offer, stated in the hero ---------------------------------
        // Price-drop strip (anchor -> nett -> S$0) shown right under the headline so
        // the value story lands before anything else. WSQ-only; numbers match the
        // detailed breakdown card below.
        $feeF = (float) $c['price'];
        $offerHtml = '';
        if ($c['is_wsq'] && $feeF > 0) {
            $gstF  = $feeF * 0.09;
            $n40   = ($feeF - $feeF * 0.70) + $gstF;
            $offerHtml = '<table role="presentation" width="100%" style="margin-top:18px;"><tr>'
                . '<td class="fl-stack" style="padding:0 10px 6px 0;"><span style="font:600 13.5px ' . $sans . ';color:#8fa1c6;"><s>S$' . number_format($feeF + $gstF, 0) . ' w/GST</s></span></td>'
                . '<td class="fl-stack" style="padding:0 10px 6px 0;"><span style="display:inline-block;font:800 15px ' . $sans . ';color:#fff;background:#1d4ed8;padding:7px 13px;border-radius:999px;white-space:nowrap;">S$' . number_format($n40, 0) . ' nett &middot; age 40+</span></td>'
                . '<td class="fl-stack" style="padding-bottom:6px;"><span style="font:700 12.5px ' . $sans . ';color:#7dd3fc;">as low as S$0 with SkillsFuture Credit</span></td>'
                . '</tr></table>';
        }

        // ---- FUNNEL: value stack — outcome-framed "what you'll walk out able to do" -
        // Benefit lines the reader can picture, not the course-page syllabus. See
        // courseOutcomes(): curated per flagship SKU, benefit-led generic fallback.
        $learnHtml = '';
        if (!empty($c['outcomes'])) {
            $lrows = '';
            foreach ($c['outcomes'] as $line) {
                $lrows .= '<tr>'
                    . '<td width="24" valign="top" style="padding:0 12px 13px 0;"><span style="display:inline-block;width:20px;height:20px;line-height:20px;text-align:center;border-radius:999px;background:#e6edff;color:#1d4ed8;font:800 12px ' . $sans . ';">&#10003;</span></td>'
                    . '<td style="font:600 14px/1.5 ' . $sans . ';color:#0a1020;padding-bottom:13px;">' . $line . '</td>'
                    . '</tr>';
            }
            $cert = $c['is_wsq']
                ? 'Finish the day and walk away with a <b style="color:#0a1020;">WSQ Statement of Attainment</b> &mdash; and an app you actually built.'
                : 'Finish the day and walk away with a certificate &mdash; and something you actually built.';
            $learnHtml = '<tr><td style="padding:24px 30px 8px;">'
                . '<div style="font:800 13px ' . $sans . ';text-transform:uppercase;letter-spacing:.8px;color:' . $accent . ';margin-bottom:16px;">What you&rsquo;ll walk out able to do</div>'
                . '<table role="presentation" width="100%" cellpadding="0" cellspacing="0">' . $lrows . '</table>'
                . '<div style="font:600 12.5px ' . $sans . ';color:#42506a;margin-top:2px;">' . $cert . '</div>'
                . '</td></tr>';
        }

        // ---- FUNNEL: friction-killer — how the funding works, in 3 steps -----------
        $stepsHtml = '';
        if ($c['is_wsq']) {
            $steps = array(
                array('1', 'Pick a date &amp; register', 'Reserve your seat on the course page in 2 minutes.'),
                array('2', 'Funding applied up front', 'Pay only the nett fee &mdash; WSQ funding is deducted at registration.'),
                array('3', 'Offset the rest', 'Use your SkillsFuture Credit for the balance &mdash; down to S$0 cash.'),
            );
            $srow = '';
            foreach ($steps as $s) {
                $srow .= '<td width="33%" valign="top" class="fl-stack" style="padding:0 12px 0 0;">'
                    . '<div style="font:800 12px ' . $sans . ';color:#fff;background:' . $accent . ';width:22px;height:22px;line-height:22px;text-align:center;border-radius:999px;">' . $s[0] . '</div>'
                    . '<div style="font:800 13.5px ' . $sans . ';color:#0a1020;margin-top:8px;">' . $s[1] . '</div>'
                    . '<div style="font:400 12.5px/1.5 ' . $sans . ';color:#42506a;margin-top:4px;">' . $s[2] . '</div>'
                    . '</td>';
            }
            $stepsHtml = '<tr><td style="padding:20px 30px 6px;">'
                . '<div style="font:800 13px ' . $sans . ';text-transform:uppercase;letter-spacing:.8px;color:' . $accent . ';margin-bottom:14px;">How your funding works</div>'
                . '<table role="presentation" width="100%"><tr>' . $srow . '</tr></table>'
                . '</td></tr>';
        }

        $badgeColors = array(
            'WSQ'=>'#1d4ed8;#e6edff','SkillsFuture Credit'=>'#a15c00;#fdf0da','PSEA'=>'#0e7490;#dcf5fb',
            'UTAP'=>'#7c3aed;#efe7fe','SFEC'=>'#047857;#d8f5e7','MCES'=>'#b91c1c;#fde5e5',
            'Absentee Payroll'=>'#475569;#eef2f7','IBF'=>'#1d4ed8;#e6edff','HRDF'=>'#a15c00;#fdf0da',
        );
        $badgesHtml = '';
        foreach ($c['badges'] as $b) {
            list($fg,$bg) = array_pad(explode(';', isset($badgeColors[$b]) ? $badgeColors[$b] : '#475569;#eef2f7'), 2, '#eef2f7');
            $badgesHtml .= '<td class="fl-badge" style="padding:0 8px 8px 0;"><span style="display:inline-block;font:700 11.5px/1 ' . $sans . ';color:' . $fg . ';background:' . $bg . ';padding:6px 11px;border-radius:999px;">' . $h($b) . '</span></td>';
        }

        // ---- Next intakes (upcoming class dates) ----------------------------------
        $scheduleHtml = '';
        if (!empty($c['runs'])) {
            $rowsHtml = '';
            foreach ($c['runs'] as $rn) {
                $ts = strtotime((string) $rn['course_start_date']);
                if (!$ts) { continue; }
                $dateTxt = date('D, j M Y', $ts);
                $timeTxt = !empty($rn['course_start_time']) ? date('g:ia', strtotime((string) $rn['course_start_time'])) : '';
                $rowsHtml .= '<td style="padding:0 10px 0 0;"><table role="presentation" style="background:#eef2f7;border:1px solid #d7e0ee;border-radius:10px;"><tr><td style="padding:10px 14px;">'
                    . '<div style="font:800 14px ' . $sans . ';color:#0a1020;">' . $h($dateTxt) . '</div>'
                    . ($timeTxt ? '<div style="font:600 11.5px ' . $sans . ';color:#7c8aa3;margin-top:2px;">' . $h($timeTxt) . '</div>' : '')
                    . '</td></tr></table></td>';
            }
            if ($rowsHtml) {
                $scheduleHtml = '<tr><td style="padding:16px 30px 4px;">'
                    . '<div style="font:800 13px ' . $sans . ';text-transform:uppercase;letter-spacing:.8px;color:' . $accent . ';margin-bottom:12px;">Upcoming intakes &mdash; seats filling</div>'
                    . '<table role="presentation"><tr>' . $rowsHtml . '</tr></table></td></tr>';
            }
        }

        // ---- Fee-after-funding breakdown (WSQ only) — the appealing money story -----
        // GST 9% settles on the full list price (CLAUDE.md). WSQ funding: baseline 50%,
        // + MCES 20% = 70% for Singaporeans aged 40+. SkillsFuture Credit covers the rest.
        $fundingHtml = '';
        $fee = (float) $c['price'];
        if ($c['is_wsq'] && $fee > 0) {
            $gst   = $fee * 0.09;
            $sub70 = $fee * 0.70;   // MCES, age 40+
            $net40 = ($fee - $sub70) + $gst;   // nett payable, 40+
            $net50 = ($fee - $fee * 0.50) + $gst; // nett payable, below 40
            $m = function ($n) { return 'S$' . number_format($n, 2); };
            $frow = function ($label, $val, $strong = false) use ($sans) {
                $c1 = $strong ? '#eaf0ff' : '#aebbd8';
                $c2 = $strong ? '#ffffff' : '#eaf0ff';
                $fw = $strong ? '800' : '400';
                return '<tr>'
                    . '<td style="padding:5px 0;font:' . $fw . ' 13.5px ' . $sans . ';color:' . $c1 . ';">' . $label . '</td>'
                    . '<td align="right" style="padding:5px 0;font:' . $fw . ' 13.5px ' . $sans . ';color:' . $c2 . ';">' . $val . '</td>'
                    . '</tr>';
            };
            $fundingHtml = '<tr><td style="padding:8px 30px 18px;">'
                . '<table role="presentation" width="100%" style="background:#0a1020;border-radius:14px;"><tr><td style="padding:20px 22px;">'
                . '<div style="font:800 10.5px ' . $sans . ';letter-spacing:1.2px;text-transform:uppercase;color:#22d3ee;margin-bottom:14px;">Your fee after funding &mdash; Singaporeans aged 40+</div>'
                . '<table role="presentation" width="100%" style="border-collapse:collapse;">'
                . $frow('Full course fee', $m($fee))
                . $frow('GST (9%)', '+ ' . $m($gst))
                . $frow('Less WSQ funding (70%, MCES)', '&minus; ' . $m($sub70))
                . '<tr><td colspan="2" style="border-top:1px solid #22345c;padding-top:4px;"></td></tr>'
                . $frow('Nett payable (age 40+)', $m($net40), true)
                . '</table>'
                . '<div style="margin-top:14px;background:#12203f;border:1px solid #22345c;border-radius:10px;padding:12px 14px;font:600 13px/1.5 ' . $sans . ';color:#7dd3fc;">Then claim the balance with your <b style="color:#fff;">SkillsFuture Credit</b> &mdash; pay as little as <b style="color:#fff;">S$0</b> out of pocket.</div>'
                . '<div style="margin-top:10px;font:400 11.5px ' . $sans . ';color:#8fa1c6;">Below age 40: 50% WSQ funding &rarr; nett payable ' . $m($net50) . '. Funding subject to eligibility.</div>'
                . '</td></tr></table></td></tr>';
        }

        // Lead magnet — the low-commitment offer that captures the not-yet-ready reader
        // (lead-magnets skill: SG's #1 hook is the SkillsFuture/WSQ funding check + syllabus).
        // Links to the course page enquiry form with a tag so the lead source is trackable.
        $leadUrl   = $c['url'] . (strpos($c['url'], '?') === false ? '?' : '&') . 'lead=funding';
        $fundLabel = $c['is_wsq'] ? 'SkillsFuture / WSQ funding' : 'funding';

        // NOTE: email-safe by design — solid colors only, no gradient-clip text or CSS
        // masks (they render invisible in Gmail/Outlook), HTML entities for punctuation so
        // it renders regardless of the client charset. This fragment is wrapped into a full
        // <html> document + unsubscribe link by Helper_Mailerlite before sending.
        // Responsive block — the ONE allowed <style> in the fragment. The flyer's
        // multi-column rows (offer strip, facts, funding steps, CTA+QR) have a
        // combined min-width around 500px and clip on phones; under 480px they
        // stack to a single column. Modern mobile clients (Gmail apps, iOS Mail)
        // honour embedded media queries; clients that strip it just show the
        // desktop layout, which is the safe fallback.
        return '<!-- Agentic flyer -->'
        . '<style>@media only screen and (max-width:480px){'
        .   '.fl-hero{padding:26px 20px 24px !important;}'
        .   '.fl-h1{font-size:24px !important;}'
        .   '.fl-stack{display:block !important;width:100% !important;box-sizing:border-box !important;padding-right:0 !important;}'
        .   '.fl-stack+.fl-stack{padding-top:12px !important;}'
        .   '.fl-fact{display:block !important;width:100% !important;box-sizing:border-box !important;border-right:0 !important;border-bottom:1px solid #e4e9f0;}'
        .   '.fl-qr{padding-top:18px !important;text-align:left !important;}'
        .   '.fl-badge{display:inline-block !important;}'
        . '}</style>'
        . '<div style="background:#eef2f7;padding:28px 12px;font-family:' . $sans . ';">'
        . '<table role="presentation" width="640" cellpadding="0" cellspacing="0" align="center" style="max-width:640px;width:100%;background:#ffffff;border:1px solid #e4e9f0;border-radius:20px;overflow:hidden;">'
        // brand bar (mark + name + funded pill)
        . '<tr><td style="padding:14px 22px;border-bottom:1px solid #e4e9f0;">'
        .   '<table role="presentation" width="100%"><tr>'
        .     '<td><table role="presentation"><tr>'
        .       '<td style="padding-right:10px;"><span style="display:inline-block;width:30px;height:30px;line-height:30px;text-align:center;border-radius:8px;background:' . $accent . ';color:#fff;font:800 16px ' . $sans . ';">T</span></td>'
        .       '<td style="font:600 15px ' . $sans . ';color:#0a1020;">Tertiary Courses <b style="font-weight:800;">Singapore</b></td>'
        .     '</tr></table></td>'
        .     '<td align="right"><span style="font:700 10.5px ' . $sans . ';letter-spacing:.9px;text-transform:uppercase;color:' . $accent . ';background:' . $accentBg . ';border:1px solid ' . $accentBr . ';padding:5px 10px;border-radius:999px;">WSQ &middot; SkillsFuture Funded</span></td>'
        .   '</tr></table>'
        . '</td></tr>'
        // hero — headline, hook, the OFFER (price drop) and a first CTA: the funnel
        // opens with the full value story instead of burying the price at the bottom
        . '<tr><td class="fl-hero" style="background:#0a1020;padding:34px 30px 30px;">'
        .   (!empty($c['logo']) ? '<div style="margin-bottom:16px;"><span style="display:inline-block;font:800 20px ' . $sans . ';color:' . $accent . ';background:#ffffff;padding:6px 13px;border-radius:9px;letter-spacing:-.5px;">' . $h($c['logo']) . '</span></div>' : '')
        .   '<div style="font:700 11px ' . $sans . ';letter-spacing:1.6px;text-transform:uppercase;color:#22d3ee;margin-bottom:14px;">Hands-on Workshop &middot; 1 Day' . ($c['is_wsq'] ? ' &middot; Up to 70% Funded' : '') . '</div>'
        .   '<h1 class="fl-h1" style="margin:0;font:800 31px/1.12 ' . $sans . ';color:#ffffff;letter-spacing:-.6px;">' . $h($c['name']) . '</h1>'
        .   ($hook ? '<div style="margin:16px 0 0;font:400 14.5px/1.55 ' . $sans . ';color:#b7c4e0;max-width:54ch;">' . $h($hook) . '</div>' : '')
        .   $offerHtml
        .   '<a href="' . $h($c['url']) . '" style="display:inline-block;margin-top:16px;background:' . $accent . ';color:#fff;text-decoration:none;font:700 14px ' . $sans . ';padding:12px 22px;border-radius:10px;">Claim my funded seat &rarr;</a>'
        .   '<div style="margin-top:18px;font:400 12.5px ' . $mono . ';letter-spacing:1px;color:#9fb3d8;background:#12203f;border:1px solid #22345c;display:inline-block;padding:6px 12px;border-radius:8px;">' . $h($c['sku']) . '</div>'
        . '</td></tr>'
        // facts
        . '<tr><td style="background:#eef2f7;border-bottom:1px solid #e4e9f0;">'
        .   '<table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr>'
        .     '<td width="33%" class="fl-fact" style="padding:16px 20px;border-right:1px solid #e4e9f0;"><div style="font:700 10.5px ' . $sans . ';letter-spacing:.8px;text-transform:uppercase;color:#7c8aa3;">Duration</div><div style="font:800 17px ' . $sans . ';color:#0a1020;margin-top:4px;">' . $duration . '</div></td>'
        .     '<td width="33%" class="fl-fact" style="padding:16px 20px;border-right:1px solid #e4e9f0;"><div style="font:700 10.5px ' . $sans . ';letter-spacing:.8px;text-transform:uppercase;color:#7c8aa3;">Format</div><div style="font:800 17px ' . $sans . ';color:#0a1020;margin-top:4px;">Classroom</div></td>'
        .     '<td width="34%" class="fl-fact" style="padding:16px 20px;"><div style="font:700 10.5px ' . $sans . ';letter-spacing:.8px;text-transform:uppercase;color:#7c8aa3;">Full Fee</div><div style="font:800 17px ' . $sans . ';color:#0a1020;margin-top:4px;">S$' . $price . '<small style="font:600 11px ' . $sans . ';color:#7c8aa3;margin-left:2px;">+GST</small></div></td>'
        .   '</tr></table>'
        . '</td></tr>'
        // FUNNEL body: value stack -> urgency -> friction-killer -> proof of the offer
        . $learnHtml
        // upcoming intakes (next 2 class dates)
        . $scheduleHtml
        // how funding works (3 steps)
        . $stepsHtml
        // fee-after-funding breakdown (WSQ)
        . $fundingHtml
        // funding badges
        . ($badgesHtml ? '<tr><td style="padding:14px 30px 8px;"><div style="font:700 12px ' . $sans . ';text-transform:uppercase;letter-spacing:.7px;color:#7c8aa3;margin-bottom:12px;">Offset your fee with</div><table role="presentation"><tr>' . $badgesHtml . '</tr></table></td></tr>' : '')
        // CTA + QR
        . '<tr><td style="background:#0a1020;padding:26px 30px;">'
        .   '<table role="presentation" width="100%"><tr>'
        .     '<td valign="middle">'
        .       '<div style="font:700 10.5px ' . $sans . ';letter-spacing:1.2px;text-transform:uppercase;color:#22d3ee;">Seats are limited</div>'
        .       '<div style="font:800 22px ' . $sans . ';color:#fff;margin-top:6px;">Scan to register</div>'
        .       '<div style="font:400 13px/1.5 ' . $sans . ';color:#aebbd8;margin-top:8px;max-width:34ch;">Point your phone camera at the code, or visit the course page.</div>'
        .       '<a href="' . $h($c['url']) . '" style="display:inline-block;margin-top:16px;background:' . $accent . ';color:#fff;text-decoration:none;font:700 14px ' . $sans . ';padding:11px 20px;border-radius:10px;">Register now &rarr;</a>'
        .       '<div style="font:400 12px ' . $mono . ';color:#8fa1c6;margin-top:12px;">' . $h($host) . '</div>'
        .     '</td>'
        .     '<td width="154" align="right" valign="middle" class="fl-stack fl-qr"><table role="presentation" style="background:#fff;border-radius:14px;"><tr><td style="padding:12px;" align="center"><img src="' . $h($qr) . '" width="130" height="130" alt="Scan to register" style="display:block;border-radius:6px;"><div style="font:400 10px ' . $mono . ';letter-spacing:.6px;color:#64748b;margin-top:8px;">' . $h($c['sku']) . '</div></td></tr></table></td>'
        .   '</tr></table>'
        . '</td></tr>'
        // lead magnet band — the funnel's fallback path for the not-yet-ready reader,
        // placed AFTER the primary CTA so it catches whoever didn't convert above
        . '<tr><td style="padding:18px 30px 22px;">'
        .   '<table role="presentation" width="100%" style="background:#eff4ff;border:1px solid ' . $accentBr . ';border-radius:14px;"><tr><td style="padding:20px 22px;">'
        .     '<div style="font:800 10.5px ' . $sans . ';letter-spacing:1.2px;text-transform:uppercase;color:' . $accent . ';">Free &middot; No obligation</div>'
        .     '<div style="font:800 18px/1.25 ' . $sans . ';color:#0a1020;margin-top:6px;">Not ready to enrol? Check your ' . $fundLabel . ' first</div>'
        .     '<div style="font:400 13.5px/1.55 ' . $sans . ';color:#42506a;margin-top:8px;max-width:56ch;">See exactly how much you can claim and get the full course syllabus emailed to you &mdash; free, in under a minute.</div>'
        .     '<a href="' . $h($leadUrl) . '" style="display:inline-block;margin-top:14px;background:#ffffff;color:#1d4ed8;text-decoration:none;font:700 13.5px ' . $sans . ';padding:10px 18px;border-radius:9px;border:1.5px solid ' . $accent . ';">Check my funding &amp; get the syllabus &rarr;</a>'
        .   '</td></tr></table>'
        . '</td></tr>'
        // footer (two lines, matches approved artifact)
        . '<tr><td style="background:#0a1020;padding:14px 22px;border-top:1px solid #1c2740;font:400 11px/1.7 ' . $sans . ';color:#8593ad;">Tertiary Infotech Academy Pte Ltd &middot; UEN 201200696W<br>+65 6100 0613 &middot; enquiry@tertiaryinfotech.com</td></tr>'
        // HARD RULE (admin, 2026-07-04): EVERY flyer design carries the standard
        // MailerLite unsubscribe footer with the {$unsubscribe} merge tag, so the
        // preview, the approval email, and the blast all show the real footer.
        // Helper_Mailerlite::_wrapEmailHtml() keeps a safety net for non-flyer HTML
        // and refuses to send without it. Do not remove this row.
        . '<tr><td align="center" style="background:#eef2f7;padding:16px 14px;font:400 11px/1.6 ' . $sans . ';color:#8593ad;">'
        .   'You are receiving this because you subscribed to Tertiary Courses updates.<br>'
        .   '<a href="{$unsubscribe}" style="color:' . $accent . ';">Unsubscribe</a>'
        . '</td></tr>'
        . '</table></div>';
    }
}
