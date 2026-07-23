<?php
/**
 * Public read-only API: FAQ / policy / funding info.
 *
 * GET /courses/api_faq
 *   Header:  X-API-Key: <shared secret>
 *   Returns: every FAQ topic in one response. The WhatsApp bot does
 *            keyword-matching on its own side, so we don't expose a
 *            ?topic= parameter — bot caches this whole payload and looks
 *            up topics locally by matching user-message keywords against
 *            each topic's `keywords` array.
 *
 * Auth: X-API-Key — same key as the other /courses/api_* endpoints.
 *
 * Content scope: SG-only schemes (SkillsFuture / SFC / WSQ / UTAP / PSEA
 * / IBF / MCES / SFEC / Absentee Payroll) + standard policy topics
 * (cancellation, certificates, corporate booking).
 *
 * Editorial note: blurbs below are best-effort summaries based on the
 * official scheme pages (sources cited in each topic's `official_source`).
 * Marketing/Compliance should review and edit the strings in this file
 * before relying on the bot to answer high-stakes questions. The bot
 * surfaces `confidence: medium` on this endpoint so callers know the
 * answers come from a static knowledge base, not real-time data.
 */
class MMD_Courses_Api_FaqController extends Mage_Core_Controller_Front_Action
{
    const CONFIG_PATH_API_KEY = 'courses/general/wsq_schedule_api_key';

    public function indexAction()
    {
        $expected = trim((string) Mage::getStoreConfig(self::CONFIG_PATH_API_KEY));
        if ($expected === '') {
            return $this->_json(503, $this->_errEnvelope('api_disabled', 'API key not configured.'));
        }
        $provided = (string) $this->getRequest()->getHeader('X-API-Key');
        if (!hash_equals($expected, $provided)) {
            return $this->_json(401, $this->_errEnvelope('unauthorized', 'Invalid or missing X-API-Key.'));
        }

        return $this->_json(200, array(
            'source_url'   => 'https://www.tertiarycourses.com.sg/',
            'last_updated' => gmdate('c'),
            'confidence'   => 'medium',
            'data'         => array(
                'note'   => 'Topics below are a static knowledge base. Match user-message keywords against each topic\'s `keywords` array to pick a topic; cite `official_source` when answering high-stakes questions.',
                'topics' => $this->_topics(),
            ),
        ));
    }

    private function _topics()
    {
        return array(

            array(
                'id'              => 'skillsfuture-credit',
                'title'           => 'SkillsFuture Credit (SFC)',
                'keywords'        => array('skillsfuture', 'sfc', 'credit', '$500', 'claim', 'subsidy', 'gov credit'),
                'summary'         => 'Every Singapore Citizen aged 25 and above receives a $500 SkillsFuture Credit from the Government that can be used to offset course fees on approved courses. From May 2024, mid-careerists aged 40+ received an additional $4,000 top-up.',
                'eligibility'     => 'Singapore Citizens aged 25 and above. The $4,000 top-up is for Singapore Citizens aged 40 and above.',
                'how_to_claim'    => array(
                    'Browse approved courses on tertiarycourses.com.sg.',
                    'Add the course to cart and proceed to checkout.',
                    'Select "SkillsFuture Credit" as the payment method.',
                    'You will be redirected to MySkillsFuture to log in with Singpass and confirm the claim.',
                    'Receipt is sent to your email; balance is auto-deducted from your SFC wallet.',
                ),
                'official_source' => 'https://www.skillsfuture.gov.sg/credit',
            ),

            array(
                'id'              => 'wsq',
                'title'           => 'Workforce Skills Qualifications (WSQ)',
                'keywords'        => array('wsq', 'workforce', 'ssg', 'tgs', 'government funded', 'subsidy', 'singapore citizen', 'pr'),
                'summary'         => 'WSQ courses are SWDA (formerly SSG) approved and qualify for government training subsidies. Singapore Citizens and PRs receive up to 50% course fee subsidy; SCs aged 40+ qualify for the enhanced Mid-Career Enhanced Subsidy (MCES) of up to 70%.',
                'eligibility'     => 'Singapore Citizens and Permanent Residents. Employer-sponsored employees also qualify under employer-sponsored funding.',
                'how_to_claim'    => array(
                    'Choose a WSQ course (SKU starts with TGS- on our catalogue).',
                    'Register and pay the full fee at checkout.',
                    'Subsidy is auto-applied at checkout for eligible learners — net fee is displayed.',
                    'Bring NRIC/FIN on the first day of class for attendance taking (mandatory for funding).',
                ),
                'official_source' => 'https://www.skillsfuture.gov.sg/initiatives/individuals/wsq',
            ),

            array(
                'id'              => 'utap',
                'title'           => 'Union Training Assistance Programme (UTAP)',
                'keywords'        => array('utap', 'ntuc', 'union', 'member', '$250', '$500', 'rebate'),
                'summary'         => 'NTUC members can claim 50% of unfunded course fees, capped at $250 per year (or $500 per year for members aged 40 and above). Claim is made AFTER course completion.',
                'eligibility'     => 'Active NTUC Ordinary Branch or General Branch members with paid-up union membership for at least 6 months at time of application.',
                'how_to_claim'    => array(
                    'Complete the course and pay the course fee in full.',
                    'Log in to e2i / NTUC member portal (https://www.ntuc.org.sg/uportal).',
                    'Submit a UTAP claim with the course invoice and certificate of completion.',
                    'Approved claims are reimbursed to the member\'s bank account within 4-6 weeks.',
                ),
                'official_source' => 'https://www.ntuc.org.sg/uportal/programmes/union-training-assistance-programme-(utap)',
            ),

            array(
                'id'              => 'psea',
                'title'           => 'Post-Secondary Education Account (PSEA)',
                'keywords'        => array('psea', 'post-secondary', 'education account', 'edusave', 'parent', 'under 30', 'siblings'),
                'summary'         => 'PSEA funds can be used to pay for approved courses for Singaporeans up to age 30. Account holders can also use their PSEA balance to pay for siblings\' approved courses, subject to eligibility.',
                'eligibility'     => 'Singapore Citizens aged 30 and below with a PSEA balance. Sibling-use is allowed for SC siblings up to age 30.',
                'how_to_claim'    => array(
                    'Confirm your PSEA balance via Singpass on MOE\'s portal.',
                    'At checkout, choose "PSEA" as the payment method.',
                    'You will be redirected to MOE to authorise the deduction.',
                    'On approval, PSEA is debited and you receive the receipt by email.',
                ),
                'official_source' => 'https://www.moe.gov.sg/financial-matters/psea',
            ),

            array(
                'id'              => 'mces',
                'title'           => 'Mid-Career Enhanced Subsidy (MCES)',
                'keywords'        => array('mces', 'mid-career', '40', '40 and above', 'enhanced subsidy', 'older worker'),
                'summary'         => 'Singapore Citizens aged 40 and above receive an enhanced subsidy of up to 70% (vs. 50% baseline) on WSQ-approved courses, automatically applied at checkout when eligibility is confirmed.',
                'eligibility'     => 'Singapore Citizens aged 40 and above on or before the first day of the course.',
                'how_to_claim'    => array(
                    'No application needed — MCES is auto-applied at checkout based on NRIC + date of birth.',
                    'Net (post-subsidy) fee is shown on the course page after eligibility check.',
                    'Verify your NRIC/DOB on the first day of class for funding confirmation.',
                ),
                'official_source' => 'https://www.skillsfuture.gov.sg/initiatives/mid-career/mces',
            ),

            array(
                'id'              => 'ibf',
                'title'           => 'Institute of Banking and Finance (IBF) Funding',
                'keywords'        => array('ibf', 'institute banking finance', 'fts', 'financial', 'banking', 'finance', 'fica'),
                'summary'         => 'IBF-accredited courses (IBF-STS or IBF-FTS programmes) qualify for IBF funding — Singapore Citizens / PRs working in the financial sector receive 50-70% co-funding from MAS, with reimbursement after course completion.',
                'eligibility'     => 'Singapore Citizens or PRs employed by a Singapore-incorporated Financial Institution. Sponsoring FI must be the employer of record.',
                'how_to_claim'    => array(
                    'Confirm the course is IBF-accredited (look for "IBF" badge on the course page).',
                    'Pay the gross fee at registration.',
                    'Submit claim via IBF Portal (https://www.ibf.org.sg) within 120 days of course completion.',
                    'Funding is disbursed to the sponsoring FI (or to the individual for self-sponsored).',
                ),
                'official_source' => 'https://www.ibf.org.sg/programmes/Pages/IBF-Funding-Schemes.aspx',
            ),

            array(
                'id'              => 'sfec',
                'title'           => 'SkillsFuture Enterprise Credit (SFEC)',
                'keywords'        => array('sfec', 'enterprise credit', 'business', 'sme', 'company', 'employer'),
                'summary'         => 'SFEC gives eligible Singapore-registered enterprises up to $10,000 in credit to defray out-of-pocket costs of supporting employee training and capability development. Topped up periodically by SWDA (formerly SSG).',
                'eligibility'     => 'Singapore-registered enterprises that have (a) contributed at least $750 SDL over the qualifying year, AND (b) employed at least 3 Singaporeans/PRs every month over that year.',
                'how_to_claim'    => array(
                    'Check eligibility on https://www.enterprisesg.gov.sg/sfec.',
                    'Send employees on supportable courses (most WSQ courses qualify).',
                    'Submit SFEC claim via Business Grants Portal after course completion.',
                    'SFEC reimburses up to 90% of qualifying out-of-pocket fees, capped at $10,000 per enterprise.',
                ),
                'official_source' => 'https://www.enterprisesg.gov.sg/financial-support/skillsfuture-enterprise-credit',
            ),

            array(
                'id'              => 'absentee-payroll',
                'title'           => 'Absentee Payroll Funding (AP)',
                'keywords'        => array('absentee payroll', 'ap', 'employer claim', 'salary', 'salary support', 'employer'),
                'summary'         => 'Employers can claim Absentee Payroll funding when their employees attend training during work hours, partially covering the employee\'s salary for the absent period. Helps employers afford to release staff for upskilling.',
                'eligibility'     => 'Singapore-registered employers releasing Singapore Citizen / PR employees to attend SWDA (formerly SSG)-supported courses during paid work hours.',
                'how_to_claim'    => array(
                    'Ensure the course is AP-supportable (most WSQ courses are).',
                    'Pay the employee\'s salary for the training days as normal.',
                    'After course completion, submit AP claim via SkillsConnect / Enterprise Portal.',
                    'Funding rate is currently $4.50 per training hour, capped at $100,000 per enterprise per calendar year.',
                ),
                'official_source' => 'https://www.skillsfuture.gov.sg/initiatives/employers/absenteepayroll',
            ),

            array(
                'id'              => 'cancellation-policy',
                'title'           => 'Cancellation, Reschedule & Refund Policy',
                'keywords'        => array('cancel', 'cancellation', 'reschedule', 'refund', 'change date', 'transfer', 'no-show'),
                'summary'         => 'Cancellations more than 7 working days before the class start date receive a full refund. Within 7 days, a 50% admin fee applies. No-shows or cancellations on the day forfeit the full fee. Date transfers (within 6 months) are allowed free of charge with at least 3 working days notice.',
                'eligibility'     => 'All learners — applies to self-pay, employer-sponsored, and funded registrations.',
                'how_to_claim'    => array(
                    'Email enquiry@tertiaryinfotech.com or WhatsApp +65 8866 6375 with: order number, learner name, course title, and reason.',
                    'For date transfers, propose a target class date that has open seats.',
                    'Refunds (where eligible) are processed within 14 working days to the original payment method.',
                ),
                'official_source' => 'https://www.tertiarycourses.com.sg/terms',
            ),

            array(
                'id'              => 'certificates',
                'title'           => 'Certificates of Completion',
                'keywords'        => array('certificate', 'cert', 'completion', 'attendance', 'transcript', 'wsq cert'),
                'summary'         => 'Every learner who attends at least 75% of the class and passes any required assessments receives a digital Certificate of Completion within 5-7 working days. WSQ courses also generate a Statement of Attainment (SOA) on MySkillsFuture once SWDA (formerly SSG) verifies attendance.',
                'eligibility'     => 'Minimum 75% attendance and a pass on any in-course assessment (where applicable).',
                'how_to_claim'    => array(
                    'Mark attendance daily — for WSQ courses, NRIC/FIN scan is mandatory.',
                    'Complete any in-course assessment (project, quiz, or trainer review).',
                    'Digital certificate is emailed to the registered email address within 5-7 working days.',
                    'For WSQ SOAs, allow up to 4 weeks for SWDA (formerly SSG) to verify and issue the official Statement of Attainment on MySkillsFuture.',
                ),
                'official_source' => 'https://www.tertiarycourses.com.sg/about',
            ),

            array(
                'id'              => 'assessments',
                'title'           => 'Course Assessments',
                'keywords'        => array('assessment', 'exam', 'test', 'quiz', 'pass', 'fail', 'project'),
                'summary'         => 'Most short courses use a hands-on project or in-class lab as the assessment — no formal exam. WSQ courses include a structured Competency-Based Assessment (CBA) on the final day, marked by the trainer. Pass rate is typically 90%+; learners who do not pass may resit at no extra charge within 30 days.',
                'eligibility'     => 'All registered learners.',
                'how_to_claim'    => array(
                    'Attend all class sessions — assessments cannot be done remotely or out-of-band.',
                    'For project-based assessments, submit deliverables to the trainer before the end of the last class.',
                    'For WSQ CBAs, the trainer marks during class and provides verbal feedback on the spot.',
                    'If you do not pass, your trainer will guide you on the resit process (typically within 30 days, no extra charge).',
                ),
                'official_source' => 'https://www.tertiarycourses.com.sg/about',
            ),

            array(
                'id'              => 'corporate-registration',
                'title'           => 'Corporate / Group Registration',
                'keywords'        => array('corporate', 'company', 'group', 'bulk', 'team', 'custom training', 'in-house', 'private class'),
                'summary'         => 'Companies sending 5+ learners qualify for tiered group discounts and dedicated invoicing. We also run private in-house sessions — same syllabus, your office (or a venue we book), at a date/time you pick. Most public courses can be customised for industry-specific case studies.',
                'eligibility'     => 'Any Singapore-registered company; HRD Corp claimable for Malaysia subsidiary training. SkillsFuture Enterprise Credit (SFEC) can offset out-of-pocket fees for SG SMEs.',
                'how_to_claim'    => array(
                    'Email enquiry@tertiaryinfotech.com with: company name, course of interest, headcount, and preferred dates.',
                    'We respond within 1 working day with a quote (incl. SFEC-eligibility check if applicable).',
                    'On confirmation, we issue a PO-friendly invoice and lock the seats / private session date.',
                    'Group discounts kick in at 5+ learners; further discounts at 10+ and 20+ tiers.',
                ),
                'official_source' => 'https://www.tertiarycourses.com.sg/corporate',
            ),

        );
    }

    private function _errEnvelope($code, $message)
    {
        return array(
            'source_url'   => null,
            'last_updated' => gmdate('c'),
            'confidence'   => 'error',
            'error'        => $code,
            'message'      => $message,
        );
    }

    private function _json($status, array $body)
    {
        $this->getResponse()
            ->setHttpResponseCode($status)
            ->setHeader('Content-Type', 'application/json; charset=utf-8', true)
            ->setHeader('Cache-Control', 'public, max-age=3600', true)
            ->setBody(json_encode($body, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
        return $this;
    }
}
