<?php
/**
 * Public (no-auth) feedback form controller.
 *
 * GET  /feedback/respond/index?run_id=<int>  — render the form
 * POST /feedback/respond/submit              — accept a submission
 */
class MMD_FeedbackForm_RespondController extends Mage_Core_Controller_Front_Action
{
    public function indexAction()
    {
        $runId = (int)$this->getRequest()->getParam('run_id');
        if (!$runId) {
            $this->_renderError('Invalid Link', 'No class run specified.');
            return;
        }

        try {
            /** @var MMD_FeedbackForm_Helper_Data $h */
            $h        = Mage::helper('mmd_feedbackform');
            $template = $h->getOrCreateTemplate();
            $run      = $this->_loadRun($runId);

            if (!$run) {
                $this->_renderError('Class Not Found', 'This feedback link is no longer valid.');
                return;
            }

            $context = array(
                'course_title' => (string)$run['course_title'],
                'course_code'  => (string)$run['course_sku'],
                'class_id'     => (string)$run['class_id'],
                'trainer_name' => (string)$run['trainer_name'],
                'start_date'   => $run['course_start_date'] ? date('Y-m-d', strtotime($run['course_start_date'])) : '',
                'end_date'     => $run['course_end_date']   ? date('Y-m-d', strtotime($run['course_end_date']))   : '',
            );

            $this->_renderForm($template, $context, $runId);
        } catch (Exception $e) {
            Mage::logException($e);
            $this->_renderError('Error', 'An error occurred. Please try again.');
        }
    }

    public function submitAction()
    {
        if (!$this->getRequest()->isPost()) {
            $this->_redirect('feedback/respond/index');
            return;
        }

        $runId = (int)$this->getRequest()->getPost('run_id');
        if (!$runId) {
            $this->_renderError('Invalid Submission', 'Missing class run.');
            return;
        }

        try {
            /** @var MMD_FeedbackForm_Helper_Data $h */
            $h        = Mage::helper('mmd_feedbackform');
            $template = $h->getOrCreateTemplate();
            $run      = $this->_loadRun($runId);

            if (!$run || !(int)$run['product_id']) {
                $this->_renderError('Class Not Found', 'This feedback link is no longer valid.');
                return;
            }

            $answers = array();
            foreach ($this->getRequest()->getPost() as $k => $v) {
                if (strpos($k, 'field_') === 0) {
                    $fieldId = substr($k, 6);
                    $answers[$fieldId] = $v;
                }
            }

            // Derive learner name, comment, and the three 1–5 star ratings by
            // scanning the template field definitions — this maps field IDs
            // (f4, f7 …) back to their semantic purpose. The rating fields map
            // positionally onto the Magento rating codes:
            //   1st rating1to5 → rating_id 1 (course meets expectation)
            //   2nd rating1to5 → rating_id 2 (trainer knowledgeable)
            //   3rd rating1to5 → rating_id 5 (training environment)
            $ratingIds   = array(1, 2, 5);
            $starValues  = array();   // rating_id => value 1..5
            $learnerName = '';
            $comment     = '';
            foreach ($template['sections'] as $section) {
                foreach ($section['fields'] as $field) {
                    if (!empty($field['autofill']) || !empty($field['readonly'])) continue;
                    $fid = $field['id'];
                    $val = isset($answers[$fid]) ? trim((string)$answers[$fid]) : '';
                    if ($learnerName === '' && $field['type'] === 'text' && !empty($field['required'])) $learnerName = $val;
                    if ($comment === '' && $field['type'] === 'textarea' && $val !== '')                $comment = $val;
                    if ($field['type'] === 'rating1to5' && !empty($ratingIds)) {
                        $ratingId = array_shift($ratingIds);
                        $star     = max(1, min(5, (int)$val ?: 5));
                        $starValues[$ratingId] = $star;
                    }
                }
            }

            // Save as a Magento product review — the single feedback store.
            $productId = (int)$run['product_id'];
            $storeId   = (int)Mage::app()->getStore()->getId();
            $average   = $starValues ? round(array_sum($starValues) / count($starValues), 1) : 5.0;

            /** @var Mage_Review_Model_Review $review */
            $review = Mage::getModel('review/review');
            $review->setEntityPkValue($productId)
                   ->setStatusId(Mage_Review_Model_Review::STATUS_APPROVED)
                   ->setTitle('Average Rating: ' . number_format($average, 1) . '/5')
                   ->setDetail($comment !== '' ? $comment : 'N/A')
                   ->setEntityId($review->getEntityIdByCode(Mage_Review_Model_Review::ENTITY_PRODUCT_CODE))
                   ->setStoreId($storeId)
                   ->setStores(array($storeId))
                   ->setNickname($learnerName)
                   ->save();

            // One vote per rating dimension: resolve the option row for the
            // chosen star value, then record + aggregate.
            $resource  = Mage::getSingleton('core/resource');
            $read      = $resource->getConnection('core_read');
            $optionTbl = $resource->getTableName('rating_option');
            foreach ($starValues as $ratingId => $star) {
                $optionId = (int)$read->fetchOne(
                    "SELECT option_id FROM `$optionTbl` WHERE rating_id = ? AND value = ?",
                    array($ratingId, $star)
                );
                if (!$optionId) continue;
                Mage::getModel('rating/rating')
                    ->setRatingId($ratingId)
                    ->setReviewId($review->getId())
                    ->addOptionVote($optionId, $productId);
            }
            $review->aggregate();

            $this->_renderThanks((string)$run['course_title']);
        } catch (Exception $e) {
            Mage::logException($e);
            $this->_renderError('Submission Error', 'An error occurred saving your response. Please try again.');
        }
    }

    // ------------------------------------------------------------------ //

    protected function _loadRun($runId)
    {
        $resource  = Mage::getSingleton('core/resource');
        $read      = $resource->getConnection('core_read');
        $runsTbl   = $resource->getTableName('course_runs');
        $pVarchar  = $resource->getTableName('catalog_product_entity_varchar');
        $eavAttr   = $resource->getTableName('eav_attribute');
        $eavType   = $resource->getTableName('eav_entity_type');
        $eavOptVal = $resource->getTableName('eav_attribute_option_value');
        $auTbl     = $resource->getTableName('admin_user');

        $nameAttrId = (int)$read->fetchOne(
            "SELECT a.attribute_id FROM `$eavAttr` a
               JOIN `$eavType` t ON t.entity_type_id = a.entity_type_id
              WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'name'"
        );

        return $read->fetchRow(
            "SELECT cr.run_id, cr.class_id, cr.course_sku, cr.product_id,
                    cr.course_start_date,
                    -- Single-day classes leave course_end_date NULL.
                    COALESCE(cr.course_end_date, cr.course_start_date) AS course_end_date,
                    cr.trainer_option_id, cr.trainer_user_id,
                    COALESCE(pn.value, cr.course_sku) AS course_title,
                    -- Phase 2: account-confirmed trainer wins, EAV is the fallback.
                    COALESCE(
                        NULLIF(TRIM(CONCAT(COALESCE(au.firstname,''),' ',COALESCE(au.lastname,''))), ''),
                        tov.value, ''
                    ) AS trainer_name
               FROM `$runsTbl` cr
               LEFT JOIN `$pVarchar` pn
                    ON pn.entity_id = cr.product_id AND pn.store_id = 0
                   AND pn.attribute_id = $nameAttrId
               LEFT JOIN `$auTbl` au
                    ON au.user_id = cr.trainer_user_id
               LEFT JOIN `$eavOptVal` tov
                    ON tov.option_id = cr.trainer_option_id AND tov.store_id = 0
              WHERE cr.run_id = ?",
            array($runId)
        ) ?: null;
    }

    protected function _renderForm(array $template, array $context, $runId)
    {
        $submitUrl = Mage::getBaseUrl() . 'feedback/respond/submit';
        $title     = htmlspecialchars($template['title']);

        $sectionsHtml = '';
        foreach ($template['sections'] as $section) {
            $sectionsHtml .= '<div class="fb-section">'
                           . '<h3 class="fb-section-title">' . htmlspecialchars($section['title']) . '</h3>';
            foreach ($section['fields'] as $field) {
                $sectionsHtml .= $this->_renderField($field, $context);
            }
            $sectionsHtml .= '</div>';
        }

        $body = $this->_pageWrap($title, '
<form id="fb-form" method="POST" action="' . $submitUrl . '">
  <input type="hidden" name="run_id" value="' . (int)$runId . '">
  ' . $sectionsHtml . '
  <div class="fb-submit-row">
    <button type="submit" class="fb-submit-btn">Submit Feedback</button>
  </div>
</form>
<script>
document.getElementById("fb-form").addEventListener("submit", function(e) {
    var required = this.querySelectorAll("[required]");
    var ok = true;
    for (var i = 0; i < required.length; i++) {
        var el = required[i];
        var val = el.type === "hidden" ? el.value : el.value.trim();
        if (!val) {
            el.style.outline = "2px solid #f87171";
            ok = false;
        } else {
            el.style.outline = "";
        }
    }
    if (!ok) { e.preventDefault(); window.scrollTo(0,0); alert("Please fill in all required fields."); }
});
</script>');
        $this->getResponse()->clearHeaders()
             ->setHeader('Content-Type', 'text/html; charset=UTF-8')
             ->setBody($body);
    }

    protected function _renderField(array $field, array $context)
    {
        $id       = 'field_' . htmlspecialchars($field['id']);
        $label    = htmlspecialchars($field['label']);
        $req      = !empty($field['required']) && empty($field['readonly']);
        $reqMark  = $req ? ' <span class="fb-req">*</span>' : '';
        // `readonly` alone blocks editing. `disabled` would additionally grey the
        // text out (making prefilled values read as empty placeholders) and stop
        // the browser submitting them, so the course context never reaches POST.
        $readonly = !empty($field['readonly']) ? ' readonly' : '';
        $reqAttr  = ($req && empty($field['readonly'])) ? ' required' : '';

        // Resolve autofill value.
        $value = '';
        if (!empty($field['autofill']) && isset($context[$field['autofill']])) {
            $value = htmlspecialchars($context[$field['autofill']]);
        }

        $input = '';
        switch ($field['type']) {
            case 'textarea':
                $input = '<textarea name="' . $id . '" id="' . $id . '" class="fb-input"' . $readonly . $reqAttr . ' rows="4">' . $value . '</textarea>';
                break;
            case 'select':
                $opts = '<option value="">— Select —</option>';
                foreach (array_filter(array_map('trim', explode(',', (string)($field['options'] ?? '')))) as $opt) {
                    $opts .= '<option>' . htmlspecialchars($opt) . '</option>';
                }
                $input = '<select name="' . $id . '" id="' . $id . '" class="fb-input"' . $readonly . $reqAttr . '>' . $opts . '</select>';
                break;
            case 'rating1to5':
                $hiddenReq = $req ? ' required' : '';
                $input = '<div class="fb-stars" data-field="' . $id . '">'
                       . '<input type="hidden" name="' . $id . '" id="' . $id . '" value=""' . $hiddenReq . '>'
                       . '<button type="button" class="fb-star" data-v="1">★</button>'
                       . '<button type="button" class="fb-star" data-v="2">★</button>'
                       . '<button type="button" class="fb-star" data-v="3">★</button>'
                       . '<button type="button" class="fb-star" data-v="4">★</button>'
                       . '<button type="button" class="fb-star" data-v="5">★</button>'
                       . '<span class="fb-star-label"></span>'
                       . '</div>';
                break;
            default:
                $type  = in_array($field['type'], array('text','email','date'), true) ? $field['type'] : 'text';
                $input = '<input type="' . $type . '" name="' . $id . '" id="' . $id . '" class="fb-input" value="' . $value . '"' . $readonly . $reqAttr . '>';
                break;
        }

        return '<div class="fb-field' . (!empty($field['readonly']) ? ' fb-field-readonly' : '') . '">'
             . '<label class="fb-label" for="' . $id . '">' . $label . $reqMark . '</label>'
             . $input
             . '</div>';
    }

    protected function _renderThanks($courseTitle)
    {
        $body = $this->_pageWrap('Thank You', '
<div class="fb-thanks">
  <div class="fb-thanks-icon">✓</div>
  <h2>Thank you for your feedback!</h2>
  <p>Your response for <strong>' . htmlspecialchars($courseTitle) . '</strong> has been recorded.</p>
  <p style="color:#64748b;font-size:13px;margin-top:8px;">You may close this window.</p>
</div>');
        $this->getResponse()->clearHeaders()
             ->setHeader('Content-Type', 'text/html; charset=UTF-8')
             ->setBody($body);
    }

    protected function _renderError($heading, $message)
    {
        $body = $this->_pageWrap($heading, '
<div class="fb-error">
  <h2>' . htmlspecialchars($heading) . '</h2>
  <p>' . htmlspecialchars($message) . '</p>
</div>');
        $this->getResponse()->clearHeaders()
             ->setHeader('Content-Type', 'text/html; charset=UTF-8')
             ->setBody($body);
    }

    protected function _pageWrap($title, $content)
    {
        return '<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>' . htmlspecialchars($title) . ' — Tertiary Courses</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{background:#0f172a;font-family:Arial,sans-serif;color:#e2e8f0;min-height:100vh;padding:24px 16px;}
.fb-wrap{max-width:680px;margin:0 auto;}
.fb-header{background:#1a3a6b;border-radius:12px 12px 0 0;padding:20px 28px;margin-bottom:0;}
.fb-header p{color:#60a5fa;font-size:12px;font-weight:700;letter-spacing:1px;text-transform:uppercase;margin:0;}
.fb-card{background:#1e2132;border-radius:0 0 12px 12px;padding:28px;}
.fb-title{font-size:20px;font-weight:700;color:#e2e8f0;margin-bottom:24px;}
.fb-section{margin-bottom:28px;}
.fb-section-title{font-size:14px;font-weight:700;color:#94a3b8;text-transform:uppercase;letter-spacing:.5px;margin-bottom:16px;padding-bottom:8px;border-bottom:1px solid #1e293b;}
.fb-field{margin-bottom:16px;}
/* Prefilled class details: full-strength text so they read as real answered
   values, not greyed-out placeholders. The muted border + background is what
   signals "not editable". */
.fb-field-readonly .fb-input{background:#172033;color:#e2e8f0;cursor:default;border-color:#2b3a55;-webkit-text-fill-color:#e2e8f0;opacity:1;}
.fb-field-readonly .fb-input:focus{border-color:#2b3a55;}
.fb-label{display:block;font-size:13px;color:#94a3b8;margin-bottom:6px;}
.fb-req{color:#f87171;}
.fb-input{width:100%;background:#0f172a;border:1px solid #334155;border-radius:8px;padding:10px 12px;color:#e2e8f0;font-size:14px;outline:none;transition:border .15s;}
.fb-input:focus{border-color:#60a5fa;}
textarea.fb-input{resize:vertical;}
.fb-stars{display:flex;align-items:center;gap:6px;}
.fb-star{background:none;border:none;font-size:28px;color:#334155;cursor:pointer;padding:2px;transition:color .1s;line-height:1;}
.fb-star.active,.fb-star:hover{color:#f59e0b;}
.fb-star-label{font-size:12px;color:#94a3b8;margin-left:4px;}
.fb-submit-row{margin-top:24px;text-align:center;}
.fb-submit-btn{padding:12px 40px;background:#2563eb;color:#fff;border:none;border-radius:8px;font-size:15px;font-weight:700;cursor:pointer;}
.fb-submit-btn:hover{background:#1d4ed8;}
.fb-thanks{text-align:center;padding:32px 0;}
.fb-thanks-icon{width:56px;height:56px;border-radius:50%;background:#14532d;color:#4ade80;font-size:28px;line-height:56px;margin:0 auto 16px;}
.fb-thanks h2{font-size:20px;margin-bottom:12px;}
.fb-thanks p{color:#94a3b8;font-size:14px;line-height:1.6;}
.fb-error h2{font-size:20px;color:#f87171;margin-bottom:12px;}
.fb-error p{color:#94a3b8;font-size:14px;}
.fb-footer{text-align:center;padding:16px 0;margin-top:16px;}
.fb-footer a{color:#60a5fa;text-decoration:none;font-size:12px;}
</style>
</head>
<body>
<div class="fb-wrap">
  <div class="fb-header"><p>Tertiary Courses — Course Feedback</p></div>
  <div class="fb-card">
    <h1 class="fb-title">' . htmlspecialchars($title) . '</h1>
    ' . $content . '
  </div>
  <div class="fb-footer"><a href="https://tertiarycourses.com.sg">tertiarycourses.com.sg</a></div>
</div>
<script>
(function(){
  document.querySelectorAll(".fb-stars").forEach(function(wrap){
    var hidden = document.getElementById(wrap.getAttribute("data-field"));
    var stars  = wrap.querySelectorAll(".fb-star");
    var lbl    = wrap.querySelector(".fb-star-label");
    var labels = ["","Poor","Fair","Good","Very Good","Excellent"];
    function set(v){
      hidden.value = v;
      stars.forEach(function(s){ s.classList.toggle("active", parseInt(s.getAttribute("data-v"))<=v); });
      if(lbl) lbl.textContent = labels[v]||"";
    }
    stars.forEach(function(s){
      s.addEventListener("click",function(){ set(parseInt(s.getAttribute("data-v"))); });
      s.addEventListener("mouseover",function(){
        var v=parseInt(s.getAttribute("data-v"));
        stars.forEach(function(x){ x.classList.toggle("active",parseInt(x.getAttribute("data-v"))<=v); });
      });
    });
    wrap.addEventListener("mouseleave",function(){ set(parseInt(hidden.value)||0); });
  });
})();
</script>
</body>
</html>';
    }
}
