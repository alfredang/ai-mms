<?php
/**
 * Active-record model for a single contact-form lead.
 *
 * Created from MMD_MagentoCaptcha_IndexController on every successful
 * /contacts/index/post submission. Fields are written verbatim from the
 * form; the store_id / store_code / ip are filled in at insert time so
 * we know which country site the lead came from and can resolve the
 * right registration URL when an operator replies.
 *
 * Status lifecycle: new → replied. (No "spam" status because Turnstile
 * already filters bots — the rows here are real human submissions.)
 */
class MMD_Leads_Model_Lead extends Mage_Core_Model_Abstract
{
    const STATUS_NEW     = 'new';
    const STATUS_REPLIED = 'replied';

    /**
     * Auto-reply lifecycle (the automatic acknowledgement sent to the
     * visitor on submit — distinct from the manual operator reply above):
     *   pending — row created, auto-reply not yet attempted
     *   sent    — acknowledgement emailed successfully
     *   failed  — send attempted but errored (see var/log/system.log)
     *   skipped — auto-reply disabled for this store
     */
    const AUTO_REPLY_PENDING = 'pending';
    const AUTO_REPLY_SENT    = 'sent';
    const AUTO_REPLY_FAILED  = 'failed';
    const AUTO_REPLY_SKIPPED = 'skipped';

    /**
     * MailerLite push lifecycle (the lead email is auto-subscribed to the
     * site's configured MailerLite group on capture):
     *   NULL    — never attempted (legacy rows)
     *   sent    — subscribed to the group
     *   skipped — MailerLite not configured, or the address previously
     *             unsubscribed/bounced (never resurrect opt-outs)
     *   failed  — API call errored (see var/log/mailerlite.log)
     */
    const MAILERLITE_SENT    = 'sent';
    const MAILERLITE_SKIPPED = 'skipped';
    const MAILERLITE_FAILED  = 'failed';

    protected function _construct()
    {
        $this->_init('mmd_leads/lead');
    }

    protected function _beforeSave()
    {
        if (!$this->getId()) {
            if (!$this->getCreatedAt()) {
                $this->setCreatedAt(Varien_Date::now());
            }
            if (!$this->getStatus()) {
                $this->setStatus(self::STATUS_NEW);
            }
        }
        $this->setUpdatedAt(Varien_Date::now());
        return parent::_beforeSave();
    }

    public function markReplied($replyBody, $adminUserId = null)
    {
        $this->setStatus(self::STATUS_REPLIED);
        $this->setRepliedAt(Varien_Date::now());
        $this->setRepliedBy((int) $adminUserId);
        $this->setRepliedMessage((string) $replyBody);
        return $this->save();
    }
}
