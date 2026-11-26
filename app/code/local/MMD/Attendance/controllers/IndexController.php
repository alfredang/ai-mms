<?php
/**
 * Public class check-in page, opened from the trainer's Take Attendance QR:
 *   /checkin/index/index/run/<run_id>[/s/<session key>]/k/<signature>
 * The trainer's QR is class-wide (no /s/): the session is picked by the clock, AM 08:00-11:59
 * and PM 12:00-17:59 on a class day (Helper::autoSessionKey); outside those hours the form is
 * closed. A link with /s/ (older per-session QR) marks THAT session.
 * No login. The learner enters name + email (+ optional phone); class code, date and time
 * are filled in. A learner not yet on the roster is registered on their first check-in
 * (MMD_Attendance_Helper_Data::publicCheckIn). A learner who gave a phone number before is
 * found again by it (this class's roster only; the email is shown masked and never sent
 * to the page), so a later session needs the phone number alone. The phone's browser also remembers the details
 * (localStorage, never sent anywhere else), so later sessions are pre-filled and typing a
 * saved name fills the rest. A 30-day HttpOnly cookie (tc_checkin, /checkin only) also carries the last
 * check-in on the phone, so the PM form is filled even without localStorage; after a phone-only
 * check-in it holds the name and phone, never the email. Checking in also registers the learner for the course's practice
 * exam, if it has one (no second form). A Learner / Trainer toggle (Learner by default): Trainer saves the
 * class trainer's signature for the session (teaches() check; no roster row). The learner signs with a finger in the signature box
 * (required); the signature is saved for the session and shows on E-Attendance and on the
 * signed attendance sheet (PDF). The link's k (HMAC of the run id) stops link guessing; the
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
        $title    = 'Class Check-in';
        $classId  = (string) $run['class_id'];
        $head     = '<p class="course">' . htmlspecialchars((string) $run['course_title']) . '</p>'
            . (!empty($run['course_sku']) ? '<p class="ccode">Course Code: ' . htmlspecialchars((string) $run['course_sku']) . '</p>' : '')
            . '<div class="runid"><span>Course Run ID</span><b>' . htmlspecialchars($classId) . '</b></div>';
        if (!$h->isWithinAttendanceWindow($run)) {
            return $this->_page($title, $head . '<p class="msg err">Check-in is not open for this class right now.</p>');
        }
        if (!$sess) {                                   // class-wide QR: the clock picks the session
            $sess = $h->sessionForRun($run, $h->autoSessionKey($run));
            if (!$sess) {
                return $this->_page($title, $head . '<p class="msg err">Check-in is not open right now. On class days the AM session'
                    . ' check-in runs from 8:00 AM to 12:00 PM and the PM session from 12:00 PM to 6:00 PM.</p>');
            }
        }
        $sessLabel = $h->sessionShortLabel($sess);
        $markKey   = $sKey !== '' ? $sKey : (string) $sess['key'];

        $name  = trim(preg_replace('/\s+/', ' ', (string) $req->getPost('name')));
        $email = strtolower(trim((string) $req->getPost('email')));
        $phone = trim((string) $req->getPost('phone'));
        $role  = $req->getPost('role') === 'trainer' ? 'trainer' : 'learner';   // Learner (default) / Trainer toggle
        $msg   = '';
        $sig   = Mage::helper('mmd_mobileapi/signature');
        $byPhone = false;
        if ($req->isPost() && $role === 'learner' && $email === '' && $phone !== '' && ($known = $h->checkinLearnerByPhone($runId, $phone))) {
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
            } elseif (!($png = $sig->decode((string) $req->getPost('signature'))) || !$sig->hasInk($png)) {
                $msg = '<p class="msg err">Please sign in the signature box with your finger, then tap Check In.</p>';
            } elseif ($role === 'trainer') {
                // Trainer: signs this session as the class's trainer (same record as E-Attendance
                // "Sign as Trainer"); only the trainer assigned to this class, never added to the roster.
                if (!Mage::helper('mmd_mobileapi/trainer')->teaches($email, $runId)) {
                    $msg = '<p class="msg err">This email is not the trainer of this class. Please use the email of your trainer account, or choose Learner.</p>';
                    Mage::log(sprintf('QR trainer check-in class %s %s: %s REFUSED not the trainer', $classId, $markKey, $email), null, 'attendance.log', true);
                } else {
                    $sig->save(array('run_id' => $runId, 'class_id' => $classId), $markKey, $email, $name, 'trainer', $png, $email);
                    Mage::log(sprintf('QR trainer check-in class %s %s: %s signed ok', $classId, $markKey, $email), null, 'attendance.log', true);
                    $this->_saveProfile($name, $email, '', 'trainer');
                    return $this->_page($title, $head
                        . '<p class="msg ok">You are checked in as the trainer. Your signature is saved for this session.</p>'
                        . '<dl><dt>Name</dt><dd>' . htmlspecialchars($name) . '</dd><dt>Class</dt><dd>' . htmlspecialchars($classId) . '</dd>'
                        . '<dt>Session</dt><dd>' . htmlspecialchars($sessLabel) . '</dd>'
                        . '<dt>Time</dt><dd>' . htmlspecialchars(Mage::getModel('core/date')->date('d M Y, g:i A')) . '</dd></dl>');
                }
            } else {
                try {
                    $r = $h->publicCheckIn($runId, $name, $email, $phone, $markKey, $png);
                } catch (Exception $e) {
                    Mage::logException($e);
                    $r = array('success' => false, 'message' => 'Check-in failed. Please ask your trainer.');
                }
                Mage::log(sprintf('QR check-in class %s %s: %s signed %s', $classId, $markKey, $email, $r['success'] ? ('ok' . (!empty($r['registered']) ? ' (registered)' : '')) : 'FAILED ' . $r['message']), null, 'attendance.log', true);
                if ($r['success']) {
                    return $this->_success($title, $head, $run, $r, $email, $phone, $sKey, $byPhone);
                }
                $msg = '<p class="msg err">' . htmlspecialchars($r['message']) . '</p>';
            }
        }

        // The last check-in on this phone (cookie set by _success) fills the form for the next
        // session, even when the browser kept no localStorage. Not over typed input or "someone else".
        if (!$req->isPost() && !$req->getParam('new') && ($saved = $this->_savedProfile())) {
            $name = $saved['name']; $email = $saved['email']; $phone = $saved['phone']; $role = $saved['role'];
        }
        $date = Mage::getModel('core/date')->date('d M Y');
        $time = Mage::getModel('core/date')->date('g:i A');
        $lookupUrl = Mage::getUrl('checkin/index/lookup', array('_nosid' => true, 'run' => $runId, 'k' => (string) $req->getParam('k')) + ($sKey !== '' ? array('s' => $sKey) : array()));
        $fresh = $req->isPost() || $req->getParam('new') ? '1' : '0';   // don't pre-fill over typed / "someone else"
        $this->_page($title, $head . $msg
            . '<form method="post" action="" autocomplete="on">'
            . '<div class="seg" role="radiogroup" aria-label="I am checking in as">'
            . '<label><input type="radio" name="role" value="learner"' . ($role === 'learner' ? ' checked' : '') . '><span>Learner</span></label>'
            . '<label><input type="radio" name="role" value="trainer"' . ($role === 'trainer' ? ' checked' : '') . '><span>Trainer</span></label></div>'
            . '<label for="ci-name">Name</label><input id="ci-name" name="name" type="text" required maxlength="200" autocomplete="name" list="ci-saved" value="' . htmlspecialchars($name) . '"><datalist id="ci-saved"></datalist>'
            . '<label for="ci-email">Email</label><input id="ci-email" name="email" type="email" required maxlength="255" autocomplete="email" value="' . htmlspecialchars($email) . '">'
            . '<div id="ci-phone-wrap"' . ($role === 'trainer' ? ' hidden' : '') . '><label for="ci-phone">Phone <span class="opt">(optional)</span></label><input id="ci-phone" name="phone" type="tel" maxlength="40" autocomplete="tel" value="' . htmlspecialchars($phone) . '"></div>'
            . '<p class="hint" id="ci-hint" role="status"></p>'
            . '<label for="ci-sess">Session</label><input id="ci-sess" type="text" readonly value="' . htmlspecialchars($sessLabel) . '">'
            . '<div class="row"><div><label for="ci-date">Date</label><input id="ci-date" type="text" readonly value="' . htmlspecialchars($date) . '"></div>'
            . '<div><label for="ci-time">Time</label><input id="ci-time" type="text" readonly value="' . htmlspecialchars($time) . '"></div></div>'
            . '<div class="sig-head"><span class="lbl" id="ci-sig-label">Signature</span>'
            . '<button type="button" class="link" id="ci-sig-clear">Clear</button></div>'
            . '<canvas id="ci-sig" class="sig" role="img" aria-labelledby="ci-sig-label" aria-describedby="ci-sig-hint" tabindex="0"></canvas>'
            . '<p class="hint" id="ci-sig-hint">Sign inside the box with your finger.</p>'
            . '<input type="hidden" name="signature" id="ci-sig-data">'
            . '<input name="website" type="text" tabindex="-1" autocomplete="off" aria-hidden="true" style="position:absolute;left:-9999px">'
            . '<button class="btn" type="submit">Check In</button></form>'
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
      hint.textContent = "Welcome back, " + d.name + ". Sign below, then tap Check In.";
    } else { e.required = true; e.placeholder = ""; hint.textContent = hint0; }
  }
  // Email already on this class roster (checked in before): fill the name if empty.
  var lastEm = "";
  var pw = document.getElementById("ci-phone-wrap");
  function isTrainer(){ var r = document.querySelector("input[name=role]:checked"); return r && r.value === "trainer"; }
  Array.prototype.forEach.call(document.querySelectorAll("input[name=role]"), function(r){
    r.addEventListener("change", function(){ pw.hidden = isTrainer(); if (isTrainer()) { e.required = true; e.placeholder = ""; } hint.textContent = ""; });
  });
  function lookupEmail(){
    if (isTrainer()) return;
    var v = e.value.trim().toLowerCase();
    if (v === lastEm || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(v)) return; lastEm = v;
    var x = new XMLHttpRequest();
    x.open("POST", ' . json_encode($lookupUrl) . ');
    x.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    x.onload = function(){ try { var d = JSON.parse(x.responseText);
      if (d && d.found) { if (!n.value.trim()) n.value = d.name; hint.textContent = "Welcome back, " + d.name + ". Sign below, then tap Check In."; }
    } catch (err) {} };
    x.send("email=" + encodeURIComponent(v));
  }
  e.addEventListener("change", lookupEmail); e.addEventListener("blur", lookupEmail);
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
  // Finger signature pad: ink is drawn at device resolution, sent as a PNG data URL.
  var cv = document.getElementById("ci-sig"), cx = cv.getContext("2d"), sd = document.getElementById("ci-sig-data"),
      sh = document.getElementById("ci-sig-hint"), sh0 = sh.textContent, ink = 0, last = null;
  function size(){
    var r = cv.getBoundingClientRect(), k = Math.min(window.devicePixelRatio || 1, 3);
    cv.width = Math.round(r.width * k); cv.height = Math.round(r.height * k);
    cx.setTransform(k, 0, 0, k, 0, 0); cx.lineWidth = 2.6; cx.lineCap = "round"; cx.lineJoin = "round"; cx.strokeStyle = "#0f172a";
    ink = 0;
  }
  size();
  function pt(ev){ var r = cv.getBoundingClientRect(); return { x: ev.clientX - r.left, y: ev.clientY - r.top }; }
  cv.addEventListener("pointerdown", function(ev){ ev.preventDefault(); cv.setPointerCapture(ev.pointerId); last = pt(ev);
    cx.beginPath(); cx.arc(last.x, last.y, 1.2, 0, 2 * Math.PI); cx.fillStyle = "#0f172a"; cx.fill(); });
  cv.addEventListener("pointermove", function(ev){ if (!last) return; ev.preventDefault(); var p = pt(ev);
    cx.beginPath(); cx.moveTo(last.x, last.y); cx.lineTo(p.x, p.y); cx.stroke();
    ink += Math.abs(p.x - last.x) + Math.abs(p.y - last.y); last = p; if (ink > 40) { sh.textContent = sh0; sh.className = "hint"; cv.classList.remove("bad"); } });
  function up(){ last = null; }
  cv.addEventListener("pointerup", up); cv.addEventListener("pointercancel", up); cv.addEventListener("pointerleave", up);
  document.getElementById("ci-sig-clear").addEventListener("click", function(){ cx.clearRect(0, 0, cv.width, cv.height); ink = 0; sd.value = ""; });
  window.addEventListener("orientationchange", function(){ setTimeout(size, 300); });
  cv.closest("form").addEventListener("submit", function(ev){
    if (ink < 40) { ev.preventDefault(); sh.textContent = "Please sign inside the box with your finger."; sh.className = "hint bad"; cv.classList.add("bad"); cv.focus(); return; }
    sd.value = cv.toDataURL("image/png");
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
        $signed = $req->isPost() && $runId > 0 && hash_equals($h->checkinSig($runId, (string) $req->getParam('s')), (string) $req->getParam('k'));
        $byEmail = strtolower(trim((string) $req->getPost('email')));
        if ($signed && $byEmail !== '' && filter_var($byEmail, FILTER_VALIDATE_EMAIL)) {
            $nm = (string) Mage::getSingleton('core/resource')->getConnection('core_read')->fetchOne(
                'SELECT learner_name FROM ' . Mage::getSingleton('core/resource')->getTableName('course_run_enrolments')
                . ' WHERE run_id = ? AND LOWER(learner_email) = ? LIMIT 1', array($runId, $byEmail));
            if ($nm === '' || strpos($nm, '@') !== false) {       // legacy rows hold the email as the name
                $nm = '';
                $c = Mage::getModel('customer/customer')->setWebsiteId((int) Mage::app()->getDefaultStoreView()->getWebsiteId())->loadByEmail($byEmail);
                $nm = $c->getId() ? trim($c->getFirstname() . ' ' . ($c->getLastname() !== '-' ? $c->getLastname() : '')) : '';
            }
            if ($nm !== '') $out = array('found' => true, 'name' => $nm);
        } elseif ($signed && ($known = $h->checkinLearnerByPhone($runId, (string) $req->getPost('phone')))) {
            list($local, $domain) = array_pad(explode('@', (string) $known['learner_email'], 2), 2, '');
            $out = array('found' => true, 'name' => (string) $known['learner_name'],
                'email' => substr($local, 0, 2) . str_repeat('*', max(3, strlen($local) - 2)) . '@' . $domain);
        }
        $this->getResponse()->setHeader('Content-Type', 'application/json', true)
            ->setHeader('Cache-Control', 'no-store', true)->setBody(json_encode($out));
    }

    protected function _success($title, $head, array $run, array $r, $email, $phone, $sKey = '', $byPhone = false)
    {
        // Found by phone alone: remember the name and phone only, so the email stays off the page.
        $this->_saveProfile((string) $r['name'], $byPhone ? '' : $email, $phone);
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
                . '<p><a class="btn" href="' . htmlspecialchars($this->_portalUrl($run, $byPhone ? '' : $email)) . '">Open the learning portal</a></p>' : '')
            . $this->_practiceExamHtml($run, (string) $r['name'], $email, $byPhone)
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

    /**
     * The learning portal with this class's Course Run ID (and the learner's email) filled in,
     * so a learner coming from check-in never has to type the class code.
     */
    protected function _portalUrl(array $run, $email = '')
    {
        $q = array('class' => (string) $run['class_id']);
        if ($email !== '') $q['email'] = $email;
        return Mage::getUrl('lmslogin', array('_nosid' => true, '_query' => $q));
    }

    /**
     * After check-in: when the course has a practice exam (MMD_PracticeExam), the learner is
     * registered for it at once (exams API, course run id = class id), so name + email (+ phone)
     * on the check-in form is all they ever enter. The exams site creates the account and emails
     * the exam link on the first registration; a repeat call changes nothing and sends nothing,
     * and a success is remembered for 30 days so later sessions skip the API. If the call fails,
     * the learner gets the class's Self-Register form instead. Found by phone only? The email
     * stays on the server: it is used for the registration but not shown or put in a link.
     * Nothing shows when the exams token is not set (partner sites) or registration is closed.
     */
    protected function _practiceExamHtml(array $run, $name, $email, $byPhone = false)
    {
        try {
            $pe   = Mage::helper('mmd_practiceexam');
            $prun = $pe->loadRun((int) $run['run_id']);
            $exam = $prun ? $pe->getCourseExam($prun['product_id']) : null;
            if (!$exam || !$pe->isConfigured() || !$pe->selfRegisterOpen($prun)) return '';
            $code     = htmlspecialchars((string) $exam['exam_code']);
            $cacheKey = 'mmd_pe_checkin_' . md5($prun['class_id'] . '|' . $exam['exam_slug'] . '|' . strtolower($email));
            $done     = (bool) Mage::app()->getCache()->load($cacheKey);
            if (!$done) {
                $r = $pe->registerPerson($name, $email, $exam['exam_slug'], $prun['class_id'],
                    'Registered at class check-in, course run ' . $prun['class_id']);
                Mage::log(sprintf('check-in register class %s -> %s: %s %s', $prun['class_id'], $exam['exam_code'], $email, $r['ok'] ? 'ok' : 'FAILED ' . $r['error']), null, 'mmd_practiceexam.log', true);
                if ($r['ok']) {
                    Mage::app()->getCache()->save('1', $cacheKey, array(), 30 * 86400);
                    $done = true;
                }
            }
            if ($done) {
                $to = $byPhone ? 'your email' : '<strong>' . htmlspecialchars($email) . '</strong>';
                return '<div class="pe"><h2>' . $code . ' Practice Exam</h2>'
                    . '<p>You are registered for the ' . $code . ' practice exam. The exam link is emailed to ' . $to
                    . '. Sign in with that email using Google or an email code.</p>'
                    . '<a class="btn" href="' . htmlspecialchars($pe->baseUrl()) . '/login">Open Tertiary Exams</a></div>';
            }
            $url = $pe->selfRegisterUrl($prun['run_id'], $name, $byPhone ? '' : $email);
        } catch (Exception $e) {
            Mage::logException($e);
            return '';
        }
        return '<div class="pe"><h2>' . $code . ' Practice Exam</h2>'
            . '<p>This course includes the ' . $code . ' practice exam. Register and we email you the exam link.</p>'
            . '<a class="btn" href="' . htmlspecialchars($url) . '">Register for the Practice Exam</a></div>';
    }

    const PROFILE_COOKIE = 'tc_checkin';

    /** Remember this phone's check-in (name, email, phone) for 30 days: HttpOnly, this site's /checkin pages only. */
    protected function _saveProfile($name, $email, $phone, $role = 'learner')
    {
        $value = base64_encode(json_encode(array('n' => mb_substr($name, 0, 200), 'e' => mb_substr($email, 0, 255), 'p' => mb_substr($phone, 0, 40),
            'r' => $role === 'trainer' ? 'trainer' : 'learner')));
        setcookie(self::PROFILE_COOKIE, $value, array(
            'expires' => time() + 30 * 86400, 'path' => '/checkin', 'secure' => Mage::app()->getStore()->isCurrentlySecure(),
            'httponly' => true, 'samesite' => 'Lax',
        ));
    }

    /** The profile _saveProfile left on this phone, or null. */
    protected function _savedProfile()
    {
        $raw = isset($_COOKIE[self::PROFILE_COOKIE]) ? (string) $_COOKIE[self::PROFILE_COOKIE] : '';
        $d   = $raw !== '' ? json_decode((string) base64_decode($raw, true), true) : null;
        if (!is_array($d) || !isset($d['n'])) return null;
        $name  = trim(preg_replace('/\s+/', ' ', (string) $d['n']));
        $email = strtolower(trim((string) (isset($d['e']) ? $d['e'] : '')));
        $phone = trim((string) (isset($d['p']) ? $d['p'] : ''));
        if (mb_strlen($name) < 2 || ($email !== '' && !filter_var($email, FILTER_VALIDATE_EMAIL)) || ($phone !== '' && !preg_match('/^[0-9+()\-\s]{6,40}$/', $phone))) return null;
        return array('name' => $name, 'email' => $email, 'phone' => $phone, 'role' => (isset($d['r']) && $d['r'] === 'trainer') ? 'trainer' : 'learner');
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
                . 'h1{font-size:22px;margin:0 0 4px}.course{color:#0f172a;font-size:16px;font-weight:600;margin:0 0 2px}'
                . '.ccode{color:#475569;font-size:14px;margin:0 0 10px}'
                . '.runid{display:flex;flex-direction:column;align-items:center;margin:0 0 16px;padding:8px 12px;border:2px solid #1d4ed8;border-radius:10px;background:#eff6ff}'
                . '.runid span{font-size:12px;font-weight:600;letter-spacing:.06em;text-transform:uppercase;color:#1e3a8a}'
                . '.runid b{font-size:30px;font-weight:800;letter-spacing:.04em;color:#0f172a;line-height:1.2}'
                . 'label{display:block;font-size:14px;font-weight:600;margin:14px 0 6px}.opt{font-weight:400;color:#64748b}'
                . '.seg{display:flex;gap:0;margin:0 0 6px;border:1px solid #94a3b8;border-radius:10px;overflow:hidden}'
                . '.seg label{flex:1;margin:0;font-weight:600;font-size:15px;text-align:center;cursor:pointer}'
                . '.seg input{position:absolute;opacity:0;pointer-events:none}'
                . '.seg span{display:block;padding:11px 8px;color:#334155;background:#fff}'
                . '.seg input:checked+span{background:#1d4ed8;color:#fff}'
                . '.seg input:focus-visible+span{outline:3px solid #93c5fd;outline-offset:-3px}'
                . '[hidden]{display:none !important}'
                . 'input[type=text],input[type=email],input[type=tel]{width:100%;box-sizing:border-box;padding:12px;font-size:16px;border:1px solid #94a3b8;border-radius:8px}'
                . 'input[readonly]{background:#f1f5f9;color:#334155;border-color:#cbd5e1}.hint{color:#475569;font-size:13px;margin:6px 0 0}'
                . '.row{display:flex;gap:12px}.row>div{flex:1;min-width:0}'
                . 'input:focus-visible,.btn:focus-visible,a:focus-visible{outline:3px solid #93c5fd;outline-offset:2px}'
                . '.btn{display:inline-block;width:100%;box-sizing:border-box;margin-top:20px;padding:14px;font-size:17px;font-weight:600;color:#fff;background:#1d4ed8;border:0;border-radius:8px;text-align:center;text-decoration:none;cursor:pointer}'
                . '.msg{padding:12px;border-radius:8px;font-size:15px}.ok{background:#dcfce7;color:#14532d}.err{background:#fee2e2;color:#7f1d1d}'
                . 'dl{display:grid;grid-template-columns:auto 1fr;gap:6px 14px;font-size:15px;margin:16px 0}dt{color:#475569}dd{margin:0;font-weight:600}'
                . '.note{color:#475569;font-size:13px;margin:16px 0 0}.note a{color:#1d4ed8}'
                . '.sig-head{display:flex;align-items:flex-end;justify-content:space-between}.lbl{font-size:14px;font-weight:600;margin:14px 0 6px}'
                . '.link{background:none;border:0;color:#1d4ed8;font-size:14px;font-weight:600;padding:4px 2px 6px;cursor:pointer}'
                . '.sig{display:block;width:100%;height:170px;background:#fff;border:1px dashed #64748b;border-radius:8px;touch-action:none;cursor:crosshair}'
                . '.sig.bad{border:2px solid #b91c1c}.hint.bad{color:#b91c1c;font-weight:600}.sig:focus-visible{outline:3px solid #93c5fd;outline-offset:2px}'
                . '.pe{margin:20px 0 0;padding:16px;border:1px solid #bfdbfe;border-radius:10px;background:#eff6ff}'
                . '.pe h2{font-size:17px;margin:0 0 6px}.pe p{font-size:14px;color:#334155;margin:0}.pe .btn{margin-top:14px}'
                . '</style></head><body><main class="card"><h1>' . $t . '</h1>' . $body . '</main></body></html>');
    }
}
