<?php
/**
 * Extends the general lead so the AI-draft review pipeline (MMD_Leads cron +
 * /leadreview decide endpoint) drafts and sends replies for customised
 * training enquiries too. Columns from migration 1334.
 */
class MMD_Customised_Model_Lead extends MMD_Leads_Model_Lead
{
    protected function _construct() { $this->_init('mmd_customised/lead'); }

    public function getKind() { return 'customised'; }
    public function getKindLabel() { return 'Customised Training'; }
    public function getEnquiryMessage() { return (string) $this->getMessage(); }
    public function getEnquiryInterest() { return (string) $this->getTrainingTopic(); }
    public function getEnquiryFacts()
    {
        return array_filter(array(
            'No. of Participants' => (string) $this->getNumPax(),
            'Preferred Dates'     => (string) $this->getPreferredDates(),
        ), 'strlen');
    }
    public function getAdminPath() { return 'customisedlead/'; }
}
