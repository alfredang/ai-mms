<?php
/**
 * The signed-in learner's LMS: classes, one class (sessions, materials,
 * attendance, survey, certificate), self-marked attendance, the in-house
 * survey, certificates and billing. Every class read is limited to runs the
 * learner is enrolled in. The App Review account gets sample data only.
 */
class MMD_MobileApi_LearnerController extends MMD_MobileApi_Controller_Base
{
    public function classesAction()
    {
        if (!$this->_requireLearner()) return;
        return $this->_guard(function () {
            $classes = $this->_isDemo() ? $this->_demo()->classes() : $this->_learner()->classes($this->_email());
            return $this->_ok(array('today' => $this->_helper()->today()) + $classes);
        });
    }

    /** GET ?run_id= */
    public function classAction()
    {
        if (!$this->_requireLearner()) return;
        return $this->_guard(function () {
            $runId  = (int) $this->_input('run_id');
            $detail = $this->_isDemo() ? $this->_demo()->classDetail($runId) : $this->_learner()->classDetail($this->_email(), $runId);
            if (!$detail) {
                return $this->_error(404, 'This class is not on your account.', 'not_found');
            }
            return $this->_ok(array('class' => $detail));
        });
    }

    /** POST {run_id} — mark the learner present for the current session. */
    public function attendanceAction()
    {
        if (!$this->_requirePost() || !$this->_requireLearner()) return;
        return $this->_guard(function () {
            $runId = (int) $this->_input('run_id');
            $res = $this->_isDemo()
                ? $this->_demo()->markAttendance($runId)
                : $this->_learner()->markAttendance($this->_email(), $runId);
            if (!$res['success']) {
                return $this->_error(409, $res['message'], 'attendance_rejected');
            }
            return $this->_ok(array('message' => $res['message']));
        });
    }

    /** GET ?run_id= → questions; POST {run_id, answers:{field_id: value}} → submit. */
    public function surveyAction()
    {
        if (!$this->_requireLearner()) return;
        return $this->_guard(function () {
            $runId = (int) $this->_input('run_id');
            if ($this->getRequest()->isPost()) {
                $answers = $this->_input('answers', array());
                if (!is_array($answers)) $answers = array();
                $res = $this->_isDemo()
                    ? $this->_demo()->submitSurvey($runId)
                    : $this->_learner()->submitSurvey($this->_email(), $runId, $answers);
                if (!$res['success']) {
                    return $this->_error(409, $res['message'], 'survey_rejected');
                }
                return $this->_ok(array('message' => $res['message']));
            }
            $survey = $this->_isDemo() ? $this->_demo()->survey($runId) : $this->_learner()->survey($this->_email(), $runId);
            if (!$survey) {
                return $this->_error(404, 'This class is not on your account.', 'not_found');
            }
            return $this->_ok(array('survey' => $survey));
        });
    }

    /**
     * A lesson quiz (MMD_LessonQuiz). GET ?quiz_id=&run_id=[&k=] → questions
     * (no answers) + the learner's latest score; POST {quiz_id, run_id, k,
     * answers:{question id: option index}} → scored on the server and recorded.
     * Allowed with the signature of the trainer's quiz link (k), or when the
     * learner is enrolled in the class and the quiz is in its course's Lesson.
     */
    public function quizAction()
    {
        if (!$this->_requireLearner()) return;
        return $this->_guard(function () {
            $lq     = Mage::helper('mmd_lessonquiz');
            $quizId = (int) $this->_input('quiz_id');
            $runId  = max(0, (int) $this->_input('run_id'));
            $signed = hash_equals($lq->sig($quizId, $runId), (string) $this->_input('k', ''));
            $quiz   = $quizId > 0 ? $lq->getQuiz($quizId) : null;
            if (!$quiz || !$quiz['questions']
                || !($signed || (!$this->_isDemo() && $this->_learner()->hasQuiz($this->_email(), $runId, $quizId)))) {
                return $this->_error(404, 'This quiz is not available.', 'not_found');
            }
            if (!$this->getRequest()->isPost()) {
                return $this->_ok(array(
                    'quiz'     => $lq->learnerQuiz($quiz),
                    'previous' => $this->_isDemo() ? null : $lq->lastAttempt($quizId, $this->_email()),
                ));
            }
            $answers = $this->_input('answers', array());
            $graded  = $lq->grade($quiz, is_array($answers) ? $answers : array());
            if (!$this->_isDemo()) {
                $profile = $this->_helper()->learnerProfile($this->_email());
                $lq->recordAttempt($quizId, $runId, $this->_email(), $profile['full_name'], $graded,
                    $this->_input('platform', '') === 'web' ? 'web' : 'app');
            }
            return $this->_ok(array('score' => $graded['score'], 'total' => $graded['total'], 'breakdown' => $graded['breakdown']));
        });
    }

    public function certificatesAction()
    {
        if (!$this->_requireLearner()) return;
        return $this->_guard(function () {
            $certs = $this->_isDemo() ? $this->_demo()->certificates() : $this->_learner()->certificates($this->_email());
            return $this->_ok(array('certificates' => $certs));
        });
    }

    public function billingAction()
    {
        if (!$this->_requireLearner()) return;
        return $this->_guard(function () {
            $orders = $this->_isDemo() ? $this->_demo()->billing() : $this->_learner()->billing($this->_email());
            return $this->_ok(array('orders' => $orders));
        });
    }

    /** @return MMD_MobileApi_Helper_Learner */
    protected function _learner()
    {
        return Mage::helper('mmd_mobileapi/learner');
    }

    /** @return MMD_MobileApi_Helper_Demo */
    protected function _demo()
    {
        return Mage::helper('mmd_mobileapi/demo');
    }
}
