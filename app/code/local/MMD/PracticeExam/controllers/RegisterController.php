<?php
/**
 * Public Practice Exam self-register page, opened from the QR code the trainer shows in class:
 *   /practiceexam/register/index/run/<run_id>/k/<signature>
 * The learner enters name + email; the exams site creates the account, grants the practice
 * exam for this class and emails the sign-in link. The signature (HMAC of the run id) stops
 * link guessing, and the link only works around the class dates.
 */
class MMD_PracticeExam_RegisterController extends Mage_Core_Controller_Front_Action
{
    public function indexAction()
    {
        $h     = Mage::helper('mmd_practiceexam');
        $req   = $this->getRequest();
        $runId = (int) $req->getParam('run');
        $run   = $runId > 0 ? $h->loadRun($runId) : null;
        $exam  = $run ? $h->getCourseExam($run['product_id']) : null;

        if (!$run || !$exam || !$h->isConfigured()
            || !hash_equals($h->selfRegisterSig($runId), (string) $req->getParam('k'))) {
            return $this->_page('Practice Exam', '<p class="msg err">This registration link is not valid.</p>', 404);
        }
        $title = $exam['exam_code'] . ' Practice Exam';
        if (!$h->selfRegisterOpen($run)) {
            return $this->_page($title, '<p class="msg err">Registration for this class is closed.</p>');
        }

        $name = trim((string) $req->getPost('name'));
        $email = strtolower(trim((string) $req->getPost('email')));
        $msg = '';
        if ($req->isPost()) {
            if (trim((string) $req->getPost('website')) !== '') {           // honeypot
                $msg = '<p class="msg err">Registration failed. Please try again.</p>';
            } elseif (mb_strlen($name) < 2 || mb_strlen($name) > 200 || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
                $msg = '<p class="msg err">Please enter your full name and a valid email address.</p>';
            } else {
                $r = $h->registerPerson($name, $email, $exam['exam_slug'], $run['class_id'], 'Self-registered from MMS');
                Mage::log(sprintf('self-register class %s -> %s: %s %s', $run['class_id'], $exam['exam_code'], $email, $r['ok'] ? 'ok' : 'FAILED ' . $r['error']), null, 'mmd_practiceexam.log', true);
                if ($r['ok']) {
                    $e = htmlspecialchars($email);
                    return $this->_page($title, '<p class="msg ok">You are registered for the ' . htmlspecialchars($exam['exam_code'])
                        . ' practice exam.</p><p>' . ($r['emailSent'] ? 'We emailed the exam link to <strong>' . $e . '</strong>. ' : '')
                        . 'Sign in with <strong>' . $e . '</strong> using Google or an email code.</p>'
                        . '<p><a class="btn" href="' . htmlspecialchars($h->baseUrl()) . '/login">Open Tertiary Exams</a></p>');
                }
                $msg = '<p class="msg err">Registration failed. Please try again or ask your trainer.</p>';
            }
        }

        $sku = htmlspecialchars((string) $run['course_sku']);
        $this->_page($title, '<p class="sub">Class ' . htmlspecialchars((string) $run['class_id']) . ' &middot; ' . $sku . '</p>' . $msg
            . '<form method="post" action="">'
            . '<label for="pe-name">Full name</label><input id="pe-name" name="name" type="text" required maxlength="200" autocomplete="name" value="' . htmlspecialchars($name) . '">'
            . '<label for="pe-email">Email</label><input id="pe-email" name="email" type="email" required maxlength="320" autocomplete="email" value="' . htmlspecialchars($email) . '">'
            . '<input name="website" type="text" tabindex="-1" autocomplete="off" aria-hidden="true" style="position:absolute;left:-9999px">'
            . '<button class="btn" type="submit">Register</button></form>'
            . '<p class="note">We create your Tertiary Exams account with this email and send you the exam link.</p>');
    }

    protected function _page($title, $body, $code = 200)
    {
        $t = htmlspecialchars($title);
        $this->getResponse()->setHttpResponseCode($code)
            ->setHeader('Content-Type', 'text/html; charset=UTF-8', true)
            ->setHeader('Cache-Control', 'no-store', true)
            ->setHeader('X-Robots-Tag', 'noindex, nofollow', true)
            ->setBody('<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
                . '<meta name="robots" content="noindex,nofollow"><title>' . $t . '</title><style>'
                . 'body{margin:0;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;background:#f1f5f9;color:#0f172a}'
                . '.card{max-width:420px;margin:32px auto;padding:28px 24px;background:#fff;border-radius:12px;box-shadow:0 1px 3px rgba(15,23,42,.12)}'
                . 'h1{font-size:22px;margin:0 0 4px}.sub{color:#475569;font-size:14px;margin:0 0 18px}'
                . 'label{display:block;font-size:14px;font-weight:600;margin:14px 0 6px}'
                . 'input[type=text],input[type=email]{width:100%;box-sizing:border-box;padding:12px;font-size:16px;border:1px solid #94a3b8;border-radius:8px}'
                . 'input:focus-visible,.btn:focus-visible{outline:3px solid #93c5fd;outline-offset:2px}'
                . '.btn{display:inline-block;width:100%;box-sizing:border-box;margin-top:20px;padding:13px;font-size:16px;font-weight:600;color:#fff;background:#1d4ed8;border:0;border-radius:8px;text-align:center;text-decoration:none;cursor:pointer}'
                . '.msg{padding:12px;border-radius:8px;font-size:15px}.ok{background:#dcfce7;color:#14532d}.err{background:#fee2e2;color:#7f1d1d}'
                . '.note{color:#475569;font-size:13px;margin:16px 0 0}'
                . '</style></head><body><main class="card"><h1>' . $t . '</h1>' . $body . '</main></body></html>');
    }
}
