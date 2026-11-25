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

    // ---- Admin home and calendar: every class, as the ai-lms-tms admin view ------

    /**
     * Admin class lists. Without a range: KPIs (running today, starting in the
     * next 30 days, learners in today's classes) plus `current` (running today)
     * and `upcoming` (next 30 days). With from/to (Y-m-d): `classes` overlapping
     * that range, for the calendar. Non-WSQ (C-prefix) classes only, like the rest of these apps.
     */
    public function adminClasses($from = '', $to = '')
    {
        $today = Mage::helper('mmd_mobileapi')->today();
        $in30  = date('Y-m-d', strtotime($today . ' +30 days'));
        $valid = function ($d) { return (bool) preg_match('/^\d{4}-\d{2}-\d{2}$/', (string) $d); };
        if ($valid($from) && $valid($to)) {
            if ($to < $from || (strtotime($to) - strtotime($from)) > 62 * 86400) {
                $to = date('Y-m-d', strtotime($from . ' +62 days'));
            }
            return array('classes' => $this->_classRows($from, $to, false));
        }
        $current  = $this->_classRows($today, $today, false);
        $upcoming = $this->_classRows(date('Y-m-d', strtotime($today . ' +1 day')), $in30, true);
        $learners = 0;
        foreach ($current as $c) $learners += $c['learner_count'];
        return array(
            'today'    => $today,
            'kpis'     => array('running_today' => count($current), 'next_30_days' => count($upcoming), 'learners_today' => $learners),
            'current'  => $current,
            'upcoming' => $upcoming,
        );
    }

    /** Classes overlapping [from, to]; with $startsInRange only those starting in it. */
    protected function _classRows($from, $to, $startsInRange)
    {
        $runs  = $this->_t('course_runs');
        $where = $startsInRange
            ? 'cr.course_start_date >= ? AND cr.course_start_date <= ?'
            : 'cr.course_start_date <= ? AND COALESCE(cr.course_end_date, cr.course_start_date) >= ?';
        $bind  = $startsInRange ? array($from, $to) : array($to, $from);
        $nonWsq = "TRIM(cr.course_sku) REGEXP '" . MMD_MobileApi_Helper_Learner::RUN_SKU_SQL . "'";
        $rows  = $this->_r()->fetchAll(
            "SELECT cr.run_id, cr.class_id, cr.product_id, TRIM(cr.course_sku) AS sku, cr.course_start_date,
                    COALESCE(cr.course_end_date, cr.course_start_date) AS end_date, cr.course_start_time, cr.course_end_time,
                    cr.mode_of_training, cr.venue_block, cr.venue_street, cr.venue_building, cr.venue_floor, cr.venue_unit,
                    cr.postal_code, cr.trainer_user_id, cr.trainer_option_id,
                    COALESCE(NULLIF(TRIM(CONCAT(COALESCE(au.firstname,''),' ',COALESCE(au.lastname,''))),''), tov.value, '') AS trainer_name,
                    (SELECT COUNT(*) FROM " . $this->_t('course_run_enrolments') . " e WHERE e.run_id = cr.run_id) AS n
               FROM {$runs} cr
          LEFT JOIN " . $this->_t('admin/user') . " au ON au.user_id = cr.trainer_user_id
          LEFT JOIN " . $this->_t('eav_attribute_option_value') . " tov ON tov.option_id = cr.trainer_option_id AND tov.store_id = 0
              WHERE cr.course_start_date IS NOT NULL AND {$nonWsq} AND {$where}
              ORDER BY cr.course_start_date, cr.course_start_time, cr.run_id LIMIT 600",
            $bind
        );
        $modes = array(1 => 'Classroom', 2 => 'Live Online', 3 => 'Hybrid');
        $page  = Mage::helper('mmd_mobileapi/classPage');
        $out   = array();
        foreach ($rows as $r) {
            $mode = (int) $r['mode_of_training'];
            $out[] = array(
                'run_id'        => (int) $r['run_id'],
                'class_id'      => (string) $r['class_id'],
                'sku'           => (string) $r['sku'],
                'title'         => $this->_productName((int) $r['product_id'], (string) $r['sku']),
                'start_date'    => substr((string) $r['course_start_date'], 0, 10),
                'end_date'      => substr((string) $r['end_date'], 0, 10),
                'start_time'    => $r['course_start_time'] ? substr((string) $r['course_start_time'], 0, 5) : '',
                'end_time'      => $r['course_end_time'] ? substr((string) $r['course_end_time'], 0, 5) : '',
                'mode'          => isset($modes[$mode]) ? $modes[$mode] : 'Classroom',
                'venue'         => $page->venue($r, $mode),
                'trainer'       => trim((string) $r['trainer_name']),
                'learner_count' => (int) $r['n'],
            );
        }
        return $out;
    }

    // ---- Developer home: the course list, in the ai-lms-tms developer layout ---------

    /**
     * Every non-WSQ (C-prefix) course: enabled or disabled, its upcoming class
     * count and next class date.
     */
    /** Plain text from catalogue HTML: paragraphs and list items become lines. */
    protected function _plain($html)
    {
        $t = preg_replace('#<!--.*?-->#s', '', (string) $html);
        $t = preg_replace('#</(p|div|h[1-6]|li|tr)>|<br\s*/?>#i', "\n", $t);
        $t = html_entity_decode(strip_tags($t), ENT_QUOTES, 'UTF-8');
        $t = preg_replace("/[ \t\xC2\xA0]+/u", ' ', $t);
        return trim(preg_replace("/\n\s*\n+/", "\n", $t));
    }

    /**
     * One non-WSQ course, read-only, as the admin Edit Course page holds it:
     * status, price, duration, level, software, outline topics, prerequisites,
     * notes, trainer profile, SEO fields, and its upcoming classes.
     */
    public function developerCourse($id)
    {
        $id = (int) $id;
        $r  = $this->_r();
        $nonWsq = "TRIM(p.sku) REGEXP '" . MMD_MobileApi_Helper_Learner::RUN_SKU_SQL . "'";
        $ok = (int) $r->fetchOne("SELECT COUNT(*) FROM " . $this->_t('catalog/product') . " p WHERE p.entity_id = ? AND {$nonWsq}", array($id));
        if (!$ok) return null;
        $p = Mage::getModel('catalog/product')->setStoreId(0)->load($id);
        if (!$p->getId()) return null;

        $text = function ($code) use ($p) { return $this->_plain($p->getData($code)); };
        $opt = function ($code) use ($p) {
            try { $v = $p->getAttributeText($code); return is_array($v) ? implode(', ', $v) : trim((string) $v); }
            catch (Exception $e) { return ''; }
        };

        $topics = array();
        if (preg_match('/<!--\s*LSN_DATA:\s*(\[.*?\])\s*-->/s', (string) $p->getData('description'), $m)) {
            $data = json_decode($m[1], true);
            foreach ((is_array($data) ? $data : array()) as $t) {
                $subs = array();
                foreach ((isset($t['subsecs']) && is_array($t['subsecs']) ? $t['subsecs'] : array()) as $sub) {
                    $title = is_array($sub) ? (isset($sub['title']) ? $sub['title'] : '') : $sub;
                    if (trim((string) $title) !== '') $subs[] = trim((string) $title);
                }
                $topics[] = array('title' => trim((string) (isset($t['title']) ? $t['title'] : '')), 'sub_topics' => $subs);
            }
        }

        $today = Mage::helper('mmd_mobileapi')->today();
        $classes = array();
        foreach ($r->fetchAll(
            "SELECT class_id, course_start_date, course_end_date, course_start_time, course_end_time, vacancy, mode_of_training
               FROM " . $this->_t('course_runs') . " WHERE product_id = ? AND course_start_date >= ? ORDER BY course_start_date LIMIT 20",
            array($id, $today)) as $c) {
            $classes[] = array(
                'class_id'   => (string) $c['class_id'],
                'start_date' => substr((string) $c['course_start_date'], 0, 10),
                'end_date'   => substr((string) $c['course_end_date'], 0, 10),
                'start_time' => substr((string) $c['course_start_time'], 0, 5),
                'end_time'   => substr((string) $c['course_end_time'], 0, 5),
                'vacancy'    => (string) $c['vacancy'],
                'mode'       => (string) $c['mode_of_training'],
            );
        }
        $path = trim((string) $p->getData('url_path'));
        $sku  = trim((string) $p->getSku());
        list($fundFrom, $fundTo) = $this->_fundingValidity($p);
        $training = (float) $p->getData('duration');
        $assess   = $this->_assessmentHours($id);
        return array('course' => array(
            'id'                => $id,
            // App 1.8 Developer page: identity, funding, hours, courseware, practice exam.
            'course_type'       => $this->_courseType($p),
            'funding_validity_start' => $fundFrom,
            'funding_validity_end'   => $fundTo,
            'training_hours'    => $training,
            'assessment_hours'  => $assess,
            'duration_days'     => ($training + $assess) > 0 ? (int) ceil(($training + $assess) / 8) : 0,
            'courseware'        => $this->_courseware($id),
            'practice_exam_setting' => $this->_practiceExamSetting($id),
            // Fields shown by app 1.7 and earlier.
            'sku'               => $sku,
            'title'             => trim((string) $p->getName()),
            'enabled'           => (int) $p->getStatus() === 1,
            'visibility'        => (int) $p->getVisibility(),
            'price'             => (float) $p->getPrice(),
            'currency'          => Mage::helper('mmd_mobileapi')->currencyCode(),
            'duration_hours'    => (string) $p->getData('duration'),
            'sessions'          => (string) $p->getData('sessions'),
            'level'             => $opt('level'),
            'software'          => $opt('software'),
            'programming_language' => $opt('progromming_language'),
            'short_description' => $text('short_description'),
            'topics'            => $topics,
            'prerequisite'      => $text('prerequisite'),
            'additional_note'   => $text('additional_note'),
            'trainer_profile'   => $text('trainerprofile'),
            'meta_title'        => trim((string) $p->getData('meta_title')),
            'meta_description'  => trim((string) $p->getData('meta_description')),
            'meta_keywords'     => trim((string) $p->getData('meta_keyword')),
            'url'               => $path !== '' ? rtrim(Mage::app()->getDefaultStoreView()->getBaseUrl(Mage_Core_Model_Store::URL_TYPE_WEB), '/') . '/' . $path : '',
            'image_url'         => trim((string) $p->getData('course_image_url')),
            'upcoming_classes'  => $classes,
        ));
    }

    public function developerCourses()
    {
        $today  = Mage::helper('mmd_mobileapi')->today();
        $r      = $this->_r();
        $attr   = function ($code) use ($r) {
            return (int) $r->fetchOne(
                "SELECT a.attribute_id FROM " . $this->_t('eav_attribute') . " a JOIN " . $this->_t('eav_entity_type')
                . " t ON t.entity_type_id = a.entity_type_id WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = ?",
                array($code));
        };
        $name = $attr('name'); $status = $attr('status');
        $dur = $attr('duration'); $assess = $attr('assessment_duration');
        $nonWsq = "TRIM(p.sku) REGEXP '" . MMD_MobileApi_Helper_Learner::RUN_SKU_SQL . "'";
        $rows = $r->fetchAll(
            "SELECT p.entity_id, TRIM(p.sku) AS sku, nm.value AS name, st.value AS status,
                    du.value AS training_hours, aov.value AS assessment_hours,
                    (SELECT COUNT(*) FROM " . $this->_t('course_runs') . " cr WHERE cr.product_id = p.entity_id AND cr.course_start_date >= ?) AS upcoming,
                    (SELECT MIN(cr.course_start_date) FROM " . $this->_t('course_runs') . " cr WHERE cr.product_id = p.entity_id AND cr.course_start_date >= ?) AS next_class
               FROM " . $this->_t('catalog/product') . " p
          LEFT JOIN " . $this->_t('catalog_product_entity_varchar') . " nm ON nm.entity_id = p.entity_id AND nm.store_id = 0 AND nm.attribute_id = {$name}
          LEFT JOIN " . $this->_t('catalog_product_entity_int') . " st ON st.entity_id = p.entity_id AND st.store_id = 0 AND st.attribute_id = {$status}
          LEFT JOIN " . $this->_t('catalog_product_entity_varchar') . " du ON du.entity_id = p.entity_id AND du.store_id = 0 AND du.attribute_id = {$dur}
          LEFT JOIN " . $this->_t('catalog_product_entity_int') . " ad ON ad.entity_id = p.entity_id AND ad.store_id = 0 AND ad.attribute_id = {$assess}
          LEFT JOIN " . $this->_t('eav_attribute_option_value') . " aov ON aov.option_id = ad.value AND aov.store_id = 0
              WHERE {$nonWsq}
              ORDER BY nm.value",
            array($today, $today)
        );
        $out = array(); $withClasses = 0; $disabled = 0;
        foreach ($rows as $row) {
            $enabled = (int) $row['status'] === 1;
            if (!$enabled) $disabled++;
            if ((int) $row['upcoming'] > 0) $withClasses++;
            $out[] = array(
                'id'               => (int) $row['entity_id'],
                'sku'              => (string) $row['sku'],
                'title'            => trim((string) $row['name']) !== '' ? trim((string) $row['name']) : (string) $row['sku'],
                'enabled'          => $enabled,
                'course_type'      => stripos((string) $row['sku'], 'TGS-') === 0 ? 'WSQ' : 'Non-WSQ',
                'training_hours'   => (float) $row['training_hours'],
                'assessment_hours' => is_numeric($row['assessment_hours']) ? (float) $row['assessment_hours'] : 0.0,
                'upcoming_classes' => (int) $row['upcoming'],
                'next_class'       => $row['next_class'] ? substr((string) $row['next_class'], 0, 10) : '',
            );
        }
        return array(
            'today'   => $today,
            'kpis'    => array('courses' => count($out), 'with_classes' => $withClasses, 'disabled' => $disabled),
            'courses' => $out,
        );
    }

    /** Courseware links, in the web course page's order (empty links left out). */
    protected $_coursewareLabels = array(
        'trainer_slides_url'    => 'Trainer Slides',
        'learner_slides_url'    => 'Learner Slides',
        'lesson_plan_url'       => 'Lesson Plan',
        'learner_guide_url'     => 'Learner Guide',
        'facilitator_guide_url' => 'Facilitator Guide',
        'assessment_plan_url'   => 'Assessment Plan',
        'lab_url'               => 'Activities / Labs',
        'lab_simulator_url'     => 'Lab Simulator',
        'practice_exam_url'     => 'Practice Exam',
        'courseware_link'       => 'Courseware Folder',
        'brochure_link'         => 'Brochure',
    );

    protected function _courseware($productId)
    {
        try {
            $table = $this->_t('course_courseware');
            $cols  = array_values(array_intersect(array_keys($this->_coursewareLabels), array_keys($this->_r()->describeTable($table))));
            $row   = $cols ? $this->_r()->fetchRow('SELECT `' . implode('`, `', $cols) . "` FROM {$table} WHERE product_id = ?", array((int) $productId)) : null;
        } catch (Exception $e) {
            return array();
        }
        $out = array();
        foreach ($this->_coursewareLabels as $key => $label) {
            $url = $row && isset($row[$key]) ? trim((string) $row[$key]) : '';
            if ($url !== '') $out[] = array('key' => $key, 'label' => $label, 'url' => $url);
        }
        return $out;
    }

    /** WSQ / IBF / CASL for a TGS- course (from its funding badge, IBF first), else Non-WSQ: as the web course page. */
    protected function _courseType($product)
    {
        if (stripos(trim((string) $product->getSku()), 'TGS-') !== 0) return 'Non-WSQ';
        try {
            $badges = Mage::helper('mmd_courseimage')->getProductBadges($product);
            if (in_array('IBF', $badges, true)) return 'IBF';
            if (in_array('CASL', $badges, true)) return 'CASL';
        } catch (Exception $e) {}
        return 'WSQ';
    }

    /**
     * SSG funding validity [start, end] (yyyy-mm-dd or null): WSQ (TGS-) courses only, from
     * the TMS support period, else the course's Funding Validity dates. On a C- course those
     * dates are a legacy class-date mirror, so a non-WSQ course has none (the web shows NA).
     */
    protected function _fundingValidity($product)
    {
        if (stripos(trim((string) $product->getSku()), 'TGS-') !== 0) return array(null, null);
        $a = Mage::helper('courses')->getCourseAvailability((int) $product->getId());
        $from = !empty($a['support_from']) ? $a['support_from'] : $product->getData('news_from_date');
        $to   = !empty($a['support_to']) ? $a['support_to'] : $product->getData('news_to_date');
        $day  = function ($v) { $v = substr((string) $v, 0, 10); return ($v === '' || $v === '0000-00-00') ? null : $v; };
        return array($day($from), $day($to));
    }

    /** Assessment hours: the assessment_duration option's label (NA or none counts as 0). */
    protected function _assessmentHours($productId)
    {
        try {
            $r = $this->_r();
            $attr = (int) $r->fetchOne("SELECT attribute_id FROM " . $this->_t('eav_attribute') . " WHERE entity_type_id = 4 AND attribute_code = 'assessment_duration'");
            if (!$attr) return 0.0;
            $label = (string) $r->fetchOne(
                "SELECT ov.value FROM " . $this->_t('catalog_product_entity_int') . " v
                   JOIN " . $this->_t('eav_attribute_option_value') . " ov ON ov.option_id = v.value AND ov.store_id = 0
                  WHERE v.entity_id = ? AND v.attribute_id = ? ORDER BY v.store_id LIMIT 1",
                array((int) $productId, $attr));
            return is_numeric($label) ? (float) $label : 0.0;
        } catch (Exception $e) {
            return 0.0;
        }
    }

    /**
     * The course's Practice Exam switch, as Edit Course -> Course Settings holds it: whether
     * the integration is set up, the linked exam (slug '' = off) and the exams to choose from.
     */
    protected function _practiceExamSetting($productId)
    {
        $pe = Mage::helper('mmd_practiceexam');
        if (!$pe->isConfigured()) {
            return array('configured' => false, 'enabled' => false, 'exam_slug' => '', 'exam_code' => '', 'exams' => array(), 'warning' => null);
        }
        $exam = $pe->getCourseExam((int) $productId);
        $exams = array(); $warning = null;
        try {
            foreach ($pe->listExams() as $x) {
                $exams[] = array('slug' => $x['slug'], 'code' => $x['code'], 'title' => $x['title'], 'vendor' => $x['vendor']);
            }
        } catch (Exception $e) {
            $warning = 'Could not reach Tertiary Exams. Try again later.';
        }
        return array(
            'configured' => true,
            'enabled'    => (bool) $exam,
            'exam_slug'  => $exam ? (string) $exam['exam_slug'] : '',
            'exam_code'  => $exam ? (string) $exam['exam_code'] : '',
            'exams'      => $exams,
            'warning'    => $warning,
        );
    }

    /** Turn a non-WSQ course's practice exam on (link it to $slug) or off (''). Returns the new setting. */
    public function setPracticeExam($productId, $slug, $by)
    {
        $productId = (int) $productId;
        $nonWsq = "TRIM(p.sku) REGEXP '" . MMD_MobileApi_Helper_Learner::RUN_SKU_SQL . "'";
        $ok = (int) $this->_r()->fetchOne("SELECT COUNT(*) FROM " . $this->_t('catalog/product') . " p WHERE p.entity_id = ? AND {$nonWsq}", array($productId));
        if (!$ok) return null;
        $pe = Mage::helper('mmd_practiceexam');
        if (!$pe->isConfigured()) throw new Mage_Core_Exception('Practice exams are not set up on this site.');
        try {
            $pe->setCourseExam($productId, (string) $slug);
        } catch (Exception $e) {
            // Turning one on reads the live exam catalogue: an unknown exam or an unreachable site.
            throw new Mage_Core_Exception(strpos($e->getMessage(), 'No practice exam matches') === 0
                ? 'That practice exam is no longer offered. Pick another.'
                : 'Could not reach Tertiary Exams. Try again later.');
        }
        Mage::log(sprintf('app: course %d practice exam -> %s (by %s)', $productId, $slug === '' ? 'off' : $slug, $by), null, 'mmd_practiceexam.log', true);
        return $this->_practiceExamSetting($productId);
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
