<?php
/**
 * LMS Feedback Review API — create a product review from an LMS course-feedback
 * submission.
 *
 * This is a SEPARATE endpoint from kael_review_api.php. The Kael API is the
 * proven path used by the agent for manual/backfill review posting and is
 * deliberately left untouched while this new automated path is on trial. The
 * two differ in two ways that matter:
 *
 *   1. SKU resolution — the LMS knows a course by its TGS course code (which is
 *      the storefront SKU), not by the Magento product entity_id. This endpoint
 *      accepts `sku` and resolves it with getIdBySku(), the same way every
 *      MMD_AgentApi capability does. `product_id` is still accepted directly.
 *
 *   2. Moderation — reviews are NOT unconditionally auto-approved. The average
 *      of the submitted star ratings decides:
 *          average  > 2.0  -> APPROVED, live on the storefront immediately
 *          average <= 2.0  -> PENDING, held for a human in
 *                             Catalog > Reviews and Ratings > Pending Reviews
 *      Low-scoring feedback therefore never auto-publishes; an admin reads it
 *      and approves or rejects by hand.
 *
 * Endpoint: POST <site_base_url>/lms_feedback_review_api.php
 *
 * Headers:
 *   Content-Type: application/json
 *   X-Api-Key:    same key as the Kael review API (mmd_company/api/kael_review_key,
 *                 else env KAEL_REVIEW_API_KEY)
 *
 * Request body (JSON):
 * {
 *   "sku":            "TGS-2024045798",   // required unless product_id given
 *   "product_id":     1079,               // optional alternative to sku
 *   "nickname":       "John Tan",         // required — learner name
 *   "detail":         "Great course!",    // required — the comment
 *   "ratings":        { "1": 5, "2": 5, "5": 4 },  // required, rating_id => 1..5
 *   "title":          "Average Rating: 4.7/5",     // optional, auto-generated
 *   "created_at":     "2026-04-10 04:00:17",       // optional
 *   "store_id":       1,                  // optional
 *   "customer_id":    null,               // optional
 *   "external_ref":   "<uuid>"            // optional — LMS feedback_form_response.id,
 *                                         //   used for idempotency (see below)
 * }
 *
 * Rating IDs (must match the storefront's 3-criteria review form):
 *   "1" = course meets expectation      "2" = trainer knowledgeable
 *   "5" = training environment
 *
 * Idempotency: when `external_ref` is supplied the endpoint first looks for an
 * existing review already recorded against that reference and returns it
 * unchanged (duplicate: true) instead of creating a second one. This makes the
 * LMS side safe to retry.
 *
 * Success (HTTP 200):
 *   { "success": true, "review_id": 22863, "status": "approved"|"pending",
 *     "average_rating": 4.7, "auto_published": true|false, "duplicate": false }
 */

// Rating option ID mapping: rating_id => [1-star option_id, ... 5-star option_id].
// Mirrors kael_review_api.php — these are the radio values on the review form.
$RATING_MAP = array(
    '1' => array(1, 2, 3, 4, 5),       // Q1: Course meets expectation? values 1-5
    '2' => array(6, 7, 8, 9, 10),      // Q2: Trainer knowledgeable?    values 6-10
    '5' => array(21, 22, 23, 24, 25),  // Q3: Training environment?     values 21-25
);

// Reviews whose average star rating is at or below this never auto-publish.
define('LMS_REVIEW_AUTO_APPROVE_ABOVE', 2.0);

// Table holding external_ref -> review_id, for idempotent retries.
define('LMS_REVIEW_REF_TABLE', 'mmd_lms_feedback_review');

header('Content-Type: application/json; charset=utf-8');

function lms_review_fail($status, $error, $message = '')
{
    http_response_code($status);
    echo json_encode(array('success' => false, 'error' => $error, 'message' => $message));
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    lms_review_fail(405, 'method_not_allowed', 'Method not allowed. Use POST.');
}

require_once 'app/Mage.php';
// No store code arg — matches kael_review_api.php; the site has no "default"
// store and Mage::app() resolves the admin-side store, which is fine for API use.
Mage::app();

// Same key as the Kael API so the LMS needs only one shared secret.
$apiSecretKey = (string) Mage::getStoreConfig('mmd_company/api/kael_review_key', 0);
if ($apiSecretKey === '') {
    $apiSecretKey = (string) (getenv('KAEL_REVIEW_API_KEY') ?: '');
}
if ($apiSecretKey === '') {
    lms_review_fail(503, 'api_disabled', 'Review API key is not configured on this site.');
}

$apiKey = isset($_SERVER['HTTP_X_API_KEY']) ? $_SERVER['HTTP_X_API_KEY'] : '';
if (!hash_equals($apiSecretKey, $apiKey)) {
    lms_review_fail(401, 'unauthorized', 'Invalid API key');
}

$input = json_decode(file_get_contents('php://input'), true);
if (!is_array($input)) {
    lms_review_fail(400, 'validation_error', 'Request body must be a JSON object.');
}

foreach (array('nickname', 'detail', 'ratings') as $field) {
    if (!isset($input[$field]) || $input[$field] === '' || $input[$field] === array()) {
        lms_review_fail(400, 'validation_error', "Missing required field: $field");
    }
}
if (!is_array($input['ratings'])) {
    lms_review_fail(400, 'validation_error', 'ratings must be an object of rating_id => stars.');
}
if (empty($input['sku']) && empty($input['product_id'])) {
    lms_review_fail(400, 'validation_error', 'Either sku or product_id is required.');
}

$createdAtSql = '';
if (isset($input['created_at']) && trim((string) $input['created_at']) !== '') {
    $raw = trim((string) $input['created_at']);
    $ts  = strtotime($raw);
    if ($ts === false) {
        lms_review_fail(400, 'validation_error', "Invalid created_at: '$raw'");
    }
    $createdAtSql = date('Y-m-d H:i:s', $ts);
}

try {
    // ── Resolve the product ────────────────────────────────────────────────
    // The LMS holds the TGS course code, which IS the storefront SKU. Resolve it
    // server-side rather than making the caller know Magento entity ids.
    if (!empty($input['product_id'])) {
        $productId = (int) $input['product_id'];
    } else {
        $sku       = trim((string) $input['sku']);
        $productId = (int) Mage::getModel('catalog/product')->getIdBySku($sku);
        if (!$productId) {
            lms_review_fail(404, 'not_found', "No course with sku=$sku on this site.");
        }
    }

    $product = Mage::getModel('catalog/product')->load($productId);
    if (!$product->getId()) {
        lms_review_fail(404, 'not_found', "Product ID $productId not found");
    }

    $resource = Mage::getSingleton('core/resource');
    $write    = $resource->getConnection('core_write');
    $read     = $resource->getConnection('core_read');

    // ── Idempotency: never double-post the same LMS submission ─────────────
    $externalRef = isset($input['external_ref']) ? trim((string) $input['external_ref']) : '';
    $refTable    = $resource->getTableName(LMS_REVIEW_REF_TABLE);
    $haveRefTable = false;
    try {
        $haveRefTable = (bool) $read->fetchOne('SHOW TABLES LIKE ?', array($refTable));
    } catch (Exception $e) {
        $haveRefTable = false;
    }

    if ($externalRef !== '' && $haveRefTable) {
        $existing = $read->fetchRow(
            "SELECT review_id, status_id FROM `{$refTable}` WHERE external_ref = ? LIMIT 1",
            array($externalRef)
        );
        if ($existing) {
            echo json_encode(array(
                'success'        => true,
                'duplicate'      => true,
                'review_id'      => (int) $existing['review_id'],
                'status'         => ((int) $existing['status_id'] === Mage_Review_Model_Review::STATUS_APPROVED)
                                        ? 'approved' : 'pending',
                'auto_published' => ((int) $existing['status_id'] === Mage_Review_Model_Review::STATUS_APPROVED),
                'message'        => 'Review already exists for this external_ref; nothing created.',
            ));
            exit;
        }
    }

    // ── Moderation decision ────────────────────────────────────────────────
    // Average only the ratings we actually recognise and that are in range —
    // the same set that will be recorded as votes, so the published star
    // average and the moderation decision can never disagree.
    $validStars = array();
    foreach ($input['ratings'] as $ratingId => $starValue) {
        $ratingId  = (string) $ratingId;
        $starValue = (int) $starValue;
        if (isset($RATING_MAP[$ratingId]) && $starValue >= 1 && $starValue <= 5) {
            $validStars[$ratingId] = $starValue;
        }
    }
    if (!$validStars) {
        lms_review_fail(400, 'validation_error',
            'No usable ratings supplied. Expected rating_id 1, 2 or 5 with 1-5 stars.');
    }

    $average  = array_sum($validStars) / count($validStars);
    $approved = ($average > LMS_REVIEW_AUTO_APPROVE_ABOVE);
    $statusId = $approved
        ? Mage_Review_Model_Review::STATUS_APPROVED
        : Mage_Review_Model_Review::STATUS_PENDING;

    $title = isset($input['title']) && trim((string) $input['title']) !== ''
        ? trim((string) $input['title'])
        : sprintf('Average Rating: %.1f/5', $average);

    $storeId    = isset($input['store_id']) ? (int) $input['store_id'] : (int) Mage::app()->getStore()->getId();
    $customerId = isset($input['customer_id']) && $input['customer_id'] !== '' ? (int) $input['customer_id'] : null;

    // ── Create the review ──────────────────────────────────────────────────
    $review = Mage::getModel('review/review');
    $review->setEntityPkValue($productId);
    $review->setStatusId($statusId);
    $review->setTitle($title);
    $review->setDetail(trim((string) $input['detail']));
    $review->setEntityId($review->getEntityIdByCode(Mage_Review_Model_Review::ENTITY_PRODUCT_CODE));
    $review->setStoreId($storeId);
    $review->setStores(array($storeId));
    $review->setCustomerId($customerId);
    $review->setNickname(trim((string) $input['nickname']));
    $review->save();

    // save() stamps NOW() from the schema default, so a supplied created_at is
    // patched in afterwards (same approach as kael_review_api.php).
    if ($createdAtSql !== '') {
        $write->update(
            $resource->getTableName('review/review'),
            array('created_at' => $createdAtSql),
            array('review_id = ?' => (int) $review->getId())
        );
    }

    foreach ($validStars as $ratingId => $starValue) {
        $optionId = $RATING_MAP[$ratingId][$starValue - 1];
        Mage::getModel('rating/rating')
            ->setRatingId($ratingId)
            ->setReviewId($review->getId())
            ->addOptionVote($optionId, $productId);
    }

    // Recompute the product's rating summary. Magento aggregates only APPROVED
    // reviews, so a pending one correctly does not move the public star average;
    // approving it later in the admin re-aggregates automatically.
    $review->aggregate();

    if ($externalRef !== '' && $haveRefTable) {
        try {
            $write->insert($refTable, array(
                'external_ref' => $externalRef,
                'review_id'    => (int) $review->getId(),
                'product_id'   => $productId,
                'status_id'    => $statusId,
                'created_at'   => now(),
            ));
        } catch (Exception $e) {
            // A failed bookkeeping write must not fail an already-created review.
            Mage::logException($e);
        }
    }

    echo json_encode(array(
        'success'        => true,
        'duplicate'      => false,
        'review_id'      => (int) $review->getId(),
        'product_id'     => $productId,
        'status'         => $approved ? 'approved' : 'pending',
        'auto_published' => $approved,
        'average_rating' => round($average, 2),
        'created_at'     => $createdAtSql !== '' ? $createdAtSql : date('Y-m-d H:i:s'),
        'store_id'       => $storeId,
        'message'        => $approved
            ? 'Review created and approved'
            : 'Review created and held for admin approval (average rating <= '
              . LMS_REVIEW_AUTO_APPROVE_ABOVE . ')',
    ));

} catch (Exception $e) {
    Mage::logException($e);
    lms_review_fail(500, 'internal_error', $e->getMessage());
}
