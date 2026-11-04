-- 1903: Featured reviews — two WhatsApp testimonials from Dr Alfred Ang's
-- 4 Nov 2026 Agentic AI Applications with Claude Code class.
--
-- Seeds two WhatsApp thank-you messages (replies to the trainer's post-class
-- note, 4 Nov 2026 5:26 PM and 5:30 PM) as approved product reviews flagged
-- `is_featured = 1` (same pattern as 1417/1902), so they show on the homepage
-- "What our learners say" strip, /testimonials, and the course's own review
-- list.
--
--   * XJ  (5*, 2026-11-04 17:26) -> TGS-2025052468
--   * Eds (5*, 2026-11-04 17:30) -> TGS-2025052468
--   Nicknames are the learners' WhatsApp display names as sent.
--
-- Review text is the learners' own wording (curly apostrophe made ASCII).
-- ASCII-only throughout (apply.php connects utf8, NOT utf8mb4 -- emoji/smart
-- quotes would abort the whole chain and 502 the site).
--
-- Also rebuilds the course's `review_entity_summary` row from the live
-- review/vote data -- raw-SQL seeds bypass Magento's aggregate().
--
-- Partner safety: every statement is gated on @sg (store_id 1 = 'singapore'),
-- which is false on partner servers, so the whole file no-ops there. `@rid` is
-- derived from ROW_COUNT() so a skipped seed can never attach detail/votes to
-- an unrelated review. The NOT EXISTS guards key on nickname + title.
-- Idempotent.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

-- ═══ Review 1 — XJ (WSQ Agentic AI with Claude Code, 5*) ═══════════════════
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-11-04 17:26:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg > 0
  AND e.sku = 'TGS-2025052468'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'XJ'
        AND d.title = 'Really helpful lesson'
        AND r.entity_pk_value = e.entity_id
  );
SET @rid1 := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid1, 1,
       'Really helpful lesson',
       'Thank you so much for the lesson, Dr Alfred! It was really helpful. I definitely need more practice. Let''s keep in touch!',
       'XJ', NULL
FROM dual WHERE @rid1 > 0;
INSERT INTO review_store (review_id, store_id)
SELECT @rid1, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid1 > 0
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ═══ Review 2 — Eds (WSQ Agentic AI with Claude Code, 5*) ══════════════════
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-11-04 17:30:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg > 0
  AND e.sku = 'TGS-2025052468'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Eds'
        AND d.title = 'Straight forward teaching and guidance'
        AND r.entity_pk_value = e.entity_id
  );
SET @rid2 := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid2, 1,
       'Straight forward teaching and guidance',
       'Thank you Dr Alfred for the guidance and straight forward teaching. I gain a tremendous knowledge today. Cheers',
       'Eds', NULL
FROM dual WHERE @rid2 > 0;
INSERT INTO review_store (review_id, store_id)
SELECT @rid2, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid2 > 0
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ═══ Star ratings — 5 stars each ════════════════════════════════════════
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
  AND e.sku = 'TGS-2025052468'
  AND ((d.nickname = 'XJ'  AND d.title = 'Really helpful lesson')
    OR (d.nickname = 'Eds' AND d.title = 'Straight forward teaching and guidance'))
  AND NOT EXISTS (
      SELECT 1 FROM rating_option_vote v
      WHERE v.review_id = r.review_id AND v.rating_id = ro.rating_id
  );

-- ═══ Rebuild review_entity_summary for the affected course ══════════════
SET @p1 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025052468');
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
