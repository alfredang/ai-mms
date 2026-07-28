<?php
/**
 * Public read-only API: course schedules (WSQ bulk + single-course detail).
 *
 * Two modes:
 *   GET /courses/api_schedule            → original behaviour, ALL enabled
 *                                          TGS- (WSQ) courses with their
 *                                          "Course Date" option values.
 *                                          Response shape unchanged for
 *                                          backwards-compat with existing
 *                                          WSQ-feed consumer.
 *   GET /courses/api_schedule?sku=<sku>  → richer per-course response with
 *                                          class details from course_runs
 *                                          (trainer name, vacancy, status,
 *                                          time, mode). Works for ANY SKU
 *                                          (TGS-, C, M…), not just WSQ.
 *
 * Auth: X-API-Key header compared against
 *       courses/general/wsq_schedule_api_key. Mismatch → 401.
 *
 * Scope: SG store (store_id=1).
 */
class MMD_Courses_Api_ScheduleController extends Mage_Core_Controller_Front_Action
{
    const SG_STORE_ID = 1;
    const CONFIG_PATH_API_KEY = 'courses/general/wsq_schedule_api_key';
    const COURSE_DATE_OPTION_TITLE = 'Course Date';

    public function indexAction()
    {
        $expected = trim((string) Mage::getStoreConfig(self::CONFIG_PATH_API_KEY));
        if ($expected === '') {
            return $this->_json(503, array('error' => 'api_disabled'));
        }

        $provided = (string) $this->getRequest()->getHeader('X-API-Key');
        if (!hash_equals($expected, $provided)) {
            return $this->_json(401, array('error' => 'unauthorized'));
        }

        $sku = trim((string) $this->getRequest()->getParam('sku', ''));
        if ($sku !== '') {
            return $this->_perSkuResponse($sku);
        }

        try {
            $courses = $this->_collectCourses();
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_json(500, array('error' => 'internal_error'));
        }

        return $this->_json(200, array(
            'generated_at' => gmdate('c'),
            'store'        => 'singapore',
            'count'        => count($courses),
            'courses'      => $courses,
        ));
    }

    /**
     * Per-course schedule response — used by the WhatsApp bot to answer
     * "when is the next session of course X?" with trainer, vacancy, and
     * status. Wrapped in the standard {source_url, last_updated, confidence,
     * data} envelope so the bot can reason about freshness.
     */
    private function _perSkuResponse($sku)
    {
        try {
            $product = Mage::getModel('catalog/product')->setStoreId(self::SG_STORE_ID)
                ->loadByAttribute('sku', $sku);
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_json(500, $this->_errEnvelope('internal_error', $e->getMessage()));
        }
        if (!$product || !$product->getId()) {
            return $this->_json(404, $this->_errEnvelope('not_found',
                'No course with sku=' . $sku . ' in the SG catalogue.'));
        }
        $product = Mage::getModel('catalog/product')->setStoreId(self::SG_STORE_ID)->load($product->getId());

        // Never surface a disabled course. Flat catalog already excludes disabled
        // products from loadByAttribute above; guard explicitly so the per-SKU
        // endpoint stays enabled-only even if flat is off or mid-reindex.
        if ((int) $product->getStatus() === Mage_Catalog_Model_Product_Status::STATUS_DISABLED) {
            return $this->_json(404, $this->_errEnvelope('not_found',
                'Course ' . $sku . ' is not currently available.'));
        }

        $classes    = $this->_collectClasses($product);
        $sourceUrl  = $this->_productUrl($product);
        $confidence = count($classes) === 0 ? 'low' : 'high';

        return $this->_json(200, array(
            'source_url'   => $sourceUrl,
            'last_updated' => gmdate('c'),
            'confidence'   => $confidence,
            'data'         => array(
                'course_code'    => (string) $product->getSku(),
                'course_title'   => (string) $product->getName(),
                'course_page_url'=> $sourceUrl,
                'classes_count'  => count($classes),
                'classes'        => $classes,
            ),
        ));
    }

    /**
     * Read upcoming classes from course_runs for the given product, joined
     * to the trainer name via the product option value title (trainers are
     * stored as custom-option values). Sorted ascending by start date.
     * Vacancy uses the single-char enum from course_runs (A/L/F/-);
     * we surface a friendly label too.
     */
    private function _collectClasses($product)
    {
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $runs     = $resource->getTableName('course_runs');
        $optTitle = $resource->getTableName('catalog/product_option_type_title');

        $select = $read->select()
            ->from(array('cr' => $runs), array(
                'run_id', 'course_sku', 'trainer_option_id',
                'course_start_date', 'course_end_date',
                'vacancy', 'mode_of_training', 'venue_building',
            ))
            ->joinLeft(
                array('ott' => $optTitle),
                'ott.option_type_id = cr.trainer_option_id AND ott.store_id = 0',
                array('trainer_name' => 'title')
            )
            ->where('cr.product_id = ?', (int) $product->getId())
            ->where('cr.course_start_date IS NULL OR cr.course_start_date >= CURDATE()')
            ->order('cr.course_start_date ASC')
            ->limit(50);

        $rows = $read->fetchAll($select);

        $out = array();
        foreach ($rows as $r) {
            $trainer = trim((string) ($r['trainer_name'] ?? ''));
            $hasTrainer = $trainer !== '';
            $out[] = array(
                'class_id'        => $this->_formatClassId((int) $r['run_id']),
                'start_date'      => $r['course_start_date'] ?: null,
                'end_date'        => $r['course_end_date']   ?: null,
                'time'            => '09:30-17:30', // stock default — actual time per-run not in this table
                'trainer'         => $hasTrainer ? $trainer : null,
                'status'          => $hasTrainer ? 'Confirmed' : 'Pending',
                'mode'            => $this->_modeLabel($r['mode_of_training']),
                'venue'           => trim((string) ($r['venue_building'] ?? '')) ?: null,
                'vacancy_code'    => (string) ($r['vacancy'] ?? '-'),
                'seats_available' => $this->_vacancyLabel($r['vacancy']),
            );
        }
        return $out;
    }

    private function _modeLabel($v)
    {
        // course_runs.mode_of_training: 1 = classroom, 2 = online, 3 = hybrid (best guess from schema)
        switch ((int) $v) {
            case 2: return 'Live Online';
            case 3: return 'Hybrid (Classroom + Online)';
            default: return 'Classroom';
        }
    }

    private function _vacancyLabel($code)
    {
        // course_runs.vacancy enum guess: A=available, L=limited, F=full, -=unknown
        switch (strtoupper((string) $code)) {
            case 'A': return 'Available';
            case 'L': return 'Limited seats';
            case 'F': return 'Full';
            default:  return 'Contact for availability';
        }
    }

    private function _formatClassId($runId)
    {
        return 'SG' . str_pad((string) $runId, 6, '0', STR_PAD_LEFT);
    }

    private function _productUrl($product)
    {
        try {
            $url = (string) $product->getProductUrl(false);
            if ($url !== '') return $url;
        } catch (Exception $e) {
            // fall through
        }
        $urlKey = $product->getUrlKey();
        return $urlKey ? 'https://www.tertiarycourses.com.sg/' . $urlKey . '.html'
                       : 'https://www.tertiarycourses.com.sg/';
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

    private function _collectCourses()
    {
        $parser = Mage::getModel('mmd_rolemanager/courseRunEnrolmentService');
        if (!$parser) {
            Mage::throwException('CourseRunEnrolmentService model not available');
        }

        $collection = Mage::getModel('catalog/product')->getCollection()
            ->setStoreId(self::SG_STORE_ID)
            ->addStoreFilter(self::SG_STORE_ID)
            ->addAttributeToSelect(array('name', 'sku'))
            ->addAttributeToFilter('sku', array('like' => 'TGS-%'))
            ->addAttributeToFilter('status', Mage_Catalog_Model_Product_Status::STATUS_ENABLED);

        $out = array();
        foreach ($collection as $product) {
            $product->setStoreId(self::SG_STORE_ID);
            $schedules = $this->_extractSchedules($product, $parser);
            $out[] = array(
                'course_code'  => $product->getSku(),
                'course_title' => $product->getName(),
                'schedules'    => $schedules,
            );
        }
        return $out;
    }

    private function _extractSchedules($product, $parser)
    {
        $options = Mage::getModel('catalog/product_option')->getCollection()
            ->addProductToFilter($product->getId())
            ->addTitleToResult(self::SG_STORE_ID)
            ->addValuesToResult(self::SG_STORE_ID);

        $schedules = array();
        foreach ($options as $option) {
            if (strcasecmp(trim((string) $option->getTitle()), self::COURSE_DATE_OPTION_TITLE) !== 0) {
                continue;
            }
            foreach ($option->getValues() as $value) {
                $label = trim((string) $value->getTitle());
                if ($label === '') {
                    continue;
                }
                $entry = array(
                    'raw'               => $label,
                    'course_start_date' => null,
                    'course_end_date'   => null,
                );
                $parsed = $parser->_parseDate($label);
                if (!is_array($parsed) || empty($parsed[0]) || empty($parsed[1])) {
                    $parsed = $this->_parseCrossMonthRange($label);
                }
                if (is_array($parsed) && !empty($parsed[0]) && !empty($parsed[1])) {
                    $entry['course_start_date'] = $parsed[0];
                    $entry['course_end_date']   = $parsed[1];
                }
                $schedules[] = $entry;
            }
        }
        return $schedules;
    }

    /**
     * Fallback parser for "DD Mon - DD Mon YYYY" cross-month hyphen ranges
     * (e.g. "29 Jun - 3 Jul 2026"). Upstream _parseDate handles only same-month
     * hyphen ranges, so this catches the most common remaining WSQ label shape.
     * Strips trailing "(...)" annotations before matching.
     */
    private function _parseCrossMonthRange($raw)
    {
        $s = trim(preg_replace('/\s*\([^)]*\)?\s*$/', '', (string) $raw));
        if (!preg_match('/^(\d{1,2})\s+([A-Za-z]+)\s*-\s*(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$/', $s, $m)) {
            return null;
        }
        $months = array(
            'jan'=>1,'feb'=>2,'mar'=>3,'apr'=>4,'may'=>5,'jun'=>6,'june'=>6,
            'jul'=>7,'july'=>7,'aug'=>8,'sep'=>9,'sept'=>9,'oct'=>10,'nov'=>11,'dec'=>12,
        );
        $ms = $months[strtolower(substr($m[2], 0, 4))] ?? $months[strtolower(substr($m[2], 0, 3))] ?? null;
        $me = $months[strtolower(substr($m[4], 0, 4))] ?? $months[strtolower(substr($m[4], 0, 3))] ?? null;
        if (!$ms || !$me) return null;
        $year = (int) $m[5];
        $startYear = ($me < $ms) ? $year - 1 : $year;  // crosses Jan boundary
        $start = sprintf('%04d-%02d-%02d', $startYear, $ms, (int) $m[1]);
        $end   = sprintf('%04d-%02d-%02d', $year,      $me, (int) $m[3]);
        return array($start, $end);
    }

    private function _json($status, array $body)
    {
        $this->getResponse()
            ->setHttpResponseCode($status)
            ->setHeader('Content-Type', 'application/json; charset=utf-8', true)
            ->setHeader('Cache-Control', 'no-store', true)
            ->setBody(json_encode($body, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
        return $this;
    }
}
