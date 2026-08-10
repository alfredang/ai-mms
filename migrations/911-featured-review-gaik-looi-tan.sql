-- 911: Featured review — Gaik Looi Tan (Google, 2026-08-10).
--
-- Seeds the 5-star Google Business Profile review for TGS-2023018794
-- IBF - Machine Learning 101 for Financial Trading as a normal approved
-- product review flagged `is_featured = 1` (same pattern as migration 897),
-- so it shows on the homepage "What our learners say" strip, /testimonials,
-- and the course's own review list.
--
-- Also rebuilds the course's `review_entity_summary` row from the live
-- review/vote data — the raw-SQL seeds bypass Magento's aggregate(), so the
-- product-page star summary was one review behind after 897 and would fall
-- two behind after this seed.
--
-- Partner safety: everything is keyed off the SG-only TGS- SKU via SELECT
-- joins; on MY/GH nothing matches and the whole file no-ops. Idempotent
-- (NOT EXISTS on the seed; the summary rebuild is a recompute).

-- ── 1. Seed the review ──────────────────────────────────────────────────
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-08-10 11:00:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE e.sku = 'TGS-2023018794'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Gaik Looi Tan' AND r.entity_pk_value = e.entity_id
  );
SET @rid := LAST_INSERT_ID();
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid, 1,
       'Excellent Course for Beginners',
       'Really enjoyed Dr Alvin Ang''s Machine Learning 101 for Financial Trading course. He has a jovial and engaging teaching style that makes even complex machine learning concepts easy to understand — we were never bored! What I found especially valuable was how he clearly showed where and how machine learning fits into the different stages of an AI trading system. The conceptual materials and sample Python codes shared were also very useful for further learning and experimentation after the course. A fair note for anyone considering the course: this is not a course on profitable trading strategies. It focuses on the fundamental building blocks of data-driven systematic trading, which I think is exactly what beginners need to build a solid foundation. Highly recommended for beginners, or anyone looking to refresh their ML knowledge and understand how it is being applied to systematic trading today. Thanks, Dr Alvin, for the great insights and enjoyable learning experience!',
       'Gaik Looi Tan', NULL
FROM dual WHERE @rid > 0 AND EXISTS (SELECT 1 FROM review WHERE review_id = @rid);
INSERT INTO review_store (review_id, store_id)
SELECT @rid, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid > 0
  AND EXISTS (SELECT 1 FROM review WHERE review_id = @rid)
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ── 2. 5-star vote on every rating question ─────────────────────────────
INSERT INTO rating_option_vote
    (option_id, remote_ip, remote_ip_long, customer_id, entity_pk_value, rating_id, review_id, percent, value)
SELECT ro.option_id, '', 0, NULL, r.entity_pk_value, ro.rating_id, r.review_id, 100, 5
FROM review r
JOIN review_detail d ON d.review_id = r.review_id
JOIN rating rt ON rt.entity_id = (SELECT entity_id FROM review_entity WHERE entity_code = 'product')
JOIN rating_option ro ON ro.rating_id = rt.rating_id AND ro.value = 5
WHERE d.nickname = 'Gaik Looi Tan'
  AND r.is_featured = 1
  AND NOT EXISTS (
      SELECT 1 FROM rating_option_vote v
      WHERE v.review_id = r.review_id AND v.rating_id = ro.rating_id
  );

-- ── 3. Rebuild the product-page star summary for this course ────────────
-- reviews_count = all approved reviews; rating_summary = avg vote percent
-- across those reviews (reviews with no votes are ignored by AVG).
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023018794');
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
