<?php
/**
 * OpenAI generation relay — lets the MY/GH partner sites generate through SG's
 * one OpenAI OAuth login, so that login is never copied onto partner servers
 * (its refresh token rotates: a second copy refreshing it would log SG out).
 *
 * POST /courses/api_ai_generate
 *   Header: X-API-Key: <one of mmd_ai/relay/api_keys>  (comma-separated, one per partner)
 *   JSON:   {"prompt": "...", "system": "...", "web_search": false, "images": []}
 *   200:    {"success": true, "text": "..."}
 *
 * Disabled (503) wherever mmd_ai/relay/api_keys is unset — set on SG only.
 * Partner side: mmd_ai/openai/relay_url + relay_key, see MMD_RoleManager_Model_AiProvider.
 */
class MMD_Courses_Api_Ai_GenerateController extends Mage_Core_Controller_Front_Action
{
    const CONFIG_KEYS = 'mmd_ai/relay/api_keys';

    public function indexAction()
    {
        $keys = array_filter(array_map('trim', explode(',', (string) Mage::getStoreConfig(self::CONFIG_KEYS))));
        if (!$keys) {
            return $this->_json(503, array('success' => false, 'error' => 'AI relay is not enabled on this site.'));
        }
        $provided = (string) $this->getRequest()->getHeader('X-API-Key');
        $ok = false;
        foreach ($keys as $key) { $ok = hash_equals($key, $provided) || $ok; }
        if (!$ok) {
            return $this->_json(401, array('success' => false, 'error' => 'Invalid or missing X-API-Key.'));
        }
        if (!$this->getRequest()->isPost()) {
            return $this->_json(405, array('success' => false, 'error' => 'POST only.'));
        }
        $in = json_decode((string) $this->getRequest()->getRawBody(), true);
        if (!is_array($in) || trim((string) ($in['prompt'] ?? '')) === '') {
            return $this->_json(400, array('success' => false, 'error' => 'prompt is required.'));
        }
        @set_time_limit(180);
        try {
            $text = Mage::getModel('mmd_rolemanager/aiProvider')->invokeOpenAiOnly(
                (string) $in['prompt'], (string) ($in['system'] ?? ''),
                !empty($in['web_search']), is_array($in['images'] ?? null) ? $in['images'] : array());
            $this->_json(200, array('success' => true, 'text' => $text));
        } catch (DomainException $e) {
            $this->_json(502, array('success' => false, 'error' => $e->getMessage()));
        } catch (Exception $e) {
            Mage::logException($e);
            $this->_json(500, array('success' => false, 'error' => 'Generation failed.'));
        }
    }

    private function _json($code, array $data)
    {
        $this->getResponse()
            ->setHttpResponseCode($code)
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(json_encode($data));
    }
}
