<?php
/**
 * LinkedIn auto-publish for the agentic flyer pipeline.
 *
 * Two responsibilities:
 *   1. renderCard($productId) — build a LinkedIn-optimised branded IMAGE card
 *      (1200x1200 PNG) for the course, entirely server-side with GD (no headless
 *      browser, no third-party): dark hero + title + funding story + next intakes
 *      + funding badges + the SELF-HOSTED QR composited in. LinkedIn needs a
 *      static image; the email flyer is HTML, so we draw a purpose-built card.
 *   2. postFlyer($productId) — publish that card to LinkedIn via the REST API,
 *      the same flow ai-cms uses for blog posts: POST /rest/images?action=
 *      initializeUpload -> PUT the bytes -> POST /rest/posts with the image URN.
 *
 * Credentials (mmd_marketing/linkedin/* in core_config_data, encrypted):
 *   access_token, author_urn (e.g. urn:li:person:xxxx). Reused from the same
 *   LinkedIn app ai-cms uses. Missing creds => isConfigured() false => the
 *   pipeline skips LinkedIn silently (never blocks MailerLite scheduling).
 */
class MMD_Marketing_Helper_Linkedin extends Mage_Core_Helper_Abstract
{
    const REST_BASE    = 'https://api.linkedin.com/rest';
    const REST_VERSION = '202604';   // bump every few quarters (YYYYMM)

    const CFG_TOKEN  = 'mmd_marketing/linkedin/access_token';
    const CFG_AUTHOR = 'mmd_marketing/linkedin/author_urn';
    // Optional organisation author (urn:li:organization:NNNN). When set AND the
    // token carries w_organization_social, the pipelines post to the company
    // page as well as the member feed. Empty = org posting silently skipped.
    const CFG_ORG    = 'mmd_marketing/linkedin/org_urn';
    // Company-page posts authenticate with the DEDICATED org app's token
    // (LinkedIn requires the Community Management API to be an app's only
    // product, so the org credential comes from a different app than the
    // member one). Core-encrypted. Falls back to the member token when unset.
    const CFG_ORG_TOKEN = 'mmd_marketing/linkedin/org_access_token';
    const CFG_ENABLED = 'mmd_marketing/linkedin/enabled';

    protected function _token()  { return trim((string) Mage::helper('core')->decrypt(Mage::getStoreConfig(self::CFG_TOKEN))); }
    protected function _author() { return trim((string) Mage::getStoreConfig(self::CFG_AUTHOR)); }
    public function orgUrn()     { return trim((string) Mage::getStoreConfig(self::CFG_ORG)); }
    protected function _orgToken()
    {
        $enc = trim((string) Mage::getStoreConfig(self::CFG_ORG_TOKEN));
        $dec = $enc !== '' ? trim((string) Mage::helper('core')->decrypt($enc)) : '';
        return $dec !== '' ? $dec : $this->_token();
    }

    public function isConfigured()
    {
        return (bool) (int) Mage::getStoreConfig(self::CFG_ENABLED)
            && $this->_token() !== '' && $this->_author() !== '';
    }

    protected function _font($bold = false)
    {
        $dir = Mage::getBaseDir() . '/vendor/mpdf/mpdf/ttfonts/';
        return $dir . ($bold ? 'DejaVuSansCondensed-Bold.ttf' : 'DejaVuSansCondensed.ttf');
    }

    protected function _hex($img, $hex)
    {
        $hex = ltrim($hex, '#');
        return imagecolorallocate($img, hexdec(substr($hex, 0, 2)), hexdec(substr($hex, 2, 2)), hexdec(substr($hex, 4, 2)));
    }

    /** Wrap $text to lines that fit within $maxW at the given font/size. */
    protected function _wrap($font, $size, $text, $maxW)
    {
        $words = preg_split('/\s+/', trim($text));
        $lines = array();
        $cur = '';
        foreach ($words as $w) {
            $try = $cur === '' ? $w : $cur . ' ' . $w;
            $bb = imagettfbbox($size, 0, $font, $try);
            if (($bb[2] - $bb[0]) > $maxW && $cur !== '') {
                $lines[] = $cur;
                $cur = $w;
            } else {
                $cur = $try;
            }
        }
        if ($cur !== '') { $lines[] = $cur; }
        return $lines;
    }

    protected function _text($img, $size, $x, $y, $color, $font, $text, $letterSpace = 0)
    {
        if ($letterSpace <= 0) {
            imagettftext($img, $size, 0, $x, $y, $color, $font, $text);
            return;
        }
        $cx = $x;
        foreach (preg_split('//u', $text, -1, PREG_SPLIT_NO_EMPTY) as $ch) {
            imagettftext($img, $size, 0, (int) $cx, $y, $color, $font, $ch);
            $bb = imagettfbbox($size, 0, $font, $ch);
            $cx += ($bb[2] - $bb[0]) + $letterSpace;
        }
    }

    /** Rounded filled rectangle. */
    protected function _roundRect($img, $x1, $y1, $x2, $y2, $r, $color)
    {
        imagefilledrectangle($img, $x1 + $r, $y1, $x2 - $r, $y2, $color);
        imagefilledrectangle($img, $x1, $y1 + $r, $x2, $y2 - $r, $color);
        imagefilledarc($img, $x1 + $r, $y1 + $r, $r * 2, $r * 2, 180, 270, $color, IMG_ARC_PIE);
        imagefilledarc($img, $x2 - $r, $y1 + $r, $r * 2, $r * 2, 270, 360, $color, IMG_ARC_PIE);
        imagefilledarc($img, $x1 + $r, $y2 - $r, $r * 2, $r * 2, 90, 180, $color, IMG_ARC_PIE);
        imagefilledarc($img, $x2 - $r, $y2 - $r, $r * 2, $r * 2, 0, 90, $color, IMG_ARC_PIE);
    }

    /** The self-hosted QR PNG bytes for a course URL (chillerlan, high-ECC). */
    protected function _qrPng($url)
    {
        try {
            $opt = new \chillerlan\QRCode\QROptions(array(
                'outputType'    => \chillerlan\QRCode\QRCode::OUTPUT_IMAGE_PNG,
                'eccLevel'      => \chillerlan\QRCode\QRCode::ECC_H,
                'scale'         => 12,
                'quietzoneSize' => 3,
                'imageBase64'   => false,
            ));
            return (new \chillerlan\QRCode\QRCode($opt))->render($url);
        } catch (Exception $e) { return ''; }
    }

    /**
     * Render the 1200x1200 LinkedIn card PNG for a course. Returns PNG bytes.
     */
    public function renderCard($productId)
    {
        $c = Mage::helper('mmd_marketing/flyer')->courseData($productId);
        if (!$c) { return ''; }

        $W = 1200; $H = 1200;
        $img = imagecreatetruecolor($W, $H);
        imagealphablending($img, true);

        $navy   = $this->_hex($img, '#0a1020');
        $navy2  = $this->_hex($img, '#12203f');
        $white  = $this->_hex($img, '#ffffff');
        $cyan   = $this->_hex($img, '#22d3ee');
        $blue   = $this->_hex($img, '#2563eb');
        $slate  = $this->_hex($img, '#aebbd8');
        $ink    = $this->_hex($img, '#0a1020');
        $mist   = $this->_hex($img, '#eef2f7');
        $muted  = $this->_hex($img, '#7c8aa3');

        // full dark background
        imagefilledrectangle($img, 0, 0, $W, $H, $navy);
        // bottom light panel
        imagefilledrectangle($img, 0, 830, $W, $H, $white);

        $reg = $this->_font(false);
        $bld = $this->_font(true);
        $pad = 80;

        // brand row
        $this->_roundRect($img, $pad, 70, $pad + 56, 126, 12, $blue);
        $this->_text($img, 26, $pad + 16, 110, $white, $bld, 'T');
        $this->_text($img, 22, $pad + 76, 108, $white, $bld, 'Tertiary Courses Singapore');
        // funded pill (right)
        $pillTxt = 'WSQ  ·  SKILLSFUTURE FUNDED';
        $bb = imagettfbbox(15, 0, $bld, $pillTxt);
        $pw = ($bb[2] - $bb[0]) + 44;
        $this->_roundRect($img, $W - $pad - $pw, 78, $W - $pad, 122, 22, $navy2);
        $this->_text($img, 15, $W - $pad - $pw + 22, 106, $cyan, $bld, $pillTxt);

        // eyebrow
        $eyebrow = '1-DAY HANDS-ON WORKSHOP' . ($c['is_wsq'] ? '  ·  UP TO 70% FUNDED' : '');
        $this->_text($img, 20, $pad, 210, $cyan, $bld, $eyebrow, 3);

        // title (wrapped)
        $title = (string) $c['name'];
        $tSize = 58;
        $lines = $this->_wrap($bld, $tSize, $title, $W - 2 * $pad);
        if (count($lines) > 3) { $tSize = 46; $lines = $this->_wrap($bld, $tSize, $title, $W - 2 * $pad); }
        $ty = 300;
        foreach (array_slice($lines, 0, 4) as $ln) {
            $this->_text($img, $tSize, $pad, $ty, $white, $bld, $ln);
            $ty += (int) ($tSize * 1.24);
        }

        // course code chip
        $codeY = $ty + 14;
        $bb = imagettfbbox(20, 0, $reg, $c['sku']);
        $cw = ($bb[2] - $bb[0]) + 40;
        $this->_roundRect($img, $pad, $codeY - 34, $pad + $cw, $codeY + 14, 10, $navy2);
        $this->_text($img, 20, $pad + 20, $codeY, $slate, $reg, $c['sku']);

        // offer strip (WSQ)
        $oy = $codeY + 90;
        $fee = (float) $c['price'];
        if ($c['is_wsq'] && $fee > 0) {
            $gst = $fee * 0.09; $net = ($fee - $fee * 0.70) + $gst;
            $anchor = 'S$' . number_format($fee + $gst, 0) . ' w/GST';
            $this->_text($img, 26, $pad, $oy, $slate, $reg, $anchor);
            $bb = imagettfbbox(26, 0, $reg, $anchor); $ax = $pad + ($bb[2] - $bb[0]);
            // strike-through
            imagefilledrectangle($img, $pad, $oy - 9, $ax, $oy - 6, $slate);
            $nettTxt = 'S$' . number_format($net, 0) . ' nett · age 40+';
            $bb2 = imagettfbbox(28, 0, $bld, $nettTxt); $nw = ($bb2[2] - $bb2[0]) + 44;
            $this->_roundRect($img, $ax + 30, $oy - 40, $ax + 30 + $nw, $oy + 14, 26, $blue);
            $this->_text($img, 28, $ax + 52, $oy, $white, $bld, $nettTxt);
            $this->_text($img, 22, $pad, $oy + 52, $cyan, $bld, 'As low as S$0 with your SkillsFuture Credit');
        }

        // next intakes
        $iy = $oy + 130;
        if (!empty($c['runs'])) {
            $this->_text($img, 18, $pad, $iy, $cyan, $bld, 'UPCOMING INTAKES', 2);
            $dates = array();
            foreach (array_slice($c['runs'], 0, 2) as $rn) {
                $ts = strtotime((string) $rn['course_start_date']);
                if ($ts) { $dates[] = date('D, j M Y', $ts); }
            }
            $this->_text($img, 26, $pad, $iy + 48, $white, $bld, implode('     ·     ', $dates));
        }

        // ---- bottom light panel: badges (left) + QR (right) ----
        // funding badges
        $bx = $pad; $by = 900;
        $this->_text($img, 18, $pad, $by, $muted, $bld, 'OFFSET YOUR FEE WITH', 2);
        $bx = $pad; $by = 950;
        $palette = array(
            'WSQ'=>'#1d4ed8','SkillsFuture Credit'=>'#a15c00','PSEA'=>'#0e7490','UTAP'=>'#7c3aed',
            'SFEC'=>'#047857','MCES'=>'#b91c1c','Absentee Payroll'=>'#475569','IBF'=>'#1d4ed8','HRDF'=>'#a15c00',
        );
        $rowW = 0; $lineH = 60;
        foreach (array_slice($c['badges'], 0, 8) as $b) {
            $bb = imagettfbbox(20, 0, $bld, $b); $w = ($bb[2] - $bb[0]) + 40;
            if ($bx + $w > 720) { $bx = $pad; $by += $lineH; }
            $col = $this->_hex($img, isset($palette[$b]) ? $palette[$b] : '#475569');
            imagesetthickness($img, 2);
            $this->_roundRect($img, $bx, $by - 34, $bx + $w, $by + 12, 22, $white);
            // outline
            $r=22;
            imagefilledrectangle($img, $bx, $by-34, $bx+$w, $by+12, $white);
            $this->_text($img, 20, $bx + 20, $by, $col, $bld, $b);
            $bx += $w + 16;
        }

        // QR (self-hosted) bottom-right
        $qr = $this->_qrPng($c['url']);
        if ($qr !== '') {
            $qrImg = imagecreatefromstring($qr);
            if ($qrImg) {
                $qs = 300; $qx = $W - $pad - $qs; $qy = 870;
                // white rounded frame
                $this->_roundRect($img, $qx - 20, $qy - 20, $qx + $qs + 20, $qy + $qs + 20, 18, $mist);
                imagecopyresampled($img, $qrImg, $qx, $qy, 0, 0, $qs, $qs, imagesx($qrImg), imagesy($qrImg));
                imagedestroy($qrImg);
                $this->_text($img, 18, $qx + 30, $qy + $qs + 54, $muted, $bld, 'SCAN TO REGISTER', 1);
            }
        }

        ob_start();
        imagepng($img);
        $png = ob_get_clean();
        imagedestroy($img);
        return $png;
    }

    /**
     * Publish the course card to LinkedIn. Returns ['ok'=>bool,'url'=>..,'msg'=>..].
     * Non-fatal by contract: any failure returns ok=false without throwing so the
     * approval pipeline continues (MailerLite scheduling must not depend on this).
     */
    public function postFlyer($productId, $commentary = '', $author = null)
    {
        if (!$this->isConfigured()) {
            return array('ok' => false, 'msg' => 'LinkedIn not configured');
        }
        // $author override lets callers post the same card as the organisation
        // (orgUrn()) instead of the member; image upload owner follows it, and
        // org posts sign with the org app's token.
        if ($author === null || $author === '') { $author = $this->_author(); }
        $token = ($author !== '' && $author === $this->orgUrn()) ? $this->_orgToken() : $this->_token();
        $c = Mage::helper('mmd_marketing/flyer')->courseData($productId);
        if (!$c) { return array('ok' => false, 'msg' => 'no course data'); }

        if ($commentary === '') {
            $commentary = $this->_defaultCommentary($c);
        }

        try {
            $png = $this->renderCard($productId);
            if ($png === '') { throw new Exception('card render returned empty'); }
            $imageUrn = $this->_uploadImage($token, $author, $png);

            $body = array(
                'author'       => $author,
                'commentary'   => $commentary,
                'visibility'   => 'PUBLIC',
                'distribution' => array(
                    'feedDistribution' => 'MAIN_FEED',
                    'targetEntities' => array(),
                    'thirdPartyDistributionChannels' => array(),
                ),
                'lifecycleState' => 'PUBLISHED',
                'isReshareDisabledByAuthor' => false,
                'content' => array('media' => array('id' => $imageUrn, 'altText' => $c['name'] . ' — course flyer')),
            );
            list($code, $resp, $headers) = $this->_send('POST', '/posts', $body, $token);
            if ($code >= 400) {
                throw new Exception('post failed ' . $code . ': ' . substr($resp, 0, 300));
            }
            $urn = '';
            if (preg_match('/x-restli-id:\s*([^\r\n]+)/i', $headers, $m)) { $urn = trim($m[1]); }
            $url = $urn ? 'https://www.linkedin.com/feed/update/' . rawurlencode($urn) . '/' : 'https://www.linkedin.com/';
            return array('ok' => true, 'url' => $url, 'urn' => $urn, 'msg' => 'posted');
        } catch (Exception $e) {
            Mage::log('LinkedIn postFlyer failed: ' . $e->getMessage(), null, 'marketing.log');
            return array('ok' => false, 'msg' => $e->getMessage());
        }
    }

    protected function _defaultCommentary($c)
    {
        $lines = array();
        $lines[] = '🚀 New WSQ course open for registration: ' . $c['name'];
        $lines[] = '';
        if ($c['is_wsq'] && (float) $c['price'] > 0) {
            $net = ((float) $c['price'] - (float) $c['price'] * 0.70) + (float) $c['price'] * 0.09;
            $lines[] = '💰 Up to 70% SkillsFuture funding — pay as little as S$' . number_format($net, 0)
                . ' nett (age 40+), or offset the rest with your SkillsFuture Credit.';
        }
        if (!empty($c['runs'])) {
            $ds = array();
            foreach (array_slice($c['runs'], 0, 2) as $rn) { $t = strtotime((string) $rn['course_start_date']); if ($t) { $ds[] = date('j M', $t); } }
            if ($ds) { $lines[] = '📅 Next intakes: ' . implode(' & ', $ds) . '. Seats are limited.'; }
        }
        $lines[] = '';
        $lines[] = '👉 Register: ' . $c['url'];
        $lines[] = '';
        $lines[] = '#SkillsFuture #WSQ #Singapore #ProfessionalDevelopment #Upskilling';
        return implode("\n", $lines);
    }

    /** Upload PNG bytes to LinkedIn, return the image URN. */
    protected function _uploadImage($token, $author, $png)
    {
        list($code, $resp) = $this->_send('POST', '/images?action=initializeUpload',
            array('initializeUploadRequest' => array('owner' => $author)), $token);
        if ($code >= 400) { throw new Exception('image init ' . $code . ': ' . substr($resp, 0, 200)); }
        $j = json_decode($resp, true);
        $uploadUrl = isset($j['value']['uploadUrl']) ? $j['value']['uploadUrl'] : '';
        $imageUrn  = isset($j['value']['image']) ? $j['value']['image'] : '';
        if ($uploadUrl === '' || $imageUrn === '') { throw new Exception('image init missing uploadUrl/urn'); }

        $ch = curl_init($uploadUrl);
        curl_setopt_array($ch, array(
            CURLOPT_PUT => false,
            CURLOPT_CUSTOMREQUEST => 'PUT',
            CURLOPT_POSTFIELDS => $png,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 60,
            CURLOPT_HTTPHEADER => array('Authorization: Bearer ' . $token, 'Content-Type: image/png'),
        ));
        $up = curl_exec($ch);
        $upCode = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        if ($upCode >= 400) { throw new Exception('image upload ' . $upCode . ': ' . substr((string) $up, 0, 200)); }
        return $imageUrn;
    }

    /** Signed LinkedIn REST call. Returns [httpCode, body, rawHeaders]. */
    protected function _send($method, $path, $body, $token)
    {
        $ch = curl_init(self::REST_BASE . $path);
        curl_setopt_array($ch, array(
            CURLOPT_CUSTOMREQUEST => $method,
            CURLOPT_POSTFIELDS => json_encode($body),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HEADER => true,
            CURLOPT_TIMEOUT => 45,
            CURLOPT_HTTPHEADER => array(
                'Authorization: Bearer ' . $token,
                'LinkedIn-Version: ' . self::REST_VERSION,
                'X-Restli-Protocol-Version: 2.0.0',
                'Content-Type: application/json',
            ),
        ));
        $raw = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $hsize = (int) curl_getinfo($ch, CURLINFO_HEADER_SIZE);
        curl_close($ch);
        $headers = substr((string) $raw, 0, $hsize);
        $respBody = substr((string) $raw, $hsize);
        return array($code, $respBody, $headers);
    }
}
