<?php
/**
 * Single-lead view with prefilled reply form. Renders the lead's full
 * message plus a textarea seeded with course details auto-matched from
 * the lead's "Course Interested" text. Operator can edit and click Send.
 */
class MMD_Leads_Block_Adminhtml_Leads_View extends Mage_Adminhtml_Block_Template
{
    public function __construct()
    {
        parent::__construct();
        $this->setTemplate('mmd_leads/view.phtml');
    }

    public function getLead()
    {
        return Mage::registry('current_lead');
    }

    public function getReplyPostUrl()
    {
        return $this->getUrl('*/*/reply', array('id' => $this->getLead()->getId()));
    }

    public function getBackUrl()
    {
        return $this->getUrl('*/*/');
    }

    public function getDeleteUrl()
    {
        return $this->getUrl('*/*/delete', array('id' => $this->getLead()->getId()));
    }

    public function getAiDraftUrl()
    {
        return $this->getUrl('*/*/aidraft', array('id' => $this->getLead()->getId()));
    }

    /** Prefilled To — the lead's own email. Operator-editable before sending. */
    public function getInitialTo()
    {
        return (string) $this->getLead()->getEmail();
    }

    /**
     * Prefilled CC — the same training-team list the auto-reply CCs
     * (mmd_leads/auto_reply/cc), resolved at the lead's store scope.
     */
    public function getInitialCc()
    {
        return trim((string) Mage::getStoreConfig(
            'mmd_leads/auto_reply/cc',
            (int) $this->getLead()->getStoreId() ?: null
        ));
    }

    /**
     * Return matched products as a thin array of [title, code, schedule, url]
     * keyed by product_id. Empty array if no fuzzy match.
     *
     * @return array
     */
    public function getMatchedCourses()
    {
        $lead = $this->getLead();
        $text = trim($lead->getCoursesInterested() . ' ' . $lead->getComment());
        if ($text === '') {
            return array();
        }

        $coll = Mage::helper('mmd_leads')->matchCourses($text, (int) $lead->getStoreId());
        if (!$coll) {
            return array();
        }

        $out = array();
        foreach ($coll as $product) {
            $out[$product->getId()] = Mage::helper('mmd_leads')->buildCourseSnippet($product, (int) $lead->getStoreId());
        }
        return $out;
    }

    /**
     * Build the initial reply-body HTML to seed the textarea. If we matched
     * one or more courses, list them. Otherwise leave placeholders so the
     * operator can fill in manually.
     */
    public function getInitialReplyHtml()
    {
        $matches = $this->getMatchedCourses();

        if (empty($matches)) {
            return "<p><strong>Course Title:</strong> [please fill in]<br/>"
                . "<strong>Course Code:</strong> [please fill in]<br/>"
                . "<strong>Next Schedule:</strong> [please fill in]<br/>"
                . "<strong>Course Registration Link:</strong> [please fill in]</p>";
        }

        $html = '';
        foreach ($matches as $m) {
            $html .= "<p>"
                . "<strong>Course Title:</strong> " . $this->escapeHtml($m['course_title']) . "<br/>"
                . "<strong>Course Code:</strong> "  . $this->escapeHtml($m['course_code'])  . "<br/>"
                . "<strong>Next Schedule:</strong> " . $this->escapeHtml($m['course_schedule']) . "<br/>"
                . "<strong>Course Registration Link:</strong> <a href=\"" . $this->escapeHtml($m['course_url']) . "\">" . $this->escapeHtml($m['course_url']) . "</a>"
                . "</p>";
        }
        return $html;
    }

    public function getInitialSubjectCourse()
    {
        $matches = $this->getMatchedCourses();
        if (!empty($matches)) {
            $first = reset($matches);
            return $first['course_title'];
        }
        return trim((string) $this->getLead()->getCoursesInterested()) ?: 'your enquiry';
    }
}
