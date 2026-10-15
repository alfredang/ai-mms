<?php
/**
 * Malaysia localisation rules for content copied from the Singapore master.
 *
 * Used by the Malaysia-aware course sync and the Batch 2 content refresh, so the same rules
 * apply everywhere SG course content lands on the Malaysia site:
 *
 *   R1  Singapore funding boxes removed — "Funding and Grant Applications" / "WSQ Funding"
 *       wrappers and headings, "No funding is available…" / "For WSQ funding…" paragraphs.
 *   R2  Links to tertiarycourses.com.sg: pointed at the same Malaysia page when it exists,
 *       otherwise the link is dropped (its text kept unless the text is SG wording); SG
 *       exam-voucher paragraphs and images served from the SG site are removed.
 *   R3  Company / brand: Singapore legal entities -> "Tertiary Infotech Sdn. Bhd.";
 *       "Tertiary Courses Singapore" -> "Tertiary Courses Malaysia".
 *   R4  Singapore funding schemes: sentences mentioning SkillsFuture, SSG, UTAP, PSEA, SFEC,
 *       IBF, MCES, SWDA, Absentee Payroll, CASL, NTUC — or Singapore regulators / systems (IRAS,
 *       InvoiceNow, CPF, ACRA, "Singapore's …") — are removed; "WSQ" used as a label
 *       ("this WSQ course", "the WSQ assessment") is dropped.
 *   R5  "in Singapore" -> "in Malaysia", "like Singapore" -> "like Kuala Lumpur" (generic phrasing only).
 *   R6  Sections under an h2/h3 about SG funding (Training Grant, SkillsFuture, UTAP, PWM,
 *       WSQ promo rules) are removed, then headings left with no content are dropped.
 *   R7  Singapore prices and GST: tables, rows, list items and paragraphs mentioning GST, S$ or
 *       SGD are removed (group, 15 Oct: no S$ or Singapore GST wording on Malaysia).
 *
 * Anything still matching SG terms after the rules is reported by remainingSgTerms() for
 * manual review rather than rewritten blindly.
 *
 * Field helpers for the sync: metaDescription() (<= 160 chars at a sentence / clause
 * boundary), keywords() (drops SG keywords), urlKey() (no singapore / wsq / skillsfuture
 * slug tokens), isSgOnlyCategory(), eveningLabel() ("… Evening (Wed/Thu, 2 evenings)").
 */
class MMD_RoleManager_Model_Sync_MyLocaliser
{
    const WS = '(?:\s|&nbsp;|\x{00A0})';

    /** Malaysia request paths (url_rewrite + CMS identifiers) used by R2. */
    protected $_myPaths = array();

    public function __construct(array $myPaths = array())
    {
        $this->_myPaths = array_flip($myPaths);
    }

    public function localise($html)
    {
        $html = (string) $html;
        if ($html === '') {
            return $html;
        }
        $html = $this->_removeFundingBoxes($html);
        $html = $this->_localiseSgLinks($html);
        $html = $this->_localiseCompany($html);
        $html = $this->_removeSgSchemes($html);
        $html = $this->_removeSgPricing($html);
        $html = preg_replace('#\bin' . self::WS . '+Singapore\b#u', 'in Malaysia', $html);
        $html = preg_replace('#\blike' . self::WS . '+Singapore\b#u', 'like Kuala Lumpur', $html);
        // tidy: empty paragraphs/list items left behind by removed sentences
        $html = preg_replace('#<(p|li)\b[^>]*>(?:\s|&nbsp;|<br\s*/?>)*</\1>#iu', '', $html);
        $html = preg_replace('#<(ul|ol)\b[^>]*>\s*</\1>#iu', '', $html);
        // headings whose whole section was removed (followed directly by another heading or the end)
        for ($lv = 6; $lv >= 1; $lv--) {
            $html = preg_replace('#<h' . $lv . '\b[^>]*>(?:(?!</h' . $lv . '>).)*</h' . $lv . '>\s*(?=<h[1-' . $lv . ']\b|\z)#siu', '', $html);
        }
        return trim($html);
    }

    const SG_TERMS = 'WSQ|SkillsFuture|Singapore|\bSSG\b|UTAP|\bIBF\b|PSEA|SFEC|SWDA|\bIRAS\b|InvoiceNow|\bCPF\b|\bACRA\b|\bGST\b|S\$|\bSGD\b';

    /** Plain-text meta description, localised, <= $max chars (whole sentences, else a clause). */
    public function metaDescription($text, $max = 160)
    {
        $text = html_entity_decode(strip_tags($this->localise((string) $text)), ENT_QUOTES, 'UTF-8');
        $text = trim(preg_replace('/\s+/u', ' ', str_replace("\xEF\xBF\xBD", '-', $text)));
        if (preg_match('/' . self::SG_TERMS . '/iu', $text)) {
            return '';   // still Singapore-specific after localising (short plain text) — callers keep Malaysia's value
        }
        if (mb_strlen($text) <= 170) {
            return $text;
        }
        $out = '';
        foreach (preg_split('/(?<=[.!?])\s+/u', $text) as $s) {
            if (mb_strlen(trim("$out $s")) > $max) {
                break;
            }
            $out = trim("$out $s");
        }
        if (mb_strlen($out) >= 120) {
            return $out;
        }
        $cut = mb_substr($text, 0, $max);
        $pos = 0;
        foreach (array(', ', ' - ', " \u{2013} ", ' and ', '. ') as $sep) {
            $p = mb_strrpos($cut, $sep);
            if ($p !== false && $p > $pos) {
                $pos = $p;
            }
        }
        if ($pos < 110) {
            $pos = mb_strrpos(mb_substr($text, 0, $max - 1), ' ');
        }
        $out = rtrim(mb_substr($text, 0, $pos), " ,;:-\u{2013}.");
        $out = preg_replace('/(?:\s+(?:at|in|with|and|or|for|to|the|a|an|of|using|like|by|on|from|your|our))+$/iu', '', $out);
        return rtrim($out, " ,;:-\u{2013}.") . '.';
    }

    /** Comma-separated keywords without Singapore funding / regulator terms. */
    public function keywords($csv)
    {
        return implode(', ', array_filter(array_map('trim', explode(',', (string) $csv)), function ($k) {
            return $k !== '' && !preg_match('/' . self::SG_TERMS . '/iu', $k);
        }));
    }

    /** Malaysia URL key from a Singapore one: singapore -> malaysia, wsq / skillsfuture tokens dropped. */
    public function urlKey($key)
    {
        $parts = array();
        foreach (explode('-', strtolower(preg_replace('/\.html$/', '', trim((string) $key)))) as $p) {
            if ($p === 'singapore') {
                $parts[] = 'malaysia';
            } elseif ($p !== '' && !in_array($p, array('wsq', 'skillsfuture', 'sg'), true)) {
                $parts[] = $p;
            }
        }
        return implode('-', $parts);
    }

    /** Category that only makes sense in Singapore (funding schemes / WSQ), by URL key or name. */
    public function isSgOnlyCategory($urlKey, $name = '')
    {
        return (bool) preg_match('/wsq|skillsfuture|\bibf\b|utap|psea|sfec|casl/i', $urlKey . ' ' . $name)
            || substr((string) $urlKey, -8) === '-retired';
    }

    /** "28/29 Oct 2026 Evening (Wed/Thu)" -> "28/29 Oct 2026 Evening (Wed/Thu, 2 evenings)". */
    public function eveningLabel($title)
    {
        return preg_match('#/.* Evening \(\w{3}/\w{3}\)$#', $title) && stripos($title, 'evenings') === false
            ? substr($title, 0, -1) . ', 2 evenings)' : $title;
    }

    /** SG terms still present (for the review report), e.g. ['WSQ' => 2]. */
    public function remainingSgTerms($html)
    {
        preg_match_all('#WSQ|SkillsFuture|\bSSG\b|UTAP|PSEA|SFEC|\bIBF\b|\bCASL\b|MCES|SWDA|NTUC|Singapore|tertiarycourses\.com\.sg|S\$#u',
            strip_tags((string) $html) . ' ' . $html, $m);
        return array_count_values($m[0]);
    }

    protected function _removeFundingBoxes($html)
    {
        $ws = self::WS;
        $fundingRe = '#WSQ|SkillsFuture|Funding' . $ws . '+and' . $ws . '+Grant|No' . $ws . '+funding|grant#iu';
        $html = preg_replace_callback('#<div\b[^>]*border-radius\s*:[^>]*>(.*?)</div>#siu', function ($m) use ($fundingRe) {
            return preg_match($fundingRe, $m[1]) ? '' : $m[0];
        }, $html);
        $html = preg_replace('#<h[1-6][^>]*>' . $ws . '*(?:WSQ' . $ws . '+Funding|Funding' . $ws . '+and' . $ws . '+Grant' . $ws . '+Applications?)' . $ws . '*</h[1-6]>.*?(?=<h[12]\b|\z)#siu', '', $html);
        // h2/h3 sections about SG funding, claims, PWM or WSQ promo rules (up to the next h1-h3)
        $html = preg_replace('#<h([23])\b[^>]*>(?:(?!</h\1>).)*?(?:Training' . $ws . '+Grant|Funding|Skills' . $ws . '*Future|UTAP|SWDA|\bSSG\b|WSQ|Fee' . $ws . '+Support|PWM|Progressive' . $ws . '+Wage|Level-Up|Promotion' . $ws . '+Code)(?:(?!</h\1>).)*?</h\1>.*?(?=<h[1-3]\b|\z)#siu', '', $html);
        return preg_replace('#<p\b[^>]*>(?:(?!</p>).)*?(?:No' . $ws . '+funding|For' . $ws . '+WSQ' . $ws . '+funding)(?:(?!</p>).)*?</p>#siu', '', $html);
    }

    protected function _localiseSgLinks($html)
    {
        $sgHost = 'https?://(?:www\.)?tertiarycourses\.com\.sg';
        $myPaths = $this->_myPaths;
        $html = preg_replace('#<p\b[^>]*>(?:(?!</p>).)*?exam voucher(?:(?!</p>).)*?' . $sgHost . '(?:(?!</p>).)*?</p>#siu', '', $html);
        $html = preg_replace('#<img\b[^>]*src="' . $sgHost . '[^"]*"[^>]*>#iu', '', $html);
        // bare SG URLs written as text: the paragraph/list item is an SG cross-sell, drop it
        $html = preg_replace('#<(p|li)\b[^>]*>(?:(?!</\1>).)*?(?<!")' . $sgHost . '(?:(?!</\1>).)*?</\1>#siu', '', $html);
        return preg_replace_callback('#<a\b[^>]*href="' . $sgHost . '/?([^"\#?]*)[^"]*"[^>]*>(.*?)</a>#siu', function ($m) use ($myPaths) {
            if ($m[1] !== '' && isset($myPaths[$m[1]])) {
                return preg_replace('#href="[^"]*"#', 'href="/' . $m[1] . '"', $m[0], 1);
            }
            return preg_match('#WSQ|SkillsFuture|\bIBF\b|\bCASL\b#i', strip_tags($m[2])) ? '' : $m[2];
        }, $html);
    }

    protected function _localiseCompany($html)
    {
        $html = preg_replace('#Tertiary' . self::WS . '+Infotech' . self::WS . '+(?:Academy' . self::WS . '+)?Pte\.?' . self::WS . '*Ltd\.?#u', 'Tertiary Infotech Sdn. Bhd.', $html);
        return preg_replace('#Tertiary' . self::WS . '+Courses' . self::WS . '+Singapore#u', 'Tertiary Courses Malaysia', $html);
    }

    protected function _removeSgSchemes($html)
    {
        $schemes = 'SkillsFuture|\bSSG\b|UTAP|PSEA|SFEC|\bIBF\b|MCES|SWDA|Absentee' . self::WS . '+Payroll|\bCASL\b|NTUC'
                 . '|\bIRAS\b|InvoiceNow|\bCPF\b|\bACRA\b|Singapore(?:&rsquo;|\x{2019}|\')s';   // SG regulators / systems
        // whole list items / paragraphs that are about an SG scheme
        $html = preg_replace('#<(li|p)\b[^>]*>(?:(?!</\1>).)*?(?:' . $schemes . ')(?:(?!</\1>).)*?</\1>#siu', '', $html);
        // remaining sentences inside other text
        $html = preg_replace('#[^.!?<>]*(?:' . $schemes . ')[^.!?<>]*[.!?]\s*#iu', '', $html);
        // Singapore-style percentage subsidy claims ("the generous 70% funding subsidy …") — sentence only
        $html = preg_replace('#[^.!?<>]*\d+\s*%\s*(?:WSQ\s+)?(?:funding|subsid)[^.!?<>]*[.!?]\s*#iu', '', $html);
        // "WSQ" as a label: "this WSQ course", "the WSQ assessment", "WSQ - X" titles
        $html = preg_replace('#\bWSQ' . self::WS . '*-' . self::WS . '*#u', '', $html);
        return preg_replace('#\bWSQ' . self::WS . '+#u', '', $html);
    }

    protected function _removeSgPricing($html)
    {
        $sg = '\bGST\b|S\$|\bSGD\b';
        $html = preg_replace('#<table\b[^>]*>(?:(?!</table>).)*?(?:' . $sg . ')(?:(?!</table>).)*?</table>#siu', '', $html);
        return preg_replace('#<(tr|li|p)\b[^>]*>(?:(?!</\1>).)*?(?:' . $sg . ')(?:(?!</\1>).)*?</\1>#siu', '', $html);
    }
}
