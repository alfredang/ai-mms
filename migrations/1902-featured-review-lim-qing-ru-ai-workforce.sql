-- 1902: Featured review — Lim Qing Ru's WhatsApp testimonial for Dr Alfred
-- Ang's Build a Human-AI Workforce with Autonomous AI Agents class.
--
-- Seeds one WhatsApp thank-you message (sent 5:21 PM just before Mon
-- 2 Nov 2026, replying to the trainer's post-class note) as an approved
-- product review flagged `is_featured = 1` (same pattern as 1417/1324), so it
-- shows on the homepage "What our learners say" strip, /testimonials, and the
-- course's own review list.
--
--   * Lim Qing Ru (5*, 2026-11-01) -> TGS-2024043854 "WSQ - Build a Human-AI
--     Workforce with Autonomous AI Agents". The learner already has two
--     survey-imported reviews on this course (20173, 24224, both titled
--     "Average Rating: 5.0/5"), so the NOT EXISTS guard keys on
--     nickname + title, not nickname alone.
--
-- Review text is the learner's own wording, emoji dropped. ASCII-only
-- throughout (apply.php connects utf8, NOT utf8mb4 -- emoji/smart quotes would
-- abort the whole chain and 502 the site).
--
-- Also rebuilds the course's `review_entity_summary` row from the live
-- review/vote data -- raw-SQL seeds bypass Magento's aggregate().
--
-- Partner safety: every statement is gated on @sg (store_id 1 = 'singapore'),
-- which is false on partner servers, so the whole file no-ops there. `@rid` is
-- derived from ROW_COUNT() so a skipped seed can never attach detail/votes to
-- an unrelated review. Idempotent.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

-- ═══ Review — Lim Qing Ru (WSQ Human-AI Workforce, 5*) ══════════════════════
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-11-01 17:21:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg > 0
  AND e.sku = 'TGS-2024043854'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Lim Qing Ru'
        AND d.title = 'Made AI agents practical and easy to understand'
        AND r.entity_pk_value = e.entity_id
  );
SET @rid1 := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid1, 1,
       'Made AI agents practical and easy to understand',
       'Thank you so much for the training Dr Ang! I really learnt a lot from your class, thanks for making the AI agents so practical and easy to understand. Really appreciate you offering post-training consultations as well, that''s very generous of you.',
       'Lim Qing Ru', NULL
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
  AND d.nickname = 'Lim Qing Ru'
  AND d.title = 'Made AI agents practical and easy to understand'
  AND e.sku = 'TGS-2024043854'
  AND NOT EXISTS (
      SELECT 1 FROM rating_option_vote v
      WHERE v.review_id = r.review_id AND v.rating_id = ro.rating_id
  );

-- ═══ Rebuild review_entity_summary for the affected course ══════════════
SET @p1 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024043854');
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
