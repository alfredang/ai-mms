-- 928: Featured review — Nah Yi Wei (Google, 2026-08-12).
--
-- Seeds the 5-star Google Business Profile review for C182
-- Data Analytics with R as a normal approved product review flagged
-- `is_featured = 1` (same pattern as migrations 897/911/920), so it shows on
-- the homepage "What our learners say" strip, /testimonials, and the
-- course's own review list. The reviewer attended the C182 class running
-- 2026-08-12 and posted the review the same day.
--
-- Also rebuilds the course's `review_entity_summary` rows from the live
-- review/vote data — raw-SQL seeds bypass Magento's aggregate().
--
-- Partner safety: unlike the earlier TGS- seeds, C182 EXISTS on MY/GH
-- (C-prefix catalog parity), so SKU matching alone is not a guard. Every
-- statement is gated on @sg (store_id 1 = 'singapore'), which is false on
-- partner servers — the whole file no-ops there. The review names
-- "Tertiary Courses Singapore" and must not surface on partner sites.
-- `@rid` is derived from ROW_COUNT() so a skipped seed can never attach
-- detail/votes to an unrelated review. Idempotent.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

-- ── 1. Seed the review ──────────────────────────────────────────────────
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-08-12 12:00:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg = 1
  AND e.sku = 'C182'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Nah Yi Wei' AND r.entity_pk_value = e.entity_id
  );
SET @rid := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid, 1,
       'Engaging Data Analytics with R Course',
       'I had the opportunity to attend Dr Alvin Ang''s Data Analytics with R course, and I enjoyed the class a lot. Dr Alvin Ang was able to explain R concepts very clearly and answer our questions promptly. His teaching style was very engaging (he includes some witty humour during the class from time to time). I would recommend anybody who wants to learn a skill to come sign up for a course at Tertiary Courses Singapore.',
       'Nah Yi Wei', NULL
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
JOIN catalog_product_entity e ON e.entity_id = r.entity_pk_value AND e.sku = 'C182'
JOIN rating rt ON rt.entity_id = (SELECT entity_id FROM review_entity WHERE entity_code = 'product')
JOIN rating_option ro ON ro.rating_id = rt.rating_id AND ro.value = 5
WHERE @sg = 1
  AND d.nickname = 'Nah Yi Wei'
  AND r.is_featured = 1
  AND NOT EXISTS (
      SELECT 1 FROM rating_option_vote v
      WHERE v.review_id = r.review_id AND v.rating_id = ro.rating_id
  );

-- ── 3. Rebuild the product-page star summary for this course ────────────
-- reviews_count = all approved reviews; rating_summary = avg vote percent
-- across those reviews (reviews with no votes are ignored by AVG).
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C182');
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
  AND res.entity_type = (SELECT entity_id FROM review_entity WHERE entity_code = 'product');
