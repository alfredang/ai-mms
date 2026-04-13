<?php
/**
 * Kael Review API — Custom endpoint for submitting product reviews
 * Place this file in the Magento root directory (same level as index.php)
 * 
 * Usage: POST https://www.tertiarycourses.com.sg/kael_review_api.php
 * 
 * Headers:
 *   Content-Type: application/json
 *   X-Api-Key: <secret key below>
 * 
 * Body (JSON):
 * {
 *   "product_id": 1362,
 *   "nickname": "John Tan",
 *   "title": "Average Rating: 4.7/5",
 *   "detail": "Great course, very informative!",
 *   "ratings": {
 *     "1": 5,
 *     "2": 5,
 *     "3": 4
 *   }
 * }
 * 
 * Rating IDs:
 *   "1" = "Do you find the course meet your expectation?" (1-5 stars)
 *   "2" = "Do you find the trainer knowledgeable?" (1-5 stars)
 *   "5" = "How do you find the training environment?" (1-5 stars)
 * 
 * The API auto-approves reviews (status = APPROVED).
 */

// ── Configuration ──────────────────────────────────────────────────────
define('API_SECRET_KEY', getenv('KAEL_REVIEW_API_KEY') ?: 'CHANGE_ME');

// Rating option ID mapping: rating_id => [1-star option_id, 2-star, 3-star, 4-star, 5-star]
// These map to the radio button values in the review form
$RATING_MAP = array(
    '1' => array(1, 2, 3, 4, 5),       // Q1: Course meets expectation? values 1-5
    '2' => array(6, 7, 8, 9, 10),      // Q2: Trainer knowledgeable?    values 6-10
    '5' => array(21, 22, 23, 24, 25),  // Q3: Training environment?     values 21-25
);

// ── Request Handling ───────────────────────────────────────────────────

// Only allow POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(array('error' => 'Method not allowed. Use POST.'));
    exit;
}

// Validate API key
$apiKey = isset($_SERVER['HTTP_X_API_KEY']) ? $_SERVER['HTTP_X_API_KEY'] : '';
if ($apiKey !== API_SECRET_KEY) {
    http_response_code(401);
    echo json_encode(array('error' => 'Invalid API key'));
    exit;
}

// Parse JSON body
$input = json_decode(file_get_contents('php://input'), true);
if (!$input) {
    http_response_code(400);
    echo json_encode(array('error' => 'Invalid JSON body'));
    exit;
}

// Validate required fields
$required = array('product_id', 'nickname', 'title', 'detail', 'ratings');
foreach ($required as $field) {
    if (empty($input[$field])) {
        http_response_code(400);
        echo json_encode(array('error' => "Missing required field: $field"));
        exit;
    }
}

// ── Bootstrap Magento ──────────────────────────────────────────────────
require_once 'app/Mage.php';
Mage::app('default');

// ── Create Review ──────────────────────────────────────────────────────
try {
    $productId = (int) $input['product_id'];
    $nickname  = trim($input['nickname']);
    $title     = trim($input['title']);
    $detail    = trim($input['detail']);
    $ratings   = $input['ratings'];
    $storeId   = Mage::app()->getStore()->getId();

    // Verify product exists
    $product = Mage::getModel('catalog/product')->load($productId);
    if (!$product->getId()) {
        http_response_code(404);
        echo json_encode(array('error' => "Product ID $productId not found"));
        exit;
    }

    // Create the review
    $review = Mage::getModel('review/review');
    $review->setEntityPkValue($productId);
    $review->setStatusId(Mage_Review_Model_Review::STATUS_APPROVED); // Auto-approve
    $review->setTitle($title);
    $review->setDetail($detail);
    $review->setEntityId($review->getEntityIdByCode(Mage_Review_Model_Review::ENTITY_PRODUCT_CODE));
    $review->setStoreId($storeId);
    $review->setStores(array($storeId));
    $review->setCustomerId(null); // Guest review
    $review->setNickname($nickname);
    $review->save();

    // Add rating votes
    foreach ($ratings as $ratingId => $starValue) {
        $ratingId = (string) $ratingId;
        $starValue = (int) $starValue;

        if (!isset($RATING_MAP[$ratingId])) {
            continue; // Skip unknown rating IDs
        }

        if ($starValue < 1 || $starValue > 5) {
            continue; // Skip invalid star values
        }

        // Get the option_id for this star value
        $optionId = $RATING_MAP[$ratingId][$starValue - 1];

        Mage::getModel('rating/rating')
            ->setRatingId($ratingId)
            ->setReviewId($review->getId())
            ->addOptionVote($optionId, $productId);
    }

    // Aggregate ratings for the product
    $review->aggregate();

    // Return success
    header('Content-Type: application/json');
    echo json_encode(array(
        'success'   => true,
        'review_id' => (int) $review->getId(),
        'message'   => 'Review created and approved'
    ));

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(array(
        'error'   => 'Failed to create review',
        'message' => $e->getMessage()
    ));
}
