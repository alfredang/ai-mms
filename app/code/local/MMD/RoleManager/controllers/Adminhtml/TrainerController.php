<?php
class MMD_RoleManager_Adminhtml_TrainerController extends Mage_Adminhtml_Controller_Action
{
    /**
     * AJAX action — create a new trainer.
     * Expects POST: email, full_name, status (1|0), telephone, trainer_type,
     * gender, linkedin_url, default_password (informational only).
     * Returns JSON: { success: bool, message: string, trainer_id?: int }
     */
    public function addAction()
    {
        $result = array('success' => false);

        try {
            if (!$this->getRequest()->isPost()) {
                $result['message'] = 'POST required';
                $this->_sendJson($result);
                return;
            }

            $email    = trim((string) $this->getRequest()->getPost('email'));
            $name     = trim((string) $this->getRequest()->getPost('full_name'));
            $statusIn = (string) $this->getRequest()->getPost('status');
            $tel      = trim((string) $this->getRequest()->getPost('telephone'));
            $type     = trim((string) $this->getRequest()->getPost('trainer_type'));
            $gender   = trim((string) $this->getRequest()->getPost('gender'));
            $linkedin = trim((string) $this->getRequest()->getPost('linkedin_url'));

            // Required-field validation (matches the form's `required` markers)
            if ($email === '' || $name === '' || $tel === '' || $type === '' || $statusIn === '' || $gender === '') {
                $result['message'] = 'Email, Full Name, Telephone, Trainer Type, Status, and Gender are required';
                $this->_sendJson($result);
                return;
            }
            if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                $result['message'] = 'Invalid email address';
                $this->_sendJson($result);
                return;
            }

            $resource = Mage::getSingleton('core/resource');
            $write    = $resource->getConnection('core_write');
            $table    = $resource->getTableName('courses_trainers');

            // Reject duplicate email
            $exists = $write->fetchOne("SELECT trainers_id FROM {$table} WHERE email = ?", array($email));
            if ($exists) {
                $result['message'] = 'A trainer with that email already exists';
                $this->_sendJson($result);
                return;
            }

            // Detect optional columns so we save into them only if they exist
            // (keeps the action portable across schema variants — local lacks
            // telephone/trainer_type/gender/linkedin_url, prod may have them).
            $cols = $write->fetchCol("SHOW COLUMNS FROM {$table}");
            $colSet = array_flip($cols);

            $row = array(
                'title'         => $name,
                'email'         => $email,
                'profile_image' => '',
                'status'        => ($statusIn === 'Active' || $statusIn === '1') ? 1 : 0,
                'created_time'  => date('Y-m-d H:i:s'),
                'update_time'   => date('Y-m-d H:i:s'),
            );
            if (isset($colSet['relation_id'])) $row['relation_id'] = 0;
            if (isset($colSet['telephone']))   $row['telephone']   = $tel;
            if (isset($colSet['tel']))         $row['tel']         = $tel;
            if (isset($colSet['phone']))       $row['phone']       = $tel;
            if (isset($colSet['trainer_type']))$row['trainer_type']= $type;
            if (isset($colSet['type']))        $row['type']        = $type;
            if (isset($colSet['gender']))      $row['gender']      = $gender;
            if (isset($colSet['linkedin_url']))$row['linkedin_url']= $linkedin;
            if (isset($colSet['linkedin']))    $row['linkedin']    = $linkedin;

            $write->insert($table, $row);
            $newId = (int) $write->lastInsertId($table);

            $result['success']    = true;
            $result['trainer_id'] = $newId;
            $result['message']    = 'Trainer added successfully';
        } catch (Exception $e) {
            $result['message'] = 'Error: ' . $e->getMessage();
        } catch (Error $e) {
            $result['message'] = 'Error: ' . $e->getMessage();
        }

        $this->_sendJson($result);
    }

    /**
     * Stream a CSV template with the bulk-upload columns.
     */
    public function templateAction()
    {
        $headers = array(
            'Common Name', 'Full Name', 'Country', 'Domain', 'Contact',
            'Email', 'CN Plus Email', 'ACLP', 'LinkedIn', 'CV', 'NRIC'
        );
        $sample = array(
            'JaneD', 'Jane Doe', 'Singapore', 'IT', '+65 8123 4567',
            'jane.doe@example.com', '', 'TRUE', 'https://linkedin.com/in/janedoe', '', 'S1234567A'
        );

        $this->getResponse()
            ->setHeader('Content-Type', 'text/csv; charset=utf-8', true)
            ->setHeader('Content-Disposition', 'attachment; filename="trainers-template.csv"', true);

        $body  = implode(',', $headers) . "\r\n";
        $body .= '"' . implode('","', $sample) . '"' . "\r\n";
        $this->getResponse()->setBody($body);
    }

    /**
     * Bulk-upload trainers from a CSV file.
     * POST: file (multipart upload), form_key.
     * Returns JSON: { success, created, updated, errors:[{row, message}] }
     */
    public function bulkUploadAction()
    {
        $result = array('success' => false, 'created' => 0, 'updated' => 0, 'errors' => array());

        try {
            if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
                $result['errors'][] = array('row' => 0, 'message' => 'No file uploaded');
                $this->_sendJson($result);
                return;
            }

            $tmp  = $_FILES['file']['tmp_name'];
            $name = strtolower($_FILES['file']['name']);
            $ext  = pathinfo($name, PATHINFO_EXTENSION);

            if (!in_array($ext, array('csv'))) {
                $result['errors'][] = array('row' => 0, 'message' => 'Only CSV files are supported in this build (xlsx/xls coming later)');
                $this->_sendJson($result);
                return;
            }

            $fh = fopen($tmp, 'r');
            if (!$fh) {
                $result['errors'][] = array('row' => 0, 'message' => 'Could not read uploaded file');
                $this->_sendJson($result);
                return;
            }

            $header = fgetcsv($fh);
            if (!$header) {
                $result['errors'][] = array('row' => 0, 'message' => 'Empty file');
                fclose($fh);
                $this->_sendJson($result);
                return;
            }
            // Normalize header → lowercased keys
            $idx = array();
            foreach ($header as $i => $h) {
                $key = strtolower(trim($h));
                $idx[$key] = $i;
            }
            $get = function ($row, $key) use ($idx) {
                if (!isset($idx[$key])) return '';
                $i = $idx[$key];
                return isset($row[$i]) ? trim($row[$i]) : '';
            };

            $resource = Mage::getSingleton('core/resource');
            $write    = $resource->getConnection('core_write');
            $table    = $resource->getTableName('courses_trainers');
            $cols     = array_flip($write->fetchCol("SHOW COLUMNS FROM {$table}"));

            $rowNum = 1;
            while (($r = fgetcsv($fh)) !== false) {
                $rowNum++;
                if (count(array_filter($r, 'strlen')) === 0) continue; // skip blank rows

                $email = $get($r, 'email');
                $name  = $get($r, 'full name');

                if ($email === '' || $name === '') {
                    $result['errors'][] = array('row' => $rowNum, 'message' => 'Full Name and Email are required');
                    continue;
                }
                if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                    $result['errors'][] = array('row' => $rowNum, 'message' => 'Invalid email: ' . $email);
                    continue;
                }

                $aclpRaw = strtoupper($get($r, 'aclp'));
                $type    = ($aclpRaw === 'TRUE' || $aclpRaw === '1' || $aclpRaw === 'YES') ? 'ACLP' : 'non-ACLP';

                $row = array(
                    'title'         => $name,
                    'email'         => $email,
                    'profile_image' => '',
                    'status'        => 1,
                    'update_time'   => date('Y-m-d H:i:s'),
                );
                if (isset($cols['relation_id']))  $row['relation_id']  = 0;
                if (isset($cols['country_id']))   $row['country_id']   = $get($r, 'country');
                if (isset($cols['telephone']))    $row['telephone']    = $get($r, 'contact');
                if (isset($cols['trainer_type']))$row['trainer_type'] = $type;
                if (isset($cols['linkedin_url'])) $row['linkedin_url'] = $get($r, 'linkedin');
                if (isset($cols['gender']))       $row['gender']       = 'Prefer not to say';

                $existingId = $write->fetchOne("SELECT trainers_id FROM {$table} WHERE email = ?", array($email));
                if ($existingId) {
                    $write->update($table, $row, array('trainers_id = ?' => (int)$existingId));
                    $result['updated']++;
                } else {
                    $row['created_time'] = date('Y-m-d H:i:s');
                    $write->insert($table, $row);
                    $result['created']++;
                }
            }
            fclose($fh);
            $result['success'] = true;
        } catch (Exception $e) {
            $result['errors'][] = array('row' => 0, 'message' => 'Error: ' . $e->getMessage());
        } catch (Error $e) {
            $result['errors'][] = array('row' => 0, 'message' => 'Error: ' . $e->getMessage());
        }

        $this->_sendJson($result);
    }

    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isLoggedIn();
    }

    protected function _sendJson(array $data)
    {
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(Mage::helper('core')->jsonEncode($data));
    }
}
