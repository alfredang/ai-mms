<?php

/**
 * GD-rendered EDITORIAL hero image for a blog post.
 *
 * Deliberately NOT the course cover (mmd_courseimage/cover): a blog card is an
 * article, not a product. The course cover carries the Tertiary logo lockup and
 * the "FUNDING AVAILABLE / WSQ / SkillsFuture Credit" chip row, which on a blog
 * listing reads as an ad tile sitting among editorial cards. This renderer drops
 * both and instead builds a topic-specific graphic so every post looks distinct
 * at thumbnail size.
 *
 * Canvas: 1600 x 900 (16:9 — matches the .mmd-blog-card-hero crop and the
 * og:image ratio social platforms expect).
 *
 * Layout:
 *   - Dark tech background, hue chosen per topic (not always brand navy, so the
 *     listing does not read as one repeated blue block).
 *   - Left column:  category kicker pill, headline (auto-fit 1-4 lines),
 *                   accent underline.
 *   - Right column: a generated MOTIF illustrating the topic (shield, terminal,
 *                   funnel, network, ...) — this is what makes the card feel
 *                   designed rather than typeset.
 *
 * Only GD + the bundled Inter TTFs, matching Cover.php, so output is
 * reproducible across dev/prod containers regardless of host fontconfig.
 */
class MMD_Blog_Model_Hero
{
    public const WIDTH  = 1600;
    public const HEIGHT = 900;

    private const PAD_X = 90;
    // 5 lines and a low ceiling: long course-style titles ("Lean Six Sigma
    // Green Belt Training Singapore: WSQ CLSSGB Guide") should step DOWN in
    // size and wrap rather than clip. Cards are ~380px wide on the listing, so
    // 56px on a 1600px canvas is still comfortably legible when scaled.
    private const MAX_TITLE_LINES = 5;
    private const TITLE_MIN_PX = 30;
    private const TITLE_MAX_PX = 56;

    /**
     * SAFE BAND — the only vertical slice guaranteed to be visible everywhere.
     *
     * The listing card crops 16:9 (the full canvas), but the POST PAGE banner
     * is `.mmd-blog-post-hero { aspect-ratio: 32/9 }` with `object-fit: cover`,
     * which shows only the middle half: y=225..675 of a 1600x900 canvas. Text
     * outside that band is invisible on the post page no matter how small the
     * font is — which is why "just shrink the title" does not fix a clipped
     * banner. ALL text must be laid out inside these bounds.
     */
    private const SAFE_TOP    = 258;
    private const SAFE_BOTTOM = 660;

    /**
     * Topic themes. Each entry: two background stops, an accent, a motif name
     * and the keywords that select it. Order matters — the first theme with a
     * keyword hit wins, so put specific topics above generic ones.
     */
    private const THEMES = array(
        'security' => array(
            'bg' => array(0x0A, 0x12, 0x22), 'bg2' => array(0x10, 0x2A, 0x38),
            'accent' => array(0x34, 0xE0, 0xC8), 'motif' => 'shield',
            'kw' => array('security', 'secure', 'cyber', 'red team', 'attack', 'breach', 'risk', 'passkey', 'governance'),
        ),
        'seo' => array(
            'bg' => array(0x14, 0x0B, 0x2E), 'bg2' => array(0x2A, 0x14, 0x52),
            'accent' => array(0xC0, 0x8A, 0xFF), 'motif' => 'search',
            'kw' => array('seo', 'search engine', 'meta title', 'meta description', 'ai overview', 'ranking', 'keyword'),
        ),
        'marketing' => array(
            'bg' => array(0x2A, 0x0E, 0x1E), 'bg2' => array(0x52, 0x18, 0x38),
            'accent' => array(0xFF, 0x8A, 0xB0), 'motif' => 'funnel',
            'kw' => array('linkedin', 'marketing', 'content', 'social', 'brand', 'audience', 'lead'),
        ),
        // Named agentic CODING tools sit above 'automation': their titles almost
        // always also say "agent"/"agentic", which would otherwise steal them
        // into the green node-graph and make a coding article look like an n8n
        // workflow piece.
        'coding_agent' => array(
            'bg' => array(0x0B, 0x14, 0x2C), 'bg2' => array(0x16, 0x30, 0x5C),
            'accent' => array(0x59, 0xEB, 0xFD), 'motif' => 'terminal',
            'kw' => array('claude code', 'codex', 'cursor', 'copilot', 'coding agent', 'pair programmer'),
        ),
        // CAD / BIM tools sit above 'automation', 'code', 'data' and 'video':
        // these titles nearly always also say "design"/"visual" (a video kw),
        // "app" (a code kw) or "drawing", which would otherwise render a
        // play-button or terminal on an AutoCAD/Revit article.
        'cad' => array(
            'bg' => array(0x07, 0x16, 0x2A), 'bg2' => array(0x0E, 0x33, 0x50),
            'accent' => array(0x7C, 0xC4, 0xFF), 'motif' => 'blueprint',
            'kw' => array(
                'autocad', 'revit', 'fusion 360', 'inventor', '3ds max', 'civil 3d',
                'autodesk', 'bim', 'cad', '3d modeling', '3d modelling', 'technical drawing',
            ),
        ),
        // Urban farming sits above EVERY generic theme, not just 'funding'. These
        // titles routinely also contain "build"/"grow" (code), "process" (data) and
        // "course"/"skillsfuture" (funding) - a post called "Building a Hydroponic
        // System From Scratch" rendered the blue terminal window until this moved up.
        'farming' => array(
            'bg' => array(0x06, 0x1C, 0x18), 'bg2' => array(0x0E, 0x3E, 0x30),
            'accent' => array(0x6E, 0xE7, 0xA8), 'motif' => 'sprout',
            'kw' => array(
                'hydroponic', 'hydroponics', 'urban farming', 'farming', 'farm',
                'grow', 'vertical farm', 'agriculture', 'crop', 'melon', 'harvest',
                'seedling', 'nutrient solution', 'greenhouse',
            ),
        ),
        // IoT sits above 'automation', 'code' and 'data': these titles routinely
        // also say "sensor data" (data), "build" (code) or "automation", any of
        // which would otherwise render a chart or terminal on a connected-device
        // article. Without this theme an IoT post falls all the way through to
        // THEME_DEFAULT and draws the same generic blue node graph as everything
        // else that misses.
        'iot' => array(
            'bg' => array(0x06, 0x18, 0x26), 'bg2' => array(0x0C, 0x36, 0x48),
            'accent' => array(0x4F, 0xD8, 0xE8), 'motif' => 'sensor',
            'kw' => array(
                'iot', 'internet of things', 'sensor', 'raspberry pi', 'arduino',
                'esp8266', 'esp32', 'mqtt', 'microcontroller', 'smart device', 'embedded',
            ),
        ),
        'automation' => array(
            'bg' => array(0x0A, 0x1C, 0x14), 'bg2' => array(0x12, 0x3A, 0x2A),
            'accent' => array(0x5E, 0xE8, 0x9B), 'motif' => 'nodes',
            'kw' => array('n8n', 'workflow', 'automation', 'automate', 'agent', 'agentic', 'openclaw', 'hermes', 'pipeline'),
        ),
        'code' => array(
            'bg' => array(0x0B, 0x14, 0x2C), 'bg2' => array(0x16, 0x30, 0x5C),
            'accent' => array(0x59, 0xEB, 0xFD), 'motif' => 'terminal',
            'kw' => array('claude code', 'coding', 'developer', 'python', 'sql', 'app', 'build', 'programming', 'vibe'),
        ),
        'data' => array(
            'bg' => array(0x1A, 0x10, 0x06), 'bg2' => array(0x3E, 0x26, 0x0C),
            'accent' => array(0xFF, 0xB4, 0x4D), 'motif' => 'chart',
            'kw' => array('data', 'analytics', 'six sigma', 'process', 'quality', 'business', 'hr', 'project management', 'pmp'),
        ),
        'video' => array(
            'bg' => array(0x22, 0x0C, 0x14), 'bg2' => array(0x48, 0x16, 0x2E),
            'accent' => array(0xFF, 0x7A, 0x8A), 'motif' => 'play',
            'kw' => array('video', 'youtube', 'infographic', 'image', 'creative', 'design', 'visual'),
        ),
        'funding' => array(
            'bg' => array(0x08, 0x1A, 0x2E), 'bg2' => array(0x10, 0x38, 0x54),
            'accent' => array(0x66, 0xD0, 0xFF), 'motif' => 'badge',
            'kw' => array('utap', 'skillsfuture', 'funding', 'claim', 'subsidy', 'grant', 'certification', 'course'),
        ),
    );

    /**
     * Per-post variation seed, derived from the title in render(). Deterministic
     * (same title always renders the same art) but differs between posts, so
     * two articles sharing a theme do not produce identical motifs.
     */
    private int $seed = 0;

    private const THEME_DEFAULT = array(
        'bg' => array(0x08, 0x12, 0x28), 'bg2' => array(0x14, 0x32, 0x64),
        'accent' => array(0x59, 0xEB, 0xFD), 'motif' => 'nodes', 'kw' => array(),
    );

    /**
     * @param string $title  post title (drives both the headline and the theme)
     * @param string $kicker short category label, e.g. "GENERATIVE AI"
     * @return string PNG binary
     */
    public function render(string $title, string $kicker = ''): string
    {
        if (!function_exists('imagecreatetruecolor')) {
            Mage::throwException('GD extension not available.');
        }

        /** @var MMD_CourseImage_Helper_Data $h */
        $h = Mage::helper('mmd_courseimage');
        $bold = $h->getFontPath();
        $semi = $h->getSemiBoldFontPath();
        if (!is_readable($bold)) {
            Mage::throwException("Missing TTF font at {$bold}");
        }
        if (!is_readable($semi)) {
            $semi = $bold;
        }

        $theme = $this->pickTheme($title . ' ' . $kicker);
        $clean = $this->cleanTitle($title);
        $this->seed = (int) hexdec(substr(md5($clean), 0, 6));

        $im = imagecreatetruecolor(self::WIDTH, self::HEIGHT);
        imagealphablending($im, true);
        imagesavealpha($im, true);

        $this->drawBackground($im, $theme);
        $this->drawGrid($im, $theme);
        $this->drawMotif($im, $theme);
        $this->drawScrim($im);
        $this->drawAccentBar($im, $theme);

        $y = 300;
        if ($kicker !== '') {
            $y = $this->drawKicker($im, $kicker, $semi, $theme);
        }
        $this->drawTitle($im, $clean, $bold, $theme, $y);

        ob_start();
        imagepng($im, null, 6);
        $png = (string) ob_get_clean();
        imagedestroy($im);

        return $png;
    }

    /** First theme with a keyword hit wins; falls back to the neutral blue. */
    private function pickTheme(string $haystack): array
    {
        $hay = mb_strtolower($haystack, 'UTF-8');
        foreach (self::THEMES as $theme) {
            foreach ($theme['kw'] as $kw) {
                if (mb_strpos($hay, $kw) !== false) {
                    return $theme;
                }
            }
        }
        return self::THEME_DEFAULT;
    }

    /**
     * Strip the segment prefixes that only matter in the catalog. A blog
     * headline reading "WSQ - ..." is course furniture, not an article title.
     *
     * Post titles are stored with HTML entities (&mdash; etc.) because migration
     * content must stay pure ASCII, so decode first — imagettftext draws the raw
     * string and would otherwise render a literal "&mdash;" in the headline.
     */
    private function cleanTitle(string $title): string
    {
        $t = html_entity_decode($title, ENT_QUOTES | ENT_HTML5, 'UTF-8');
        $t = trim(preg_replace('/\s+/u', ' ', $t) ?? '');
        $t = preg_replace('/^\s*(?:WSQ|CASL|IBF)\s*[-:–—]?\s*/i', '', $t) ?? $t;
        return trim($t);
    }

    /**
     * Diagonal two-stop gradient — darker top-left, lighter bottom-right. The
     * lighter stop is nudged per post (seed-driven, +/-14) so two articles in
     * the same theme differ in tone as well as in motif geometry.
     */
    private function drawBackground(\GdImage $im, array $theme): void
    {
        [$r1, $g1, $b1] = $theme['bg'];
        [$r2, $g2, $b2] = $theme['bg2'];
        $shift = ($this->seed % 29) - 14;
        $r2 = max(0, min(255, $r2 + $shift));
        $g2 = max(0, min(255, $g2 + (int) round($shift * 0.6)));
        $b2 = max(0, min(255, $b2 + (int) round($shift * 1.2)));
        $w = self::WIDTH;
        $hh = self::HEIGHT;
        $max = $w + $hh;

        for ($y = 0; $y < $hh; $y++) {
            for ($x = 0; $x < $w; $x += 8) {
                $t = ($x + $y) / $max;
                $r = (int) round($r1 + ($r2 - $r1) * $t);
                $g = (int) round($g1 + ($g2 - $g1) * $t);
                $b = (int) round($b1 + ($b2 - $b1) * $t);
                $c = imagecolorallocate($im, $r, $g, $b);
                imagefilledrectangle($im, $x, $y, $x + 8, $y, $c);
            }
        }
    }

    /** Faint blueprint grid — texture that reads as "technical" at thumbnail size. */
    private function drawGrid(\GdImage $im, array $theme): void
    {
        [$r, $g, $b] = $theme['accent'];
        $c = imagecolorallocatealpha($im, $r, $g, $b, 118);
        for ($x = 0; $x < self::WIDTH; $x += 60) {
            imageline($im, $x, 0, $x, self::HEIGHT, $c);
        }
        for ($y = 0; $y < self::HEIGHT; $y += 60) {
            imageline($im, 0, $y, self::WIDTH, $y, $c);
        }
    }

    /**
     * Darken the left column so the headline keeps contrast over whatever the
     * motif drew. Without this a bright motif limb can run under the text.
     */
    private function drawScrim(\GdImage $im): void
    {
        $split = (int) (self::WIDTH * 0.60);
        for ($x = 0; $x < $split; $x++) {
            $t = 1 - ($x / $split);
            $alpha = (int) round(127 - 88 * $t);
            $c = imagecolorallocatealpha($im, 0, 0, 0, max(0, min(127, $alpha)));
            imageline($im, $x, 0, $x, self::HEIGHT, $c);
        }
    }

    private function drawAccentBar(\GdImage $im, array $theme): void
    {
        [$r, $g, $b] = $theme['accent'];
        imagefilledrectangle($im, 0, 0, self::WIDTH, 5, imagecolorallocate($im, $r, $g, $b));
    }

    /** Category pill, top-left. Returns the y baseline the title should start from. */
    private function drawKicker(\GdImage $im, string $kicker, string $font, array $theme): int
    {
        [$r, $g, $b] = $theme['accent'];
        $text = mb_strtoupper(trim($kicker), 'UTF-8');
        $size = 22;
        $box  = imagettfbbox($size, 0, $font, $text);
        $tw   = abs($box[2] - $box[0]);
        $th   = abs($box[7] - $box[1]);

        $x = self::PAD_X;
        // Baseline inside the 32:9 safe band, not at the canvas top — a kicker
        // at y=150 is cropped away entirely on the post-page banner.
        $y = self::SAFE_TOP + $th;
        $padX = 26;
        $padY = 16;

        // Fill only, no outline: GD's imagearc corners never land exactly on the
        // filled ellipse edge, so a stroked pill shows four corner "bumps". The
        // translucent fill alone reads clean at every size.
        $pill = imagecolorallocatealpha($im, $r, $g, $b, 96);
        $this->roundedRect($im, $x, $y - $th - $padY, $x + $tw + $padX * 2, $y + $padY, 10, $pill);

        $ink = imagecolorallocate($im, $r, $g, $b);
        imagettftext($im, $size, 0, $x + $padX, $y, $ink, $font, $text);

        return $y + $padY + 34;
    }

    /**
     * Headline, auto-fitted on BOTH axes.
     *
     * Fitting on line-count alone is not enough: 4 lines at the max size needs
     * ~420px, more than the band left below the kicker, so long titles used to
     * run off the bottom of the canvas (and under the card's fade). The loop
     * therefore also requires the rendered block to fit $availH.
     */
    private function drawTitle(\GdImage $im, string $title, string $font, array $theme, int $top): void
    {
        $maxW = (int) (self::WIDTH * 0.56) - self::PAD_X;
        // Measure against the SAFE BAND, not the canvas: anything below
        // SAFE_BOTTOM is cropped off by the 32:9 post-page banner. Reserve ~46px
        // for the accent underline that sits under the last line.
        $availH = self::SAFE_BOTTOM - $top - 46;

        $size = self::TITLE_MAX_PX;
        $lines = $this->wrap($title, $font, $size, $maxW);

        for (; $size > self::TITLE_MIN_PX; $size -= 2) {
            $lines = $this->wrap($title, $font, $size, $maxW);
            $blockH = (int) round($size * 1.24) * count($lines);
            if (count($lines) <= self::MAX_TITLE_LINES && $blockH <= $availH) {
                break;
            }
        }
        // Still too long at the minimum size — clamp lines and ellipsise.
        if (count($lines) > self::MAX_TITLE_LINES) {
            $lines = array_slice($lines, 0, self::MAX_TITLE_LINES);
            $last = count($lines) - 1;
            $lines[$last] = rtrim($lines[$last], " .,:;") . '…';
        }

        $lineH = (int) round($size * 1.24);
        $blockH = $lineH * count($lines);
        // Vertically center the block in the band below the kicker.
        $y = $top + (int) max(0, ($availH - $blockH) / 2) + $size;

        $white  = imagecolorallocate($im, 0xFF, 0xFF, 0xFF);
        $shadow = imagecolorallocatealpha($im, 0, 0, 0, 85);

        foreach ($lines as $line) {
            imagettftext($im, $size, 0, self::PAD_X + 2, $y + 3, $shadow, $font, $line);
            imagettftext($im, $size, 0, self::PAD_X, $y, $white, $font, $line);
            $y += $lineH;
        }

        // Accent underline anchoring the headline block.
        [$r, $g, $b] = $theme['accent'];
        $c = imagecolorallocate($im, $r, $g, $b);
        imagefilledrectangle($im, self::PAD_X, $y - $size + 34, self::PAD_X + 120, $y - $size + 40, $c);
    }

    /** @return string[] */
    private function wrap(string $text, string $font, int $size, int $maxW): array
    {
        $words = preg_split('/\s+/u', $text) ?: array();
        $lines = array();
        $cur = '';
        foreach ($words as $word) {
            $try = $cur === '' ? $word : $cur . ' ' . $word;
            $box = imagettfbbox($size, 0, $font, $try);
            if (abs($box[2] - $box[0]) > $maxW && $cur !== '') {
                $lines[] = $cur;
                $cur = $word;
            } else {
                $cur = $try;
            }
        }
        if ($cur !== '') {
            $lines[] = $cur;
        }
        return $lines;
    }

    // ---------------------------------------------------------------- motifs

    /** Dispatch to the theme's motif, drawn in the right-hand column. */
    private function drawMotif(\GdImage $im, array $theme): void
    {
        $cx = (int) (self::WIDTH * 0.775);
        // Centre on the safe band (= canvas centre here, but stated explicitly
        // so the motif follows the band if the crop ever changes).
        $cy = (int) ((self::SAFE_TOP + self::SAFE_BOTTOM) / 2);
        [$r, $g, $b] = $theme['accent'];

        // Halo behind every motif so it reads as a focal point.
        for ($i = 16; $i >= 1; $i--) {
            $c = imagecolorallocatealpha($im, $r, $g, $b, 120 + (int) round(7 * (1 - $i / 16)));
            imagefilledellipse($im, $cx, $cy, (int) (620 * $i / 16), (int) (620 * $i / 16), $c);
        }

        switch ($theme['motif']) {
            case 'shield':   $this->motifShield($im, $cx, $cy, $theme); break;
            case 'search':   $this->motifSearch($im, $cx, $cy, $theme); break;
            case 'funnel':   $this->motifFunnel($im, $cx, $cy, $theme); break;
            case 'terminal': $this->motifTerminal($im, $cx, $cy, $theme); break;
            case 'chart':    $this->motifChart($im, $cx, $cy, $theme); break;
            case 'play':     $this->motifPlay($im, $cx, $cy, $theme); break;
            case 'badge':    $this->motifBadge($im, $cx, $cy, $theme); break;
            case 'blueprint': $this->motifBlueprint($im, $cx, $cy, $theme); break;
            case 'sprout':   $this->motifSprout($im, $cx, $cy, $theme); break;
            case 'sensor':   $this->motifSensor($im, $cx, $cy, $theme); break;
            case 'nodes':
            default:         $this->motifNodes($im, $cx, $cy, $theme); break;
        }
    }

    private function motifShield(\GdImage $im, int $cx, int $cy, array $theme): void
    {
        [$r, $g, $b] = $theme['accent'];
        $c = imagecolorallocate($im, $r, $g, $b);
        $w = 210;
        $h = 260;
        $pts = array(
            $cx - $w, $cy - $h + 40,
            $cx,      $cy - $h,
            $cx + $w, $cy - $h + 40,
            $cx + $w, $cy + 30,
            $cx,      $cy + $h,
            $cx - $w, $cy + 30,
        );
        $this->thickPolygon($im, $pts, $c, 9);

        // Keyhole inside.
        imagefilledellipse($im, $cx, $cy - 30, 78, 78, $c);
        imagefilledrectangle($im, $cx - 22, $cy - 30, $cx + 22, $cy + 78, $c);
    }

    /**
     * Hydroponics: a seedling in a net pot suspended over a nutrient reservoir,
     * roots hanging into the solution. Leaf count varies with the per-post seed
     * so two farming posts do not render identical art.
     */
    private function motifSprout(\GdImage $im, int $cx, int $cy, array $theme): void
    {
        [$r, $g, $b] = $theme['accent'];
        $c = imagecolorallocate($im, $r, $g, $b);

        // Reservoir: tank walls, plus the waterline drawn as two segments either
        // side of the net pot so the surface stays visible rather than hidden
        // behind it. The seed nudges the level so posts vary slightly.
        $water = $cy + 70 + ($this->seed % 3) * 8;
        $halfW = 215;
        $this->thickLine($im, $cx - $halfW, $water, $cx - 62, $water, $c, 10);
        $this->thickLine($im, $cx + 62, $water, $cx + $halfW, $water, $c, 10);
        $this->thickLine($im, $cx - $halfW, $water, $cx - $halfW, $cy + 250, $c, 9);
        $this->thickLine($im, $cx + $halfW, $water, $cx + $halfW, $cy + 250, $c, 9);
        $this->thickLine($im, $cx - $halfW, $cy + 250, $cx + $halfW, $cy + 250, $c, 9);

        // Net pot straddling the waterline.
        $potTop = $water - 74;
        $this->thickPolygon($im, array(
            $cx - 78, $potTop,
            $cx + 78, $potTop,
            $cx + 54, $water + 30,
            $cx - 54, $water + 30,
        ), $c, 8);
        // Net slots.
        foreach (array(-34, 0, 34) as $dx) {
            $this->thickLine($im, $cx + $dx, $potTop + 18, $cx + (int) round($dx * 0.72), $water + 14, $c, 5);
        }

        // Roots trailing into the solution.
        foreach (array(-40, -14, 14, 40) as $i => $dx) {
            $len = 92 + ($i % 2) * 34;
            $this->thickLine($im, $cx + $dx, $water + 24, $cx + $dx + ($i % 2 ? 18 : -18), $water + $len, $c, 5);
        }

        // Stem.
        $this->thickLine($im, $cx, $potTop + 6, $cx, $cy - 176, $c, 11);

        // Leaves, alternating up the stem. 3-5 pairs depending on the seed.
        $pairs = 3 + ($this->seed % 3);
        for ($i = 0; $i < $pairs; $i++) {
            $ly = $potTop - 4 - $i * 62;
            $span = 132 - $i * 20;
            $lift = 46 - $i * 6;
            // Left leaf.
            $this->thickPolygon($im, array(
                $cx, $ly,
                $cx - $span / 2, $ly - $lift,
                $cx - $span, $ly - $lift / 3,
                $cx - $span / 2, $ly + $lift / 3,
            ), $c, 7);
            // Right leaf.
            $this->thickPolygon($im, array(
                $cx, $ly - 26,
                $cx + $span / 2, $ly - 26 - $lift,
                $cx + $span, $ly - 26 - $lift / 3,
                $cx + $span / 2, $ly - 26 + $lift / 3,
            ), $c, 7);
        }
    }

    private function motifSearch(\GdImage $im, int $cx, int $cy, array $theme): void
    {
        [$r, $g, $b] = $theme['accent'];
        $c = imagecolorallocate($im, $r, $g, $b);

        // Magnifier ring. imagesetthickness is ignored by imageellipse on most
        // GD builds, so the stroke is built by stacking concentric ellipses.
        $ring = 170;
        for ($t = 0; $t < 20; $t++) {
            imageellipse($im, $cx - 40, $cy - 40, $ring * 2 - $t, $ring * 2 - $t, $c);
        }
        // Handle.
        $this->thickLine($im, $cx + 78, $cy + 78, $cx + 210, $cy + 210, $c, 22);

        // Result bars inside the lens — "the answer sits in the search".
        $bw = 150;
        foreach (array(-70, -20, 30) as $i => $dy) {
            $len = $bw - $i * 34;
            imagefilledrectangle($im, $cx - 40 - $len / 2, $cy - 40 + $dy, $cx - 40 + $len / 2, $cy - 40 + $dy + 14, $c);
        }
    }

    private function motifFunnel(\GdImage $im, int $cx, int $cy, array $theme): void
    {
        [$r, $g, $b] = $theme['accent'];
        $c = imagecolorallocate($im, $r, $g, $b);

        $w = 250;
        $pts = array(
            $cx - $w, $cy - 200,
            $cx + $w, $cy - 200,
            $cx + 55, $cy + 30,
            $cx + 55, $cy + 215,
            $cx - 55, $cy + 150,
            $cx - 55, $cy + 30,
        );
        $this->thickPolygon($im, $pts, $c, 9);

        // Audience dots falling in.
        $dot = imagecolorallocatealpha($im, $r, $g, $b, 35);
        for ($i = 0; $i < 7; $i++) {
            imagefilledellipse($im, $cx - 190 + $i * 62, $cy - 265, 26, 26, $dot);
        }
    }

    private function motifTerminal(\GdImage $im, int $cx, int $cy, array $theme): void
    {
        [$r, $g, $b] = $theme['accent'];
        $c = imagecolorallocate($im, $r, $g, $b);
        $w = 290;
        $h = 210;

        $this->roundedRectOutline($im, $cx - $w, $cy - $h, $cx + $w, $cy + $h, 18, $c, 8);
        // Title bar + traffic lights.
        imagefilledrectangle($im, $cx - $w + 8, $cy - $h + 8, $cx + $w - 8, $cy - $h + 62, imagecolorallocatealpha($im, $r, $g, $b, 100));
        foreach (array(0, 1, 2) as $i) {
            imagefilledellipse($im, $cx - $w + 52 + $i * 46, $cy - $h + 35, 22, 22, $c);
        }
        // Prompt lines.
        $y = $cy - 90;
        foreach (array(360, 250, 300, 180) as $i => $len) {
            imagefilledrectangle($im, $cx - $w + 52, $y, $cx - $w + 52 + $len, $y + 18, $i === 3
                ? imagecolorallocatealpha($im, $r, $g, $b, 60) : $c);
            $y += 62;
        }
    }

    private function motifChart(\GdImage $im, int $cx, int $cy, array $theme): void
    {
        [$r, $g, $b] = $theme['accent'];
        $c = imagecolorallocate($im, $r, $g, $b);
        $soft = imagecolorallocatealpha($im, $r, $g, $b, 70);

        // Axes.
        $this->thickLine($im, $cx - 250, $cy + 200, $cx + 260, $cy + 200, $c, 8);
        $this->thickLine($im, $cx - 250, $cy + 200, $cx - 250, $cy - 230, $c, 8);

        // Bars.
        $heights = array(110, 190, 150, 265, 330);
        foreach ($heights as $i => $bh) {
            $x = $cx - 190 + $i * 92;
            imagefilledrectangle($im, $x, $cy + 200 - $bh, $x + 58, $cy + 194, $i === 4 ? $c : $soft);
        }
        // Trend arrow.
        $this->thickLine($im, $cx - 170, $cy + 60, $cx + 210, $cy - 160, $c, 9);
        $this->thickPolygon($im, array(
            $cx + 210, $cy - 160, $cx + 150, $cy - 150, $cx + 190, $cy - 105,
        ), $c, 7);
    }

    /**
     * A sensor board broadcasting upward: a chip with pin legs and three
     * widening signal arcs. Says "device sending readings" rather than the
     * node-graph's "things connected to things", so an IoT article reads
     * differently from an automation one in the listing.
     */
    private function motifSensor(\GdImage $im, int $cx, int $cy, array $theme): void
    {
        [$r, $g, $b] = $theme['accent'];
        $c    = imagecolorallocate($im, $r, $g, $b);
        $soft = imagecolorallocatealpha($im, $r, $g, $b, 78);

        $by = $cy + 130;   // board sits low; arcs radiate into the space above
        $bw = 150;
        $bh = 96;

        // Pin legs on both sides of the board.
        for ($i = 0; $i < 4; $i++) {
            $y = $by - $bh / 2 + 18 + $i * 20;
            $this->thickLine($im, $cx - $bw / 2 - 34, (int) $y, $cx - $bw / 2, (int) $y, $soft, 7);
            $this->thickLine($im, $cx + $bw / 2, (int) $y, $cx + $bw / 2 + 34, (int) $y, $soft, 7);
        }

        // Board body + inner die.
        $this->roundedRect($im, $cx - $bw / 2, (int) ($by - $bh / 2), $cx + $bw / 2, (int) ($by + $bh / 2), 16, $soft);
        $this->roundedRectOutline($im, $cx - $bw / 2, (int) ($by - $bh / 2), $cx + $bw / 2, (int) ($by + $bh / 2), 16, $c, 6);
        $this->roundedRect($im, $cx - 34, $by - 26, $cx + 34, $by + 26, 8, $c);

        // Three broadcast arcs, widening as they rise. imagearc ignores
        // imagesetthickness, so stack passes to build a readable stroke.
        $seedShift = ($this->seed % 3) * 6;
        for ($n = 1; $n <= 3; $n++) {
            $w  = 150 + $n * 132;
            $h  = 110 + $n * 96;
            $ay = $by - $bh / 2 - 6;
            for ($t = 0; $t < 7; $t++) {
                imagearc($im, $cx, (int) $ay, $w - $t * 2, $h - $t * 2, 206 + $seedShift, 334 - $seedShift, $n === 1 ? $c : $soft);
            }
        }
    }

    private function motifPlay(\GdImage $im, int $cx, int $cy, array $theme): void
    {
        [$r, $g, $b] = $theme['accent'];
        $c = imagecolorallocate($im, $r, $g, $b);

        for ($t = 0; $t < 20; $t++) {
            imageellipse($im, $cx, $cy, 460 - $t, 460 - $t, $c);
        }
        $this->thickPolygon($im, array(
            $cx - 70, $cy - 110,
            $cx + 120, $cy,
            $cx - 70, $cy + 110,
        ), $c, 9);
        imagefilledpolygon($im, array(
            $cx - 62, $cy - 92,
            $cx + 100, $cy,
            $cx - 62, $cy + 92,
        ), 3, imagecolorallocatealpha($im, $r, $g, $b, 60));
    }

    /**
     * Drafting sheet: a faint construction grid, an isometric extruded solid and
     * a dimension line — the visual language of AutoCAD/Revit/Fusion, so a CAD
     * article never has to borrow the video or terminal motif.
     */
    private function motifBlueprint(\GdImage $im, int $cx, int $cy, array $theme): void
    {
        [$r, $g, $b] = $theme['accent'];
        $c    = imagecolorallocate($im, $r, $g, $b);
        $soft = imagecolorallocatealpha($im, $r, $g, $b, 88);
        $grid = imagecolorallocatealpha($im, $r, $g, $b, 112);

        // Construction grid behind the solid. Pitch varies per post so a grid of
        // CAD cards does not read as the same image repeated.
        $pitch = 62 + ($this->seed % 4) * 9;
        for ($i = -3; $i <= 3; $i++) {
            imageline($im, $cx + $i * ($pitch + 12), $cy - 250, $cx + $i * ($pitch + 12), $cy + 210, $grid);
            imageline($im, $cx - 250, $cy + $i * $pitch, $cx + 250, $cy + $i * $pitch, $grid);
        }

        // Isometric block: top face, then the two visible side faces. Its
        // footprint and extrusion depth are seed-driven for the same reason.
        $tx = $cx;      $ty = $cy - 168;
        $hw = 150 + ($this->seed % 5) * 14;
        $hh = (int) round($hw * 0.52);
        $dep = 120 + (($this->seed >> 3) % 5) * 18;
        $this->thickPolygon($im, array(
            $tx, $ty, $tx + $hw, $ty + $hh, $tx, $ty + $hh * 2, $tx - $hw, $ty + $hh,
        ), $c, 7);
        $this->thickPolygon($im, array(
            $tx - $hw, $ty + $hh, $tx, $ty + $hh * 2, $tx, $ty + $hh * 2 + $dep, $tx - $hw, $ty + $hh + $dep,
        ), $soft, 7);
        $this->thickPolygon($im, array(
            $tx + $hw, $ty + $hh, $tx, $ty + $hh * 2, $tx, $ty + $hh * 2 + $dep, $tx + $hw, $ty + $hh + $dep,
        ), $c, 7);

        // Dimension line with end ticks under the solid.
        $dy = $cy + 232;
        $this->thickLine($im, $cx - $hw, $dy, $cx + $hw, $dy, $c, 6);
        $this->thickLine($im, $cx - $hw, $dy - 26, $cx - $hw, $dy + 26, $c, 6);
        $this->thickLine($im, $cx + $hw, $dy - 26, $cx + $hw, $dy + 26, $c, 6);

        // Vertex handles — the "selected geometry" cue from a CAD viewport.
        foreach (array(array($tx, $ty), array($tx - $hw, $ty + $hh), array($tx + $hw, $ty + $hh)) as $p) {
            imagefilledrectangle($im, $p[0] - 9, $p[1] - 9, $p[0] + 9, $p[1] + 9, $c);
        }
    }

    private function motifBadge(\GdImage $im, int $cx, int $cy, array $theme): void
    {
        [$r, $g, $b] = $theme['accent'];
        $c = imagecolorallocate($im, $r, $g, $b);

        // Rosette.
        $pts = array();
        $spikes = 12;
        for ($i = 0; $i < $spikes * 2; $i++) {
            $rad = ($i % 2 === 0) ? 215 : 178;
            $a = M_PI * $i / $spikes - M_PI / 2;
            $pts[] = (int) ($cx + cos($a) * $rad);
            $pts[] = (int) ($cy - 60 + sin($a) * $rad);
        }
        $this->thickPolygon($im, $pts, $c, 7);
        // Tick inside.
        $this->thickLine($im, $cx - 70, $cy - 60, $cx - 18, $cy - 6, $c, 18);
        $this->thickLine($im, $cx - 18, $cy - 6, $cx + 82, $cy - 130, $c, 18);
        // Ribbons.
        $this->thickPolygon($im, array($cx - 96, $cy + 118, $cx - 40, $cy + 108, $cx - 62, $cy + 252), $c, 7);
        $this->thickPolygon($im, array($cx + 96, $cy + 118, $cx + 40, $cy + 108, $cx + 62, $cy + 252), $c, 7);
    }

    /**
     * Hub-and-spoke agent graph. The spoke COUNT is varied per post (5-8) by
     * the caller's seed so two posts sharing a theme — e.g. several "Agentic
     * AI" articles — do not render byte-identical artwork side by side in the
     * listing.
     */
    private function motifNodes(\GdImage $im, int $cx, int $cy, array $theme): void
    {
        [$r, $g, $b] = $theme['accent'];
        $c = imagecolorallocate($im, $r, $g, $b);
        $edge = imagecolorallocatealpha($im, $r, $g, $b, 72);

        $count = 5 + ($this->seed % 4);      // 5..8 spokes
        $rot   = ($this->seed % 12) * (M_PI / 18); // small rotation offset
        $rx = 215;
        $nodes = array();
        for ($i = 0; $i < $count; $i++) {
            $a = $rot - M_PI / 2 + 2 * M_PI * $i / $count;
            $nodes[] = array((int) round(cos($a) * $rx), (int) round(sin($a) * $rx));
        }
        foreach ($nodes as $n) {
            $this->thickLine($im, $cx, $cy, $cx + $n[0], $cy + $n[1], $edge, 6);
        }
        // Ring linking the workers.
        for ($i = 0; $i < count($nodes); $i++) {
            $a = $nodes[$i];
            $bn = $nodes[($i + 1) % count($nodes)];
            $this->thickLine($im, $cx + $a[0], $cy + $a[1], $cx + $bn[0], $cy + $bn[1], $edge, 4);
        }
        foreach ($nodes as $n) {
            imagefilledellipse($im, $cx + $n[0], $cy + $n[1], 62, 62, $c);
        }
        // Hub.
        imagefilledellipse($im, $cx, $cy, 118, 118, $c);
        imagefilledellipse($im, $cx, $cy, 74, 74, imagecolorallocate($im, ...$theme['bg']));
    }

    // ------------------------------------------------------------- primitives

    private function thickLine(\GdImage $im, int $x1, int $y1, int $x2, int $y2, int $color, int $w): void
    {
        imagesetthickness($im, $w);
        imageline($im, $x1, $y1, $x2, $y2, $color);
        imagesetthickness($im, 1);
    }

    /** @param int[] $pts flat x,y list */
    private function thickPolygon(\GdImage $im, array $pts, int $color, int $w): void
    {
        imagesetthickness($im, $w);
        $n = count($pts) / 2;
        for ($i = 0; $i < $n; $i++) {
            $x1 = $pts[$i * 2];
            $y1 = $pts[$i * 2 + 1];
            $j  = ($i + 1) % $n;
            imageline($im, $x1, $y1, $pts[$j * 2], $pts[$j * 2 + 1], $color);
        }
        imagesetthickness($im, 1);
    }

    /**
     * Rounded filled rect that composites correctly for TRANSLUCENT colours.
     *
     * The naive build (two overlapping rectangles + four corner ellipses)
     * double-blends every pixel in the overlap when alpha < 127, so the corners
     * render darker than the body and read as bumps. Drawing scanline-by-
     * scanline touches each pixel exactly once, so any alpha stays flat.
     */
    private function roundedRect(\GdImage $im, int $x1, int $y1, int $x2, int $y2, int $r, int $color): void
    {
        for ($y = $y1; $y <= $y2; $y++) {
            $inset = 0;
            if ($y < $y1 + $r) {
                $dy = $r - ($y - $y1);
                $inset = (int) round($r - sqrt(max(0, $r * $r - $dy * $dy)));
            } elseif ($y > $y2 - $r) {
                $dy = $r - ($y2 - $y);
                $inset = (int) round($r - sqrt(max(0, $r * $r - $dy * $dy)));
            }
            imageline($im, $x1 + $inset, $y, $x2 - $inset, $y, $color);
        }
    }

    private function roundedRectOutline(\GdImage $im, int $x1, int $y1, int $x2, int $y2, int $r, int $color, int $w = 2): void
    {
        imagesetthickness($im, $w);
        imageline($im, $x1 + $r, $y1, $x2 - $r, $y1, $color);
        imageline($im, $x1 + $r, $y2, $x2 - $r, $y2, $color);
        imageline($im, $x1, $y1 + $r, $x1, $y2 - $r, $color);
        imageline($im, $x2, $y1 + $r, $x2, $y2 - $r, $color);
        imagearc($im, $x1 + $r, $y1 + $r, $r * 2, $r * 2, 180, 270, $color);
        imagearc($im, $x2 - $r, $y1 + $r, $r * 2, $r * 2, 270, 360, $color);
        imagearc($im, $x1 + $r, $y2 - $r, $r * 2, $r * 2, 90, 180, $color);
        imagearc($im, $x2 - $r, $y2 - $r, $r * 2, $r * 2, 0, 90, $color);
        imagesetthickness($im, 1);
    }
}
