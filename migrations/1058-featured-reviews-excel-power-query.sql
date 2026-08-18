-- 1058: Featured reviews — Tan michele, Verly Tan, Jahn pp (Google, 2026-08-18).
--
-- Seeds three 5-star Google Business Profile reviews for TGS-2026064177
-- CASL - Excel Power Query and Power Pivot as normal approved product reviews
-- flagged `is_featured = 1` (same pattern as migrations 897/911/920/928), so
-- they show on the homepage "What our learners say" strip, /testimonials, and
-- the course's own review list. All three reviewers attended / registered for
-- the class around 2026-08-18 and posted on Google the same day.
--
-- Also rebuilds the course's `review_entity_summary` rows from the live
-- review/vote data — raw-SQL seeds bypass Magento's aggregate().
--
-- Partner safety: TGS- SKUs exist only on SG, and every statement is
-- additionally gated on @sg (store_id 1 = 'singapore'), which is false on
-- partner servers — the whole file no-ops there. `@rid` is derived from
-- ROW_COUNT() so a skipped seed can never attach detail/votes to an
-- unrelated review. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @ent := (SELECT entity_id FROM review_entity WHERE entity_code = 'product');

-- ── 1a. Seed review: Tan michele ────────────────────────────────────────
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-08-18 12:00:00', @ent, e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg = 1
  AND e.sku = 'TGS-2026064177'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Tan michele' AND r.entity_pk_value = e.entity_id
  );
SET @rid := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid, 1,
       'Patient Trainer Who Makes Sure We Really Understand',
       'This is my second time joining Dr. Alvin Ang''s class. I first attended last year on 16 Aug 2025. Today I signed up for the Excel Power Query and Power Pivot course. Dr. Ang is very patient. He makes sure we really understand, and he''ll even invite us to a Google Meet to troubleshoot why Power Pivot or Power Query isn''t working. He also shares tips to help speed up our work and make daily tasks easier.',
       'Tan michele', NULL
FROM dual WHERE @rid > 0;
INSERT INTO review_store (review_id, store_id)
SELECT @rid, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid > 0
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ── 1b. Seed review: Verly Tan ──────────────────────────────────────────
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-08-18 11:30:00', @ent, e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg = 1
  AND e.sku = 'TGS-2026064177'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Verly Tan' AND r.entity_pk_value = e.entity_id
  );
SET @rid := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid, 1,
       'Practical Tips and Insights from Dr Alvin Ang',
       'Had a chance to attend the Excel Power Query and Power Pivot by Dr Alvin Ang. He would give insights about the course and some practical tips. Hope to have a chance to attend his other course. It would be great if there are other location that''s a bit more central.',
       'Verly Tan', NULL
FROM dual WHERE @rid > 0;
INSERT INTO review_store (review_id, store_id)
SELECT @rid, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid > 0
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ── 1c. Seed review: Jahn pp ────────────────────────────────────────────
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-08-18 05:00:00', @ent, e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg = 1
  AND e.sku = 'TGS-2026064177'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Jahn pp' AND r.entity_pk_value = e.entity_id
  );
SET @rid := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid, 1,
       'Clear, Practical, and Very Useful for My Work',
       'Dr Alvin Ang, I enjoy the statistics, because it gives me ideals how to do the work.
This is my second course with Tertiary Courses Singapore. Dr. Alvin Ang''s Excel Power Query and Power Pivot class was clear, practical, and very useful for my work.',
       'Jahn pp', NULL
FROM dual WHERE @rid > 0;
INSERT INTO review_store (review_id, store_id)
SELECT @rid, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid > 0
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ── 2. 5-star vote on every rating question, for all three reviews ──────
INSERT INTO rating_option_vote
    (option_id, remote_ip, remote_ip_long, customer_id, entity_pk_value, rating_id, review_id, percent, value)
SELECT ro.option_id, '', 0, NULL, r.entity_pk_value, ro.rating_id, r.review_id, 100, 5
FROM review r
JOIN review_detail d ON d.review_id = r.review_id
JOIN catalog_product_entity e ON e.entity_id = r.entity_pk_value AND e.sku = 'TGS-2026064177'
JOIN rating rt ON rt.entity_id = @ent
JOIN rating_option ro ON ro.rating_id = rt.rating_id AND ro.value = 5
WHERE @sg = 1
  AND d.nickname IN ('Tan michele', 'Verly Tan', 'Jahn pp')
  AND r.is_featured = 1
  AND NOT EXISTS (
      SELECT 1 FROM rating_option_vote v
      WHERE v.review_id = r.review_id AND v.rating_id = ro.rating_id
  );

-- ── 3. Rebuild the product-page star summary for this course ────────────
-- reviews_count = all approved reviews; rating_summary = avg vote percent
-- across those reviews (reviews with no votes are ignored by AVG).
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026064177');
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
WHERE @sg = 1
  AND res.entity_pk_value = @pid
  AND res.entity_type = @ent;
