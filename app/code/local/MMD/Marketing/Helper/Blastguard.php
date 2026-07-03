<?php
/**
 * Blast guard — the HARD RULE enforcement for newsletter → MailerLite blasts.
 *
 *  - Feature is SG-only and gated by config mmd_marketing/newsletter/blast_enabled
 *    (default 0; set to 1 only on the SG instance — see migration 300 + the admin
 *    toggle). isEnabled() is the master switch: nothing blasts when off.
 *  - Blasts may only be SCHEDULED for a Monday or a Thursday (10:00 local).
 *  - HARD cap: at most MAX_PER_WEEK (2) campaigns per calendar week (Mon 00:00 →
 *    Sun 23:59:59, server TZ Asia/Singapore). Every successful schedule is written
 *    to mmd_marketing_blast_log; the count is read back from there so the limit is
 *    enforced on real data, not an in-memory guess. Test-sends to reviewers never
 *    touch this table, so they never count against the cap.
 *
 * This helper only COUNTS and PICKS SLOTS — it never calls MailerLite. The
 * controller calls canScheduleNow()/nextSendSlot() before pushing, and
 * recordBlast() only after MailerLite confirms the schedule.
 */
class MMD_Marketing_Helper_Blastguard extends Mage_Core_Helper_Abstract
{
    const MAX_PER_WEEK   = 2;
    const CONFIG_ENABLED = 'mmd_marketing/newsletter/blast_enabled';
    const SEND_HOUR      = 8;           // 08:00 local (Asia/Singapore) on the send day
    const DOW_MON        = 1;
    const DOW_THU        = 4;

    /**
     * HMAC token binding a review action to (newsletter, reviewer email). Signed
     * with the Magento crypt key so the public approve/reject endpoint needs no
     * login — a valid token IS the authorisation. Emails only go to the two
     * fixed reviewers, so the token also scopes each link to one of them.
     */
    public function signToken($newsletterId, $reviewerEmail)
    {
        $secret = (string) Mage::getConfig()->getNode('global/crypt/key');
        $payload = (int) $newsletterId . '|' . strtolower(trim($reviewerEmail));
        return substr(hash_hmac('sha256', $payload, $secret), 0, 40);
    }

    public function verifyToken($newsletterId, $reviewerEmail, $token)
    {
        $expected = $this->signToken($newsletterId, $reviewerEmail);
        return is_string($token) && hash_equals($expected, (string) $token);
    }

    /** The two fixed reviewers for the human-in-the-loop approval. */
    public function reviewers()
    {
        return array('angch@tertiaryinfotech.com', 'tansc@tertiaryinfotech.com');
    }

    /** Master switch — SG-only, admin-toggleable. */
    public function isEnabled()
    {
        return (bool) (int) Mage::getStoreConfig(self::CONFIG_ENABLED);
    }

    /** Monday 00:00:00 and Sunday 23:59:59 for the calendar week containing $when. */
    protected function _weekBounds(DateTime $when)
    {
        $dow    = (int) $when->format('N');            // 1=Mon .. 7=Sun
        $monday = clone $when;
        $monday->modify('-' . ($dow - 1) . ' days')->setTime(0, 0, 0);
        $sunday = clone $monday;
        $sunday->modify('+6 days')->setTime(23, 59, 59);
        return array($monday, $sunday);
    }

    protected function _tbl()
    {
        return Mage::getSingleton('core/resource')->getTableName('mmd_marketing_blast_log');
    }

    /** Scheduled/sent campaigns whose send time falls in the week containing $when. */
    protected function _blastsInWeekOf(DateTime $when)
    {
        list($mon, $sun) = $this->_weekBounds($when);
        $res  = Mage::getSingleton('core/resource');
        $conn = $res->getConnection('core_read');
        return (int) $conn->fetchOne(
            'SELECT COUNT(*) FROM ' . $this->_tbl() . ' WHERE blasted_at BETWEEN ? AND ?',
            array($mon->format('Y-m-d H:i:s'), $sun->format('Y-m-d H:i:s'))
        );
    }

    /** Campaigns already scheduled/sent in the CURRENT calendar week. */
    public function blastsThisWeek()
    {
        return $this->_blastsInWeekOf(new DateTime('now'));
    }

    /** How many of this week's 2 slots are still free (0, 1, or 2). */
    public function remainingThisWeek()
    {
        return max(0, self::MAX_PER_WEEK - $this->blastsThisWeek());
    }

    /**
     * The soonest future Monday/Thursday 10:00 slot whose calendar week still
     * has capacity (< MAX_PER_WEEK already booked). Looks up to 3 weeks ahead.
     * Returns a DateTime (local) or null if nothing is bookable in that window.
     */
    public function nextSendSlot()
    {
        $now = new DateTime('now');
        for ($i = 0; $i <= 21; $i++) {
            $day = clone $now;
            $day->modify('+' . $i . ' days');
            $dow = (int) $day->format('N');
            if ($dow !== self::DOW_MON && $dow !== self::DOW_THU) {
                continue;
            }
            $slot = clone $day;
            $slot->setTime(self::SEND_HOUR, 0, 0);
            if ($slot <= $now) {
                continue;                       // slot must be in the future
            }
            if ($this->_blastsInWeekOf($slot) < self::MAX_PER_WEEK) {
                return $slot;
            }
        }
        return null;
    }

    /**
     * Can a campaign be scheduled right now? Requires the feature enabled AND a
     * bookable Mon/Thu slot within the cap. $reason is filled with a human message.
     */
    public function canScheduleNow(&$reason = '')
    {
        if (!$this->isEnabled()) {
            $reason = 'Newsletter blasting is turned off for this site.';
            return false;
        }
        if ($this->nextSendSlot() === null) {
            $reason = 'The weekly limit of ' . self::MAX_PER_WEEK
                    . ' campaigns is reached for the coming weeks. Try again later.';
            return false;
        }
        return true;
    }

    /**
     * Record a confirmed blast so it counts against the weekly cap. $sendAt is the
     * scheduled Mon/Thu send time (this is what the cap is measured against).
     */
    public function recordBlast($newsletterId, $countryCode, $mailerliteId, DateTime $sendAt, $userId = null)
    {
        $res  = Mage::getSingleton('core/resource');
        $conn = $res->getConnection('core_write');
        $conn->insert($this->_tbl(), array(
            'newsletter_id' => $newsletterId ? (int) $newsletterId : null,
            'country_code'  => $countryCode ?: null,
            'mailerlite_id' => $mailerliteId ?: null,
            'blasted_at'    => $sendAt->format('Y-m-d H:i:s'),
            'blasted_by'    => $userId ? (int) $userId : null,
        ));
        return (int) $conn->lastInsertId();
    }
}
