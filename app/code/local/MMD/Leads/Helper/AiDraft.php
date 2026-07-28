<?php
/**
 * AI reply drafter for leads.
 *
 * draft($lead) gathers the lead's context plus live course data (course
 * recommendation from the catalog + upcoming class runs pulled from the
 * /courses/api_schedule API), asks Claude to write the reply, and returns
 *   array('subject_course' => string, 'body_html' => string)
 * ready to prefill the "Reply with Course Information" form. The body is
 * the INNER fragment of the mmd_leads_course_reply template (the template
 * already supplies greeting + signature), so Claude is instructed to write
 * neither.
 *
 * Claude invocation mirrors MMD_RoleManager_Model_AiSeo: direct Anthropic
 * API when an sk-ant-api* key is configured (Company Setting → Marketing
 * API), otherwise the `claude` CLI fallback via that model. The model id
 * comes from the same mmd_marketing/api/anthropic_model config.
 */
class MMD_Leads_Helper_AiDraft extends Mage_Core_Helper_Abstract
{
    const SCHEDULE_API_KEY_PATH = 'courses/general/wsq_schedule_api_key';
    const API_TIMEOUT           = 90;
    const SCHEDULE_TIMEOUT      = 8;

    /**
     * @param  MMD_Leads_Model_Lead $lead
     * @param  string $reviewerFeedback  optional request-changes notes from
     *                                   the admin — the redraft must honour
     *                                   them (plus the prior draft as context)
     * @return array{subject_course:string, body_html:string}
     * @throws Exception when every generator tier fails or output is unparseable
     */
    public function draft(MMD_Leads_Model_Lead $lead, $reviewerFeedback = '')
    {
        $context = $this->buildContext($lead);
        $prompt  = $this->_userPrompt($context);
        $reviewerFeedback = trim((string) $reviewerFeedback);
        if ($reviewerFeedback !== '') {
            $prompt .= "\n\nREVISION REQUEST — the admin reviewed a previous draft and asked for changes."
                . " Rewrite the reply honouring this feedback exactly:\n\"" . $reviewerFeedback . "\"";
            if (trim((string) $lead->getDraftHtml()) !== '') {
                $prompt .= "\n\nPrevious draft body for reference:\n" . $lead->getDraftHtml();
            }
        }
        $stdout = $this->_invokeClaude(
            $this->_systemPrompt($context['store_brand']),
            $prompt
        );

        if (trim((string) $stdout) === '') {
            Mage::throwException($this->__('AI draft failed — no output from any generator tier. Check the Anthropic key under Company Setting → Marketing API.'));
        }

        $parsed = $this->_parseJson($stdout);
        if (!is_array($parsed) || trim((string) ($parsed['body_html'] ?? '')) === '') {
            // Surface the head of the raw output — tier failures announce
            // themselves there (e.g. "Not logged in" from the claude CLI).
            $peek = trim(preg_replace('/\s+/', ' ', mb_substr(strip_tags((string) $stdout), 0, 140)));
            Mage::throwException($this->__('AI draft returned an unexpected format: "%s"', $peek));
        }

        return array(
            'subject_course' => trim((string) ($parsed['subject_course'] ?? '')) ?: trim((string) $lead->getCoursesInterested()) ?: 'your enquiry',
            'body_html'      => trim((string) $parsed['body_html']),
        );
    }

    /**
     * Everything the model needs to know about the lead + matched courses.
     */
    public function buildContext(MMD_Leads_Model_Lead $lead)
    {
        $helper  = Mage::helper('mmd_leads');
        $storeId = (int) $lead->getStoreId();

        // Best single recommendation (exact course-code match wins, then
        // keyword scoring) + up to 3 fuzzy catalog matches as alternates.
        $recommended = $helper->recommendCourse($lead);

        $matches = array();
        $text    = trim($lead->getCoursesInterested() . ' ' . $lead->getComment());
        if ($text !== '') {
            $coll = $helper->matchCourses($text, $storeId);
            if ($coll) {
                foreach ($coll as $product) {
                    $matches[] = $helper->buildCourseSnippet($product, $storeId);
                }
            }
        }

        // Live upcoming classes from the schedule API for the recommended
        // (or form-supplied) course code.
        $sku = $recommended ? $recommended['code'] : trim((string) $lead->getCourseCode());
        $schedule = $sku !== '' ? $this->fetchScheduleFromApi($sku, $storeId) : null;

        return array(
            'store_brand'  => $helper->getStoreBrandName($storeId),
            'store_url'    => Mage::app()->getStore($storeId ?: null)->getBaseUrl(),
            'lead'         => array(
                'name'              => (string) $lead->getName(),
                'email'             => (string) $lead->getEmail(),
                'company'           => (string) $lead->getCompany(),
                'telephone'         => (string) $lead->getTelephone(),
                'courses_interested' => (string) $lead->getCoursesInterested(),
                'course_code'       => (string) $lead->getCourseCode(),
                'message'           => (string) $lead->getComment(),
            ),
            'recommended'  => $recommended,
            'matches'      => $matches,
            'schedule'     => $schedule,
        );
    }

    /**
     * GET /courses/api_schedule?sku=<sku> against this site's own base URL
     * using the configured X-API-Key. Returns the decoded `data` payload
     * (course_title, course_page_url, classes[] with start/end date, trainer,
     * mode, vacancy) or null when the API is unavailable — callers degrade
     * to catalog-snippet data.
     */
    public function fetchScheduleFromApi($sku, $storeId)
    {
        $apiKey = trim((string) Mage::getStoreConfig(self::SCHEDULE_API_KEY_PATH, $storeId));
        if ($apiKey === '') {
            return null;
        }

        try {
            $base = rtrim(Mage::app()->getStore($storeId ?: null)->getBaseUrl(), '/');
            $url  = $base . '/courses/api_schedule?sku=' . rawurlencode($sku);
            $ch   = curl_init($url);
            curl_setopt_array($ch, array(
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT        => self::SCHEDULE_TIMEOUT,
                CURLOPT_CONNECTTIMEOUT => 4,
                CURLOPT_HTTPHEADER     => array('X-API-Key: ' . $apiKey),
            ));
            $raw  = curl_exec($ch);
            $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            if ($code !== 200 || !$raw) {
                return null;
            }
            $rsp = json_decode($raw, true);
            return isset($rsp['data']) && is_array($rsp['data']) ? $rsp['data'] : null;
        } catch (Exception $e) {
            Mage::logException($e);
            return null;
        }
    }

    protected function _systemPrompt($storeBrand)
    {
        return 'You are a training consultant at ' . $storeBrand . ', a professional '
            . 'course-training academy. You draft warm, precise reply emails to course '
            . 'enquiries. You only state facts present in the provided data — never invent '
            . 'dates, prices, or policies. Output exactly the JSON object requested, no '
            . 'preamble, no markdown fences.';
    }

    protected function _userPrompt(array $ctx)
    {
        $data = json_encode(array(
            'lead'               => $ctx['lead'],
            'recommended_course' => $ctx['recommended'],
            'other_matches'      => $ctx['matches'],
            'live_schedule'      => $ctx['schedule'],
        ), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

        return <<<PROMPT
Draft the reply to this course enquiry lead.

DATA (lead + course info pulled from our catalog and schedule API):
{$data}

The body you write is inserted into a branded email template that ALREADY renders:
- greeting: "Hi <name>, Thanks for getting in touch with {$ctx['store_brand']}. Here are the details you asked about:"
- closing: a follow-up invitation and a signature.
So write ONLY the middle content — no greeting, no sign-off, no subject line inside the body.

Requirements for body_html:
1. First, directly address what the lead actually asked in their message (e.g. an application status, invoice/billing question, schedule question) in 1–2 short paragraphs. If their question needs internal follow-up we cannot answer from the data (like an order status), say our team is checking and will confirm shortly — do not invent a status.
2. Then present the relevant course information as a clean block using this exact structure per course (only include courses supported by the data; usually just the recommended one):
   <p><strong>Course Title:</strong> ...<br/>
   <strong>Course Code:</strong> ...<br/>
   <strong>Next Schedule:</strong> ...<br/>
   <strong>Course Registration Link:</strong> <a href="...">...</a></p>
3. Next Schedule: use the earliest upcoming class from live_schedule (format "Mon, 3 Aug 2026" or a range; include mode e.g. Classroom / Live Online and seats note if available). If no schedule data, write "Please contact us for upcoming dates."
4. If recommended_course.kind is "wsq", add one short paragraph noting WSQ funding: no upfront payment needed, we apply the WSQ subsidy on their behalf, SkillsFuture Credit can offset the balance, and they may also apply via the MySkillsFuture portal link (recommended_course.myskillsfuture_url).
5. If the lead mentioned paying by company invoice, note that corporate/invoice billing is available and our team will arrange it.
6. Simple HTML only: <p>, <br/>, <strong>, <a>. No inline CSS, no images, no tables.
7. Keep the whole body under 220 words. Professional, warm, concise.

subject_course: a short topic for the subject line "Re: Your enquiry about <subject_course>" — normally the recommended course title, else the lead's stated interest.

Return ONLY this JSON object:
{"subject_course": "...", "body_html": "..."}
PROMPT;
    }

    /**
     * Two-tier Claude invocation. Direct API when an sk-ant-api* key is
     * configured (so we control the system prompt); otherwise delegate to
     * MMD_RoleManager_Model_AiSeo::invokeClaude() whose CLI fallback runs
     * when no API key is present.
     */
    protected function _invokeClaude($system, $prompt)
    {
        $cfg    = Mage::helper('mmd_rolemanager')->getMarketingApiConfig();
        $apiKey = trim((string) ($cfg['anthropic_key']   ?? ''));
        $model  = trim((string) ($cfg['anthropic_model'] ?? '')) ?: 'claude-sonnet-4-6';

        if (stripos($apiKey, 'sk-ant-api') === 0) {
            $body = json_encode(array(
                'model'      => $model,
                'max_tokens' => 2000,
                'system'     => $system,
                'messages'   => array(array('role' => 'user', 'content' => $prompt)),
            ));
            $ch = curl_init('https://api.anthropic.com/v1/messages');
            curl_setopt_array($ch, array(
                CURLOPT_POST           => true,
                CURLOPT_POSTFIELDS     => $body,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT        => self::API_TIMEOUT,
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
            if (isset($rsp['error']['message'])) {
                Mage::log('AiDraft Anthropic API error: ' . $rsp['error']['message'], Zend_Log::ERR);
            }
            // fall through to the CLI tier
        }

        // AiSeo's invokeClaude skips straight to the `claude` CLI when the
        // key is not an sk-ant-api* key; fold the system prompt into the
        // user prompt since the CLI path has no separate system channel.
        return Mage::getModel('mmd_rolemanager/aiSeo')->invokeClaude($system . "\n\n" . $prompt);
    }

    /**
     * Tolerant JSON extraction — strips markdown fences and grabs the first
     * {...} span in case the model added prose despite instructions.
     */
    protected function _parseJson($stdout)
    {
        $s = trim((string) $stdout);
        $s = preg_replace('/^```(?:json)?\s*/i', '', $s);
        $s = preg_replace('/\s*```$/', '', $s);
        $parsed = json_decode($s, true);
        if (is_array($parsed)) {
            return $parsed;
        }
        $start = strpos($s, '{');
        $end   = strrpos($s, '}');
        if ($start !== false && $end !== false && $end > $start) {
            $parsed = json_decode(substr($s, $start, $end - $start + 1), true);
            if (is_array($parsed)) {
                return $parsed;
            }
        }
        return null;
    }
}
