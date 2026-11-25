<?php
/**
 * Finger signatures for e-attendance in the TC LMS apps (table
 * mmd_attendance_signature, migration 1960). The app sends the signature as a
 * base64 PNG; a learner signs to check in, the trainer signs for the session
 * (or hands the phone to a learner, who signs and is marked present).
 */
class MMD_MobileApi_Helper_Signature extends Mage_Core_Helper_Abstract
{
    const MAX_BYTES = 300000;

    /**
     * Decode and check an app signature (base64 PNG, optional data: prefix).
     * @return string|null PNG bytes, or null if it is not a usable PNG
     */
    public function decode($b64)
    {
        $b64 = trim((string) $b64);
        if ($b64 === '') {
            return null;
        }
        if (strpos($b64, 'base64,') !== false) {
            $b64 = substr($b64, strpos($b64, 'base64,') + 7);
        }
        $png = base64_decode($b64, true);
        if ($png === false || strlen($png) < 100 || strlen($png) > self::MAX_BYTES
            || substr($png, 0, 8) !== "\x89PNG\r\n\x1a\n") {
            return null;
        }
        $size = @getimagesizefromstring($png);
        if (!$size || $size[0] < 50 || $size[1] < 20 || $size[0] > 3000 || $size[1] > 3000) {
            return null;
        }
        return $png;
    }

    /** Save (or replace) one signature. */
    public function save(array $run, $sessionKey, $email, $name, $role, $png, $capturedBy)
    {
        $res = Mage::getSingleton('core/resource');
        $res->getConnection('core_write')->insertOnDuplicate(
            $res->getTableName('mmd_attendance_signature'),
            array(
                'run_id'            => (int) $run['run_id'],
                'class_id'          => !empty($run['class_id']) ? (string) $run['class_id'] : null,
                'session_key'       => (string) $sessionKey,
                'signer_email'      => strtolower(trim((string) $email)),
                'signer_name'       => (string) $name,
                'signer_role'       => $role === 'trainer' ? 'trainer' : 'learner',
                'image_png'         => $png,
                'captured_by_email' => strtolower(trim((string) $capturedBy)),
                'signed_at'         => new Zend_Db_Expr('CURRENT_TIMESTAMP'),
            ),
            array('signer_name', 'image_png', 'captured_by_email', 'signed_at', 'class_id')
        );
    }

    /**
     * Session keys signed in one class run, per signer.
     * @return array role => email => [session keys]
     */
    public function signedSessions($runId)
    {
        $out = array('learner' => array(), 'trainer' => array());
        try {
            $res = Mage::getSingleton('core/resource');
            foreach ($res->getConnection('core_read')->fetchAll(
                'SELECT signer_role, signer_email, session_key FROM ' . $res->getTableName('mmd_attendance_signature') . ' WHERE run_id = ?',
                array((int) $runId)
            ) as $r) {
                $role = $r['signer_role'] === 'trainer' ? 'trainer' : 'learner';
                $out[$role][strtolower((string) $r['signer_email'])][] = (string) $r['session_key'];
            }
        } catch (Exception $e) {
            // Table not migrated yet on this site: nobody has signed.
        }
        return $out;
    }
}
