<?php
/**
 * Public read-only API: fallback contact info + office hours.
 *
 * GET /courses/api_contact
 *   Header:  X-API-Key: <shared secret>
 *   Returns: SG office contact (phone, email, WhatsApp, address) and
 *            office hours. Used by the WhatsApp bot to gracefully
 *            escalate when it can't answer ("we're closed now — please
 *            email us at enquiry@..." style replies).
 *
 * Auth: X-API-Key — same key as the other /courses/api_* endpoints.
 *
 * Content scope: SG-only. Numbers and address below are best-effort —
 * verify and edit this controller before relying on the bot to give
 * customers your address. The +65 8866 6375 WhatsApp number comes
 * from Alisha's original spec; office hours and email are conventional
 * defaults that should be reviewed by the operations team.
 */
class MMD_Courses_Api_ContactController extends Mage_Core_Controller_Front_Action
{
    const CONFIG_PATH_API_KEY         = 'courses/general/wsq_schedule_api_key';
    const CONFIG_PATH_TRAINER_API_KEY = 'courses/general/trainer_reminders_api_key';

    public function indexAction()
    {
        // Accept EITHER the customer-reply key or the trainer-reminders role
        // key. The trainer-reminders bot needs to read this endpoint so it
        // can quote the canonical `trainer_bot_redirect_message` verbatim
        // when a customer-style question slips into the trainer channel.
        $keyCustomer = trim((string) Mage::getStoreConfig(self::CONFIG_PATH_API_KEY));
        $keyTrainer  = trim((string) Mage::getStoreConfig(self::CONFIG_PATH_TRAINER_API_KEY));
        if ($keyCustomer === '' && $keyTrainer === '') {
            return $this->_json(503, $this->_errEnvelope('api_disabled', 'No API keys configured.'));
        }
        $provided = trim((string) $this->getRequest()->getHeader('X-API-Key'));
        $ok = false;
        if ($keyCustomer !== '' && hash_equals($keyCustomer, $provided)) { $ok = true; }
        if ($keyTrainer  !== '' && hash_equals($keyTrainer,  $provided)) { $ok = true; }
        if (!$ok) {
            return $this->_json(401, $this->_errEnvelope('unauthorized', 'Invalid or missing X-API-Key.'));
        }

        return $this->_json(200, array(
            'source_url'   => 'https://www.tertiarycourses.com.sg/contacts',
            'last_updated' => gmdate('c'),
            'confidence'   => 'medium',
            'data'         => array(
                'office' => array(
                    'name'     => 'Tertiary Infotech Academy — Singapore',
                    'address'  => '12 Woodlands Square #07-85/86/87, Woods Square Tower 1, Singapore 737715',
                    'phone'    => '+65 6100 0613',
                    'email'    => 'enquiry@tertiaryinfotech.com',
                    'whatsapp' => '+65 8866 6375',
                ),
                'office_hours' => array(
                    'timezone'         => 'Asia/Singapore',
                    'summary'          => 'Open every day, 9:00 AM to 6:00 PM (Singapore time)',
                    'summary_short'    => '9 AM - 6 PM daily',
                    'monday'           => '9:00 AM - 6:00 PM',
                    'tuesday'          => '9:00 AM - 6:00 PM',
                    'wednesday'        => '9:00 AM - 6:00 PM',
                    'thursday'         => '9:00 AM - 6:00 PM',
                    'friday'           => '9:00 AM - 6:00 PM',
                    'saturday'         => '9:00 AM - 6:00 PM',
                    'sunday'           => '9:00 AM - 6:00 PM',
                    'monday_24h'       => '09:00 - 18:00',
                    'tuesday_24h'      => '09:00 - 18:00',
                    'wednesday_24h'    => '09:00 - 18:00',
                    'thursday_24h'     => '09:00 - 18:00',
                    'friday_24h'       => '09:00 - 18:00',
                    'saturday_24h'     => '09:00 - 18:00',
                    'sunday_24h'       => '09:00 - 18:00',
                    'public_holidays'  => 'Closed (Singapore public holidays)',
                ),
                'google_maps_url'    => 'https://maps.google.com/?q=12+Woodlands+Square+%2307-85+Singapore',
                'fallback_message'   => 'For urgent enquiries outside office hours (after 6 PM SGT), email enquiry@tertiaryinfotech.com — we respond within 1 business day. For class-day emergencies (running late, can\'t find the venue), WhatsApp +65 8866 6375 and we will route the message to the trainer on duty.',
                'response_times'   => array(
                    'whatsapp'      => 'Auto-reply 24/7; live agent during office hours.',
                    'email'         => 'Within 1 business day.',
                    'phone'         => 'Office hours only.',
                ),
                // Bot escalation contacts. Use these when the bot cannot answer
                // a customer's question with confidence — DO NOT make up facts.
                'escalation' => array(
                    'customer_phone'    => '+65 6100 0613',
                    'customer_email'    => 'enquiry@tertiaryinfotech.com',
                    'internal_kb_email' => 'lms-tms@tertiaryinfotech.com',
                    'bot_hours'         => '24/7 — bot replies anytime',
                    'human_hours'       => '9 AM - 6 PM daily SGT (escalation channel only)',
                    'instruction'       => 'You (the bot) reply to customers 24/7 — always attempt to answer immediately using data from this API, regardless of time of day. Never refuse to reply because of office hours. Only escalate when you genuinely cannot answer with confidence (API returned confidence: low or error). When escalating, tell the customer: "I\'m not 100% sure about that. Please call +65 6100 0613 or email enquiry@tertiaryinfotech.com — our team is available 9 AM - 6 PM daily and will respond within 1 business day." Never invent facts; only use data returned from this API.',
                    // For the trainer-reminders agent (separate role/key):
                    // it must NEVER attempt to answer customer-style questions.
                    // Reply with `trainer_bot_redirect_message` verbatim instead.
                    'trainer_bot_redirect_message' => 'Hi! This channel handles trainer reminders only. For course enquiries, fees, schedules, or funding questions, please contact our team at +65 6100 0613 or email enquiry@tertiaryinfotech.com. We respond within 1 business day (Mon-Sun, 9 AM - 6 PM SGT). Thank you!',
                    'trainer_bot_instruction'      => 'You are the trainer-reminders agent — your ONLY scope is sending and acknowledging upcoming-class reminders to assigned trainers. You must NOT attempt to answer course enquiries, pricing questions, funding questions, schedule lookups, or any other customer-style question. If a customer-style message comes in, reply with the `trainer_bot_redirect_message` field above verbatim — do not improvise, do not look up data from /api_search or /api_courses (you do not have access to those endpoints anyway). Only respond substantively to trainer-focused content (reminder confirmations, class details, "I cannot make it" messages, etc.).',
                ),
            ),
        ));
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
