<?php
/**
 * MMD_AgentApi shared dispatch + protocol helper.
 *
 * Every agent write endpoint is a thin controller that calls dispatch($this,
 * '<capability>'). This helper enforces the whole protocol uniformly:
 *
 *   1. X-API-Key auth (reuses the shared external key the agent already holds).
 *   2. POST + JSON body parsing.
 *   3. actor (WhatsApp number + name + role) - recorded, not authorised here.
 *   4. Delegates to a capability model (schedule/course/content/ops) that
 *      exposes preview($op,$body) and commit($op,$body,$preview).
 *   5. dry_run -> returns diff + human_summary + warnings + change_token.
 *      commit  -> recomputes the token from LIVE data, rejects if it differs
 *      from the caller's (stale_preview), applies, audits, responds.
 *
 * The change_token is an HMAC over the capability + op + the preview's
 * token_payload (target ids + new values + a snapshot of the current values it
 * depends on), salted with the install crypt key so it cannot be forged. Because
 * commit recomputes preview() against live data, an intervening edit changes the
 * token and the commit is refused - guaranteeing "what was approved in chat" ==
 * "what is applied".
 */
class MMD_AgentApi_Helper_Data extends Mage_Core_Helper_Abstract
{
    /** Reuse the shared external API key the agent already presents to the read APIs. */
    const CONFIG_PATH_API_KEY = 'courses/general/wsq_schedule_api_key';
    const AUDIT_TABLE         = 'mmd_agent_api_audit';

    /**
     * Run the full protocol for one endpoint call.
     *
     * @param Mage_Core_Controller_Front_Action $controller
     * @param string                            $capability  model alias suffix (schedule|course|content|ops)
     * @return Mage_Core_Controller_Front_Action
     */
    public function dispatch($controller, $capability)
    {
        $request = $controller->getRequest();

        // 1. Auth.
        $expected = trim((string) Mage::getStoreConfig(self::CONFIG_PATH_API_KEY));
        if ($expected === '') {
            return $this->_json($controller, 503, array('success' => false, 'error' => 'api_disabled',
                'message' => 'Agent API key not configured on this site.'));
        }
        if (!hash_equals($expected, (string) $request->getHeader('X-API-Key'))) {
            return $this->_json($controller, 401, array('success' => false, 'error' => 'unauthorized',
                'message' => 'Missing or invalid X-API-Key.'));
        }

        // 2. Method + body.
        if (!$request->isPost()) {
            return $this->_json($controller, 405, array('success' => false, 'error' => 'method_not_allowed',
                'message' => 'POST required.'));
        }
        $body = json_decode((string) $request->getRawBody(), true);
        if (!is_array($body)) {
            return $this->_json($controller, 400, array('success' => false, 'error' => 'validation_error',
                'message' => 'Request body must be a JSON object.'));
        }

        try {
            // 3. actor + op.
            $actor = $this->_parseActor($body);
            $op    = isset($body['op']) ? trim((string) $body['op']) : '';
            if ($op === '') {
                throw new MMD_AgentApi_Model_Exception('validation_error', 'Missing "op".', 400);
            }
            $dryRun = !empty($body['dry_run']);

            // 4. Capability model.
            $model = Mage::getModel('mmd_agentapi/' . $capability);
            if (!$model instanceof MMD_AgentApi_Model_Abstract) {
                throw new MMD_AgentApi_Model_Exception('internal_error', 'Capability unavailable.', 500);
            }

            // 5. Preview (always computed - it is also the token source).
            $preview = $model->preview($op, $body);
            $token   = $this->computeToken($capability, $op, isset($preview['token_payload']) ? $preview['token_payload'] : array());

            if ($dryRun) {
                return $this->_json($controller, 200, array(
                    'success'       => true,
                    'dry_run'       => true,
                    'op'            => $op,
                    'target'        => isset($preview['target']) ? $preview['target'] : null,
                    'diff'          => isset($preview['diff']) ? $preview['diff'] : array(),
                    'human_summary' => isset($preview['human_summary']) ? $preview['human_summary'] : '',
                    'warnings'      => isset($preview['warnings']) ? $preview['warnings'] : array(),
                    'change_token'  => $token,
                ));
            }

            // 6. Commit - verify the caller's token against the freshly computed one.
            $provided = isset($body['change_token']) ? (string) $body['change_token'] : '';
            if ($provided === '') {
                throw new MMD_AgentApi_Model_Exception('change_token_required',
                    'Commit requires the change_token returned by a prior dry_run.', 400);
            }
            if (!hash_equals($token, $provided)) {
                throw new MMD_AgentApi_Model_Exception('stale_preview',
                    'The course/class changed since your preview. Re-preview, re-confirm, and retry.', 409);
            }

            $result  = $model->commit($op, $body, $preview);
            $auditId = $this->audit($actor, $capability, $op, $preview, $result, $request);

            $out = array(
                'success'   => true,
                'applied'   => true,
                'op'        => $op,
                'target'    => isset($result['target']) ? $result['target'] : (isset($preview['target']) ? $preview['target'] : null),
                'audit_id'  => $auditId,
                'reindexed' => isset($result['reindexed']) ? $result['reindexed'] : array(),
            );
            if (isset($result['extra']) && is_array($result['extra'])) {
                $out = array_merge($out, $result['extra']);
            }
            return $this->_json($controller, 200, $out);
        } catch (MMD_AgentApi_Model_Exception $e) {
            return $this->_json($controller, $e->getHttpStatus(), array(
                'success' => false, 'error' => $e->getErrorCode(), 'message' => $e->getMessage(),
            ));
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_json($controller, 500, array(
                'success' => false, 'error' => 'internal_error', 'message' => $e->getMessage(),
            ));
        }
    }

    /**
     * Allowed actor roles for the audit trail. `user` is the universal default for an
     * as-yet-undistinguished requester - the agent currently authorizes via a binary
     * whitelist and is being exposed to customers too, so most callers are just "a user".
     * The other six mirror the canonical MMS role codes (mmd_user_role_map) for when the
     * agent starts distinguishing operators; sending one of those then needs no backend change.
     */
    const ACTOR_ROLES = 'user,learner,trainer,developer,marketing,admin,training_provider';

    /**
     * Validate + normalise the actor block. WhatsApp number is the identity;
     * name + role are recorded for traceability. Authorization itself is the
     * agent's job - this only records who it says asked.
     *
     * `role` is optional and defaults to `user`; if provided it must be a known role.
     */
    protected function _parseActor(array $body)
    {
        $actor = isset($body['actor']) && is_array($body['actor']) ? $body['actor'] : array();
        $id    = isset($actor['id'])   ? trim((string) $actor['id'])   : '';
        $name  = isset($actor['name']) ? trim((string) $actor['name']) : '';
        $role  = isset($actor['role']) ? strtolower(trim((string) $actor['role'])) : '';
        if ($id === '' || $name === '') {
            throw new MMD_AgentApi_Model_Exception('validation_error',
                'actor.id (WhatsApp number) and actor.name are required.', 400);
        }
        $allowed = explode(',', self::ACTOR_ROLES);
        if ($role === '') {
            $role = 'user';
        } elseif (!in_array($role, $allowed, true)) {
            throw new MMD_AgentApi_Model_Exception('validation_error',
                'actor.role "' . $role . '" is not recognised. Use one of: ' . self::ACTOR_ROLES
                . ' (or omit it for the default "user").', 400);
        }
        return array('id' => $id, 'name' => $name, 'role' => $role);
    }

    /**
     * HMAC over capability + op + the deterministic token_payload, salted with
     * the install crypt key so a caller cannot forge a token to skip stale
     * detection.
     */
    public function computeToken($capability, $op, $payload)
    {
        $canonical = json_encode(array($capability, $op, $payload), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
        $salt      = (string) Mage::getConfig()->getNode('global/crypt/key');
        return 'sha256:' . hash_hmac('sha256', (string) $canonical, $salt);
    }

    /**
     * Append an audit row. before/after come from the preview/commit result.
     * Never throws - a failed audit must not fail the change (it is logged).
     */
    public function audit(array $actor, $capability, $op, array $preview, array $result, $request)
    {
        try {
            $resource = Mage::getSingleton('core/resource');
            $write    = $resource->getConnection('core_write');
            $table    = $resource->getTableName(self::AUDIT_TABLE);
            $write->insert($table, array(
                'actor_wa_number' => $actor['id'],
                'actor_name'      => $actor['name'],
                'actor_role'      => $actor['role'],
                'capability'      => (string) $capability,
                'op'              => (string) $op,
                'target'          => isset($result['target']) ? (string) $result['target']
                                       : (isset($preview['target']) ? (string) $preview['target'] : null),
                'before_json'     => json_encode(isset($preview['diff']) ? $preview['diff'] : array(), JSON_UNESCAPED_UNICODE),
                'after_json'      => json_encode(isset($result['after']) ? $result['after'] : array(), JSON_UNESCAPED_UNICODE),
                'human_summary'   => isset($preview['human_summary']) ? (string) $preview['human_summary'] : null,
                'result'          => 'applied',
                'ip'              => (string) $request->getClientIp(),
                'created_at'      => now(),
            ));
            return (int) $write->lastInsertId();
        } catch (Exception $e) {
            Mage::logException($e);
            return null;
        }
    }

    protected function _json($controller, $status, array $body)
    {
        $controller->getResponse()
            ->setHttpResponseCode($status)
            ->setHeader('Content-Type', 'application/json; charset=utf-8', true)
            ->setHeader('Cache-Control', 'no-store', true)
            ->setBody(json_encode($body, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
        return $controller;
    }
}
