<?php
/**
 * Lesson quiz admin endpoints (JSON), used by the course editor's Lesson
 * builder and by the Lesson card on the class page.
 *
 *   GET  lessonquiz/load?quiz_id=              -> editor: title + questions with answers
 *   POST lessonquiz/save                       -> editor: product_id, quiz_id (0 = new), title, questions (JSON)
 *   POST lessonquiz/generate                   -> editor: topic, count, instruction -> AI-drafted questions
 *   GET  lessonquiz/results?quiz_id=&run_id=   -> class: who completed the quiz + scores
 *   GET  lessonquiz/qr?quiz_id=&run_id=        -> class: PNG QR code of the quiz link
 */
class MMD_LessonQuiz_Adminhtml_LessonquizController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::helper('mmd_rolemanager')->isRoleAllowed($this->_h()->classRoles());
    }

    /** @return MMD_LessonQuiz_Helper_Data */
    protected function _h()
    {
        return Mage::helper('mmd_lessonquiz');
    }

    protected function _json(array $data, $code = 200)
    {
        $this->getResponse()->setHttpResponseCode($code)
             ->setHeader('Content-Type', 'application/json', true)
             ->setBody(json_encode($data));
    }

    /** Writing quizzes is for the course editor's roles, not trainers. */
    protected function _canEdit()
    {
        if (Mage::helper('mmd_rolemanager')->isRoleAllowed($this->_h()->editRoles())) {
            return true;
        }
        $this->_json(array('success' => false, 'error' => 'Your role cannot edit quizzes.'), 403);
        return false;
    }

    public function loadAction()
    {
        if (!$this->_canEdit()) return;
        $quiz = $this->_h()->getQuiz((int) $this->getRequest()->getParam('quiz_id'));
        if (!$quiz) {
            return $this->_json(array('success' => false, 'error' => 'Quiz not found.'), 404);
        }
        $this->_json(array('success' => true, 'quiz' => $quiz));
    }

    public function saveAction()
    {
        if (!$this->_canEdit()) return;
        $req = $this->getRequest();
        if (!$req->isPost() || !$this->_validateFormKey()) {
            return $this->_json(array('success' => false, 'error' => 'Your session has expired. Reload the page and try again.'), 400);
        }
        try {
            $id = $this->_h()->saveQuiz(
                (int) $req->getPost('product_id'),
                (int) $req->getPost('quiz_id'),
                (string) $req->getPost('title'),
                json_decode((string) $req->getPost('questions'), true)
            );
            $quiz = $this->_h()->getQuiz($id);
            $this->_json(array('success' => true, 'quiz_id' => $id, 'title' => $quiz['title'], 'count' => count($quiz['questions'])));
        } catch (Mage_Core_Exception $e) {
            $this->_json(array('success' => false, 'error' => $e->getMessage()), 422);
        }
    }

    public function generateAction()
    {
        if (!$this->_canEdit()) return;
        $req = $this->getRequest();
        if (!$req->isPost() || !$this->_validateFormKey()) {
            return $this->_json(array('success' => false, 'error' => 'Your session has expired. Reload the page and try again.'), 400);
        }
        $topic = trim((string) $req->getPost('topic'));
        if ($topic === '') {
            return $this->_json(array('success' => false, 'error' => 'Enter a topic to generate questions about.'), 422);
        }
        try {
            $questions = $this->_h()->generate($topic, (int) $req->getPost('count'), (string) $req->getPost('instruction'));
            $this->_json(array('success' => true, 'questions' => $questions));
        } catch (Mage_Core_Exception $e) {
            $this->_json(array('success' => false, 'error' => $e->getMessage()), 502);
        }
    }

    /** A trainer only reads the classes assigned to them. Returns the run id, or null after the error response. */
    protected function _runId()
    {
        $runId = (int) $this->getRequest()->getParam('run_id');
        if ($runId <= 0) {
            if (Mage::helper('mmd_rolemanager')->isRoleAllowed($this->_h()->editRoles())) {
                return 0;
            }
        } else {
            $pe  = Mage::helper('mmd_practiceexam');
            $run = $pe->loadRun($runId);
            if ($run && $pe->canAccessRun($run)) {
                return $runId;
            }
        }
        $this->_json(array('success' => false, 'error' => 'Class not found.'), 404);
        return null;
    }

    public function resultsAction()
    {
        $runId = $this->_runId();
        if ($runId === null) return;
        $quiz = $this->_h()->getQuiz((int) $this->getRequest()->getParam('quiz_id'));
        if (!$quiz) {
            return $this->_json(array('success' => false, 'error' => 'Quiz not found.'), 404);
        }
        $results = $this->_h()->results($quiz['quiz_id'], $runId);
        $this->_json(array(
            'success' => true,
            'title'   => $quiz['title'],
            'count'   => count($quiz['questions']),
            'tally'   => $this->_h()->tally($results),
            'results' => $results,
        ));
    }

    public function qrAction()
    {
        $runId = $this->_runId();
        if ($runId === null) return;
        $url = $this->_h()->quizUrl((int) $this->getRequest()->getParam('quiz_id'), $runId);
        try {
            $opt = new \chillerlan\QRCode\QROptions(array(
                'outputType'       => \chillerlan\QRCode\QRCode::OUTPUT_IMAGE_PNG,
                'eccLevel'         => \chillerlan\QRCode\QRCode::ECC_M,
                'scale'            => 12,
                'quietzoneSize'    => 4,
                'imageBase64'      => false,
                'imageTransparent' => false,
            ));
            $png = (new \chillerlan\QRCode\QRCode($opt))->render($url);
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->getResponse()->setRedirect('https://quickchart.io/qr?size=600&margin=4&text=' . rawurlencode($url), 302);
        }
        $this->getResponse()
             ->setHeader('Content-Type', 'image/png', true)
             ->setHeader('Cache-Control', 'private, max-age=3600', true)
             ->setBody($png);
    }
}
