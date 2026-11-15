<?php
/**
 * Class Announcements — posts a trainer makes to one class (course_runs row).
 * Stored in mmd_class_announcement (migration 1934); an optional document goes
 * to Cloudflare R2 under class-announcements/<class_id>/.
 *
 * Who can do what:
 *   post / delete — the trainer assigned to the class, or operations staff
 *   read          — the above, plus a learner enrolled in that class
 */
class MMD_Attendance_Helper_Announcement extends Mage_Core_Helper_Abstract
{
    const MAX_FILE_BYTES = 52428800; // 50 MB
    const MAX_MESSAGE_CHARS = 5000;

    /** Document types a post may carry: extension => content type. */
    protected $_fileTypes = array(
        'pdf'  => 'application/pdf',
        'doc'  => 'application/msword',
        'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'ppt'  => 'application/vnd.ms-powerpoint',
        'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'xls'  => 'application/vnd.ms-excel',
        'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'csv'  => 'text/csv',
        'txt'  => 'text/plain',
        'md'   => 'text/plain',
        'zip'  => 'application/zip',
        'png'  => 'image/png',
        'jpg'  => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'gif'  => 'image/gif',
        'webp' => 'image/webp',
    );

    public function canPost($runId)
    {
        $roles = Mage::helper('mmd_rolemanager');
        if ($roles->isRoleAllowed(array('training_provider', 'admin', 'developer'))) {
            return true;
        }
        return $roles->isRoleAllowed('trainer') && Mage::helper('mmd_attendance')->isRunTrainer($runId);
    }

    public function canView($runId)
    {
        if ($this->canPost($runId)) {
            return true;
        }
        if (!Mage::helper('mmd_rolemanager')->isRoleAllowed('learner')) {
            return false;
        }
        $ctx = Mage::helper('mmd_attendance')->getSelfMarkContext($runId);
        return $ctx && !empty($ctx['enrolled']);
    }

    /** Posts of a class, oldest first, ready for the class page. */
    public function listForRun($runId)
    {
        $resource = Mage::getSingleton('core/resource');
        try {
            $rows = $resource->getConnection('core_read')->fetchAll(
                "SELECT * FROM " . $resource->getTableName('mmd_class_announcement')
                . " WHERE run_id = ? ORDER BY created_at ASC, announcement_id ASC",
                array((int) $runId)
            );
        } catch (Exception $e) { // table not there yet (pre-1934)
            return array();
        }
        $out = array();
        foreach ($rows as $row) {
            $out[] = $this->_present($row);
        }
        return $out;
    }

    /**
     * Save a post. $file is a $_FILES entry or null. A post needs a message,
     * a document, or both. Returns the saved post.
     */
    public function add($runId, $message, $file = null)
    {
        $runId = (int) $runId;
        $run   = Mage::helper('mmd_attendance')->getClassRow($runId);
        if (!$run) {
            Mage::throwException('Class not found.');
        }
        $message = $this->_clean($message);
        if (function_exists('mb_substr')) {
            $message = mb_substr($message, 0, self::MAX_MESSAGE_CHARS, 'UTF-8');
        }
        $hasFile = is_array($file) && isset($file['error']) && (int) $file['error'] !== UPLOAD_ERR_NO_FILE;
        if ($message === '' && !$hasFile) {
            Mage::throwException('Type a message or attach a document before posting.');
        }

        $stored = $hasFile ? $this->_storeFile($file, $run) : array('name' => null, 'url' => null, 'key' => null);

        $user     = Mage::getSingleton('admin/session')->getUser();
        $postedBy = $user ? trim($user->getFirstname() . ' ' . $user->getLastname()) : '';
        if ($postedBy === '' && $user) {
            $postedBy = (string) $user->getEmail();
        }
        $resource = Mage::getSingleton('core/resource');
        $write    = $resource->getConnection('core_write');
        $table    = $resource->getTableName('mmd_class_announcement');
        $write->insert($table, array(
            'run_id'            => $runId,
            'message'           => $message !== '' ? $message : null,
            'file_name'         => $stored['name'],
            'file_url'          => $stored['url'],
            'file_key'          => $stored['key'],
            'posted_by'         => $postedBy !== '' ? $this->_clean($postedBy) : 'Trainer',
            'posted_by_user_id' => $user ? (int) $user->getId() : null,
            'created_at'        => gmdate('Y-m-d H:i:s'),
        ));
        return $this->_present($write->fetchRow(
            "SELECT * FROM `$table` WHERE announcement_id = ?",
            array((int) $write->lastInsertId())
        ));
    }

    /** The post row, or null. */
    public function load($announcementId)
    {
        $resource = Mage::getSingleton('core/resource');
        $row = $resource->getConnection('core_read')->fetchRow(
            "SELECT * FROM " . $resource->getTableName('mmd_class_announcement') . " WHERE announcement_id = ?",
            array((int) $announcementId)
        );
        return $row ?: null;
    }

    /** Delete a post and its document. */
    public function delete(array $row)
    {
        $resource = Mage::getSingleton('core/resource');
        $resource->getConnection('core_write')->delete(
            $resource->getTableName('mmd_class_announcement'),
            array('announcement_id = ?' => (int) $row['announcement_id'])
        );
        if (!empty($row['file_key'])) {
            try {
                Mage::helper('mmd_courseimage/r2')->deleteObject($row['file_key']);
            } catch (Exception $e) {
                Mage::log('Class announcement: R2 delete failed for ' . $row['file_key'] . ': ' . $e->getMessage(), null, 'mmd_announcement.log');
            }
        }
    }

    protected function _storeFile(array $file, array $run)
    {
        $err = (int) $file['error'];
        if ($err === UPLOAD_ERR_INI_SIZE || $err === UPLOAD_ERR_FORM_SIZE || (int) $file['size'] > self::MAX_FILE_BYTES) {
            Mage::throwException('That file is larger than 50 MB. Upload a smaller file, or paste a link to it in the message.');
        }
        if ($err !== UPLOAD_ERR_OK || !is_uploaded_file($file['tmp_name'])) {
            Mage::throwException('The document did not upload. Please try again.');
        }
        $name = $this->_clean(basename((string) $file['name']));
        $ext  = strtolower(pathinfo($name, PATHINFO_EXTENSION));
        if (!isset($this->_fileTypes[$ext])) {
            Mage::throwException('That file type cannot be attached. Allowed: ' . implode(', ', array_keys($this->_fileTypes)) . '.');
        }
        $safe = trim(preg_replace('/[^A-Za-z0-9._-]+/', '-', $name), '-.');
        $key  = 'class-announcements/' . preg_replace('/[^A-Za-z0-9]+/', '', (string) $run['class_id'] ?: (string) $run['run_id'])
              . '/' . bin2hex(random_bytes(8)) . '/' . ($safe !== '' ? $safe : 'document.' . $ext);
        try {
            $put = Mage::helper('mmd_courseimage/r2')->putObject($key, file_get_contents($file['tmp_name']), $this->_fileTypes[$ext]);
        } catch (Exception $e) {
            Mage::log('Class announcement: R2 upload failed: ' . $e->getMessage(), null, 'mmd_announcement.log');
            Mage::throwException('The document could not be saved to cloud storage, so nothing was posted. Please try again, or paste a link to it in the message.');
        }
        return array('name' => substr($name, 0, 255), 'url' => $put['url'], 'key' => $key);
    }

    /** Trim, and drop 4-byte characters (emoji) the utf8 connection cannot store. */
    protected function _clean($text)
    {
        return trim((string) preg_replace('/[\x{10000}-\x{10FFFF}]/u', '', (string) $text));
    }

    protected function _present(array $row)
    {
        return array(
            'id'        => (int) $row['announcement_id'],
            'message'   => (string) $row['message'],
            'file_name' => (string) $row['file_name'],
            'file_url'  => (string) $row['file_url'],
            'posted_by' => (string) $row['posted_by'],
            'posted_at' => Mage::getModel('core/date')->date('D, j M Y, H:i', $row['created_at']),
        );
    }
}
