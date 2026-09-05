<?php
/**
 * Extends the general lead so the AI-draft review pipeline (MMD_Leads cron +
 * /leadreview decide endpoint) drafts and sends replies for franchise
 * partnership enquiries too. Columns from migration 1334.
 *
 * @method string getName()
 * @method string getEmail()
 * @method string getTelephone()
 * @method string getCompany()
 * @method string getCountry()
 * @method string getMessage()
 * @method string getStatus()
 * @method string getCreatedAt()
 */
class MMD_Franchise_Model_Lead extends MMD_Leads_Model_Lead
{
    protected function _construct()
    {
        $this->_init('mmd_franchise/lead');
    }

    public function getKind() { return 'franchise'; }
    public function getKindLabel() { return 'Franchise Enquiry'; }
    public function getEnquiryMessage() { return (string) $this->getMessage(); }
    public function getEnquiryInterest()
    {
        $c = trim((string) $this->getCountry());
        return $c !== '' ? 'Franchise partnership in ' . $c : 'Franchise partnership';
    }
    public function getEnquiryFacts()
    {
        return array_filter(array('Country / Region' => (string) $this->getCountry()), 'strlen');
    }
    public function getAdminPath() { return 'franchiselead/'; }
}
