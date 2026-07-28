<?php
/**
 * Shared AI-SEO logic. Pulled out of the controller so the CLI bulk
 * generator (scripts/maintenance/bulk-seo-meta.php) and the controller's
 * aiSeoAllStoresAction can share the same code path without the CLI
 * having to instantiate a controller with a full request/response.
 *
 * Three responsibilities:
 *   1. Invoke Claude (Anthropic API → CLI fallback)
 *   2. Parse the multi-store markdown output
 *   3. Persist meta_title / meta_keyword / meta_description per store
 */
class MMD_RoleManager_Model_AiSeo
{
    const STORE_SG = 1;
    const STORE_NG = 4;

    /**
     * Multi-store generate for ONE product. Returns:
     *   stubbed     => bool
     *   stub_reason => string|null
     *   raw         => string raw model output
     *   per_store   => [ storeId => [meta_title, meta_keyword, meta_description] ]
     */
    public function generateMultiStore($product, $courseTitle, $learningOutcomes, $courseHighlights)
    {
        $sku     = (string) $product->getSku();
        $segment = (strpos($sku, 'TGS-') === 0) ? 'WSQ' : 'Non-WSQ';

        $tplFile = Mage::getBaseDir('code') . '/local/MMD/RoleManager/etc/ai-seo/multi-store.md';
        if (!is_readable($tplFile)) {
            throw new Exception('Multi-store prompt template missing: ' . $tplFile);
        }
        $tpl  = file_get_contents($tplFile);
        $vals = array(
            'segment'           => $segment,
            'course_title'      => $courseTitle ?: (string) $product->getName(),
            'learning_outcomes' => $learningOutcomes,
            'course_highlights' => $courseHighlights ?: strip_tags((string) $product->getData('short_description')),
        );
        foreach ($vals as $k => $v) {
            $tpl = str_replace('{' . $k . '}', $v, $tpl);
        }

        $stdout      = $this->invokeClaude($tpl);
        $stubbed     = false;
        $stub_reason = null;
        if ($stdout === '' || $stdout === null) {
            $stubbed     = true;
            $stub_reason = 'all generator tiers failed';
            $stdout      = '';
        }

        $sections = $stdout !== '' ? $this->parseSections($stdout) : array();

        $kw      = (string) ($sections['meta_keywords']    ?? '');
        $descDef = (string) ($sections['meta_description'] ?? '');
        $perStore = array(
            self::STORE_SG => array(
                'meta_title'       => (string) ($sections['meta_title'] ?? ''),
                'meta_keyword'     => $kw,
                'meta_description' => $descDef,
            ),
            self::STORE_NG => array(
                'meta_title'       => (string) ($sections['meta_title_for_nigeria'] ?? ''),
                'meta_keyword'     => $kw,
                'meta_description' => $descDef,
            ),
        );

        // Strip stores where the title came back empty so we don't blank
        // out existing copy with a parser miss.
        foreach ($perStore as $sid => $row) {
            if (trim($row['meta_title']) === '') unset($perStore[$sid]);
        }

        return array(
            'stubbed'     => $stubbed,
            'stub_reason' => $stub_reason,
            'raw'         => $stdout,
            'per_store'   => $perStore,
        );
    }

    /**
     * Persist meta to one store scope via saveAttribute (no full product
     * save → no indexer/observer side-effects).
     */
    public function persistToStore($productId, $storeId, $title, $keyword, $description)
    {
        $storeId = (int) $storeId;
        if ($storeId <= 0) return;
        $sp = Mage::getModel('catalog/product')->setStoreId($storeId)->load((int) $productId);
        if (!$sp || !$sp->getId()) return;
        foreach (array(
            'meta_title'       => $title,
            'meta_keyword'     => $keyword,
            'meta_description' => $description,
        ) as $attr => $val) {
            if ($val === null) continue;
            $sp->setData($attr, (string) $val);
            $sp->getResource()->saveAttribute($sp, $attr);
        }
    }

    /**
     * Three-tier Claude invocation.
     *   1. Anthropic API direct (sk-ant-api* keys; OAuth tokens skip
     *      because they 429 aggressively).
     *   2. `claude` CLI via proc_open with HOME pointing at the mounted
     *      ~/.claude credentials.
     *   3. Empty string — caller decides whether to fall back further.
     */
    public function invokeClaude($prompt)
    {
        $cfg    = Mage::helper('mmd_rolemanager')->getMarketingApiConfig();
        $apiKey = trim((string) ($cfg['anthropic_key']   ?? ''));
        $model  = trim((string) ($cfg['anthropic_model'] ?? '')) ?: 'claude-sonnet-4-6';

        if (stripos($apiKey, 'sk-ant-api') === 0) {
            try {
                $body = json_encode(array(
                    'model'      => $model,
                    'max_tokens' => 2000,
                    'system'     => 'You are an SEO copywriter for Tertiary Courses. Output exactly the labeled sections requested, no preamble.',
                    'messages'   => array(array('role' => 'user', 'content' => $prompt)),
                ));
                $ch = curl_init('https://api.anthropic.com/v1/messages');
                curl_setopt_array($ch, array(
                    CURLOPT_POST           => true,
                    CURLOPT_POSTFIELDS     => $body,
                    CURLOPT_RETURNTRANSFER => true,
                    CURLOPT_TIMEOUT        => 60,
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

        $descriptors = array(0 => array('pipe','r'), 1 => array('pipe','w'), 2 => array('pipe','w'));
        $env = array();
        foreach ($_ENV as $k => $v) if ($k !== 'CLAUDECODE') $env[$k] = $v;
        foreach (array('PATH', 'HOME') as $k) {
            if (!isset($env[$k]) && getenv($k) !== false) $env[$k] = getenv($k);
        }
        if (is_dir('/var/www/.claude'))                          $env['HOME'] = '/var/www';
        elseif (is_dir('/root/.claude') && is_readable('/root')) $env['HOME'] = '/root';
        if (empty($env['HOME']) || !is_writable($env['HOME'])) {
            $env['HOME'] = sys_get_temp_dir();
        }
        // Subscription OAuth tokens (sk-ant-oat*) can't use the direct API
        // path above, but they DO authenticate the Claude Code CLI headlessly.
        if (stripos($apiKey, 'sk-ant-oat') === 0) {
            $env['CLAUDE_CODE_OAUTH_TOKEN'] = $apiKey;
        }
        $env['DISABLE_AUTOUPDATER'] = '1';

        $proc = @proc_open('timeout 110 claude -p --output-format text', $descriptors, $pipes, null, $env);
        if (!is_resource($proc)) return '';
        fwrite($pipes[0], $prompt);
        fclose($pipes[0]);
        stream_set_blocking($pipes[1], false);
        stream_set_blocking($pipes[2], false);
        $deadline = time() + 115;
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

    /**
     * Parse the **Label:** value sections from Claude's markdown.
     * Same shape as CoursesaveController::_parseAiSeoSections — kept in
     * sync. Singapore "for X" collapses to default key.
     */
    public function parseSections($md)
    {
        $out = array();
        $pattern = '/^\s*(?:\d+\.\s*)?\*\*([^*]+?)\*\*:?\s*(.*)$/mu';
        if (!preg_match_all($pattern, $md, $matches, PREG_OFFSET_CAPTURE)) return $out;
        $count = count($matches[0]);
        for ($i = 0; $i < $count; $i++) {
            $rawLabel = strtolower(trim($matches[1][$i][0]));
            $rawLabel = rtrim($rawLabel, " :.\t");
            $rawLabel = preg_replace('/^seo\s+/', '', $rawLabel);
            $rawLabel = preg_replace('/\s+for\s+singapore$/', '', $rawLabel);
            if (preg_match('/^(.*?)\s*\(([^)]+)\)\s*$/u', $rawLabel, $pm)) {
                $base = trim($pm[1]);
                $var  = strtolower(trim($pm[2]));
                $rawLabel = ($var === 'default' || $var === 'singapore') ? $base : ($base . ' for ' . $var);
            }
            $label = preg_replace('/\s+/', '_', trim($rawLabel));
            $start = $matches[2][$i][1];
            $end   = ($i + 1 < $count) ? $matches[0][$i + 1][1] : strlen($md);
            $value = trim(substr($md, $start, $end - $start));
            $value = preg_replace('/^[\-\*]\s+/m', '', $value);
            $value = preg_replace('/^-{3,}\s*$/m', '', $value);
            $out[$label] = trim($value);
        }
        return $out;
    }
}
