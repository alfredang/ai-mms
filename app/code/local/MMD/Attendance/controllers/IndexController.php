<?php
/**
 * Public class check-in page, opened from the trainer's Take Attendance QR:
 *   /checkin/index/index/run/<run_id>/s/<session key>/k/<signature>
 * One QR per session (Day 1 AM, Day 1 PM, …): the check-in marks THAT session. A link
 * without /s/ is the old class-wide one and marks the session running right now.
 * No login. The learner enters name + email (+ optional phone); class code, date and time
 * are filled in. A learner not yet on the roster is registered on their first check-in
 * (MMD_Attendance_Helper_Data::publicCheckIn). A learner who gave a phone number before is
 * found again by it (this class's roster only; the email is shown masked and never sent
 * to the page), so a later session needs the phone number alone. The phone's browser also remembers the details
 * (localStorage, never sent anywhere else), so later sessions are pre-filled and typing a
 * saved name fills the rest. The signature (HMAC of the run id) stops link guessing; the
 * attendance window (class start to end + 1 day) gates the check-in itself.
 */
class MMD_Attendance_IndexController extends Mage_Core_Controller_Front_Action
{
    public function indexAction()
    {
        $h     = Mage::helper('mmd_attendance');
        $req   = $this->getRequest();
        $runId = (int) $req->getParam('run');
        $run   = $runId > 0 ? $h->loadRunForSelfMark($runId) : null;

        $sKey  = (string) $req->getParam('s');
        $sess  = ($run && $sKey !== '') ? $h->sessionForRun($run, $sKey) : null;
        if (!$run || ($sKey !== '' && !$sess) || !hash_equals($h->checkinSig($runId, $sKey), (string) $req->getParam('k'))) {
            return $this->_page('Class Check-in', '<p class="msg err">This check-in link is not valid.</p>', 404);
        }
        if (!$sess) {
            $sess = $h->sessionForRun($run, $h->currentSessionKey($run));
        }
        $sessLabel = $sess ? $h->sessionShortLabel($sess) : '';
        $title    = 'Class Check-in';
        $classId  = (string) $run['class_id'];
        $head     = '<p class="course">' . htmlspecialchars((string) $run['course_title']) . '</p>';
        if (!$h->isWithinAttendanceWindow($run)) {
            return $this->_page($title, $head . '<p class="msg err">Check-in is not open for this class right now.</p>');
        }

        $name  = trim(preg_replace('/\s+/', ' ', (string) $req->getPost('name')));
        $email = strtolower(trim((string) $req->getPost('email')));
        $phone = trim((string) $req->getPost('phone'));
        $msg   = '';
        $byPhone = false;
        if ($req->isPost() && $email === '' && $phone !== '' && ($known = $h->checkinLearnerByPhone($runId, $phone))) {
            $email = strtolower((string) $known['learner_email']);     // returning learner: phone number is enough
            $name  = (string) $known['learner_name'];
            $byPhone = true;
        }
        if ($req->isPost()) {
            if (trim((string) $req->getPost('website')) !== '') {           // honeypot
                $msg = '<p class="msg err">Check-in failed. Please try again.</p>';
            } elseif (mb_strlen($name) < 2 || mb_strlen($name) > 200 || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
                $msg = '<p class="msg err">Please enter your full name and a valid email address.</p>';
            } elseif ($phone !== '' && !preg_match('/^[0-9+()\-\s]{6,40}$/', $phone)) {
                $msg = '<p class="msg err">Please enter a valid phone number, or leave it blank.</p>';
            } else {
                try {
                    $r = $h->publicCheckIn($runId, $name, $email, $phone, $sKey !== '' ? $sKey : null);
                } catch (Exception $e) {
                    Mage::logException($e);
                    $r = array('success' => false, 'message' => 'Check-in failed. Please ask your trainer.');
                }
                Mage::log(sprintf('QR check-in class %s %s: %s %s', $classId, $sKey, $email, $r['success'] ? ('ok' . (!empty($r['registered']) ? ' (registered)' : '')) : 'FAILED ' . $r['message']), null, 'attendance.log', true);
                if ($r['success']) {
                    return $this->_success($title, $head, $run, $r, $email, $phone, $sKey, $byPhone);
                }
                $msg = '<p class="msg err">' . htmlspecialchars($r['message']) . '</p>';
            }
        }

        $date = Mage::getModel('core/date')->date('d M Y');
        $time = Mage::getModel('core/date')->date('g:i A');
        $lookupUrl = Mage::getUrl('checkin/index/lookup', array('_nosid' => true, 'run' => $runId, 'k' => (string) $req->getParam('k')) + ($sKey !== '' ? array('s' => $sKey) : array()));
        $fresh = $req->isPost() || $req->getParam('new') ? '1' : '0';   // don't pre-fill over typed / "someone else"
        $this->_page($title, $head . $msg
            . '<form method="post" action="" autocomplete="on">'
            . '<label for="ci-phone">Phone</label><input id="ci-phone" name="phone" type="tel" maxlength="40" autocomplete="tel" value="' . htmlspecialchars($phone) . '">'
            . '<p class="hint" id="ci-hint" role="status">Checked in before? Enter your phone number and we fill in the rest.</p>'
            . '<label for="ci-name">Name</label><input id="ci-name" name="name" type="text" required maxlength="200" autocomplete="name" list="ci-saved" value="' . htmlspecialchars($name) . '"><datalist id="ci-saved"></datalist>'
            . '<label for="ci-email">Email</label><input id="ci-email" name="email" type="email" required maxlength="255" autocomplete="email" value="' . htmlspecialchars($email) . '">'
            . '<div class="row"><div><label for="ci-class">Class Code</label><input id="ci-class" type="text" readonly value="' . htmlspecialchars($classId) . '"></div>'
            . '<div><label for="ci-sess">Session</label><input id="ci-sess" type="text" readonly value="' . htmlspecialchars($sessLabel) . '"></div></div>'
            . '<div class="row"><div><label for="ci-date">Date</label><input id="ci-date" type="text" readonly value="' . htmlspecialchars($date) . '"></div>'
            . '<div><label for="ci-time">Time</label><input id="ci-time" type="text" readonly value="' . htmlspecialchars($time) . '"></div></div>'
            . '<input name="website" type="text" tabindex="-1" autocomplete="off" aria-hidden="true" style="position:absolute;left:-9999px">'
            . '<button class="btn" type="submit">Check In</button></form>'
            . '<p class="note">First time? You are registered for this class when you check in. Next session, your phone number is enough.</p>'
            . '<script>' . $this->_profilesJs() . '
(function(){
  var P = ciLoad(), n = document.getElementById("ci-name"), e = document.getElementById("ci-email"),
      ph = document.getElementById("ci-phone"), dl = document.getElementById("ci-saved");
  P.forEach(function(p){ var o = document.createElement("option"); o.value = p.name; dl.appendChild(o); });
  function fill(p){ n.value = p.name; e.value = p.email; ph.value = p.phone || ""; }
  // Returning learner: the phone number finds them on the roster of this class. The email comes
  // back masked and stays on the server; the form is then submitted with the phone alone.
  var hint = document.getElementById("ci-hint"), hint0 = hint.textContent, lastPh = "";
  function known(d){
    if (d && d.found) {
      if (!n.value.trim()) n.value = d.name;
      if (!e.value.trim()) { e.required = false; e.placeholder = d.email; }
      hint.textContent = "Welcome back, " + d.name + ". Tap Check In.";
    } else { e.required = true; e.placeholder = ""; hint.textContent = hint0; }
  }
  function lookup(){
    var v = ph.value.replace(/\D+/g, "");
    if (v === lastPh) return; lastPh = v;
    if (v.length < 8) { known(null); return; }
    var x = new XMLHttpRequest();
    x.open("POST", ' . json_encode($lookupUrl) . ');
    x.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    x.onload = function(){ try { known(JSON.parse(x.responseText)); } catch (err) {} };
    x.send("phone=" + encodeURIComponent(ph.value));
  }
  ph.addEventListener("change", lookup); ph.addEventListener("blur", lookup);
  var phT; ph.addEventListener("input", function(){ clearTimeout(phT); phT = setTimeout(lookup, 600); });
  if (' . $fresh . ' === 0 && P.length && !n.value) fill(P[0]);
  if (ph.value && !e.value) lookup();
  n.addEventListener("input", function(){
    var v = n.value.trim().toLowerCase();
    for (var i = 0; i < P.length; i++) if (P[i].name.toLowerCase() === v) { fill(P[i]); return; }
  });
  // Keep the time current while the form is open (server time + elapsed).
  var t0 = Date.now(), base = ' . (int) Mage::getModel('core/date')->timestamp() . ' * 1000, tm = document.getElementById("ci-time");
  setInterval(function(){
    var d = new Date(base + Date.now() - t0), h = d.getUTCHours(), m = d.getUTCMinutes();
    tm.value = ((h % 12) || 12) + ":" + (m < 10 ? "0" : "") + m + " " + (h < 12 ? "AM" : "PM");
  }, 15000);
})();
</script>');
    }

    /**
     * Phone lookup for the form (same signed link). JSON: found, name, email (masked).
     * Only this class's roster is searched and the full email never leaves the server.
     */
    public function lookupAction()
    {
        $h     = Mage::helper('mmd_attendance');
        $req   = $this->getRequest();
        $runId = (int) $req->getParam('run');
        $out   = array('found' => false);
        if ($req->isPost() && $runId > 0 && hash_equals($h->checkinSig($runId, (string) $req->getParam('s')), (string) $req->getParam('k'))
            && ($known = $h->checkinLearnerByPhone($runId, (string) $req->getPost('phone')))) {
            list($local, $domain) = array_pad(explode('@', (string) $known['learner_email'], 2), 2, '');
            $out = array('found' => true, 'name' => (string) $known['learner_name'],
                'email' => substr($local, 0, 2) . str_repeat('*', max(3, strlen($local) - 2)) . '@' . $domain);
        }
        $this->getResponse()->setHeader('Content-Type', 'application/json', true)
            ->setHeader('Cache-Control', 'no-store', true)->setBody(json_encode($out));
    }

    protected function _success($title, $head, array $run, array $r, $email, $phone, $sKey = '', $byPhone = false)
    {
        $profile = json_encode(array('name' => (string) $r['name'], 'email' => $email, 'phone' => $phone), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT);
        $when    = Mage::getModel('core/date')->date('d M Y, g:i A');
        $again   = Mage::helper('mmd_attendance')->checkinUrl($run['run_id'], $sKey) . '?new=1';
        $body = $head
            . '<p class="msg ok">' . htmlspecialchars($r['message']) . '</p>'
            . '<dl><dt>Name</dt><dd>' . htmlspecialchars((string) $r['name']) . '</dd>'
            . '<dt>Class</dt><dd>' . htmlspecialchars((string) $run['class_id']) . '</dd>'
            . ($r['session_label'] !== '' ? '<dt>Session</dt><dd>' . htmlspecialchars($r['session_label']) . '</dd>' : '')
            . '<dt>Time</dt><dd>' . htmlspecialchars($when) . '</dd></dl>'
            . (!empty($r['registered']) ? '<p>You are now registered for this class. Sign in to the learning portal with <strong>'
                . htmlspecialchars($email) . '</strong> and an email code to get the course material.</p>'
                . '<p><a class="btn" href="' . htmlspecialchars(Mage::getUrl('lmslogin', array('_nosid' => true))) . '">Open the learning portal</a></p>' : '')
            . '<p class="note"><a href="' . htmlspecialchars($again) . '">Check in someone else on this phone</a></p>'
            // Found by phone number alone: the email was never typed here, so it is not sent to the page.
            . ($byPhone ? '' : '<script>' . $this->_profilesJs() . '
(function(){
  var p = ' . $profile . ', P = ciLoad().filter(function(x){ return x.email !== p.email; });
  P.unshift(p);
  try { localStorage.setItem("tcCheckinProfiles", JSON.stringify(P.slice(0, 5))); } catch (e) {}
})();
</script>');
        $this->_page($title, $body);
    }

    /** Saved check-in profiles on this device, most recent first. */
    protected function _profilesJs()
    {
        return 'function ciLoad(){ try { var a = JSON.parse(localStorage.getItem("tcCheckinProfiles") || "[]");'
            . ' return Array.isArray(a) ? a.filter(function(p){ return p && p.name && p.email; }) : []; } catch (e) { return []; } }';
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
                . '.card{max-width:420px;margin:24px auto;padding:26px 22px;background:#fff;border-radius:12px;box-shadow:0 1px 3px rgba(15,23,42,.12)}'
                . 'h1{font-size:22px;margin:0 0 4px}.course{color:#475569;font-size:14px;margin:0 0 16px}'
                . 'label{display:block;font-size:14px;font-weight:600;margin:14px 0 6px}.opt{font-weight:400;color:#64748b}'
                . 'input[type=text],input[type=email],input[type=tel]{width:100%;box-sizing:border-box;padding:12px;font-size:16px;border:1px solid #94a3b8;border-radius:8px}'
                . 'input[readonly]{background:#f1f5f9;color:#334155;border-color:#cbd5e1}.hint{color:#475569;font-size:13px;margin:6px 0 0}'
                . '.row{display:flex;gap:12px}.row>div{flex:1;min-width:0}'
                . 'input:focus-visible,.btn:focus-visible,a:focus-visible{outline:3px solid #93c5fd;outline-offset:2px}'
                . '.btn{display:inline-block;width:100%;box-sizing:border-box;margin-top:20px;padding:14px;font-size:17px;font-weight:600;color:#fff;background:#1d4ed8;border:0;border-radius:8px;text-align:center;text-decoration:none;cursor:pointer}'
                . '.msg{padding:12px;border-radius:8px;font-size:15px}.ok{background:#dcfce7;color:#14532d}.err{background:#fee2e2;color:#7f1d1d}'
                . 'dl{display:grid;grid-template-columns:auto 1fr;gap:6px 14px;font-size:15px;margin:16px 0}dt{color:#475569}dd{margin:0;font-weight:600}'
                . '.note{color:#475569;font-size:13px;margin:16px 0 0}.note a{color:#1d4ed8}'
                . '</style></head><body><main class="card"><h1>' . $t . '</h1>' . $body . '</main></body></html>');
    }
}
