<?php
/**
 * Token-secured HTTP reindex endpoint — lets ops trigger a full reindex (and
 * optional cache flush) on any environment without shell access. Reuses the
 * same Cron::run() the scheduled job uses, so results are logged to
 * mmd_reindex_log and the Reindex Scheduler page.
 *
 *   GET /reindex/api/run?token=<token>            full reindex
 *   GET /reindex/api/run?token=<token>&flush=1    flush cache first (fixes a
 *                                                  stale merged CSS/JS bundle)
 *
 * Token is mmd_reindex/api/token (default in config.xml; override in
 * core_config_data for production).
 */
class MMD_Reindex_ApiController extends Mage_Core_Controller_Front_Action
{
    public function runAction()
    {
        $res = $this->getResponse();
        $res->setHeader('Content-Type', 'application/json', true);
        $res->setHeader('Cache-Control', 'no-store', true);

        $token    = (string) $this->getRequest()->getParam('token');
        $expected = (string) Mage::getStoreConfig('mmd_reindex/api/token');
        if ($expected === '' || !hash_equals($expected, $token)) {
            $res->setHttpResponseCode(403)->setBody(json_encode(array('ok' => false, 'error' => 'forbidden')));
            return;
        }

        $flush = (bool) $this->getRequest()->getParam('flush');
        try {
            if ($flush) {
                Mage::app()->cleanCache();
                Mage::app()->getCacheInstance()->flush();
            }
            $results = Mage::getModel('mmd_reindex/cron')->run('api');
            $failed  = array_filter($results, function ($v) { return strpos((string) $v, 'fail') === 0; });
            $res->setBody(json_encode(array(
                'ok'        => empty($failed),
                'flushed'   => $flush,
                'reindexed' => count($results),
                'failed'    => count($failed),
                'results'   => $results,
            ), JSON_PRETTY_PRINT));
        } catch (Exception $e) {
            Mage::logException($e);
            $res->setHttpResponseCode(500)->setBody(json_encode(array('ok' => false, 'error' => $e->getMessage())));
        }
    }

    /**
     * Cache-only refresh (faster than a full reindex).
     *   GET /reindex/api/flush?token=<token>
     */
    public function flushAction()
    {
        $res = $this->getResponse();
        $res->setHeader('Content-Type', 'application/json', true);
        $res->setHeader('Cache-Control', 'no-store', true);

        $token    = (string) $this->getRequest()->getParam('token');
        $expected = (string) Mage::getStoreConfig('mmd_reindex/api/token');
        if ($expected === '' || !hash_equals($expected, $token)) {
            $res->setHttpResponseCode(403)->setBody(json_encode(array('ok' => false, 'error' => 'forbidden')));
            return;
        }
        try {
            Mage::app()->cleanCache();
            Mage::app()->getCacheInstance()->flush();
            $res->setBody(json_encode(array('ok' => true, 'flushed' => true)));
        } catch (Exception $e) {
            Mage::logException($e);
            $res->setHttpResponseCode(500)->setBody(json_encode(array('ok' => false, 'error' => $e->getMessage())));
        }
    }
}
