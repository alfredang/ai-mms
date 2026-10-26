<?php
/**
 * Public certificate download — /certificate/download/index?token=<hex>
 *
 * No login required; the token (stored on the certificate row) is the
 * authentication. Regenerates the PDF on demand from the snapshotted row data
 * and streams it inline. Nothing is stored on disk.
 */
class MMD_Certificate_DownloadController extends Mage_Core_Controller_Front_Action
{
    public function indexAction()
    {
        $token = (string) $this->getRequest()->getParam('token', '');
        if (strlen($token) < 16) {
            $this->getResponse()->setHttpResponseCode(404)->setBody('Invalid certificate link.');
            return;
        }

        $res  = Mage::getSingleton('core/resource');
        $read = $res->getConnection('core_read');
        $row  = $read->fetchRow(
            "SELECT * FROM " . $res->getTableName('mmd_course_run_certificate') . " WHERE token = ? LIMIT 1",
            array($token)
        );
        if (!$row) {
            $this->getResponse()->setHttpResponseCode(404)->setBody('Certificate not found.');
            return;
        }

        try {
            /** @var MMD_Certificate_Helper_Data $h */
            $h = Mage::helper('mmd_certificate');

            // Serve the stored artifact verbatim (source of truth). Only
            // regenerate as a last resort if no blob was stored (legacy rows).
            if (isset($row['pdf_blob']) && $row['pdf_blob'] !== null && $row['pdf_blob'] !== '') {
                $pdf = $row['pdf_blob'];
            } else {
                $dates = $h->formatDates($row['start_date'], $row['end_date']);
                $pdf   = $h->renderPdf($h->buildCertHtml($row['learner_name'], $row['course_title'], $dates));
            }

            $fileName = preg_replace('/[^A-Za-z0-9_\- ]/', '', (string)$row['learner_name']);
            // "Certificate-of-Attendance" on Malaysia, "Certificate-of-Achievement" elsewhere (same as the email attachment).
            // Malaysia certificates issued before the attendance release (migration 1833) keep their original file name.
            $kind = str_replace(' ', '-', $h->certificateName());
            if ($kind !== 'Certificate-of-Achievement') {
                $since = $read->fetchOne("SELECT applied_at FROM schema_migrations WHERE filename = '1833-class-session-timetable.sql'");
                if (!$since || $row['created_at'] < $since) $kind = 'Certificate-of-Achievement';
            }
            $fileName = (trim($fileName) !== '' ? trim($fileName) : 'Certificate') . '-' . $kind . '.pdf';

            $this->getResponse()
                 ->clearHeaders()
                 ->setHeader('Content-Type', 'application/pdf', true)
                 ->setHeader('Content-Disposition', 'inline; filename="' . $fileName . '"', true)
                 ->setHeader('Content-Length', strlen($pdf), true)
                 ->setBody($pdf);
        } catch (Exception $e) {
            Mage::logException($e);
            $this->getResponse()->setHttpResponseCode(500)->setBody('Unable to generate certificate.');
        }
    }
}
