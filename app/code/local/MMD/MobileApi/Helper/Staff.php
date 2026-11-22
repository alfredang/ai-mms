<?php
/**
 * Numbers behind the staff dashboards in the native apps. Each role gets a few
 * cards (one number each) and a few short lists. Every figure is computed on
 * its own and a failure leaves that one out, so a missing table on one site
 * never breaks the screen. Read-only. Class, registration and course figures
 * count non-WSQ (C-prefix) courses only, like the rest of these apps.
 */
class MMD_MobileApi_Helper_Staff extends Mage_Core_Helper_Abstract
{
    protected $_titles = array(
        'admin' => 'Admin', 'marketing' => 'Marketing', 'developer' => 'Developer', 'franchise_admin' => 'Franchise Admin',
    );

    public function dashboard($role)
    {
        $method = '_' . str_replace('_', '', $role);
        $out = array('cards' => array(), 'lists' => array());
        if (method_exists($this, $method)) {
            $this->$method($out);
        }
        return array(
            'role'       => $role,
            'title'      => isset($this->_titles[$role]) ? $this->_titles[$role] : $role,
            'cards'      => $out['cards'],
            'lists'      => $out['lists'],
            'updated_at' => Mage::helper('mmd_mobileapi')->now(),
        );
    }

    // ---- Admin: today's classes, staffing gaps, new registrations -------------

    protected function _admin(array &$out)
    {
        $today = Mage::helper('mmd_mobileapi')->today();
        $week  = date('Y-m-d', strtotime($today . ' +7 days'));
        $runs  = $this->_t('course_runs');
        $nonWsq = "TRIM(course_sku) REGEXP '" . MMD_MobileApi_Helper_Learner::RUN_SKU_SQL . "'";
        $this->_card($out, 'Classes today', 'calendar', function () use ($runs, $today, $nonWsq) {
            return (int) $this->_r()->fetchOne(
                "SELECT COUNT(*) FROM {$runs} WHERE {$nonWsq} AND course_start_date <= ? AND COALESCE(course_end_date, course_start_date) >= ?",
                array($today, $today));
        });
        $this->_card($out, 'Starting in 7 days', 'calendar.badge.clock', function () use ($runs, $today, $week, $nonWsq) {
            return (int) $this->_r()->fetchOne(
                "SELECT COUNT(*) FROM {$runs} WHERE {$nonWsq} AND course_start_date > ? AND course_start_date <= ?", array($today, $week));
        });
        $this->_card($out, 'No trainer (next 14 days)', 'person.fill.questionmark', function () use ($runs, $today, $nonWsq) {
            return (int) $this->_r()->fetchOne(
                "SELECT COUNT(*) FROM {$runs} WHERE {$nonWsq} AND course_start_date >= ? AND course_start_date <= ?
                   AND COALESCE(trainer_user_id, 0) = 0 AND COALESCE(trainer_option_id, 0) = 0",
                array($today, date('Y-m-d', strtotime($today . ' +14 days'))));
        }, 'warning');
        $this->_card($out, 'Registrations (7 days)', 'cart.fill', function () {
            return (int) $this->_r()->fetchOne(
                'SELECT COUNT(*) FROM ' . $this->_t('sales/order') . ' o WHERE o.created_at >= ? AND ' . $this->_nonWsqOrder(),
                array(gmdate('Y-m-d H:i:s', time() - 7 * 86400)));
        });
        $this->_card($out, 'Trainer sign-ups to approve', 'person.badge.plus', function () {
            return (int) $this->_r()->fetchOne(
                'SELECT COUNT(*) FROM ' . $this->_t('admin/user') . ' u JOIN ' . $this->_t('mmd_user_role_map')
                . " m ON m.user_id = u.user_id AND m.role_code = 'trainer' WHERE u.is_active = 0");
        }, 'warning');

        $this->_list($out, 'Classes today and next', function () use ($runs, $today) {
            $nonWsq = "TRIM(cr.course_sku) REGEXP '" . MMD_MobileApi_Helper_Learner::RUN_SKU_SQL . "'";
            $rows = $this->_r()->fetchAll(
                "SELECT cr.run_id, cr.product_id, cr.course_sku, cr.course_start_date, COALESCE(cr.course_end_date, cr.course_start_date) AS end_date,
                        COALESCE(cr.trainer_user_id, 0) AS tu, COALESCE(cr.trainer_option_id, 0) AS topt,
                        (SELECT COUNT(*) FROM " . $this->_t('course_run_enrolments') . " e WHERE e.run_id = cr.run_id) AS n
                   FROM {$runs} cr
                  WHERE {$nonWsq} AND COALESCE(cr.course_end_date, cr.course_start_date) >= ? AND cr.course_start_date <= ?
                  ORDER BY cr.course_start_date, cr.run_id LIMIT 12",
                array($today, date('Y-m-d', strtotime($today . ' +30 days'))));
            $out = array();
            foreach ($rows as $r) {
                $out[] = array(
                    'title'    => $this->_productName((int) $r['product_id'], (string) $r['course_sku']),
                    'subtitle' => $this->_range($r['course_start_date'], $r['end_date']) . ' · ' . trim((string) $r['course_sku'])
                                  . (((int) $r['tu'] === 0 && (int) $r['topt'] === 0) ? ' · no trainer' : ''),
                    'value'    => (int) $r['n'] > 0 ? (int) $r['n'] . ' enrolled' : '',
                );
            }
            return $out;
        });
        $this->_list($out, 'Latest registrations', function () {
            $rows = $this->_r()->fetchAll(
                'SELECT o.increment_id, o.customer_firstname, o.customer_lastname, o.grand_total, o.order_currency_code, o.status, o.created_at
                   FROM ' . $this->_t('sales/order') . ' o WHERE ' . $this->_nonWsqOrder() . ' ORDER BY o.entity_id DESC LIMIT 10');
            $out = array();
            foreach ($rows as $r) {
                $out[] = array(
                    'title'    => trim($r['customer_firstname'] . ' ' . $r['customer_lastname']) ?: 'Guest',
                    'subtitle' => '#' . $r['increment_id'] . ' · ' . ucfirst(str_replace('_', ' ', (string) $r['status'])) . ' · ' . substr((string) $r['created_at'], 0, 10),
                    'value'    => trim((string) $r['order_currency_code'] . ' ' . number_format((float) $r['grand_total'], 2)),
                );
            }
            return $out;
        });
    }

    // ---- Marketing: leads, approvals waiting, content going out ----------------

    protected function _marketing(array &$out)
    {
        $since = gmdate('Y-m-d H:i:s', time() - 30 * 86400);
        $lead  = $this->_t('mmd_lead');
        $blog  = $this->_t('mmd_blog_post');
        $this->_card($out, 'Leads (30 days)', 'person.2.fill', function () use ($lead, $since) {
            return (int) $this->_r()->fetchOne("SELECT COUNT(*) FROM {$lead} WHERE created_at >= ?", array($since));
        });
        $this->_card($out, 'Lead replies to review', 'envelope.badge', function () use ($lead) {
            return (int) $this->_r()->fetchOne("SELECT COUNT(*) FROM {$lead} WHERE draft_status = 'pending_review'");
        }, 'warning');
        $this->_card($out, 'Blog posts to review', 'doc.text.magnifyingglass', function () use ($blog) {
            return (int) $this->_r()->fetchOne("SELECT COUNT(*) FROM {$blog} WHERE status = 2");
        }, 'warning');
        $this->_card($out, 'Blogs published (30 days)', 'newspaper.fill', function () use ($blog, $since) {
            return (int) $this->_r()->fetchOne("SELECT COUNT(*) FROM {$blog} WHERE status = 1 AND published_at >= ?", array($since));
        });
        $this->_card($out, 'Newsletters sent (30 days)', 'paperplane.fill', function () use ($since) {
            return (int) $this->_r()->fetchOne(
                'SELECT COUNT(*) FROM ' . $this->_t('newsletters') . " WHERE status = 'sent' AND sent_at >= ?", array($since));
        });
        $this->_list($out, 'Blog posts waiting for review', function () use ($blog) {
            $out = array();
            foreach ($this->_r()->fetchAll(
                "SELECT title, scheduled_publish_at, created_at FROM {$blog} WHERE status = 2 ORDER BY COALESCE(scheduled_publish_at, created_at) LIMIT 8"
            ) as $r) {
                $out[] = array(
                    'title'    => trim((string) $r['title']),
                    'subtitle' => $r['scheduled_publish_at'] ? 'Slot ' . substr((string) $r['scheduled_publish_at'], 0, 10) : 'Written ' . substr((string) $r['created_at'], 0, 10),
                    'value'    => '',
                );
            }
            return $out;
        });
        $this->_list($out, 'Latest leads', function () use ($lead) {
            $out = array();
            foreach ($this->_r()->fetchAll(
                "SELECT name, company, courses_interested, course_code, store_code, created_at FROM {$lead} ORDER BY lead_id DESC LIMIT 10"
            ) as $r) {
                $what = trim((string) $r['courses_interested']) !== '' ? trim((string) $r['courses_interested']) : trim((string) $r['course_code']);
                $out[] = array(
                    'title'    => trim((string) $r['name']) . (trim((string) $r['company']) !== '' ? ' · ' . trim((string) $r['company']) : ''),
                    'subtitle' => mb_substr($what !== '' ? $what : 'General enquiry', 0, 90),
                    'value'    => substr((string) $r['created_at'], 5, 5),
                );
            }
            return $out;
        });
    }

    // ---- Developer: catalogue health and audit issues ---------------------------

    protected function _developer(array &$out)
    {
        $issues = $this->_t('mmd_audit_issues');
        $this->_card($out, 'Courses enabled', 'books.vertical.fill', function () {
            return (int) Mage::getModel('catalog/product')->getCollection()
                ->addAttributeToFilter('sku', array('regexp' => MMD_MobileApi_Helper_Learner::RUN_SKU_SQL))
                ->addAttributeToFilter('status', Mage_Catalog_Model_Product_Status::STATUS_ENABLED)->getSize();
        });
        $this->_card($out, 'Courses disabled', 'eye.slash.fill', function () {
            return (int) Mage::getModel('catalog/product')->getCollection()
                ->addAttributeToFilter('sku', array('regexp' => MMD_MobileApi_Helper_Learner::RUN_SKU_SQL))
                ->addAttributeToFilter('status', Mage_Catalog_Model_Product_Status::STATUS_DISABLED)->getSize();
        });
        $this->_card($out, 'High audit issues open', 'exclamationmark.triangle.fill', function () use ($issues) {
            return (int) $this->_r()->fetchOne("SELECT COUNT(*) FROM {$issues} WHERE status = 'open' AND severity = 'high'");
        }, 'warning');
        $this->_card($out, 'All audit issues open', 'checklist', function () use ($issues) {
            return (int) $this->_r()->fetchOne("SELECT COUNT(*) FROM {$issues} WHERE status = 'open'");
        });
        $this->_card($out, 'Audit issues fixed (7 days)', 'checkmark.seal.fill', function () use ($issues) {
            return (int) $this->_r()->fetchOne("SELECT COUNT(*) FROM {$issues} WHERE fixed_at >= ?", array(gmdate('Y-m-d H:i:s', time() - 7 * 86400)));
        });
        $this->_list($out, 'Open audit issues by category', function () use ($issues) {
            $out = array();
            foreach ($this->_r()->fetchAll(
                "SELECT category, SUM(severity = 'high') AS high, COUNT(*) AS n FROM {$issues} WHERE status = 'open'
                  GROUP BY category ORDER BY high DESC, n DESC LIMIT 10"
            ) as $r) {
                $out[] = array(
                    'title'    => ucfirst(str_replace('_', ' ', (string) $r['category'])),
                    'subtitle' => (int) $r['high'] > 0 ? (int) $r['high'] . ' high' : 'No high-severity issues',
                    'value'    => number_format((int) $r['n']),
                );
            }
            return $out;
        });
        $this->_list($out, 'Newest high-severity issues', function () use ($issues) {
            $out = array();
            foreach ($this->_r()->fetchAll(
                "SELECT title, category, found_at FROM {$issues} WHERE status = 'open' AND severity = 'high' ORDER BY issue_id DESC LIMIT 8"
            ) as $r) {
                $out[] = array(
                    'title'    => mb_substr(trim((string) $r['title']), 0, 110),
                    'subtitle' => ucfirst(str_replace('_', ' ', (string) $r['category'])) . ' · ' . substr((string) $r['found_at'], 0, 10),
                    'value'    => '',
                );
            }
            return $out;
        });
    }

    // ---- Franchise Admin: partner sites, from the tables the nightly pull fills --

    protected function _franchiseadmin(array &$out)
    {
        $cls = $this->_t('mmd_franchise_classes');
        $fee = $this->_t('mmd_franchise_class_fee');
        $partners = "source_country <> 'SG'";
        $this->_card($out, 'Partner classes upcoming', 'globe.asia.australia.fill', function () use ($cls, $partners) {
            return (int) $this->_r()->fetchOne("SELECT COUNT(*) FROM {$cls} WHERE {$partners} AND status IN ('upcoming', 'confirmed')");
        });
        $this->_card($out, 'Partner learners enrolled', 'person.3.fill', function () use ($cls, $partners) {
            return (int) $this->_r()->fetchOne("SELECT COALESCE(SUM(enrolled), 0) FROM {$cls} WHERE {$partners}");
        });
        $this->_card($out, 'Certificates issued', 'rosette', function () use ($cls, $partners) {
            return (int) $this->_r()->fetchOne("SELECT COALESCE(SUM(certs_issued), 0) FROM {$cls} WHERE {$partners}");
        });
        $this->_card($out, 'Class fees pending', 'banknote.fill', function () use ($fee) {
            return (int) $this->_r()->fetchOne("SELECT COUNT(*) FROM {$fee} WHERE status = 'pending'");
        }, 'warning');
        $this->_list($out, 'By partner site', function () use ($cls, $partners) {
            $names = array('MY' => 'Malaysia', 'GH' => 'Ghana', 'SG' => 'Singapore');
            $out = array();
            foreach ($this->_r()->fetchAll(
                "SELECT source_country, COUNT(*) AS n, COALESCE(SUM(enrolled), 0) AS learners, SUM(status = 'completed') AS done
                   FROM {$cls} WHERE {$partners} GROUP BY source_country ORDER BY source_country"
            ) as $r) {
                $cc = (string) $r['source_country'];
                $out[] = array(
                    'title'    => isset($names[$cc]) ? $names[$cc] : $cc,
                    'subtitle' => (int) $r['n'] . ' classes · ' . (int) $r['done'] . ' completed',
                    'value'    => (int) $r['learners'] . ' learners',
                );
            }
            return $out;
        });
        $this->_list($out, 'Fees waiting for payment', function () use ($fee) {
            $out = array();
            foreach ($this->_r()->fetchAll(
                "SELECT source_country, course_title, class_code, start_date, billable_learners, amount, currency
                   FROM {$fee} WHERE status = 'pending' ORDER BY start_date LIMIT 12"
            ) as $r) {
                $out[] = array(
                    'title'    => trim((string) $r['course_title']) ?: (string) $r['class_code'],
                    'subtitle' => $r['source_country'] . ' · ' . substr((string) $r['start_date'], 0, 10) . ' · ' . (int) $r['billable_learners'] . ' learners',
                    'value'    => trim((string) $r['currency'] . ' ' . number_format((float) $r['amount'], 2)),
                );
            }
            return $out;
        });
        $this->_list($out, 'Data', function () {
            $last = (string) Mage::getStoreConfig('mmd/franchise_stats/last_pull');
            return array(array('title' => 'Last refreshed from partner sites', 'subtitle' => $last !== '' ? $last . ' UTC' : 'Not yet', 'value' => ''));
        });
    }

    // ---- plumbing -----------------------------------------------------------------

    /** SQL condition: order `o` holds at least one non-WSQ (C-prefix) course. */
    protected function _nonWsqOrder()
    {
        return 'EXISTS (SELECT 1 FROM ' . $this->_t('sales/order_item') . " oi WHERE oi.order_id = o.entity_id AND TRIM(oi.sku) REGEXP '"
            . MMD_MobileApi_Helper_Learner::RUN_SKU_SQL . "')";
    }

    protected function _card(array &$out, $title, $icon, $fn, $tone = 'normal')
    {
        try {
            $n = $fn();
        } catch (Exception $e) {
            return;   // table or column absent on this site: leave the card out
        }
        $out['cards'][] = array(
            'title' => $title, 'value' => number_format((int) $n), 'icon' => $icon,
            // An "attention" figure is only highlighted when there is something to do.
            'tone'  => ($tone === 'warning' && (int) $n > 0) ? 'warning' : 'normal',
        );
    }

    protected function _list(array &$out, $title, $fn)
    {
        try {
            $rows = $fn();
        } catch (Exception $e) {
            return;
        }
        if ($rows) {
            $out['lists'][] = array('title' => $title, 'rows' => $rows);
        }
    }

    protected function _productName($productId, $fallback)
    {
        try {
            $name = Mage::getResourceModel('catalog/product')->getAttributeRawValue($productId, 'name', 0);
            return is_string($name) && trim($name) !== '' ? trim($name) : trim($fallback);
        } catch (Exception $e) {
            return trim($fallback);
        }
    }

    protected function _range($start, $end)
    {
        $s = substr((string) $start, 0, 10); $e = substr((string) $end, 0, 10);
        return ($e === '' || $e === $s) ? date('j M', strtotime($s)) : date('j M', strtotime($s)) . ' – ' . date('j M', strtotime($e));
    }

    protected function _r()
    {
        return Mage::getSingleton('core/resource')->getConnection('core_read');
    }

    protected function _t($name)
    {
        return Mage::getSingleton('core/resource')->getTableName($name);
    }
}
