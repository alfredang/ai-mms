-- 900: Idempotency ledger for LMS-submitted course-feedback reviews (2026-08).
--
-- The LMS (lms-tms.tertiaryinfotech.com) posts a product review whenever a
-- learner submits the in-house course feedback form. That call may be retried —
-- by a background job, a redeploy, or an operator replaying a failed batch —
-- and Magento's review API has no natural idempotency key, so a naive retry
-- creates a duplicate review on the course page.
--
-- This table maps the LMS's own feedback_form_response.id (a UUID, passed as
-- `external_ref`) to the review it produced. lms_feedback_review_api.php looks
-- the ref up before creating anything and returns the existing review instead
-- of posting a second one.
--
-- Note this records the status at CREATION time only. It is a dedupe ledger,
-- not a mirror of moderation state — once an admin approves a held review in
-- Catalog > Reviews and Ratings, `review.status_id` is the truth and this
-- column is deliberately not chased.
--
-- Partner safety: table-only, no SKU/store literals, so SG/MY/GH can each
-- carry it harmlessly whether or not they run the LMS feedback integration.
--
-- Idempotent: CREATE TABLE IF NOT EXISTS.

CREATE TABLE IF NOT EXISTS `mmd_lms_feedback_review` (
    `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `external_ref` VARCHAR(64)  NOT NULL COMMENT 'LMS feedback_form_response.id (UUID)',
    `review_id`    INT UNSIGNED NOT NULL,
    `product_id`   INT UNSIGNED NULL,
    `status_id`    SMALLINT     NOT NULL COMMENT '1=approved, 2=pending at creation',
    `created_at`   DATETIME     NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_external_ref` (`external_ref`),
    KEY `idx_review`  (`review_id`),
    KEY `idx_product` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
