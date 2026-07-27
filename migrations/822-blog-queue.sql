-- 822: "Next blog queue" for the agentic blog pipeline (Blog Posts admin page).
-- Mirrors mmd_marketing_flyer_queue: the admin lines up courses; the daily
-- autoblog proposer consumes the TOP row (deleted on pop) before falling back
-- to the best-seller auto-pick. UNIQUE(product_id) makes re-adding a no-op.
-- Pure idempotent DDL — safe on every instance (SG/MY/GH).
CREATE TABLE IF NOT EXISTS mmd_blog_queue (
    queue_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    product_id INT UNSIGNED NOT NULL,
    position   INT UNSIGNED NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (queue_id),
    UNIQUE KEY uq_blog_queue_product (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
