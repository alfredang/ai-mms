<?php
/**
 * Weekly auto-blog job (cron: Monday 09:00, see etc/config.xml) — the Magento
 * port of ai-cms's weekly-blog pipeline:
 *
 *   1. Pick the best-selling course (last 180 days) that has no blog post yet
 *      (tracked via mmd_blog_post.source_sku).
 *   2. Ask Claude for a complete lead-magnet post as strict JSON (title, slug,
 *      excerpt, HTML body, SEO meta, tags). The prompt hard-requires the WSQ
 *      funding + SkillsFuture Credit hooks and sign-up links to the course page.
 *   3. Insert the post (published when mmd_blog/autoblog/auto_publish, else draft),
 *      sync tags into the shared Magento `tag` table.
 *   4. Share on LinkedIn (text + link; LinkedIn renders the og: card) when
 *      mmd_blog/autoblog/linkedin_enabled and the env credentials exist.
 *
 * Every step degrades gracefully: disabled -> skip, no Claude credentials ->
 * skip, LinkedIn failure -> post still exists, error logged to mmd_blog.log.
 * The admin grid's "Generate Now" button calls run('manual') directly.
 */
class MMD_Blog_Model_Cron_Autoblog
{
    public function run($trigger = 'cron')
    {
        try {
            if (!Mage::getStoreConfigFlag('mmd_blog/autoblog/enabled')) {
                return $this->_log('skipped: autoblog disabled');
            }

            // One post per cycle — protects against overlapping cron + manual runs.
            if ($trigger === 'cron' && $this->_recentAutoPostExists()) {
                return $this->_log('skipped: an auto post was already created in the last 5 days');
            }

            $course = $this->_pickCourse();
            if (!$course) {
                return $this->_log('skipped: no unblogged course with a URL found');
            }

            $raw = $this->_invokeClaude($this->_writerSystemPrompt(), $this->_writerInput($course), 8000);
            if ($raw === '') {
                return $this->_log('skipped: Claude returned nothing (no API key / CLI available?)');
            }
            $draft = $this->_parseJson($raw);

            $helper  = Mage::helper('mmd_blog');
            $urlKey  = $helper->ensureUniqueUrlKey($helper->slugify($draft['slug'] ?: $draft['title']));
            $publish = Mage::getStoreConfigFlag('mmd_blog/autoblog/auto_publish');

            $post = Mage::getModel('mmd_blog/post')->setData(array(
                'title'            => $draft['title'],
                'url_key'          => $urlKey,
                'excerpt'          => $draft['excerpt'],
                'content'          => $draft['contentHtml'],
                'author'           => Mage::getStoreConfig('general/store_information/name') ?: 'Tertiary Infotech Academy',
                'status'           => $publish ? MMD_Blog_Model_Post::STATUS_PUBLISHED : MMD_Blog_Model_Post::STATUS_DRAFT,
                'published_at'     => date('Y-m-d'),
                'related_skus'     => $course['sku'],
                'source_sku'       => $course['sku'],
                'meta_title'       => $draft['seoTitle'],
                'meta_description' => $draft['seoDescription'],
                'meta_keywords'    => $draft['seoKeywords'],
            ));
            $post->save();
            if (!empty($draft['tags'])) {
                $helper->syncTags($post->getId(), $draft['tags']);
            }

            $liMsg = ' | linkedin: off';
            if ($publish && Mage::getStoreConfigFlag('mmd_blog/autoblog/linkedin_enabled')) {
                $liMsg = ' | ' . $this->_shareOnLinkedin($post, $draft);
            }

            return $this->_log(sprintf(
                'ok: post %d (%s) from course %s [%s]%s',
                $post->getId(), $urlKey, $course['sku'], $trigger, $liMsg
            ));
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_log('error: ' . $e->getMessage());
        }
    }

    private function _recentAutoPostExists()
    {
        $read  = Mage::getSingleton('core/resource')->getConnection('core_read');
        $table = Mage::getSingleton('core/resource')->getTableName('mmd_blog/post');
        return (bool) $read->fetchOne(
            "SELECT post_id FROM {$table}
             WHERE source_sku IS NOT NULL AND created_at >= DATE_SUB(NOW(), INTERVAL 5 DAY) LIMIT 1"
        );
    }

    /**
     * Best-selling course of the last 180 days that (a) is enabled + visible,
     * (b) has a storefront URL rewrite, (c) hasn't been auto-blogged before.
     *
     * @return array{sku:string,name:string,url:string,description:string}|null
     */
    private function _pickCourse()
    {
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $rows = $read->fetchAll(
            "SELECT oi.sku, oi.name, COUNT(*) AS orders
             FROM {$resource->getTableName('sales/order_item')} oi
             WHERE oi.created_at >= DATE_SUB(NOW(), INTERVAL 180 DAY)
               AND oi.parent_item_id IS NULL AND oi.sku IS NOT NULL AND oi.sku <> ''
               AND oi.sku NOT IN (
                   SELECT bp.source_sku FROM {$resource->getTableName('mmd_blog/post')} bp
                   WHERE bp.source_sku IS NOT NULL
               )
             GROUP BY oi.sku, oi.name
             ORDER BY orders DESC
             LIMIT 20"
        );
        foreach ($rows as $row) {
            $product = Mage::getModel('catalog/product');
            $id      = $product->getIdBySku($row['sku']);
            if (!$id) {
                continue;
            }
            $product->setStoreId(Mage::app()->getStore()->getId())->load($id);
            if (!$product->getId()
                || $product->getStatus() != Mage_Catalog_Model_Product_Status::STATUS_ENABLED
                || $product->getVisibility() == Mage_Catalog_Model_Product_Visibility::VISIBILITY_NOT_VISIBLE
            ) {
                continue;
            }
            $url = $product->getUrlPath();
            if (!$url) {
                continue;
            }
            return array(
                'sku'         => $row['sku'],
                'name'        => $product->getName(),
                'url'         => rtrim(Mage::getBaseUrl(), '/') . '/' . ltrim($url, '/'),
                'description' => trim(strip_tags((string) $product->getShortDescription())),
            );
        }
        return null;
    }

    private function _writerSystemPrompt()
    {
        return 'You are the content marketer for a Singapore SkillsFuture-approved training academy. '
            . 'You write conversion-focused blog posts that act as lead magnets for instructor-led courses. '
            . 'Respond with ONE JSON object only — no markdown fences, no preamble. Keys: '
            . 'title (string, <=70 chars), slug (kebab-case), excerpt (string, <=160 chars), '
            . 'contentHtml (string: clean HTML using h2/h3/p/ul/ol/li/strong/table only), '
            . 'seoTitle (<=60 chars), seoDescription (<=155 chars), seoKeywords (comma-separated), '
            . 'tags (array of 3-5 short topic tags).';
    }

    private function _writerInput(array $course)
    {
        $isWsq = strpos($course['sku'], 'TGS-') === 0;
        return "Write a lead-magnet blog post promoting this course:\n"
            . "COURSE: {$course['name']}\n"
            . "COURSE_URL: {$course['url']}\n"
            . "COURSE_SUMMARY: " . substr($course['description'], 0, 1200) . "\n\n"
            . "Requirements:\n"
            . "- 800-1200 words of genuinely useful, practical content on the course topic (not a sales page).\n"
            . "- Weave in at least 2 inline links to COURSE_URL with action anchor text (e.g. sign up, register).\n"
            . ($isWsq
                ? "- This is a WSQ course: explicitly mention up to 70% WSQ funding for eligible Singaporeans/PRs, that SkillsFuture Credit can be used to offset the fee, and SME subsidy support.\n"
                : "- Explicitly mention that SkillsFuture Credit can be claimed for this course and highlight WSQ funding availability across our WSQ course catalogue.\n")
            . "- End with a 'What to do next' section whose final call-to-action links to COURSE_URL.\n"
            . "- Include a short FAQ (3 questions) with an answer about funding/SkillsFuture claims.\n"
            . "- Singapore audience, professional but energetic tone.";
    }

    /**
     * Same 3-tier strategy as MMD_RoleManager_Model_AiSeo::invokeClaude, with a
     * custom system prompt + larger max_tokens (a full article doesn't fit the
     * SEO helper's 2000-token cap): API key -> claude CLI -> ''.
     */
    private function _invokeClaude($system, $prompt, $maxTokens)
    {
        $cfg    = Mage::helper('mmd_rolemanager')->getMarketingApiConfig();
        $apiKey = trim((string) ($cfg['anthropic_key'] ?? ''));
        $model  = trim((string) ($cfg['anthropic_model'] ?? '')) ?: 'claude-sonnet-4-6';

        if (stripos($apiKey, 'sk-ant-api') === 0) {
            try {
                $body = json_encode(array(
                    'model'      => $model,
                    'max_tokens' => (int) $maxTokens,
                    'system'     => $system,
                    'messages'   => array(array('role' => 'user', 'content' => $prompt)),
                ));
                $ch = curl_init('https://api.anthropic.com/v1/messages');
                curl_setopt_array($ch, array(
                    CURLOPT_POST           => true,
                    CURLOPT_POSTFIELDS     => $body,
                    CURLOPT_RETURNTRANSFER => true,
                    CURLOPT_TIMEOUT        => 180,
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

        // claude CLI fallback (same environment dance as AiSeo::invokeClaude).
        $descriptors = array(0 => array('pipe', 'r'), 1 => array('pipe', 'w'), 2 => array('pipe', 'w'));
        $env = array();
        foreach ($_ENV as $k => $v) if ($k !== 'CLAUDECODE') $env[$k] = $v;
        foreach (array('PATH', 'HOME') as $k) {
            if (!isset($env[$k]) && getenv($k) !== false) $env[$k] = getenv($k);
        }
        if (is_dir('/var/www/.claude'))                          $env['HOME'] = '/var/www';
        elseif (is_dir('/root/.claude') && is_readable('/root')) $env['HOME'] = '/root';

        $proc = @proc_open('timeout 280 claude -p --output-format text', $descriptors, $pipes, null, $env);
        if (!is_resource($proc)) return '';
        fwrite($pipes[0], $system . "\n\n" . $prompt);
        fclose($pipes[0]);
        stream_set_blocking($pipes[1], false);
        stream_set_blocking($pipes[2], false);
        $deadline = time() + 285;
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

    /** @return array with title/slug/excerpt/contentHtml/seoTitle/seoDescription/seoKeywords/tags */
    private function _parseJson($raw)
    {
        $cleaned = trim(preg_replace('/^```(?:json)?\s*|```\s*$/i', '', trim($raw)));
        // Tolerate stray prose around the object.
        if ($cleaned !== '' && $cleaned[0] !== '{') {
            $start = strpos($cleaned, '{');
            $end   = strrpos($cleaned, '}');
            if ($start === false || $end === false || $end <= $start) {
                Mage::throwException('Autoblog: no JSON object in Claude output (head: ' . substr($cleaned, 0, 120) . ')');
            }
            $cleaned = substr($cleaned, $start, $end - $start + 1);
        }
        $data = json_decode($cleaned, true);
        if (!is_array($data) || empty($data['title']) || empty($data['contentHtml'])) {
            Mage::throwException('Autoblog: invalid JSON from Claude (head: ' . substr($cleaned, 0, 120) . ')');
        }
        return array(
            'title'          => trim((string) $data['title']),
            'slug'           => trim((string) ($data['slug'] ?? '')),
            'excerpt'        => trim((string) ($data['excerpt'] ?? '')),
            'contentHtml'    => trim((string) $data['contentHtml']),
            'seoTitle'       => trim((string) ($data['seoTitle'] ?? $data['title'])),
            'seoDescription' => trim((string) ($data['seoDescription'] ?? ($data['excerpt'] ?? ''))),
            'seoKeywords'    => trim((string) ($data['seoKeywords'] ?? '')),
            'tags'           => is_array($data['tags'] ?? null) ? $data['tags'] : array(),
        );
    }

    private function _shareOnLinkedin($post, array $draft)
    {
        try {
            $linkedin = Mage::helper('mmd_blog/linkedin');
            if (!$linkedin->isConfigured()) {
                return 'linkedin: skipped (credentials not set)';
            }
            $postUrl    = Mage::helper('mmd_blog')->getPostUrl($post);
            $commentary = $post->getTitle() . "\n\n" . $draft['excerpt']
                . "\n\nWSQ funding + SkillsFuture Credit claimable — full guide and course sign-up:";
            $result = $linkedin->share($commentary, $postUrl, $post->getHeroImageUrl() ?: null);
            $post->setLinkedinUrn($result['externalId'])->save();
            return 'linkedin: ok ' . $result['externalId'];
        } catch (Exception $e) {
            Mage::log('Autoblog LinkedIn share failed: ' . $e->getMessage(), null, 'mmd_blog.log');
            return 'linkedin: ERROR ' . $e->getMessage();
        }
    }

    private function _log($msg)
    {
        Mage::log('[autoblog] ' . $msg, null, 'mmd_blog.log');
        return $msg;
    }
}
