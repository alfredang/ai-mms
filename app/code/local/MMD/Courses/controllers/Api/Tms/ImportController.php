<?php
/** Dedicated Phase 1 importer; credential/configuration is independent of other APIs. */
class MMD_Courses_Api_Tms_ImportController extends Mage_Core_Controller_Front_Action
{
    public function indexAction()
    {
        if (!$this->getRequest()->isPost()) return $this->_json(405, array('success' => false, 'error' => 'POST required.'));
        $key = trim((string) Mage::getStoreConfig('mmd/tms_handover/api_key'));
        if (!Mage::getStoreConfigFlag('mmd/tms_handover/enabled') || $key === '') {
            return $this->_json(503, array('success' => false, 'error' => 'TMS handover is disabled or unconfigured.'));
        }
        if (!hash_equals($key, (string) $this->getRequest()->getHeader('X-API-Key'))) return $this->_json(401, array('success' => false, 'error' => 'Invalid integration credential.'));
        $body = $this->getRequest()->getRawBody();
        if (strlen($body) > 1048576) return $this->_json(413, array('success' => false, 'error' => 'Snapshot exceeds 1 MB.'));
        try {
            $data = json_decode($body, true, 64, JSON_THROW_ON_ERROR);
            if (!is_array($data)) throw new InvalidArgumentException('Snapshot must be an object.');
            $service = Mage::getModel('courses/tmsImport');
            $result = ($data['dry_run']??false)===true ? $service->preview($data) : $service->apply($data);
            return $this->_json(200, $result);
        } catch (JsonException $e) {
            return $this->_json(400, array('success'=>false,'error'=>'Invalid JSON snapshot.'));
        } catch (InvalidArgumentException $e) {
            return $this->_json(422, array('success' => false, 'error' => $e->getMessage()));
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_json(500, array('success' => false, 'error' => 'Import failed; retry using the source run key and revision.'));
        }
    }
    protected function _json($code, array $body)
    {
        $this->getResponse()->setHttpResponseCode($code)->setHeader('Content-Type','application/json',true)->setBody(json_encode($body));
        return $this;
    }
}
