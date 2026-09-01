-- 1305: Featured reviews — four more Google Business Profile testimonials.
--
-- Seeds four Google reviews as approved product reviews flagged `is_featured = 1`
-- (same pattern as 1303/1095/1096), so they show on the homepage "What our
-- learners say" strip, /testimonials, and each course's review list.
--
--   * Vint Tan (5*, ~2026-07-28, "5 weeks ago") -> TGS-2023037854 "WSQ - Cisco
--     Certified Network Associate (CCNA)". Names the CCNA course and trainer
--     Amanda, who is the CCNA/WSQ trainer also named in 1303's SPC reviews.
--     Chosen over the non-WSQ twin C975 because the review mentions an upcoming
--     exam, which is the WSQ/certification track.
--   * Justine Goh (5*, ~2026-07-14, "7 weeks ago") -> TGS-2019504058 "WSQ - R
--     Fundamental and Statistical Analysis for Beginners". Names "R coding",
--     "Dr Alvin Ang" and "good course for a beginner in coding" -- the only
--     active beginner-level R course.
--   * Jian Feng HO (5*, ~2026-05-26, "14 weeks ago") -> TGS-2025052468 "WSQ -
--     Agentic AI Applications with Claude Code". Names "Agentic AI using claude
--     code" and Dr Alfred explicitly.
--   * Wei Kang (5*, ~2026-03-24, "23 weeks ago") -> TGS-2020505317 "WSQ -
--     Statistical Data Analysis with Excel for Beginners". Names "Statistics
--     with Excel course at Tertiary Infotech", Dr Alvin Ang, and Excel Analysis
--     ToolPak / hypothesis testing / t-tests / ANOVA, which is this course.
--
-- Review text is the reviewers' own wording. ASCII-only throughout (apply.php
-- connects utf8, NOT utf8mb4 -- smart quotes/emoji would abort the chain), so
-- the curly apostrophes in Wei Kang's review are written as plain ASCII '.
-- Wei Kang's multi-paragraph review is joined into flowing sentences.
--
-- Also rebuilds each course's `review_entity_summary` rows from the live
-- review/vote data -- raw-SQL seeds bypass Magento's aggregate().
--
-- Partner safety: every statement is gated on @sg (store_id 1 = 'singapore'),
-- which is false on partner servers, so the whole file no-ops there. This is a
-- primary-key lookup on core_store, so it returns 0 or 1 -- unlike the
-- core_config_data base_url guard, which returns 2 on SG and silently no-ops a
-- `= 1` test. Tested `> 0` regardless. Each `@rid` is derived from ROW_COUNT()
-- so a skipped seed can never attach detail/votes to an unrelated review. The
-- NOT EXISTS guards key on nickname + title (not nickname alone -- a repeat
-- reviewer would otherwise silently no-op forever). Idempotent.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

-- ═══ Review 1 — Vint Tan (WSQ CCNA, 5*) ═════════════════════════════════
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-07-28 12:00:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg > 0
  AND e.sku = 'TGS-2023037854'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Vint Tan'
        AND d.title = 'Exceptional trainer with incredible patience'
        AND r.entity_pk_value = e.entity_id
  );
SET @rid1 := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid1, 1,
       'Exceptional trainer with incredible patience',
       'Ms. Amanda was an exceptional trainer and coach during my recent CCNA course. Throughout the session, she consistently demonstrated incredible patience, dedication, and enthusiasm for the subject matter. Rather than rushing through the agenda, she made sure to check in with the team, address every question thoroughly, and ensure that everyone fully grasped each concept before moving on to the next topic. Her engaging teaching style, practical examples, and attentive support significantly deepened my understanding of the material and gave me complete confidence in applying what I learned and also the upcoming exam.',
       'Vint Tan', NULL
FROM dual WHERE @rid1 > 0;
INSERT INTO review_store (review_id, store_id)
SELECT @rid1, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid1 > 0
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ═══ Review 2 — Justine Goh (WSQ R Fundamental, 5*) ═════════════════════
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-07-14 12:00:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg > 0
  AND e.sku = 'TGS-2019504058'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Justine Goh'
        AND d.title = 'A good course for a beginner in coding'
        AND r.entity_pk_value = e.entity_id
  );
SET @rid2 := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid2, 1,
       'A good course for a beginner in coding',
       'Dr Alvin Ang was highly knowledgeable about R coding and he made the course comprehensive and interesting. A good course for a beginner in coding.',
       'Justine Goh', NULL
FROM dual WHERE @rid2 > 0;
INSERT INTO review_store (review_id, store_id)
SELECT @rid2, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid2 > 0
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ═══ Review 3 — Jian Feng HO (WSQ Agentic AI with Claude Code, 5*) ══════
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-05-26 12:00:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg > 0
  AND e.sku = 'TGS-2025052468'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Jian Feng HO'
        AND d.title = 'A very professional training centre'
        AND r.entity_pk_value = e.entity_id
  );
SET @rid3 := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid3, 1,
       'A very professional training centre',
       'A very professional training centre. Thank you Dr Alfred for training us in Agentic AI using claude code. As a person in the same industry, their service is top notch compared to others. Hope to be back again soon. Convenient location with comfortable classroom setting.',
       'Jian Feng HO', NULL
FROM dual WHERE @rid3 > 0;
INSERT INTO review_store (review_id, store_id)
SELECT @rid3, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid3 > 0
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ═══ Review 4 — Wei Kang (WSQ Statistical Data Analysis with Excel, 5*) ══
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-03-24 12:00:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg > 0
  AND e.sku = 'TGS-2020505317'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Wei Kang'
        AND d.title = 'Clear and structured teaching style'
        AND r.entity_pk_value = e.entity_id
  );
SET @rid4 := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid4, 1,
       'Clear and structured teaching style',
       'I had the privilege of being trained by Dr. Alvin Ang during a Statistics with Excel course at Tertiary Infotech, and I am truly grateful for the experience. Dr. Alvin has a very clear and structured teaching style that made complex statistical concepts easy to understand, even for someone without a strong background in the subject. He guided us through practical tools such as Excel Analysis ToolPak, covering techniques like hypothesis testing, t-tests, ANOVA, and data visualization in a very hands-on and engaging way. What stood out most was his humor, patience and willingness to ensure every learner have a good time and kept up. He created an environment where asking questions was encouraged, which really helped build my confidence in applying these skills. Thanks to his guidance, I have been able to apply what I learned to my work and continue developing my data analysis skills. I highly recommend Dr. Alvin to anyone looking to build a strong foundation in statistics and data analysis. Thank you again for your guidance and support, Dr. Alvin.',
       'Wei Kang', NULL
FROM dual WHERE @rid4 > 0;
INSERT INTO review_store (review_id, store_id)
SELECT @rid4, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid4 > 0
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ═══ Star ratings — all four are 5 stars ════════════════════════════════
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
  AND ((d.nickname = 'Vint Tan'     AND d.title = 'Exceptional trainer with incredible patience' AND e.sku = 'TGS-2023037854')
    OR (d.nickname = 'Justine Goh'  AND d.title = 'A good course for a beginner in coding'       AND e.sku = 'TGS-2019504058')
    OR (d.nickname = 'Jian Feng HO' AND d.title = 'A very professional training centre'          AND e.sku = 'TGS-2025052468')
    OR (d.nickname = 'Wei Kang'     AND d.title = 'Clear and structured teaching style'          AND e.sku = 'TGS-2020505317'))
  AND NOT EXISTS (
      SELECT 1 FROM rating_option_vote v
      WHERE v.review_id = r.review_id AND v.rating_id = ro.rating_id
  );

-- ═══ Rebuild review_entity_summary for the four affected courses ════════
SET @p1 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023037854');
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

SET @p2 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2019504058');
UPDATE review_entity_summary res
JOIN (
    SELECT COUNT(DISTINCT r.review_id) AS cnt, ROUND(AVG(v.percent)) AS avg_pct
    FROM review r
    LEFT JOIN rating_option_vote v ON v.review_id = r.review_id
    WHERE r.entity_pk_value = @p2 AND r.status_id = 1
) agg
SET res.reviews_count  = agg.cnt,
    res.rating_summary = COALESCE(agg.avg_pct, res.rating_summary)
WHERE @sg > 0
  AND res.entity_pk_value = @p2
  AND res.entity_type = (SELECT entity_id FROM review_entity WHERE entity_code = 'product');

SET @p3 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025052468');
UPDATE review_entity_summary res
JOIN (
    SELECT COUNT(DISTINCT r.review_id) AS cnt, ROUND(AVG(v.percent)) AS avg_pct
    FROM review r
    LEFT JOIN rating_option_vote v ON v.review_id = r.review_id
    WHERE r.entity_pk_value = @p3 AND r.status_id = 1
) agg
SET res.reviews_count  = agg.cnt,
    res.rating_summary = COALESCE(agg.avg_pct, res.rating_summary)
WHERE @sg > 0
  AND res.entity_pk_value = @p3
  AND res.entity_type = (SELECT entity_id FROM review_entity WHERE entity_code = 'product');

SET @p4 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020505317');
UPDATE review_entity_summary res
JOIN (
    SELECT COUNT(DISTINCT r.review_id) AS cnt, ROUND(AVG(v.percent)) AS avg_pct
    FROM review r
    LEFT JOIN rating_option_vote v ON v.review_id = r.review_id
    WHERE r.entity_pk_value = @p4 AND r.status_id = 1
) agg
SET res.reviews_count  = agg.cnt,
    res.rating_summary = COALESCE(agg.avg_pct, res.rating_summary)
WHERE @sg > 0
  AND res.entity_pk_value = @p4
  AND res.entity_type = (SELECT entity_id FROM review_entity WHERE entity_code = 'product');
