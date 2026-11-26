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
     * Roll-out day of signatures on the QR check-in form (26 Nov 2026): learners marked present
     * that morning had no way to sign. For a morning session dated up to this day, the
     * learner's afternoon signature of the same day is copied to it (see _fillMorning).
     */
    const MORNING_FILL_UNTIL = '2026-11-26';

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

    /**
     * True when the PNG carries real ink (a few dark, opaque pixels), so a blank pad
     * cannot be submitted as a signature. Shrinks the image first: cheap on any size.
     */
    public function hasInk($png)
    {
        if (!function_exists('imagecreatefromstring')) {
            return true;                                   // no GD: trust the client-side check
        }
        $src = @imagecreatefromstring((string) $png);
        if (!$src) {
            return false;
        }
        $w = 200; $h = max(20, (int) round(imagesy($src) * 200 / max(1, imagesx($src))));
        $dst = imagecreatetruecolor($w, $h);
        imagealphablending($dst, false);
        imagesavealpha($dst, true);
        imagefill($dst, 0, 0, imagecolorallocatealpha($dst, 255, 255, 255, 127));
        imagecopyresampled($dst, $src, 0, 0, 0, 0, $w, $h, imagesx($src), imagesy($src));
        $ink = 0;
        for ($y = 0; $y < $h; $y++) {
            for ($x = 0; $x < $w; $x++) {
                $c = imagecolorat($dst, $x, $y);
                $a = ($c >> 24) & 0x7F;
                if ($a < 100 && ((($c >> 16) & 0xFF) + (($c >> 8) & 0xFF) + ($c & 0xFF)) < 600 && ++$ink >= 25) {
                    break 2;
                }
            }
        }
        imagedestroy($src);
        imagedestroy($dst);
        return $ink >= 25;
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
                'signed_at'         => Varien_Date::now(),   // UTC, like the other attendance timestamps
            ),
            array('signer_name', 'image_png', 'captured_by_email', 'signed_at', 'class_id')
        );
        if ($role !== 'trainer' && preg_match('/^d(\d+)pm$/', (string) $sessionKey, $m)) {
            $this->_fillMorning((int) $run['run_id'], 'd' . $m[1] . 'am', $email, $name, $png, $capturedBy);
        }
    }

    /**
     * Copy an afternoon signature to the same day's morning session when the learner was
     * marked present that morning but has no morning signature, for morning sessions dated
     * up to MORNING_FILL_UNTIL. An absent morning is never filled.
     */
    protected function _fillMorning($runId, $amKey, $email, $name, $png, $capturedBy)
    {
        try {
            $email = strtolower(trim((string) $email));
            $res   = Mage::getSingleton('core/resource');
            $read  = $res->getConnection('core_read');
            $sigT  = $res->getTableName('mmd_attendance_signature');
            if ($read->fetchOne("SELECT 1 FROM $sigT WHERE run_id = ? AND session_key = ? AND signer_email = ? AND signer_role = 'learner'",
                    array($runId, $amKey, $email))) {
                return;                                         // already signed that morning
            }
            if ((int) $read->fetchOne('SELECT is_present FROM ' . $res->getTableName('mmd_course_run_attendance')
                    . ' WHERE run_id = ? AND LOWER(learner_email) = ? AND session_key = ? LIMIT 1', array($runId, $email, $amKey)) !== 1) {
                return;                                         // not marked present that morning
            }
            $h   = Mage::helper('mmd_attendance');
            $run = $h->getClassRow($runId);
            $am  = $run ? $h->sessionForRun($run, $amKey) : null;
            if (!$am || empty($am['date']) || $am['date'] > self::MORNING_FILL_UNTIL) {
                return;
            }
            $res->getConnection('core_write')->insertIgnore($sigT, array(
                'run_id'            => $runId,
                'class_id'          => !empty($run['class_id']) ? (string) $run['class_id'] : null,
                'session_key'       => $amKey,
                'signer_email'      => $email,
                'signer_name'       => (string) $name,
                'signer_role'       => 'learner',
                'image_png'         => $png,
                'captured_by_email' => strtolower(trim((string) $capturedBy)),
                'signed_at'         => Varien_Date::now(),
            ));
            Mage::log(sprintf('signature run %d: %s afternoon signature copied to %s', $runId, $email, $amKey), null, 'attendance.log', true);
        } catch (Exception $e) {
            Mage::logException($e);                         // never fail the afternoon signature itself
        }
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

    /**
     * Every signature of one class run, for the website E-Attendance page (no image bytes).
     * @return array learner => email => session_key => {id, at, by}; trainer => session_key => [{id, email, name, at}]
     */
    public function forRun($runId)
    {
        $out = array('learner' => array(), 'trainer' => array());
        try {
            $res = Mage::getSingleton('core/resource');
            foreach ($res->getConnection('core_read')->fetchAll(
                'SELECT signature_id, signer_role, signer_email, signer_name, session_key, captured_by_email, signed_at FROM '
                . $res->getTableName('mmd_attendance_signature') . ' WHERE run_id = ? ORDER BY signed_at',
                array((int) $runId)
            ) as $r) {
                $email = strtolower((string) $r['signer_email']);
                $key   = (string) $r['session_key'];
                if ($r['signer_role'] === 'trainer') {
                    $out['trainer'][$key][] = array('id' => (int) $r['signature_id'], 'email' => $email,
                        'name' => (string) $r['signer_name'], 'at' => (string) $r['signed_at']);
                } else {
                    $out['learner'][$email][$key] = array('id' => (int) $r['signature_id'], 'at' => (string) $r['signed_at'],
                        'by' => strtolower((string) $r['captured_by_email']) === $email ? '' : (string) $r['captured_by_email']);
                }
            }
        } catch (Exception $e) {
            // Table not migrated yet on this site: nobody has signed.
        }
        return (object) array('learner' => (object) $out['learner'], 'trainer' => (object) $out['trainer']);
    }

    /** PNG bytes of one signature of a run, or null. */
    public function image($runId, $signatureId)
    {
        $res = Mage::getSingleton('core/resource');
        $png = $res->getConnection('core_read')->fetchOne(
            'SELECT image_png FROM ' . $res->getTableName('mmd_attendance_signature') . ' WHERE signature_id = ? AND run_id = ?',
            array((int) $signatureId, (int) $runId)
        );
        return $png === false || $png === null || $png === '' ? null : $png;
    }
}
