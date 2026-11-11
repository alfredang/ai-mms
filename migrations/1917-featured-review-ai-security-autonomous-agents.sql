-- 1917: Featured review — class evaluation for AI Security for Autonomous AI
-- Agents (TGS-2025060473), class 1456791, trainer Mohan Pothula.
--
-- Source: Kael "[TIA] Class Evaluation" email, 9 Nov 2026 8:00 PM. The learner
-- rated 5/5 on all three items (learning objectives, trainer knowledge,
-- training environment) and left a free-text comment. The evaluation is
-- anonymous ("Learner 1"), so the nickname is "Course Participant".
--
-- Seeded as an approved product review flagged `is_featured = 1` (same pattern
-- as 1902/1903), so it shows on the homepage "What our learners say" strip,
-- /testimonials, and the course's own review list.
--
-- Review text is the learner's own wording; only spacing and one typo
-- ("form" -> "from") are corrected. ASCII-only (apply.php connects utf8).
--
-- Also rebuilds the course's `review_entity_summary` row from the live
-- review/vote data -- raw-SQL seeds bypass Magento's aggregate().
--
-- Partner safety: every statement is gated on @sg (store_id 1 = 'singapore'),
-- false on partner servers, so the file no-ops there. `@rid` is derived from
-- ROW_COUNT() so a skipped seed can never attach detail/votes to an unrelated
-- review. The NOT EXISTS guard keys on nickname + title. Idempotent.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

-- ═══ Review — Course Participant (AI Security for Autonomous AI Agents, 5*) ═
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-11-09 20:00:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg > 0
  AND e.sku = 'TGS-2025060473'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Course Participant'
        AND d.title = 'Great understanding of AI security'
        AND r.entity_pk_value = e.entity_id
  );
SET @rid1 := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid1, 1,
       'Great understanding of AI security',
       'Mohan shared a lot of things such as prompt injection, jailbreak, data leak and many others. Learnt quite a lot of things from him. Great understanding of AI security.',
       'Course Participant', NULL
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
  AND e.sku = 'TGS-2025060473'
  AND d.nickname = 'Course Participant'
  AND d.title = 'Great understanding of AI security'
  AND NOT EXISTS (
      SELECT 1 FROM rating_option_vote v
      WHERE v.review_id = r.review_id AND v.rating_id = ro.rating_id
  );

-- ═══ Rebuild review_entity_summary for the affected course ══════════════
SET @p1 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025060473');
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
