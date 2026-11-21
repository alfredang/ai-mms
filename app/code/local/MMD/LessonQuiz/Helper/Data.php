<?php
/**
 * Course Lesson + lesson quizzes.
 *
 * The Lesson (topics > sub topics > assets) is the JSON in the
 * `<!-- LSN_DATA: [...] -->` marker at the top of the course description:
 *   [{title, subsecs: [{title, links: [{type, title, url, qid}]}]}]
 * Asset types: web | doc | act (URL links), yt (embedded video), qz (quiz).
 * A quiz asset carries only `qid`; its questions and correct answers are in
 * mmd_lesson_quiz so they never reach the public course page.
 */
class MMD_LessonQuiz_Helper_Data extends Mage_Core_Helper_Abstract
{
    const MAX_QUESTIONS = 10;
    const MIN_OPTIONS   = 2;
    const MAX_OPTIONS   = 4;

    /** Roles that write quizzes (the course editor). */
    public function editRoles()
    {
        return array('developer', 'admin', 'training_provider', 'franchise_admin');
    }

    /** Roles that show a quiz in class and read its results. */
    public function classRoles()
    {
        return array_merge(array('trainer'), $this->editRoles());
    }

    /* ------------------------------------------------------------ Lesson */

    /**
     * Parse a course description into Lesson topics. Prefers the LSN_DATA
     * marker; falls back to the legacy "<strong>Topic N</strong>" markup, then
     * to the storefront "<h3>Topic N</h3><ul><li>" outline.
     *
     * @return array [{title, subsecs: [{title, links: [...]}]}]
     */
    public function lessonTopics($html)
    {
        $html   = (string) $html;
        $topics = array();
        if ($html === '') {
            return $topics;
        }
        if (preg_match('/<!--\s*LSN_DATA:\s*(\[.*?\])\s*-->/s', $html, $m)) {
            $decoded = json_decode($m[1], true);
            if (is_array($decoded)) {
                foreach ($decoded as $t) {
                    if (is_array($t)) {
                        $topics[] = $this->_normaliseTopic($t);
                    }
                }
            }
        }
        if (!$topics && preg_match('#<strong>\s*(?:LU|Lesson|Topic|Module)\s*\d+#i', $html)) {
            $parts = preg_split('#<strong>\s*((?:LU|Lesson|Topic|Module)\s*\d+[^<]*?)\s*</strong>#i', $html, -1, PREG_SPLIT_DELIM_CAPTURE);
            for ($i = 1; $i < count($parts); $i += 2) {
                $title = $this->_plain($parts[$i]);
                if ($title === '') continue;
                $body = isset($parts[$i + 1]) ? $parts[$i + 1] : '';
                $subs = array();
                if (preg_match_all('#<em>(.*?)</em>#is', $body, $em)) {
                    $lines = $em[1];
                } else {
                    $lines = preg_split('#</?(?:p|li|br|div)[^>]*>#i', $body);
                }
                foreach ($lines as $line) {
                    $line = $this->_plain(strip_tags($line));
                    if ($line !== '') $subs[] = array('title' => $line, 'links' => array());
                }
                $topics[] = array('title' => $title, 'subsecs' => $subs);
            }
        }
        if (!$topics && preg_match('#<h3[^>]*>#i', $html)) {
            $parts = preg_split('#<h3[^>]*>(.*?)</h3>#is', $html, -1, PREG_SPLIT_DELIM_CAPTURE);
            for ($i = 1; $i < count($parts); $i += 2) {
                $title = $this->_plain(strip_tags($parts[$i]));
                if ($title === '') continue;
                $body = isset($parts[$i + 1]) ? $parts[$i + 1] : '';
                $subs = array();
                if (preg_match_all('#<li[^>]*>(.*?)</li>#is', $body, $li)) {
                    foreach ($li[1] as $line) {
                        $line = $this->_plain(strip_tags($line));
                        if ($line !== '') $subs[] = array('title' => $line, 'links' => array());
                    }
                }
                $topics[] = array('title' => $title, 'subsecs' => $subs);
            }
        }
        return $topics;
    }

    /** The Lesson of a course (default-scope description). */
    public function productLesson($productId)
    {
        $raw = Mage::getResourceModel('catalog/product')->getAttributeRawValue((int) $productId, 'description', 0);
        return $this->lessonTopics(is_string($raw) ? $raw : '');
    }

    /**
     * The course description as the public course page prints it: the Lesson
     * outline (topics and sub topics) without the LSN_DATA marker and without
     * the Lesson's links, videos and quizzes, which are for the class only.
     */
    public function publicOutline($html)
    {
        $html = preg_replace('/<!--\s*LSN_DATA:.*?-->\s*/s', '', (string) $html);
        // Asset lines the Lesson builder used to write: <li>… <em>[Web]</em></li>
        $html = preg_replace('#\s*<li>(?:(?!</li>).)*?<em>\[(?:Web|Document|YouTube|Activity|Quiz)\]</em>\s*</li>#is', '', $html);
        return preg_replace('#<ul>\s*</ul>\s*#i', '', $html);
    }

    /** Quiz ids used by a Lesson, in order. */
    public function quizIds(array $topics)
    {
        $ids = array();
        foreach ($topics as $t) {
            foreach ($t['subsecs'] as $s) {
                foreach ($s['links'] as $l) {
                    if ($l['type'] === 'qz' && $l['qid'] > 0) $ids[] = (int) $l['qid'];
                }
            }
        }
        return array_values(array_unique($ids));
    }

    protected function _plain($s)
    {
        return trim(html_entity_decode((string) $s, ENT_QUOTES, 'UTF-8'), " :\t\n\r\0\x0B");
    }

    /** Older saves used `subsec` (one string), `subsecs` as strings, and topic-level `links`. */
    protected function _normaliseTopic(array $t)
    {
        $raw = isset($t['subsecs']) && is_array($t['subsecs']) ? $t['subsecs']
            : (isset($t['subsec']) && is_string($t['subsec']) && $t['subsec'] !== '' ? array($t['subsec']) : array());
        $subs = array();
        foreach ($raw as $s) {
            if (is_array($s)) {
                $links = array();
                foreach (isset($s['links']) && is_array($s['links']) ? $s['links'] : array() as $l) {
                    if (is_array($l)) $links[] = $this->_normaliseLink($l);
                }
                $subs[] = array('title' => (string) (isset($s['title']) ? $s['title'] : ''), 'links' => $links);
            } elseif ((string) $s !== '') {
                $subs[] = array('title' => (string) $s, 'links' => array());
            }
        }
        if (isset($t['links']) && is_array($t['links']) && $t['links']) {
            if (!$subs) $subs[] = array('title' => '', 'links' => array());
            foreach ($t['links'] as $l) {
                if (is_array($l)) $subs[0]['links'][] = $this->_normaliseLink($l);
            }
        }
        return array('title' => (string) (isset($t['title']) ? $t['title'] : ''), 'subsecs' => $subs);
    }

    protected function _normaliseLink(array $l)
    {
        return array(
            'type'  => isset($l['type']) ? strtolower((string) $l['type']) : 'web',
            'title' => (string) (isset($l['title']) ? $l['title'] : ''),
            'url'   => (string) (isset($l['url']) ? $l['url'] : ''),
            'qid'   => isset($l['qid']) ? (int) $l['qid'] : 0,
        );
    }

    /** YouTube video id of a watch / youtu.be / embed / shorts / live link, or ''. */
    public function youtubeId($url)
    {
        $url = trim((string) $url);
        if ($url === '') return '';
        if (!preg_match('#^https?://#i', $url)) $url = 'https://' . $url;
        $p = parse_url($url);
        if (!$p || empty($p['host'])) return '';
        $host = preg_replace('/^(www|m|music)\./', '', strtolower($p['host']));
        $path = isset($p['path']) ? $p['path'] : '';
        $id   = '';
        if ($host === 'youtu.be') {
            $seg = explode('/', $path);
            $id  = isset($seg[1]) ? $seg[1] : '';
        } elseif ($host === 'youtube.com' || $host === 'youtube-nocookie.com') {
            if ($path === '/watch') {
                parse_str(isset($p['query']) ? $p['query'] : '', $q);
                $id = isset($q['v']) ? (string) $q['v'] : '';
            } elseif (preg_match('#^/(?:embed|shorts|live|v)/([^/?\#]+)#', $path, $m)) {
                $id = $m[1];
            }
        }
        return preg_match('/^[A-Za-z0-9_-]{6,20}$/', $id) ? $id : '';
    }

    /** Start offset in seconds from ?t=90, ?t=1m30s or ?start=90. */
    public function youtubeStart($url)
    {
        parse_str((string) parse_url(trim((string) $url), PHP_URL_QUERY), $q);
        $raw = isset($q['start']) ? (string) $q['start'] : (isset($q['t']) ? (string) $q['t'] : '');
        if ($raw === '') return 0;
        if (ctype_digit($raw)) return (int) $raw;
        if (preg_match('/^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?$/', $raw, $m)) {
            return (int) (isset($m[1]) ? $m[1] : 0) * 3600 + (int) (isset($m[2]) ? $m[2] : 0) * 60 + (int) (isset($m[3]) ? $m[3] : 0);
        }
        return 0;
    }

    /* ------------------------------------------------------------- Quizzes */

    /** @return array|null {quiz_id, product_id, title, questions: [{id, question, options[], correct}]} */
    public function getQuiz($quizId)
    {
        $row = $this->_read()->fetchRow(
            'SELECT quiz_id, product_id, title, questions FROM ' . $this->_table('mmd_lesson_quiz') . ' WHERE quiz_id = ?',
            array((int) $quizId)
        );
        if (!$row) return null;
        $questions = json_decode((string) $row['questions'], true);
        return array(
            'quiz_id'    => (int) $row['quiz_id'],
            'product_id' => (int) $row['product_id'],
            'title'      => (string) $row['title'],
            'questions'  => is_array($questions) ? $questions : array(),
        );
    }

    /** Question counts for a list of quiz ids: {quiz_id: count}. */
    public function questionCounts(array $quizIds)
    {
        $out = array();
        foreach ($quizIds as $id) {
            $quiz = $this->getQuiz($id);
            if ($quiz) $out[(int) $id] = count($quiz['questions']);
        }
        return $out;
    }

    /**
     * Validate questions from the editor or the AI generator.
     * @throws Mage_Core_Exception with a message for the developer
     */
    public function cleanQuestions($raw)
    {
        if (!is_array($raw) || !$raw) {
            Mage::throwException('Add at least one question.');
        }
        if (count($raw) > self::MAX_QUESTIONS) {
            Mage::throwException('A quiz has at most ' . self::MAX_QUESTIONS . ' questions.');
        }
        $out = array();
        foreach (array_values($raw) as $i => $q) {
            $n    = $i + 1;
            $text = is_array($q) && isset($q['question']) ? trim((string) $q['question']) : '';
            if ($text === '') {
                Mage::throwException('Question ' . $n . ' has no text.');
            }
            $options = array();
            $correct = -1;
            $want    = is_array($q) && isset($q['correct']) ? (int) $q['correct'] : 0;
            foreach (is_array($q) && isset($q['options']) && is_array($q['options']) ? array_values($q['options']) : array() as $oi => $opt) {
                $opt = trim((string) $opt);
                if ($opt === '') continue;
                if ($oi === $want) $correct = count($options);
                $options[] = mb_substr($opt, 0, 500);
            }
            if (count($options) < self::MIN_OPTIONS || count($options) > self::MAX_OPTIONS) {
                Mage::throwException('Question ' . $n . ' needs ' . self::MIN_OPTIONS . ' to ' . self::MAX_OPTIONS . ' options.');
            }
            if ($correct < 0) {
                Mage::throwException('Question ' . $n . ': select the correct answer.');
            }
            $id = is_array($q) && isset($q['id']) && preg_match('/^[A-Za-z0-9_]{1,40}$/', (string) $q['id']) ? (string) $q['id'] : 'q' . $n . '_' . substr(md5(uniqid('', true)), 0, 6);
            $out[] = array('id' => $id, 'question' => mb_substr($text, 0, 1000), 'options' => $options, 'correct' => $correct);
        }
        return $out;
    }

    /** Create or update a quiz. Returns the quiz id. */
    public function saveQuiz($productId, $quizId, $title, $rawQuestions)
    {
        $questions = $this->cleanQuestions($rawQuestions);
        $title     = mb_substr(trim((string) $title), 0, 255);
        if ($title === '') $title = 'Quiz';
        $now  = gmdate('Y-m-d H:i:s');
        $data = array('title' => $title, 'questions' => json_encode($questions, JSON_UNESCAPED_UNICODE), 'updated_at' => $now);
        $w    = $this->_write();
        if ((int) $quizId > 0 && $this->getQuiz($quizId)) {
            $w->update($this->_table('mmd_lesson_quiz'), $data, array('quiz_id = ?' => (int) $quizId));
            return (int) $quizId;
        }
        $w->insert($this->_table('mmd_lesson_quiz'), $data + array('product_id' => (int) $productId, 'created_at' => $now));
        return (int) $w->lastInsertId();
    }

    /** The quiz as a learner gets it: no correct answers. */
    public function learnerQuiz(array $quiz)
    {
        $questions = array();
        foreach ($quiz['questions'] as $q) {
            $questions[] = array('id' => (string) $q['id'], 'question' => (string) $q['question'], 'options' => array_values($q['options']));
        }
        return array('quiz_id' => $quiz['quiz_id'], 'title' => $quiz['title'] !== '' ? $quiz['title'] : 'Quiz', 'questions' => $questions);
    }

    /** Score answers ({question id: option index}) on the server. */
    public function grade(array $quiz, array $answers)
    {
        $score = 0;
        $rows  = array();
        $kept  = array();
        foreach ($quiz['questions'] as $q) {
            $id     = (string) $q['id'];
            $chosen = isset($answers[$id]) && is_numeric($answers[$id]) ? (int) $answers[$id] : null;
            $ok     = $chosen !== null && $chosen === (int) $q['correct'];
            if ($ok) $score++;
            if ($chosen !== null) $kept[$id] = $chosen;
            $rows[] = array('id' => $id, 'correct' => $ok, 'correct_index' => (int) $q['correct'], 'selected_index' => $chosen);
        }
        return array('score' => $score, 'total' => count($quiz['questions']), 'breakdown' => $rows, 'answers' => $kept);
    }

    public function recordAttempt($quizId, $runId, $email, $name, array $graded, $source)
    {
        $this->_write()->insert($this->_table('mmd_lesson_quiz_attempt'), array(
            'quiz_id'       => (int) $quizId,
            'run_id'        => max(0, (int) $runId),
            'learner_email' => strtolower(trim((string) $email)),
            'learner_name'  => mb_substr(trim((string) $name), 0, 255),
            'score'         => (int) $graded['score'],
            'total'         => (int) $graded['total'],
            'answers'       => json_encode($graded['answers']),
            'source'        => $source === 'app' ? 'app' : 'web',
            'completed_at'  => gmdate('Y-m-d H:i:s'),
        ));
    }

    /** A learner's latest attempt on a quiz, or null. */
    public function lastAttempt($quizId, $email)
    {
        $row = $this->_read()->fetchRow(
            'SELECT score, total, completed_at FROM ' . $this->_table('mmd_lesson_quiz_attempt') .
            ' WHERE quiz_id = ? AND learner_email = ? ORDER BY attempt_id DESC LIMIT 1',
            array((int) $quizId, strtolower(trim((string) $email)))
        );
        return $row ? array('score' => (int) $row['score'], 'total' => (int) $row['total'], 'completed_at' => str_replace(' ', 'T', $row['completed_at']) . 'Z') : null;
    }

    /**
     * Each learner's latest attempt on a quiz, for one class (run id > 0) or
     * for every attempt (run id 0). Sorted by name.
     */
    public function results($quizId, $runId)
    {
        $t    = $this->_table('mmd_lesson_quiz_attempt');
        $bind = array((int) $quizId);
        $run  = '';
        if ((int) $runId > 0) {
            $run    = ' AND run_id = ?';
            $bind[] = (int) $runId;
        }
        $rows = $this->_read()->fetchAll(
            "SELECT a.learner_email, a.learner_name, a.score, a.total, a.completed_at, a.source
               FROM {$t} a
               JOIN (SELECT MAX(attempt_id) AS attempt_id FROM {$t} WHERE quiz_id = ?{$run} GROUP BY learner_email) l
                 ON l.attempt_id = a.attempt_id
              ORDER BY a.learner_name, a.learner_email",
            $bind
        );
        $out = array();
        foreach ($rows as $r) {
            $out[] = array(
                'email'        => (string) $r['learner_email'],
                'name'         => (string) $r['learner_name'],
                'score'        => (int) $r['score'],
                'total'        => (int) $r['total'],
                'completed_at' => str_replace(' ', 'T', $r['completed_at']) . 'Z',
                'source'       => (string) $r['source'],
            );
        }
        return $out;
    }

    /** Learners who completed the quiz and their average score (%), from results(). */
    public function tally(array $results)
    {
        $sum = 0;
        $n   = 0;
        foreach ($results as $r) {
            if ($r['total'] > 0) {
                $sum += 100 * $r['score'] / $r['total'];
                $n++;
            }
        }
        return array('learners' => count($results), 'average' => $n ? (int) round($sum / $n) : null);
    }

    /* ------------------------------------------------------ Quiz link + QR */

    /** Signature of the quiz link; stops quiz id / class id guessing. */
    public function sig($quizId, $runId)
    {
        $key = (string) Mage::getConfig()->getNode('global/crypt/key');
        return substr(hash_hmac('sha256', 'lesson-quiz:' . (int) $quizId . ':' . (int) $runId, $key), 0, 24);
    }

    /** The link the quiz QR code carries. */
    public function quizUrl($quizId, $runId)
    {
        $base = Mage::app()->getDefaultStoreView()->getBaseUrl(Mage_Core_Model_Store::URL_TYPE_LINK, true);
        return $base . 'lessonquiz/index/index/q/' . (int) $quizId . '/run/' . (int) $runId . '/k/' . $this->sig($quizId, $runId) . '/';
    }

    /**
     * Quizzes of a class for the learner app: every quiz in the course's
     * Lesson that has questions, with the learner's latest score.
     */
    public function quizzesForRun($productId, $runId, $email)
    {
        $out = array();
        foreach ($this->quizIds($this->productLesson($productId)) as $id) {
            $quiz = $this->getQuiz($id);
            if (!$quiz || !$quiz['questions']) continue;
            $out[] = array(
                'quiz_id'   => $id,
                'title'     => $quiz['title'] !== '' ? $quiz['title'] : 'Quiz',
                'questions' => count($quiz['questions']),
                'url'       => $this->quizUrl($id, $runId),
                'previous'  => $this->lastAttempt($id, $email),
            );
        }
        return $out;
    }

    /* ------------------------------------------------------- AI generation */

    /**
     * Draft multiple-choice questions with the site's AI provider.
     * @return array [{question, options[], correct}]
     * @throws Mage_Core_Exception
     */
    public function generate($topic, $count, $instruction)
    {
        $count  = max(1, min(self::MAX_QUESTIONS, (int) $count));
        $prompt = "Write {$count} multiple-choice quiz questions for adult learners in a training class.\n"
            . 'Topic: ' . trim((string) $topic) . "\n"
            . (trim((string) $instruction) !== '' ? 'Extra instructions: ' . trim((string) $instruction) . "\n" : '')
            . "Each question has exactly 4 options and exactly one correct option. Keep each option under 20 words.\n"
            . "Reply with ONLY a JSON array, no markdown and no commentary, in this shape:\n"
            . '[{"question":"...","options":["...","...","...","..."],"correct":0}]' . "\n"
            . '"correct" is the zero-based index of the correct option. Vary which index is correct.';
        $text = (string) Mage::getModel('mmd_rolemanager/aiSeo')->invokeClaude($prompt);
        $from = strpos($text, '[');
        $to   = strrpos($text, ']');
        $list = ($from !== false && $to !== false && $to > $from) ? json_decode(substr($text, $from, $to - $from + 1), true) : null;
        if (!is_array($list) || !$list) {
            Mage::throwException('The AI did not return any questions. Please try again.');
        }
        $out = array();
        foreach (array_slice($list, 0, $count) as $q) {
            if (!is_array($q) || empty($q['question']) || empty($q['options']) || !is_array($q['options'])) continue;
            $options = array_slice(array_values(array_map('strval', $q['options'])), 0, self::MAX_OPTIONS);
            $correct = isset($q['correct']) ? (int) $q['correct'] : 0;
            $out[]   = array(
                'question' => trim((string) $q['question']),
                'options'  => $options,
                'correct'  => $correct >= 0 && $correct < count($options) ? $correct : 0,
            );
        }
        if (!$out) {
            Mage::throwException('The AI did not return any usable questions. Please try again.');
        }
        return $out;
    }

    protected function _read()
    {
        return Mage::getSingleton('core/resource')->getConnection('core_read');
    }

    protected function _write()
    {
        return Mage::getSingleton('core/resource')->getConnection('core_write');
    }

    protected function _table($name)
    {
        return Mage::getSingleton('core/resource')->getTableName($name);
    }
}
