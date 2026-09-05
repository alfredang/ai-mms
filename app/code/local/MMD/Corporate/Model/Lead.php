<?php
/**
 * Extends the general lead so the AI-draft review pipeline (MMD_Leads cron +
 * /leadreview decide endpoint) drafts and sends replies for corporate
 * training enquiries too. Columns from migration 1334.
 */
class MMD_Corporate_Model_Lead extends MMD_Leads_Model_Lead
{
    protected function _construct() { $this->_init('mmd_corporate/lead'); }

    public function getKind() { return 'corporate'; }
    public function getKindLabel() { return 'Corporate Training'; }
    public function getEnquiryMessage() { return (string) $this->getMessage(); }
    public function getEnquiryInterest() { return (string) $this->getTrainingTopic(); }
    public function getEnquiryFacts()
    {
        return array_filter(array(
            'No. of Participants' => (string) $this->getNumPax(),
            'Preferred Dates'     => (string) $this->getPreferredDates(),
        ), 'strlen');
    }
    public function getAdminPath() { return 'corporatelead/'; }
}
