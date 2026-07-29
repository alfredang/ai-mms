-- 829: Assign 11 enabled+visible courses to the "Adult Courses" master
-- listing category (entity_id 3, /adult-training-courses.html) they were
-- missing from. Without the assignment they were absent from that page's
-- layered nav, so its Course Type filter (Funded 298 / Non-funded 253)
-- did not tally with the backend's 562 enabled courses (299 funded via
-- WSQ/IBF/CASL tags + 263 unfunded). Applied live on SG prod 2026-07-29;
-- this migration makes a rebuilt DB keep the state.
--
-- Partner-safe: keyed by SKU (C-prefix courses exist on MY/GH per catalog
-- parity and belong on their cloned Adult Courses category too; the TGS-
-- SKU simply matches nothing there), INSERT IGNORE is idempotent on the
-- (category_id, product_id) PK, and the EXISTS guard no-ops on any
-- instance where category 3 is not the Adult Courses node under root 1/2.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 3, e.entity_id, 9999
FROM catalog_product_entity e
WHERE e.sku IN (
    'C012', 'C398', 'C814', 'TGS-2022015539', 'C864', 'C1186',
    'C1756', 'C1759', 'C1760', 'C1762', 'C1768'
)
AND EXISTS (
    SELECT 1 FROM catalog_category_entity c
    WHERE c.entity_id = 3 AND c.path LIKE '1/2/%'
);
