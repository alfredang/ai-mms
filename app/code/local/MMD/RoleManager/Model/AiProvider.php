<?php
/** Global provider selection. OAuth secrets are never returned to the browser. */
class MMD_RoleManager_Model_AiProvider
{
    const PROVIDER_PATH = 'mmd_ai/provider';
    const AUTH_PATH = 'mmd_ai/openai/oauth_encrypted';
    const OPENAI_MODEL = 'gpt-5.6-sol';

    protected function readValue($path)
    {
        $r = Mage::getSingleton('core/resource');
        return (string) $r->getConnection('core_read')->fetchOne(
            $r->getConnection('core_read')->select()->from($r->getTableName('core/config_data'), 'value')
                ->where('scope = ?', 'default')->where('scope_id = ?', 0)->where('path = ?', $path)
        );
    }

    public function isOpenAi()
    {
        return $this->readValue(self::PROVIDER_PATH) === 'openai';
    }

    public function hasOpenAiAuth()
    {
        return $this->readValue(self::AUTH_PATH) !== '';
    }

    public function validateAuth($json)
    {
        if (!is_string($json) || strlen($json) > 65536) {
            throw new DomainException('Upload a Codex OAuth auth.json file smaller than 64 KB.');
        }
        $auth = json_decode($json, true);
        if (!is_array($auth) || !empty($auth['OPENAI_API_KEY']) || ($auth['auth_mode'] ?? 'chatgpt') !== 'chatgpt') {
            throw new DomainException('Use a ChatGPT OAuth login, not an OpenAI API key.');
        }
        $tokens = array();
        foreach (array('access_token', 'refresh_token', 'id_token', 'account_id') as $key) {
            $value = $auth['tokens'][$key] ?? null;
            if (!is_string($value) || $value === '' || strlen($value) > 20000 || preg_match('/[\x00-\x20]/', $value)) {
                throw new DomainException('The OAuth file is incomplete. Sign in to Codex again and export auth.json.');
            }
            $tokens[$key] = $value;
        }
        return json_encode(array('auth_mode' => 'chatgpt', 'OPENAI_API_KEY' => null, 'tokens' => $tokens,
            'last_refresh' => is_string($auth['last_refresh'] ?? null) ? $auth['last_refresh'] : null));
    }

    /** Test before committing either the credentials or the global provider. */
    public function selectProvider($provider, $uploadedAuth = null)
    {
        if (!in_array($provider, array('claude', 'openai'), true)) {
            throw new DomainException('Choose Claude or OpenAI OAuth.');
        }
        if ($provider === 'openai') {
            $saved = $this->readValue(self::AUTH_PATH);
            $auth = $uploadedAuth !== null ? $this->validateAuth($uploadedAuth)
                : $this->validateAuth(Mage::helper('core')->decrypt($saved));
            $result = $this->runClient('Reply with exactly OK.', '', array(), false, $auth);
            if (trim($result) !== 'OK') {
                throw new DomainException('OpenAI connection test did not pass. The provider was not changed.');
            }
            Mage::getConfig()->saveConfig(self::AUTH_PATH, Mage::helper('core')->encrypt($auth), 'default', 0);
        }
        Mage::getConfig()->saveConfig(self::PROVIDER_PATH, $provider, 'default', 0);
        Mage::app()->cleanCache(array('config'));
    }

    public function invoke($prompt, $system = '', array $images = array(), $webSearch = false)
    {
        $saved = $this->readValue(self::AUTH_PATH);
        if ($saved === '') {
            throw new DomainException('OpenAI OAuth is not connected. Ask an administrator to connect it in Credentials.');
        }
        $auth = $this->validateAuth(Mage::helper('core')->decrypt($saved));
        try {
            return $this->runClient($prompt, $system, $images, $webSearch, $auth);
        } finally {
            // Compare-and-swap: an in-flight request must never overwrite a newly imported login.
            $r = Mage::getSingleton('core/resource');
            $r->getConnection('core_write')->update($r->getTableName('core/config_data'),
                array('value' => Mage::helper('core')->encrypt($auth)),
                array('scope = ?' => 'default', 'scope_id = ?' => 0, 'path = ?' => self::AUTH_PATH, 'value = ?' => $saved));
        }
    }

    protected function runClient($prompt, $system, array $images, $webSearch, &$auth)
    {
        if (!is_executable($this->clientBinary())) {
            throw new DomainException('OpenAI client is not installed on this server. Deploy the updated application first.');
        }
        if (strlen($prompt) + strlen($system) > 500000 || count($images) > 8) {
            throw new DomainException('The AI request is too large. Shorten the conversation or use fewer images.');
        }
        $dir = sys_get_temp_dir() . '/mmd-openai-' . bin2hex(random_bytes(16));
        if (!mkdir($dir, 0700)) {
            throw new DomainException('Unable to create a private OpenAI session.');
        }
        $proc = null;
        $pipes = array();
        try {
            $this->privateFile($dir . '/auth.json', $auth);
            $this->privateFile($dir . '/prompt.txt', $system . "\n\n" . $prompt);
            $args = array('/usr/bin/timeout', '-k', '5', '110', $this->clientBinary(), 'exec',
                '--ignore-user-config', '--ignore-rules', '--skip-git-repo-check', '--ephemeral',
                '--sandbox', 'read-only', '--json', '--color', 'never',
                '--model', self::OPENAI_MODEL,
                '-c', 'forced_login_method="chatgpt"', '-c', 'cli_auth_credentials_store="file"',
                '-c', 'web_search="' . ($webSearch ? 'live' : 'disabled') . '"',
                '-c', 'project_doc_max_bytes=0', '-c', 'approval_policy="never"');
            // Copywriting is not an agent workflow. No shell, files, plugins, browsers or apps.
            foreach (array('shell_tool', 'unified_exec', 'multi_agent', 'multi_agent_v2', 'apps', 'plugins',
                'hooks', 'memories', 'skill_search', 'image_generation', 'view_image', 'browser_use',
                'browser_use_external', 'computer_use', 'code_mode', 'code_mode_host', 'tool_suggest') as $feature) {
                $args[] = '--disable';
                $args[] = $feature;
            }
            foreach ($images as $i => $img) {
                $bytes = base64_decode((string) ($img['data'] ?? ''), true);
                $info = $bytes !== false ? @getimagesizefromstring($bytes) : false;
                if (!$info || strlen($bytes) > 5000000 || !in_array($info['mime'], array('image/png', 'image/jpeg', 'image/webp'), true)) {
                    throw new DomainException('Reference images must be PNG, JPEG or WebP and under 5 MB.');
                }
                $path = $dir . '/image-' . $i . '.' . array('image/png' => 'png', 'image/jpeg' => 'jpg', 'image/webp' => 'webp')[$info['mime']];
                $this->privateFile($path, $bytes);
                $args[] = '--image';
                $args[] = $path;
            }
            $args[] = '-';
            // Only intentional CLI configuration is inherited; no app/API/environment secrets.
            $env = array('PATH' => '/usr/local/bin:/usr/bin:/bin', 'CODEX_HOME' => $dir);
            $proc = @proc_open($args, array(0 => array('file', $dir . '/prompt.txt', 'r'),
                1 => array('pipe', 'w'), 2 => array('pipe', 'w')), $pipes, $dir, $env);
            if (!is_resource($proc)) {
                throw new DomainException('Unable to start the OpenAI client.');
            }
            stream_set_blocking($pipes[1], false);
            stream_set_blocking($pipes[2], false);
            $out = ''; $exit = -1; $deadline = microtime(true) + 118;
            do {
                $out .= stream_get_contents($pipes[1]);
                stream_get_contents($pipes[2]); // Never log provider errors containing credentials/prompts.
                $state = proc_get_status($proc);
                if (!$state['running']) { $exit = $state['exitcode']; break; }
                if (strlen($out) > 2000000) break;
                usleep(100000);
            } while (microtime(true) < $deadline);
            if ($state['running']) proc_terminate($proc, 9);
            $out .= stream_get_contents($pipes[1]);
            $answer = ''; $completed = false;
            foreach (explode("\n", $out) as $line) {
                $event = json_decode($line, true);
                if (($event['type'] ?? '') === 'turn.completed') $completed = true;
                if (($event['type'] ?? '') === 'item.completed' && ($event['item']['type'] ?? '') === 'agent_message') {
                    $answer = (string) ($event['item']['text'] ?? '');
                }
            }
            if ($exit !== 0 || !$completed || trim($answer) === '') {
                throw new DomainException('OpenAI generation failed or timed out. Check the OAuth connection and account access in Credentials. Nothing was sent.');
            }
            return trim($answer);
        } finally {
            if (is_resource($proc)) {
                foreach ($pipes as $pipe) if (is_resource($pipe)) fclose($pipe);
                proc_close($proc);
            }
            if (is_readable($dir . '/auth.json')) {
                try { $auth = $this->validateAuth(file_get_contents($dir . '/auth.json')); } catch (Exception $e) { /* keep validated original */ }
            }
            $this->removePrivateDirectory($dir);
        }
    }

    protected function privateFile($path, $content)
    {
        $file = fopen($path, 'x');
        if (!$file) throw new DomainException('Unable to prepare a private OpenAI session.');
        chmod($path, 0600);
        $written = fwrite($file, $content);
        fclose($file);
        if ($written !== strlen($content)) throw new DomainException('Unable to prepare a private OpenAI session.');
    }

    protected function clientBinary()
    {
        return '/usr/local/bin/codex';
    }

    protected function removePrivateDirectory($dir)
    {
        foreach (new FilesystemIterator($dir, FilesystemIterator::SKIP_DOTS) as $file) {
            if ($file->isDir() && !$file->isLink()) $this->removePrivateDirectory($file->getPathname());
            else unlink($file->getPathname());
        }
        rmdir($dir);
    }
}
