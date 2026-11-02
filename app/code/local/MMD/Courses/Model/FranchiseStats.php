<?php
/**
 * Franchise statistics collected from THIS instance's own DB. Used by
 *  - /courses/api_franchise_stats (served by every site; the SG Franchise
 *    Admin pulls MY/GH over HTTPS), and
 *  - the SG-side collector directly (SG reads itself without HTTP).
 *
 * Franchise scope = non-WSQ (C-prefix) courses only: WSQ (TGS-) and partner
 * legacy (M-) SKUs are excluded from both datasets.
 *
 * Two datasets, both read-only and free of numeric entity IDs:
 *  classes — one row per course_runs row carrying a class_id (C######):
 *            course, dates, trainer, status, enrolled / attended learners and
 *            certificates issued.
 *  orders  — one row per course registration line (sales_flat_order_item of
 *            a non-cancelled order): order no, date, status, course, class
 *            date, learners (qty), amount, currency. No learner identity.
 */
class MMD_Courses_Model_FranchiseStats
{
    /** @return array rows */
    public function classes($since, $page = 1, $pageSize = 500)
    {
        $read = $this->_read();
        $nameAttrId = $this->_nameAttrId();
        $certTable  = $this->_tableExists('mmd_course_run_certificate') ? 'mmd_course_run_certificate' : null;
        $attTable   = $this->_tableExists('mmd_course_run_attendance') ? 'mmd_course_run_attendance' : null;

        $where = "r.class_id IS NOT NULL AND r.course_sku REGEXP '^C[0-9]' AND COALESCE(r.course_end_date, r.course_start_date) IS NOT NULL
                  AND COALESCE(r.course_end_date, r.course_start_date) <= DATE_ADD(CURDATE(), INTERVAL 2 YEAR)";
        $binds = array();
        if ($since) { $where .= " AND COALESCE(r.course_end_date, r.course_start_date) >= ?"; $binds[] = $since; }

        $attended = $attTable
            ? "(SELECT COUNT(DISTINCT a.learner_email) FROM $attTable a WHERE a.run_id = r.run_id AND a.is_present = 1)"
            : "0";
        $certs = $certTable
            ? "(SELECT COUNT(*) FROM $certTable c WHERE c.run_id = r.run_id AND c.status IN ('issued','sent'))"
            : "0";
        $offset = max(0, ((int) $page - 1) * (int) $pageSize);
        $pageSize = (int) $pageSize;

        $rows = $read->fetchAll(
            "SELECT r.class_id AS class_code,
                    r.course_sku AS course_code,
                    COALESCE(pv.value, '') AS course_title,
                    r.course_start_date AS start_date,
                    COALESCE(r.course_end_date, r.course_start_date) AS end_date,
                    TRIM(CONCAT(COALESCE(u.firstname,''), ' ', COALESCE(u.lastname,''))) AS trainer_name,
                    CASE
                        WHEN (r.trainer_user_id IS NULL AND r.trainer_option_id IS NULL) THEN 'upcoming'
                        WHEN COALESCE(r.course_end_date, r.course_start_date) < CURDATE() THEN 'completed'
                        ELSE 'confirmed'
                    END AS status,
                    (SELECT COUNT(*) FROM course_run_enrolments e WHERE e.run_id = r.run_id) AS enrolled,
                    $attended AS attended,
                    $certs AS certs_issued
               FROM course_runs r
          LEFT JOIN admin_user u ON u.user_id = r.trainer_user_id
          LEFT JOIN catalog_product_entity_varchar pv
                 ON pv.entity_id = r.product_id AND pv.attribute_id = $nameAttrId AND pv.store_id = 0
              WHERE $where
           ORDER BY r.course_start_date DESC, r.class_id DESC
              LIMIT $pageSize OFFSET $offset",
            $binds
        );
        return $rows;
    }

    public function classesTotal($since)
    {
        $binds = array();
        $where = "r.class_id IS NOT NULL AND r.course_sku REGEXP '^C[0-9]' AND COALESCE(r.course_end_date, r.course_start_date) IS NOT NULL
                  AND COALESCE(r.course_end_date, r.course_start_date) <= DATE_ADD(CURDATE(), INTERVAL 2 YEAR)";
        if ($since) { $where .= " AND COALESCE(r.course_end_date, r.course_start_date) >= ?"; $binds[] = $since; }
        return (int) $this->_read()->fetchOne("SELECT COUNT(*) FROM course_runs r WHERE $where", $binds);
    }

    /** @return array rows */
    public function orders($since, $page = 1, $pageSize = 500)
    {
        $read   = $this->_read();
        $offset = max(0, ((int) $page - 1) * (int) $pageSize);
        $pageSize = (int) $pageSize;
        $binds  = array();
        $where  = "o.state NOT IN ('canceled') AND i.parent_item_id IS NULL AND i.sku REGEXP '^C[0-9]'";
        if ($since) { $where .= " AND o.created_at >= ?"; $binds[] = $since . ' 00:00:00'; }

        $rows = $read->fetchAll(
            "SELECT o.increment_id AS order_no, i.item_id, o.created_at AS ordered_at, o.status,
                    i.sku AS course_code, i.name AS course_title,
                    i.qty_ordered AS learners, i.row_total AS amount, o.order_currency_code AS currency,
                    i.product_options
               FROM sales_flat_order_item i
               JOIN sales_flat_order o ON o.entity_id = i.order_id
              WHERE $where
           ORDER BY o.created_at DESC, i.item_id DESC
              LIMIT $pageSize OFFSET $offset",
            $binds
        );
        foreach ($rows as &$r) {
            $r['class_date'] = $this->_classDate($r['product_options']);
            unset($r['product_options']);
            $r['learners'] = max(1, (int) round((float) $r['learners']));
            $r['amount']   = round((float) $r['amount'], 2);
        }
        return $rows;
    }

    public function ordersTotal($since)
    {
        $binds = array();
        $where = "o.state NOT IN ('canceled') AND i.parent_item_id IS NULL AND i.sku REGEXP '^C[0-9]'";
        if ($since) { $where .= " AND o.created_at >= ?"; $binds[] = $since . ' 00:00:00'; }
        return (int) $this->_read()->fetchOne(
            "SELECT COUNT(*) FROM sales_flat_order_item i JOIN sales_flat_order o ON o.entity_id = i.order_id WHERE $where",
            $binds
        );
    }

    /** First parseable date in the "Course Date" custom option, else null. */
    protected function _classDate($productOptions)
    {
        if (!$productOptions || !preg_match('/s:5:"label";s:11:"Course Date";s:5:"value";s:\d+:"([^"]*)"/', $productOptions, $m)) {
            return null;
        }
        $txt = preg_replace('/\(.*?\)/', '', $m[1]);
        if (preg_match('/(\d{1,2}\s+[A-Za-z]{3,9}\s+\d{4})/', $txt, $d) || preg_match('/(\d{4}-\d{2}-\d{2})/', $txt, $d)
            || preg_match('/(\d{1,2}\/\d{1,2}\/\d{4})/', $txt, $d)) {
            $ts = strtotime($d[1]);
            return $ts ? date('Y-m-d', $ts) : null;
        }
        return null;
    }

    protected function _read()
    {
        return Mage::getSingleton('core/resource')->getConnection('core_read');
    }

    protected function _nameAttrId()
    {
        return (int) $this->_read()->fetchOne(
            "SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name' LIMIT 1"
        );
    }

    protected function _tableExists($name)
    {
        return (bool) $this->_read()->fetchOne("SHOW TABLES LIKE " . $this->_read()->quote($name));
    }
}
