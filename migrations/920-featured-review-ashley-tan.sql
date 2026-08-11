-- 920: Featured review — Ashley Tan (LinkedIn recommendation, 2026-08-10).
--
-- Seeds the LinkedIn recommendation for TGS-2019504058
-- WSQ - R Fundamental and Statistical Analysis for Beginners as a normal
-- approved product review flagged `is_featured = 1` (same pattern as
-- migrations 897/911), so it shows on the homepage "What our learners say"
-- strip, /testimonials, and the course's own review list.
--
-- Also rebuilds the course's `review_entity_summary` rows from the live
-- review/vote data — raw-SQL seeds bypass Magento's aggregate().
--
-- Partner safety: keyed off the SG-only TGS- SKU; on MY/GH nothing matches
-- and the whole file no-ops. `@rid` is derived from ROW_COUNT() so a skipped
-- seed can never attach detail/votes to an unrelated review. Idempotent.

-- ── 1. Seed the review ──────────────────────────────────────────────────
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-08-10 12:00:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE e.sku = 'TGS-2019504058'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Ashley Tan' AND r.entity_pk_value = e.entity_id
  );
SET @rid := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid, 1,
       'Clear and Engaging R Programming Course',
       'I had the privilege of attending a course R Programming Fundamentals and Statistics under Alvin. The practical examples and clear explanation enabled me to grasp the concepts easily. His engaging teaching style encouraged me to ask more questions, and he took the time to patiently explain through concepts. I would highly recommend his courses to those interested in furthering their understanding of R programming!',
       'Ashley Tan', NULL
FROM dual WHERE @rid > 0;
INSERT INTO review_store (review_id, store_id)
SELECT @rid, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid > 0
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ── 2. 5-star vote on every rating question ─────────────────────────────
INSERT INTO rating_option_vote
    (option_id, remote_ip, remote_ip_long, customer_id, entity_pk_value, rating_id, review_id, percent, value)
SELECT ro.option_id, '', 0, NULL, r.entity_pk_value, ro.rating_id, r.review_id, 100, 5
FROM review r
JOIN review_detail d ON d.review_id = r.review_id
JOIN catalog_product_entity e ON e.entity_id = r.entity_pk_value AND e.sku = 'TGS-2019504058'
JOIN rating rt ON rt.entity_id = (SELECT entity_id FROM review_entity WHERE entity_code = 'product')
JOIN rating_option ro ON ro.rating_id = rt.rating_id AND ro.value = 5
WHERE d.nickname = 'Ashley Tan'
  AND r.is_featured = 1
  AND NOT EXISTS (
      SELECT 1 FROM rating_option_vote v
      WHERE v.review_id = r.review_id AND v.rating_id = ro.rating_id
  );

-- ── 3. Rebuild the product-page star summary for this course ────────────
-- reviews_count = all approved reviews; rating_summary = avg vote percent
-- across those reviews (reviews with no votes are ignored by AVG).
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2019504058');
UPDATE review_entity_summary res
JOIN (
    SELECT COUNT(DISTINCT r.review_id) AS cnt, ROUND(AVG(v.percent)) AS avg_pct
    FROM review r
    LEFT JOIN rating_option_vote v ON v.review_id = r.review_id
    WHERE r.entity_pk_value = @pid
      AND r.status_id = 1
) agg
SET res.reviews_count  = agg.cnt,
    res.rating_summary = COALESCE(agg.avg_pct, res.rating_summary)
WHERE res.entity_pk_value = @pid
  AND res.entity_type = (SELECT entity_id FROM review_entity WHERE entity_code = 'product');
