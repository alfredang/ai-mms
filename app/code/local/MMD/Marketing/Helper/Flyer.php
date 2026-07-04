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
        // Collapse Unicode whitespace (Microsoft-paste NBSP/U+202F — see memory
        // feedback_short_description_unicode_whitespace) so the trim is clean.
        $blurb = trim(preg_replace('/\s+/u', ' ', strip_tags((string) ($raw('short_description') ?: $raw('meta_description')))));

        // Next 2 upcoming class intakes (real course_runs data) — drives urgency + signup.
        $runs = array();
        try {
            $rc  = Mage::getSingleton('core/resource');
            $runs = $rc->getConnection('core_read')->fetchAll(
                'SELECT course_start_date, course_start_time, course_end_date FROM '
              . $rc->getTableName('course_runs')
              . ' WHERE product_id = ? AND course_start_date >= CURDATE()'
              . ' ORDER BY course_start_date ASC LIMIT 2',
                array((int) $productId)
            );
        } catch (Exception $e) { /* runs optional */ }

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
        );
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

        // Persuasive hook — real per-course marketing copy (first ~2 sentences of the
        // course blurb), NOT the factual syllabus. Drives the "why take this" story.
        $hook = (string) $c['blurb'];
        if (function_exists('mb_strlen') && mb_strlen($hook) > 210) {
            $cut = mb_substr($hook, 0, 210);
            $lastDot = mb_strrpos($cut, '. ');
            $hook = ($lastDot !== false && $lastDot > 90) ? mb_substr($cut, 0, $lastDot + 1) : rtrim($cut, " ,;:") . '&hellip;';
        }

        // Benefit / outcome value-props — data-driven, truthful, not spec regurgitation.
        $props = array(
            'Hands-on and practical &mdash; build skills you can apply the very next day',
            'Learn from experienced industry trainers in a small, focused class',
        );
        $props[] = $c['is_wsq']
            ? 'WSQ-recognised &mdash; earn a Statement of Attainment on completion'
            : 'Earn an industry-recognised certificate of completion';
        if ($c['is_wsq']) {
            $props[] = 'Up to 70% WSQ / SkillsFuture funding for eligible Singaporeans';
        } elseif (!empty($c['badges'])) {
            $props[] = 'Funding support available &mdash; ' . $h(implode(', ', array_slice($c['badges'], 0, 3)));
        }
        $propsHtml = '';
        foreach ($props as $p) {
            $propsHtml .= '<tr>'
                . '<td width="18" valign="top" style="padding:0 10px 12px 0;"><span style="display:inline-block;width:9px;height:9px;border-radius:3px;background:#2563eb;margin-top:5px;"></span></td>'
                . '<td style="font:400 14px/1.5 ' . $sans . ';color:#42506a;padding-bottom:12px;">' . $p . '</td>'
                . '</tr>';
        }

        $badgeColors = array(
            'WSQ'=>'#1d4ed8;#e6edff','SkillsFuture Credit'=>'#a15c00;#fdf0da','PSEA'=>'#0e7490;#dcf5fb',
            'UTAP'=>'#7c3aed;#efe7fe','SFEC'=>'#047857;#d8f5e7','MCES'=>'#b91c1c;#fde5e5',
            'Absentee Payroll'=>'#475569;#eef2f7','IBF'=>'#1d4ed8;#e6edff','HRDF'=>'#a15c00;#fdf0da',
        );
        $badgesHtml = '';
        foreach ($c['badges'] as $b) {
            list($fg,$bg) = array_pad(explode(';', isset($badgeColors[$b]) ? $badgeColors[$b] : '#475569;#eef2f7'), 2, '#eef2f7');
            $badgesHtml .= '<td style="padding:0 8px 8px 0;"><span style="display:inline-block;font:700 11.5px/1 ' . $sans . ';color:' . $fg . ';background:' . $bg . ';padding:6px 11px;border-radius:999px;">' . $h($b) . '</span></td>';
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
                    . '<div style="font:800 13px ' . $sans . ';text-transform:uppercase;letter-spacing:.8px;color:#2563eb;margin-bottom:12px;">Upcoming intakes &mdash; seats filling</div>'
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
        return '<!-- Agentic flyer -->'
        . '<div style="background:#eef2f7;padding:28px 12px;font-family:' . $sans . ';">'
        . '<table role="presentation" width="640" cellpadding="0" cellspacing="0" align="center" style="max-width:640px;width:100%;background:#ffffff;border:1px solid #e4e9f0;border-radius:20px;overflow:hidden;">'
        // brand bar (mark + name + funded pill)
        . '<tr><td style="padding:14px 22px;border-bottom:1px solid #e4e9f0;">'
        .   '<table role="presentation" width="100%"><tr>'
        .     '<td><table role="presentation"><tr>'
        .       '<td style="padding-right:10px;"><span style="display:inline-block;width:30px;height:30px;line-height:30px;text-align:center;border-radius:8px;background:#2563eb;color:#fff;font:800 16px ' . $sans . ';">T</span></td>'
        .       '<td style="font:600 15px ' . $sans . ';color:#0a1020;">Tertiary Courses <b style="font-weight:800;">Singapore</b></td>'
        .     '</tr></table></td>'
        .     '<td align="right"><span style="font:700 10.5px ' . $sans . ';letter-spacing:.9px;text-transform:uppercase;color:#2563eb;background:#eaf0fe;border:1px solid #c7d7fe;padding:5px 10px;border-radius:999px;">WSQ &middot; SkillsFuture Funded</span></td>'
        .   '</tr></table>'
        . '</td></tr>'
        // hero + persuasive hook
        . '<tr><td style="background:#0a1020;padding:34px 30px 30px;">'
        .   '<div style="font:700 11px ' . $sans . ';letter-spacing:1.6px;text-transform:uppercase;color:#22d3ee;margin-bottom:14px;">Hands-on Workshop</div>'
        .   '<h1 style="margin:0;font:800 31px/1.12 ' . $sans . ';color:#ffffff;letter-spacing:-.6px;">' . $h($c['name']) . '</h1>'
        .   ($hook ? '<div style="margin:16px 0 0;font:400 14.5px/1.55 ' . $sans . ';color:#b7c4e0;max-width:54ch;">' . $h($hook) . '</div>' : '')
        .   '<div style="margin-top:20px;font:400 12.5px ' . $mono . ';letter-spacing:1px;color:#9fb3d8;background:#12203f;border:1px solid #22345c;display:inline-block;padding:6px 12px;border-radius:8px;">' . $h($c['sku']) . '</div>'
        . '</td></tr>'
        // facts
        . '<tr><td style="background:#eef2f7;border-bottom:1px solid #e4e9f0;">'
        .   '<table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr>'
        .     '<td width="33%" style="padding:16px 20px;border-right:1px solid #e4e9f0;"><div style="font:700 10.5px ' . $sans . ';letter-spacing:.8px;text-transform:uppercase;color:#7c8aa3;">Duration</div><div style="font:800 17px ' . $sans . ';color:#0a1020;margin-top:4px;">' . $duration . '</div></td>'
        .     '<td width="33%" style="padding:16px 20px;border-right:1px solid #e4e9f0;"><div style="font:700 10.5px ' . $sans . ';letter-spacing:.8px;text-transform:uppercase;color:#7c8aa3;">Format</div><div style="font:800 17px ' . $sans . ';color:#0a1020;margin-top:4px;">Classroom / Live Online</div></td>'
        .     '<td width="34%" style="padding:16px 20px;"><div style="font:700 10.5px ' . $sans . ';letter-spacing:.8px;text-transform:uppercase;color:#7c8aa3;">Full Fee</div><div style="font:800 17px ' . $sans . ';color:#0a1020;margin-top:4px;">S$' . $price . '<small style="font:600 11px ' . $sans . ';color:#7c8aa3;margin-left:2px;">+GST</small></div></td>'
        .   '</tr></table>'
        . '</td></tr>'
        // why take this course (benefits)
        . '<tr><td style="padding:24px 30px 8px;">'
        .   '<div style="font:800 13px ' . $sans . ';text-transform:uppercase;letter-spacing:.8px;color:#2563eb;margin-bottom:16px;">Why take this course</div>'
        .   '<table role="presentation" width="100%" cellpadding="0" cellspacing="0">' . $propsHtml . '</table>'
        . '</td></tr>'
        // upcoming intakes (next 2 class dates)
        . $scheduleHtml
        // fee-after-funding breakdown (WSQ)
        . $fundingHtml
        // funding badges
        . ($badgesHtml ? '<tr><td style="padding:14px 30px 8px;"><div style="font:700 12px ' . $sans . ';text-transform:uppercase;letter-spacing:.7px;color:#7c8aa3;margin-bottom:12px;">Offset your fee with</div><table role="presentation"><tr>' . $badgesHtml . '</tr></table></td></tr>' : '')
        // lead magnet band
        . '<tr><td style="padding:16px 30px 22px;">'
        .   '<table role="presentation" width="100%" style="background:#eff4ff;border:1px solid #c7d7fe;border-radius:14px;"><tr><td style="padding:20px 22px;">'
        .     '<div style="font:800 10.5px ' . $sans . ';letter-spacing:1.2px;text-transform:uppercase;color:#2563eb;">Free &middot; No obligation</div>'
        .     '<div style="font:800 18px/1.25 ' . $sans . ';color:#0a1020;margin-top:6px;">Not ready to enrol? Check your ' . $fundLabel . ' first</div>'
        .     '<div style="font:400 13.5px/1.55 ' . $sans . ';color:#42506a;margin-top:8px;max-width:56ch;">See exactly how much you can claim and get the full course syllabus emailed to you &mdash; free, in under a minute.</div>'
        .     '<a href="' . $h($leadUrl) . '" style="display:inline-block;margin-top:14px;background:#ffffff;color:#1d4ed8;text-decoration:none;font:700 13.5px ' . $sans . ';padding:10px 18px;border-radius:9px;border:1.5px solid #2563eb;">Check my funding &amp; get the syllabus &rarr;</a>'
        .   '</td></tr></table>'
        . '</td></tr>'
        // CTA + QR
        . '<tr><td style="background:#0a1020;padding:26px 30px;">'
        .   '<table role="presentation" width="100%"><tr>'
        .     '<td valign="middle">'
        .       '<div style="font:700 10.5px ' . $sans . ';letter-spacing:1.2px;text-transform:uppercase;color:#22d3ee;">Seats are limited</div>'
        .       '<div style="font:800 22px ' . $sans . ';color:#fff;margin-top:6px;">Scan to register</div>'
        .       '<div style="font:400 13px/1.5 ' . $sans . ';color:#aebbd8;margin-top:8px;max-width:34ch;">Point your phone camera at the code, or visit the course page.</div>'
        .       '<a href="' . $h($c['url']) . '" style="display:inline-block;margin-top:16px;background:#2563eb;color:#fff;text-decoration:none;font:700 14px ' . $sans . ';padding:11px 20px;border-radius:10px;">Register now &rarr;</a>'
        .       '<div style="font:400 12px ' . $mono . ';color:#8fa1c6;margin-top:12px;">' . $h($host) . '</div>'
        .     '</td>'
        .     '<td width="154" align="right" valign="middle"><table role="presentation" style="background:#fff;border-radius:14px;"><tr><td style="padding:12px;" align="center"><img src="' . $h($qr) . '" width="130" height="130" alt="Scan to register" style="display:block;border-radius:6px;"><div style="font:400 10px ' . $mono . ';letter-spacing:.6px;color:#64748b;margin-top:8px;">' . $h($c['sku']) . '</div></td></tr></table></td>'
        .   '</tr></table>'
        . '</td></tr>'
        // footer (two lines, matches approved artifact)
        . '<tr><td style="background:#0a1020;padding:14px 22px;border-top:1px solid #1c2740;font:400 11px/1.7 ' . $sans . ';color:#8593ad;">Tertiary Infotech Academy Pte Ltd &middot; UEN 201200696W<br>+65 6100 0613 &middot; enquiry@tertiaryinfotech.com</td></tr>'
        . '</table></div>';
    }
}
