-- 1324: Featured review — "THE RJ Channel" Google testimonial for Dr Alvin Ang's
-- Statistics with Excel class.
--
-- Seeds one Google Business Profile review as an approved product review flagged
-- `is_featured = 1` (same pattern as 1303/1305/1095/1096), so it shows on the
-- homepage "What our learners say" strip, /testimonials, and the course's own
-- review list.
--
--   * THE RJ Channel (5*, ~2026-09-05) -> TGS-2020505317 "WSQ - Statistical Data
--     Analysis with Excel for Beginners". The review names the course
--     ("Statistics with Excel course") and the trainer (Dr. Alvin Ang)
--     explicitly, so no inference is needed. Same course as Wei Kang's review
--     seeded in 1305.
--
-- The companion testimonial from the same batch ("Ding Dong" - "Mr alvin is a
-- very knowledgeable and eager to share his knowledge...") is ALREADY seeded by
-- migration 1303 on C469 "Tableau Desktop Masterclass" and is live -- it is
-- deliberately not repeated here.
--
-- Review text is the reviewer's own wording, with the trailing sign-off block
-- (Trainer/Course/Rating lines and emoji) dropped and the paragraphs joined into
-- flowing sentences. ASCII-only throughout (apply.php connects utf8, NOT
-- utf8mb4 -- emoji/smart quotes would abort the whole chain and 502 the site).
--
-- Also rebuilds the course's `review_entity_summary` row from the live
-- review/vote data -- raw-SQL seeds bypass Magento's aggregate().
--
-- Partner safety: every statement is gated on @sg (store_id 1 = 'singapore'),
-- which is false on partner servers, so the whole file no-ops there. Tested
-- `> 0`. `@rid` is derived from ROW_COUNT() so a skipped seed can never attach
-- detail/votes to an unrelated review. The NOT EXISTS guard keys on
-- nickname + title (not nickname alone). Idempotent.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

-- ═══ Review — THE RJ Channel (WSQ Statistical Data Analysis with Excel, 5*) ══
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-09-05 12:00:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg > 0
  AND e.sku = 'TGS-2020505317'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'THE RJ Channel'
        AND d.title = 'Clear, engaging and easy to follow'
        AND r.entity_pk_value = e.entity_id
  );
SET @rid1 := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid1, 1,
       'Clear, engaging and easy to follow',
       'I had a great learning experience attending the Statistics with Excel course conducted by Dr. Alvin Ang. The lecture was clear, engaging, and easy to follow, with practical examples that made understanding statistics and using Excel much easier. Dr. Alvin was knowledgeable, patient, and explained the concepts in a very approachable way. I especially appreciated how the lessons connected statistical concepts with real-world applications. Highly recommended for anyone looking to strengthen their understanding of statistics and improve their Excel skills! Come and join his classes, you won''t regret it. Thank you once again Sir.',
       'THE RJ Channel', NULL
FROM dual WHERE @rid1 > 0;
INSERT INTO review_store (review_id, store_id)
SELECT @rid1, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid1 > 0
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ═══ Star rating — 5 stars ══════════════════════════════════════════════
INSERT INTO rating_option_vote
    (option_id, remote_ip, remote_ip_long, customer_id, entity_pk_value, rating_id, review_id, percent, value)
SELECT ro.option_id, '', 0, NULL, r.entity_pk_value, ro.rating_id, r.review_id, 100, 5
FROM review r
JOIN review_detail d ON d.review_id = r.review_id
JOIN catalog_product_entity e ON e.entity_id = r.entity_pk_value
JOIN rating rt ON rt.entity_id = (SELECT entity_id FROM review_entity WHERE entity_code = 'product')
JOIN rating_option ro ON ro.rating_id = rt.rating_id AND ro.value = 5
WHERE @sg > 0
  AND r.is_featured = 1
  AND d.nickname = 'THE RJ Channel'
  AND d.title = 'Clear, engaging and easy to follow'
  AND e.sku = 'TGS-2020505317'
  AND NOT EXISTS (
      SELECT 1 FROM rating_option_vote v
      WHERE v.review_id = r.review_id AND v.rating_id = ro.rating_id
  );

-- ═══ Rebuild review_entity_summary for the affected course ══════════════
SET @p1 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020505317');
UPDATE review_entity_summary res
JOIN (
    SELECT COUNT(DISTINCT r.review_id) AS cnt, ROUND(AVG(v.percent)) AS avg_pct
    FROM review r
    LEFT JOIN rating_option_vote v ON v.review_id = r.review_id
    WHERE r.entity_pk_value = @p1 AND r.status_id = 1
) agg
SET res.reviews_count  = agg.cnt,
    res.rating_summary = COALESCE(agg.avg_pct, res.rating_summary)
WHERE @sg > 0
  AND res.entity_pk_value = @p1
  AND res.entity_type = (SELECT entity_id FROM review_entity WHERE entity_code = 'product');
