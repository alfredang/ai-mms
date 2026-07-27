-- 817: Feedback Form merged into the Magento review system.
-- The public /feedback/respond form now saves straight into review /
-- review_detail / rating_option_vote (Reviews & Ratings admin grid).
-- The custom Form Builder + Responses admin pages are removed, and their
-- backing tables (created by 190-feedback-form-tables.sql) are dropped.
-- Responses table was confirmed empty on all sites before removal.
-- Idempotent + partner-safe: IF EXISTS no-ops where the tables never existed.

DROP TABLE IF EXISTS mmd_feedback_form_response;

DROP TABLE IF EXISTS mmd_feedback_form_template;
