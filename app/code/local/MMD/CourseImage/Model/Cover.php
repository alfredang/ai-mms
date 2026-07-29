<?php

/**
 * GD-rendered course cover image.
 *
 * Canvas: 1200 x 900 (4:3-ish — matches Magento product image grid layout
 * better than 16:10; product detail pages center-fit so aspect is forgiving).
 *
 * Layout:
 *   - Diagonal blue gradient background (deep navy -> brand blue).
 *   - Top-left:   small Tertiary "T" mark + "Tertiary Infotech Academy" wordmark.
 *   - Center:     course title, auto-fit to 1-4 lines.
 *   - Bottom-right (WSQ courses only): WSQ badge.
 *
 * No external font rendering except GD's imagettftext against the bundled
 * DejaVu Sans Bold TTF — keeps the output reproducible across dev/prod
 * containers regardless of host fontconfig state.
 */
class MMD_CourseImage_Model_Cover
{
    public const WIDTH  = 1600;
    public const HEIGHT = 900;
    private const PADDING_X = 80;
    private const PADDING_Y = 80;
    private const MAX_TITLE_LINES = 4;
    private const TITLE_MIN_PX = 36;
    private const TITLE_MAX_PX = 86;

    // Brand palette — richer "shaded blue": darker navy at the top corners,
    // mid-blue body, brand blue at the bottom. A radial highlight sits behind
    // the title to add depth without breaking on-brand color.
    private const BG_TOP       = [0x05, 0x10, 0x2A]; // deep midnight
    private const BG_MID       = [0x0D, 0x2A, 0x5E]; // mid navy
    private const BG_BOTTOM    = [0x1F, 0x4A, 0x8F]; // brand blue
    private const BG_HIGHLIGHT = [0x3B, 0x6F, 0xC4]; // soft radial bloom
    private const ACCENT       = [0x59, 0xEB, 0xFD]; // cyan accent line

    /**
     * @return string PNG binary
     */
    public function render(string $title, string $sku, array $badges = []): string
    {
        if (!function_exists('imagecreatetruecolor')) {
            Mage::throwException('GD extension not available.');
        }

        /** @var MMD_CourseImage_Helper_Data $h */
        $h = Mage::helper('mmd_courseimage');
        $fontPath = $h->getFontPath();
        if (!is_readable($fontPath)) {
            Mage::throwException("Missing TTF font at {$fontPath}");
        }

        $isWsq = $h->isWsqCourse($sku);
        $cleanTitle = $this->cleanTitle($title);
        // Kicker removed — no "PROFESSIONAL TRAINING" pill. The title sits
        // closer to the brand header to give it more vertical breathing room
        // above the funding chip row.
        $kicker = null;

        $im = imagecreatetruecolor(self::WIDTH, self::HEIGHT);
        imagealphablending($im, true);
        imagesavealpha($im, true);

        $this->drawGradient($im);
        $this->drawDotGrid($im);
        $this->drawCornerGlow($im);
        $semiBoldFontPath = $h->getSemiBoldFontPath();
        if (!is_readable($semiBoldFontPath)) {
            $semiBoldFontPath = $fontPath;
        }

        $this->drawAccentBar($im);
        $this->drawBrandHeader($im, $h, $fontPath);
        if ($kicker !== null) {
            $this->drawKicker($im, $kicker, $semiBoldFontPath);
        }
        $this->drawTitle($im, $cleanTitle, $fontPath, $kicker !== null);

        // Badge row is driven by the admin's checkbox selection passed in via
        // $badges. Fallback to the WSQ default trio if the caller didn't pass
        // anything but the SKU is WSQ-funded — preserves the prior behavior
        // for the preview endpoint / legacy callers.
        $chipNames = $badges;
        if (!$chipNames && $isWsq) {
            $chipNames = ['WSQ', 'SkillsFuture Credit', 'PSEA'];
        }
        if ($chipNames) {
            $this->drawFundingChips($im, $semiBoldFontPath, $chipNames);
        }

        ob_start();
        imagepng($im, null, 6);
        $png = (string) ob_get_clean();
        imagedestroy($im);

        return $png;
    }

    /**
     * Strip leading "WSQ" / "CASL" tokens from the title — those prefixes only
     * distinguish course segments in the catalog; the funding chips already
     * convey that signal on the cover, so repeating it in the headline is
     * noise. Matches "WSQ -", "CASL:", "WSQ –", "CASL ", or the token alone.
     */
    private function cleanTitle(string $title): string
    {
        $t = trim(preg_replace('/\s+/u', ' ', $title) ?? '');
        $t = preg_replace('/^\s*(?:WSQ|CASL)\s*[-:–—]?\s*/i', '', $t) ?? $t;
        return trim($t);
    }

    private function drawGradient(\GdImage $im): void
    {
        $h = self::HEIGHT;
        $w = self::WIDTH;

        // Three-stop vertical gradient: midnight -> navy -> brand blue.
        // Sweeping through a mid stop gives a more "shaded" feel than the
        // straight two-stop interpolation we had before.
        [$r1, $g1, $b1] = self::BG_TOP;
        [$r2, $g2, $b2] = self::BG_MID;
        [$r3, $g3, $b3] = self::BG_BOTTOM;
        for ($y = 0; $y < $h; $y++) {
            $t = $y / max(1, $h - 1);
            if ($t < 0.5) {
                $u = $t / 0.5;
                $r = (int) round($r1 + ($r2 - $r1) * $u);
                $g = (int) round($g1 + ($g2 - $g1) * $u);
                $b = (int) round($b1 + ($b2 - $b1) * $u);
            } else {
                $u = ($t - 0.5) / 0.5;
                $r = (int) round($r2 + ($r3 - $r2) * $u);
                $g = (int) round($g2 + ($g3 - $g2) * $u);
                $b = (int) round($b2 + ($b3 - $b2) * $u);
            }
            $color = imagecolorallocate($im, $r, $g, $b);
            imageline($im, 0, $y, $w, $y, $color);
        }

        // Radial highlight bloom slightly upper-right of center for depth.
        // Drawn as a stack of large semi-transparent ellipses, faded out at
        // the edges so the gradient still dominates.
        [$hr, $hg, $hb] = self::BG_HIGHLIGHT;
        $cx = (int) ($w * 0.62);
        $cy = (int) ($h * 0.40);
        $maxR = (int) ($w * 0.55);
        $rings = 24;
        for ($i = $rings; $i >= 1; $i--) {
            $rRadius = (int) ($maxR * $i / $rings);
            // Alpha 127 = fully transparent, 0 = fully opaque in GD.
            $alpha = 110 + (int) round((127 - 110) * (1 - $i / $rings));
            $c = imagecolorallocatealpha($im, $hr, $hg, $hb, $alpha);
            imagefilledellipse($im, $cx, $cy, $rRadius * 2, (int) ($rRadius * 1.5), $c);
        }
    }

    private function drawAccentBar(\GdImage $im): void
    {
        [$r, $g, $b] = self::ACCENT;
        $cyan = imagecolorallocate($im, $r, $g, $b);
        // 3px cyan bar across the top.
        imagefilledrectangle($im, 0, 0, self::WIDTH, 3, $cyan);
    }

    /**
     * Subtle texture: a sparse grid of faint cyan dots over the gradient.
     * Gives the panel a "tech / dashboard" feel without competing with the
     * title.
     */
    private function drawDotGrid(\GdImage $im): void
    {
        [$r, $g, $b] = self::ACCENT;
        // Heavily transparent so the dots read as texture, not pattern.
        $color = imagecolorallocatealpha($im, $r, $g, $b, 110);
        $step = 40;
        for ($y = $step; $y < self::HEIGHT; $y += $step) {
            for ($x = $step; $x < self::WIDTH; $x += $step) {
                imagefilledellipse($im, $x, $y, 3, 3, $color);
            }
        }
    }

    /**
     * Decorative ring in the bottom-left corner — gives the composition a
     * second focal point so the title isn't floating alone.
     */
    private function drawCornerGlow(\GdImage $im): void
    {
        [$r, $g, $b] = self::ACCENT;
        $cx = -60;
        $cy = self::HEIGHT - 60;
        // Stack three thin arcs at decreasing opacity to imitate a glow.
        for ($i = 0; $i < 4; $i++) {
            $alpha = 100 + $i * 6;
            $c = imagecolorallocatealpha($im, $r, $g, $b, $alpha);
            $d = 360 + $i * 80;
            imageellipse($im, $cx, $cy, $d, $d, $c);
        }
    }

    /**
     * Small uppercase kicker label rendered above the title. Acts like a
     * category pill — "WSQ FUNDED COURSE" for TGS- SKUs, otherwise
     * "TERTIARY INFOTECH ACADEMY". Renders inside a thin cyan-bordered pill.
     */
    private function drawKicker(\GdImage $im, string $text, string $fontPath): void
    {
        $fontSize = 20;
        $bbox = imagettfbbox($fontSize, 0, $fontPath, $text);
        $textW = $bbox[2] - $bbox[0];
        $textH = $bbox[1] - $bbox[7];

        $padX = 22;
        $padY = 12;
        $pillW = $textW + 2 * $padX;
        $pillH = $textH + 2 * $padY;

        // Centered horizontally; vertically positioned BELOW the brand logo
        // card. Brand card sits at y=80..~260; kicker sits in the gap above
        // the title band.
        $x1 = (int) round((self::WIDTH - $pillW) / 2);
        $y1 = 295;
        $x2 = $x1 + $pillW;
        $y2 = $y1 + $pillH;

        [$cr, $cg, $cb] = self::ACCENT;
        // Dark, mostly-opaque fill so the cyan text + border read clearly
        // against the gradient.
        $fill   = imagecolorallocatealpha($im, 5, 16, 42, 40);
        $border = imagecolorallocate($im, $cr, $cg, $cb);
        $radius = (int) ($pillH / 2);

        $this->filledRoundedRect($im, $x1, $y1, $x2, $y2, $radius, $fill);
        $this->strokeRoundedRect($im, $x1, $y1, $x2, $y2, $radius, $border);

        $textColor = imagecolorallocate($im, $cr, $cg, $cb);
        imagettftext(
            $im,
            $fontSize,
            0,
            $x1 + $padX,
            $y2 - $padY - 2,
            $textColor,
            $fontPath,
            $text
        );
    }

    /**
     * Modern "funding-eligible" chip row. Renders a small header label
     * ("FUNDING AVAILABLE") above a centered horizontal row of pill chips,
     * one per scheme name. Chips share a single visual language: cyan 2px
     * outline, frosted dark fill, cyan dot on the left, white SemiBold name.
     *
     * @param string[] $names
     */
    private function drawFundingChips(\GdImage $im, string $fontPath, array $names): void
    {
        if (!$names) {
            return;
        }

        [$cr, $cg, $cb] = self::ACCENT;
        $cyan       = imagecolorallocate($im, $cr, $cg, $cb);
        $cyanSoft   = imagecolorallocatealpha($im, $cr, $cg, $cb, 70);
        $white      = imagecolorallocate($im, 255, 255, 255);
        $frosted    = imagecolorallocatealpha($im, 5, 16, 42, 50);
        // Yellow/amber header — the prior near-cyan tone blended into the
        // blue gradient and was hard to read at small sizes. Tailwind
        // amber-400 (#FBBF24) reads as a warm contrast against the navy.
        $headerCol  = imagecolorallocate($im, 0xFB, 0xBF, 0x24);

        // Header label.
        $headerSize = 16;
        $header     = 'FUNDING AVAILABLE';
        $hb         = imagettfbbox($headerSize, 0, $fontPath, $header);
        $hw         = $hb[2] - $hb[0];
        $headerX    = (int) round((self::WIDTH - $hw) / 2);
        $headerY    = self::HEIGHT - 165;
        imagettftext($im, $headerSize, 0, $headerX, $headerY, $headerCol, $fontPath, $header);

        // Chip metrics.
        $chipFontSize = 22;
        $chipPadX     = 24;
        $chipPadY     = 14;
        $dotR         = 6;
        $dotGap       = 12;
        $gapBetween   = 18;

        // Measure each chip width.
        $widths = [];
        $textHeights = [];
        $maxTextH = 0;
        foreach ($names as $name) {
            $b = imagettfbbox($chipFontSize, 0, $fontPath, $name);
            $tw = $b[2] - $b[0];
            $th = $b[1] - $b[7];
            $widths[] = $tw + 2 * $chipPadX + (2 * $dotR + $dotGap);
            $textHeights[] = $th;
            $maxTextH = max($maxTextH, $th);
        }
        $chipH    = $maxTextH + 2 * $chipPadY;
        $totalW   = array_sum($widths) + $gapBetween * (count($names) - 1);
        $startX   = (int) round((self::WIDTH - $totalW) / 2);
        $y1       = self::HEIGHT - 130;
        $y2       = $y1 + $chipH;
        $radius   = (int) ($chipH / 2);

        $cursorX = $startX;
        foreach ($names as $i => $name) {
            $cw = $widths[$i];
            $x1 = $cursorX;
            $x2 = $cursorX + $cw;

            // Soft outer glow — a slightly larger rounded rect underneath
            // at low opacity, for that "lifted" modern feel.
            $this->strokeRoundedRect($im, $x1 - 2, $y1 - 2, $x2 + 2, $y2 + 2, $radius + 2, $cyanSoft);

            // Frosted fill + crisp 2px cyan outline.
            $this->filledRoundedRect($im, $x1, $y1, $x2, $y2, $radius, $frosted);
            $this->strokeRoundedRect($im, $x1, $y1, $x2, $y2, $radius, $cyan);
            // Doubled stroke for a 2px appearance (GD imageline is 1px native).
            $this->strokeRoundedRect($im, $x1 + 1, $y1 + 1, $x2 - 1, $y2 - 1, max(0, $radius - 1), $cyan);

            // Cyan dot on the left.
            $dotX = $x1 + $chipPadX + $dotR;
            $dotY = (int) (($y1 + $y2) / 2);
            imagefilledellipse($im, $dotX, $dotY, $dotR * 2, $dotR * 2, $cyan);

            // Scheme name.
            $textX = $dotX + $dotR + $dotGap;
            // Baseline so the text vertically centers in the chip.
            $textY = $y2 - $chipPadY - 4;
            imagettftext($im, $chipFontSize, 0, $textX, $textY, $white, $fontPath, $name);

            $cursorX += $cw + $gapBetween;
        }
    }

    private function strokeRoundedRect(\GdImage $im, int $x1, int $y1, int $x2, int $y2, int $r, int $color): void
    {
        // Stroke the four straight edges + four corner arcs.
        $r = max(0, min($r, (int) floor(min($x2 - $x1, $y2 - $y1) / 2)));
        imageline($im, $x1 + $r, $y1, $x2 - $r, $y1, $color);
        imageline($im, $x1 + $r, $y2, $x2 - $r, $y2, $color);
        imageline($im, $x1, $y1 + $r, $x1, $y2 - $r, $color);
        imageline($im, $x2, $y1 + $r, $x2, $y2 - $r, $color);
        $d = $r * 2;
        if ($d > 0) {
            imagearc($im, $x1 + $r, $y1 + $r, $d, $d, 180, 270, $color);
            imagearc($im, $x2 - $r, $y1 + $r, $d, $d, 270, 360, $color);
            imagearc($im, $x1 + $r, $y2 - $r, $d, $d, 90, 180, $color);
            imagearc($im, $x2 - $r, $y2 - $r, $d, $d, 0, 90, $color);
        }
    }

    private function drawBrandHeader(\GdImage $im, MMD_CourseImage_Helper_Data $h, string $fontPath): void
    {
        // Simple horizontal lockup, drawn directly on the gradient (no white
        // card behind it): circular "T" mark on the left, "Tertiary Infotech
        // Academy" wordmark in white to its right. Matches the cleaner
        // dark-background brand treatment shown in the reference image.
        $logo = $h->getTertiaryLogoPath();
        if (!is_readable($logo)) {
            return;
        }
        $src = @imagecreatefrompng($logo);
        if (!$src) {
            return;
        }
        imagealphablending($src, true);
        imagesavealpha($src, true);

        $markSize = 88;
        $sw = imagesx($src);
        $sh = imagesy($src);

        $markX = self::PADDING_X;
        $markY = self::PADDING_Y;
        imagecopyresampled($im, $src, $markX, $markY, 0, 0, $markSize, $markSize, $sw, $sh);
        imagedestroy($src);

        $white = imagecolorallocate($im, 255, 255, 255);
        $wordmark = 'Tertiary Infotech Academy';
        $fontSize = 32;
        $bbox = imagettfbbox($fontSize, 0, $fontPath, $wordmark);
        $textH = $bbox[1] - $bbox[7];
        $textX = $markX + $markSize + 22;
        // Vertically center the wordmark against the mark.
        $textY = $markY + (int) round(($markSize + $textH) / 2) - 6;
        imagettftext($im, $fontSize, 0, $textX, $textY, $white, $fontPath, $wordmark);
    }

    /**
     * Approximate a filled rounded rectangle. GD has no native rounded-rect
     * primitive, so this is the standard "rectangle + four corner discs"
     * trick — corners drawn as filled ellipses, body as two overlapping
     * filled rectangles.
     */
    private function filledRoundedRect(\GdImage $im, int $x1, int $y1, int $x2, int $y2, int $r, int $color): void
    {
        $r = max(0, min($r, (int) floor(min($x2 - $x1, $y2 - $y1) / 2)));
        imagefilledrectangle($im, $x1 + $r, $y1,     $x2 - $r, $y2,     $color);
        imagefilledrectangle($im, $x1,     $y1 + $r, $x2,     $y2 - $r, $color);
        $d = $r * 2;
        if ($d > 0) {
            imagefilledellipse($im, $x1 + $r, $y1 + $r, $d, $d, $color);
            imagefilledellipse($im, $x2 - $r, $y1 + $r, $d, $d, $color);
            imagefilledellipse($im, $x1 + $r, $y2 - $r, $d, $d, $color);
            imagefilledellipse($im, $x2 - $r, $y2 - $r, $d, $d, $color);
        }
    }

    private function drawTitle(\GdImage $im, string $title, string $fontPath, bool $hasKicker = false): void
    {
        $title = trim(preg_replace('/\s+/u', ' ', $title) ?? '');
        if ($title === '') {
            $title = 'Course';
        }

        $maxWidth = self::WIDTH - 2 * self::PADDING_X;
        // Top reserve: ~220px clears the brand header (logo + wordmark sit at
        // y=80..168) with a small gap. Kicker pill removed, so no extra
        // vertical budget is reserved for it.
        // Bottom reserve: ~260px to guarantee at least ~45px clearance
        // between the title descenders and the FUNDING AVAILABLE chip header.
        $topReserved    = $hasKicker ? 370 : 220;
        $bottomReserved = 260;
        $bandTop = $topReserved;
        $bandH   = self::HEIGHT - $topReserved - $bottomReserved;

        [$fontSize, $lines] = $this->fitTitle($title, $fontPath, $maxWidth, $bandH);

        $lineHeight = (int) round($fontSize * 1.25);
        $blockH = $lineHeight * count($lines);
        $startY  = $bandTop + (int) round(($bandH - $blockH) / 2);

        $white = imagecolorallocate($im, 255, 255, 255);

        foreach ($lines as $i => $line) {
            $bbox = imagettfbbox($fontSize, 0, $fontPath, $line);
            $textW = $bbox[2] - $bbox[0];
            $x = (int) round((self::WIDTH - $textW) / 2);
            $y = $startY + ($i + 1) * $lineHeight;
            // Soft shadow for legibility on the gradient.
            $shadow = imagecolorallocatealpha($im, 0, 0, 0, 90);
            imagettftext($im, $fontSize, 0, $x + 2, $y + 2, $shadow, $fontPath, $line);
            imagettftext($im, $fontSize, 0, $x, $y, $white, $fontPath, $line);
        }
    }

    /**
     * Find largest font size where the wrapped title fits in {<=MAX_LINES} lines,
     * every line within $maxWidth, AND total block height <= $maxBlockH.
     * The vertical guard prevents the title from overflowing into the kicker
     * pill above or the FUNDING AVAILABLE chip row below — a 4-line title at
     * a large font size would otherwise overlap both.
     *
     * @return array{0:int,1:string[]}
     */
    private function fitTitle(string $title, string $fontPath, int $maxWidth, int $maxBlockH): array
    {
        for ($size = self::TITLE_MAX_PX; $size >= self::TITLE_MIN_PX; $size -= 2) {
            $lines = $this->wrap($title, $fontPath, $size, $maxWidth);
            $blockH = (int) round($size * 1.25) * count($lines);
            if (count($lines) <= self::MAX_TITLE_LINES && $blockH <= $maxBlockH) {
                return [$size, $lines];
            }
        }
        // Force-fit at minimum size, even if overflow — truncate to MAX_LINES.
        $lines = $this->wrap($title, $fontPath, self::TITLE_MIN_PX, $maxWidth);
        if (count($lines) > self::MAX_TITLE_LINES) {
            $lines = array_slice($lines, 0, self::MAX_TITLE_LINES);
            $lines[self::MAX_TITLE_LINES - 1] = rtrim($lines[self::MAX_TITLE_LINES - 1]) . '…';
        }
        return [self::TITLE_MIN_PX, $lines];
    }

    /**
     * @return string[]
     */
    private function wrap(string $text, string $fontPath, int $fontSize, int $maxWidth): array
    {
        $words = preg_split('/\s+/u', $text) ?: [];
        $lines = [];
        $current = '';
        foreach ($words as $word) {
            $candidate = $current === '' ? $word : $current . ' ' . $word;
            $bbox = imagettfbbox($fontSize, 0, $fontPath, $candidate);
            $w = $bbox[2] - $bbox[0];
            if ($w <= $maxWidth) {
                $current = $candidate;
                continue;
            }
            if ($current !== '') {
                $lines[] = $current;
            }
            $current = $word;
        }
        if ($current !== '') {
            $lines[] = $current;
        }
        return $lines;
    }

    private function overlayPng(\GdImage $dst, string $path, string $anchor, int $targetWidth): void
    {
        $src = @imagecreatefrompng($path);
        if (!$src) {
            return;
        }
        imagealphablending($src, true);
        imagesavealpha($src, true);

        $sw = imagesx($src);
        $sh = imagesy($src);
        $scale = $targetWidth / max(1, $sw);
        $dw = (int) round($sw * $scale);
        $dh = (int) round($sh * $scale);

        switch ($anchor) {
            case 'bottom-right':
                $dx = self::WIDTH - self::PADDING_X - $dw;
                $dy = self::HEIGHT - self::PADDING_Y - $dh;
                break;
            case 'bottom-left':
                $dx = self::PADDING_X;
                $dy = self::HEIGHT - self::PADDING_Y - $dh;
                break;
            default:
                $dx = self::PADDING_X;
                $dy = self::PADDING_Y;
        }
        imagecopyresampled($dst, $src, $dx, $dy, 0, 0, $dw, $dh, $sw, $sh);
        imagedestroy($src);
    }

    private function overlayPngAt(\GdImage $dst, string $path, int $dx, int $dy, int $dw, int $dh): void
    {
        $src = @imagecreatefrompng($path);
        if (!$src) {
            return;
        }
        imagealphablending($src, true);
        imagesavealpha($src, true);
        $sw = imagesx($src);
        $sh = imagesy($src);
        imagecopyresampled($dst, $src, $dx, $dy, 0, 0, $dw, $dh, $sw, $sh);
        imagedestroy($src);
    }
}
