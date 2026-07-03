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

        return array(
            'id'        => $productId,
            'sku'       => $sku,
            'name'      => preg_replace('/^\s*WSQ\s*[-\x{2013}]\s*/iu', '', $name),
            'raw_name'  => $name,
            'price'     => (float) $raw('price'),
            'duration'  => $raw('duration'),
            'url'       => $courseUrl,
            'badges'    => $badges,
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
        $badgeColors = array(
            'WSQ'=>'#1d4ed8;#e6edff','SkillsFuture Credit'=>'#a15c00;#fdf0da','PSEA'=>'#0e7490;#dcf5fb',
            'UTAP'=>'#7c3aed;#efe7fe','SFEC'=>'#047857;#d8f5e7','MCES'=>'#b91c1c;#fde5e5',
            'Absentee Payroll'=>'#475569;#eef2f7','IBF'=>'#1d4ed8;#e6edff','HRDF'=>'#a15c00;#fdf0da',
        );
        $badgesHtml = '';
        foreach ($c['badges'] as $b) {
            list($fg,$bg) = array_pad(explode(';', isset($badgeColors[$b]) ? $badgeColors[$b] : '#475569;#eef2f7'), 2, '#eef2f7');
            $badgesHtml .= '<td style="padding:0 6px 6px 0;"><span style="display:inline-block;font:700 11.5px/1 -apple-system,Segoe UI,Arial,sans-serif;color:' . $fg . ';background:' . $bg . ';padding:6px 11px;border-radius:999px;">' . $h($b) . '</span></td>';
        }

        return '<!-- Agentic flyer -->'
        . '<div style="background:#eef2f7;padding:28px 12px;font-family:-apple-system,BlinkMacSystemFont,\'Segoe UI\',Roboto,Helvetica,Arial,sans-serif;">'
        . '<table role="presentation" width="640" cellpadding="0" cellspacing="0" align="center" style="max-width:640px;width:100%;background:#ffffff;border:1px solid #e4e9f0;border-radius:18px;overflow:hidden;">'
        // brand
        . '<tr><td style="padding:14px 22px;border-bottom:1px solid #e4e9f0;">'
        .   '<table role="presentation" width="100%"><tr>'
        .     '<td style="font:700 15px -apple-system,Segoe UI,Arial,sans-serif;color:#0a1020;">Tertiary Courses <b>Singapore</b></td>'
        .     '<td align="right"><span style="font:700 10.5px -apple-system,Segoe UI,Arial,sans-serif;letter-spacing:.9px;text-transform:uppercase;color:#2563eb;background:rgba(37,99,235,.09);padding:5px 10px;border-radius:999px;">WSQ · SkillsFuture Funded</span></td>'
        .   '</tr></table>'
        . '</td></tr>'
        // hero
        . '<tr><td style="background:#0a1020;padding:32px 30px;">'
        .   '<div style="font:700 11px -apple-system,Segoe UI,Arial,sans-serif;letter-spacing:1.6px;text-transform:uppercase;color:#22d3ee;margin-bottom:12px;">Hands-on Workshop</div>'
        .   '<h1 style="margin:0;font:800 32px/1.1 -apple-system,Segoe UI,Arial,sans-serif;color:#ffffff;letter-spacing:-.6px;">' . $h($c['name']) . '</h1>'
        .   '<div style="margin-top:18px;font:400 12.5px ui-monospace,Menlo,Consolas,monospace;color:#9fb3d8;background:rgba(120,160,255,.1);display:inline-block;padding:6px 12px;border-radius:8px;">' . $h($c['sku']) . '</div>'
        . '</td></tr>'
        // facts
        . '<tr><td style="background:#eef2f7;">'
        .   '<table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr>'
        .     '<td width="33%" style="padding:16px 20px;border-right:1px solid #e4e9f0;"><div style="font:700 10.5px -apple-system,Segoe UI,Arial,sans-serif;letter-spacing:.8px;text-transform:uppercase;color:#7c8aa3;">Duration</div><div style="font:800 17px -apple-system,Segoe UI,Arial,sans-serif;color:#0a1020;">' . ($c['duration'] ? $h($c['duration']) . ' hrs' : '1 day') . '</div></td>'
        .     '<td width="33%" style="padding:16px 20px;border-right:1px solid #e4e9f0;"><div style="font:700 10.5px -apple-system,Segoe UI,Arial,sans-serif;letter-spacing:.8px;text-transform:uppercase;color:#7c8aa3;">Format</div><div style="font:800 17px -apple-system,Segoe UI,Arial,sans-serif;color:#0a1020;">Classroom / Online</div></td>'
        .     '<td width="34%" style="padding:16px 20px;"><div style="font:700 10.5px -apple-system,Segoe UI,Arial,sans-serif;letter-spacing:.8px;text-transform:uppercase;color:#7c8aa3;">Full Fee</div><div style="font:800 17px -apple-system,Segoe UI,Arial,sans-serif;color:#0a1020;">S$' . $price . '</div></td>'
        .   '</tr></table>'
        . '</td></tr>'
        // funding
        . ($badgesHtml ? '<tr><td style="padding:22px 30px 6px;"><div style="font:700 12px -apple-system,Segoe UI,Arial,sans-serif;text-transform:uppercase;letter-spacing:.7px;color:#7c8aa3;margin-bottom:12px;">Offset your fee with</div><table role="presentation"><tr>' . $badgesHtml . '</tr></table></td></tr>' : '')
        // CTA + QR
        . '<tr><td style="background:#0a1020;padding:24px 30px;">'
        .   '<table role="presentation" width="100%"><tr>'
        .     '<td valign="middle">'
        .       '<div style="font:700 10.5px -apple-system,Segoe UI,Arial,sans-serif;letter-spacing:1.2px;text-transform:uppercase;color:#22d3ee;">Seats are limited</div>'
        .       '<div style="font:800 22px -apple-system,Segoe UI,Arial,sans-serif;color:#fff;margin-top:4px;">Scan to register</div>'
        .       '<a href="' . $h($c['url']) . '" style="display:inline-block;margin-top:14px;background:#2563eb;color:#fff;text-decoration:none;font:700 14px -apple-system,Segoe UI,Arial,sans-serif;padding:11px 20px;border-radius:10px;">Register now →</a>'
        .     '</td>'
        .     '<td width="150" align="right" valign="middle"><table role="presentation" style="background:#fff;border-radius:12px;"><tr><td style="padding:10px;" align="center"><img src="' . $h($qr) . '" width="130" height="130" alt="Scan to register" style="display:block;border-radius:6px;"><div style="font:400 10px ui-monospace,Menlo,monospace;color:#64748b;margin-top:6px;">' . $h($c['sku']) . '</div></td></tr></table></td>'
        .   '</tr></table>'
        . '</td></tr>'
        // footer
        . '<tr><td style="background:#0a1020;padding:14px 22px;border-top:1px solid #1c2740;font:400 11px -apple-system,Segoe UI,Arial,sans-serif;color:#8593ad;">Tertiary Infotech Academy Pte Ltd · UEN 201200696W · +65 6100 0613</td></tr>'
        . '</table></div>';
    }
}
