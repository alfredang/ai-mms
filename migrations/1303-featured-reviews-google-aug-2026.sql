-- 1303: Featured reviews — six Google Business Profile testimonials (Aug 2026).
--
-- Seeds six Google reviews as approved product reviews flagged `is_featured = 1`
-- (same pattern as 897/911/920/928/1095/1096), so they show on the homepage
-- "What our learners say" strip, /testimonials, and each course's review list.
--
--   * Aidie Fadlie (5*, 2026-08-31) → TGS-2023036656 "WSQ - Decision-Making and
--     Resource Optimization with Linear Programming". Names Excel Solver +
--     Linear Programming and Dr Alvin Ang; the only active course whose
--     description covers both (C1188 is the retired non-WSQ twin, last order 2023).
--   * Ding Dong (5*, 2026-08-27) → C469 "Tableau Desktop Masterclass". The
--     review praises "Mr Alvin" without naming the course; class C004023 ran
--     2026-08-27, which matches the review's "5 days ago". Course assignment
--     confirmed by the site owner.
--   * Li Ping Wu (5*, 2026-08-11) → TGS-2026064862 "CASL - Statistical Process
--     Control (SPC) in Manufacturing". Names the course title and the 4 Aug 2026
--     run (order 100041749 on that SKU is dated 2026-08-04) and trainer Amanda.
--   * Mavis (4*, 2026-08-11) → TGS-2026064862. Same SPC course + trainer Amanda.
--     Seeded at 4 stars (percent 80, value 4) to match the actual Google rating —
--     this is the only seed here that is not 5 stars.
--   * Darren Lim (5*, 2026-08-11) → TGS-2026064862. Names "Statistical Process
--     Control (SPC) in Manufacturing" and trainer Amanda explicitly.
--   * Kian Yee Lim (5*, 2026-08-04) → TGS-2020504082 "WSQ - Data Analytics and
--     Visualization with Python". Names "Data Analysis with Python" + Dr Alvin
--     Ang. This learner ALREADY has featured review 23299 on the same course
--     (seeded 2026-08-01 from a different, shorter testimonial), which is
--     exactly why the guards below key on nickname + title rather than
--     nickname alone — a nickname-only guard would match 23299 and silently
--     no-op this seed forever.
--
-- Review text is the reviewers' own wording, with obvious typos left intact
-- except for sentence-level tidying on Ding Dong's (line breaks joined, the
-- unrelated "managed to locate the classroom" opener dropped) and the emoji
-- stripped from Mavis's (it is not representable over apply.php's utf8 —
-- NOT utf8mb4 — PDO connection). ASCII-only throughout.
--
-- Also rebuilds each course's `review_entity_summary` rows from the live
-- review/vote data — raw-SQL seeds bypass Magento's aggregate().
--
-- Partner safety: every statement is gated on @sg (store_id 1 = 'singapore'),
-- which is false on partner servers, so the whole file no-ops there. Each
-- `@rid` is derived from ROW_COUNT() so a skipped seed can never attach
-- detail/votes to an unrelated review. The NOT EXISTS guards key on
-- nickname + title. Idempotent.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

-- ═══ Review 1 — Aidie Fadlie (Linear Programming, 5*) ═══════════════════
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-08-31 12:00:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg = 1
  AND e.sku = 'TGS-2023036656'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Aidie Fadlie'
        AND d.title = 'Takes his time to ensure students understand'
        AND r.entity_pk_value = e.entity_id
  );
SET @rid1 := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid1, 1,
       'Takes his time to ensure students understand',
       'Good training course provided by Dr Alvin Ang! Well-knowledgeable and takes his time to ensure his students understands the concept of the course (Excel Solver, Linear Programming). Very much well appreciated!',
       'Aidie Fadlie', NULL
FROM dual WHERE @rid1 > 0;
INSERT INTO review_store (review_id, store_id)
SELECT @rid1, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid1 > 0
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ═══ Review 2 — Ding Dong (Tableau Desktop Masterclass, 5*) ═════════════
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-08-27 12:00:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg = 1
  AND e.sku = 'C469'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Ding Dong'
        AND d.title = 'Well organized and structured lesson'
        AND r.entity_pk_value = e.entity_id
  );
SET @rid2 := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid2, 1,
       'Well organized and structured lesson',
       'Mr Alvin is a very knowledgeable and eager to share his knowledge with the class, not forgetting his passion in this course. Lesson is well organized and structured. He took the time to further elaborate some small details to the class. Very thankful to Mr Alvin seriously.',
       'Ding Dong', NULL
FROM dual WHERE @rid2 > 0;
INSERT INTO review_store (review_id, store_id)
SELECT @rid2, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid2 > 0
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ═══ Review 3 — Li Ping Wu (SPC in Manufacturing, 5*) ═══════════════════
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-08-11 12:00:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg = 1
  AND e.sku = 'TGS-2026064862'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Li Ping Wu'
        AND d.title = 'Patient trainer who explained things clearly'
        AND r.entity_pk_value = e.entity_id
  );
SET @rid3 := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid3, 1,
       'Patient trainer who explained things clearly',
       'Just attended the Statistical Process Control (SPC) in manufacturing course on 4 Aug 2026. I went with little knowledge of SPC but the trainer Amanda was very patient and explained things clearly. She could keep our attention and made it easy for us to understand and follow. Thanks Amanda!',
       'Li Ping Wu', NULL
FROM dual WHERE @rid3 > 0;
INSERT INTO review_store (review_id, store_id)
SELECT @rid3, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid3 > 0
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ═══ Review 4 — Mavis (SPC in Manufacturing, 4*) ════════════════════════
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-08-11 12:00:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg = 1
  AND e.sku = 'TGS-2026064862'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Mavis'
        AND d.title = 'Clear explanations with practical examples'
        AND r.entity_pk_value = e.entity_id
  );
SET @rid4 := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid4, 1,
       'Clear explanations with practical examples',
       'Had a great experience attending the SPC course! The trainer, Amanda, explained everything clearly with practical examples, making the concepts easy to understand. Very useful and relevant to my work. Highly recommended!',
       'Mavis', NULL
FROM dual WHERE @rid4 > 0;
INSERT INTO review_store (review_id, store_id)
SELECT @rid4, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid4 > 0
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ═══ Review 5 — Darren Lim (SPC in Manufacturing, 5*) ═══════════════════
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-08-11 12:00:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg = 1
  AND e.sku = 'TGS-2026064862'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Darren Lim'
        AND d.title = 'Interactive and interesting course'
        AND r.entity_pk_value = e.entity_id
  );
SET @rid5 := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid5, 1,
       'Interactive and interesting course',
       'Attended the Statistical Process Control (SPC) in Manufacturing under trainer named Amanda. Course was interactive and interesting with her as a trainer.',
       'Darren Lim', NULL
FROM dual WHERE @rid5 > 0;
INSERT INTO review_store (review_id, store_id)
SELECT @rid5, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid5 > 0
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ═══ Review 6 — Kian Yee Lim (Data Analytics with Python, 5*) ═══════════
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-08-04 12:00:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg = 1
  AND e.sku = 'TGS-2020504082'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Kian Yee Lim'
        AND d.title = 'Complex concepts broken down into practical examples'
        AND r.entity_pk_value = e.entity_id
  );
SET @rid6 := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid6, 1,
       'Complex concepts broken down into practical examples',
       'I had the opportunity to attend Dr. Alvin Ang''s Data Analysis with Python course, and it was a great learning experience. As someone who was relatively new to Python, I found his teaching style clear, structured, and easy to follow. He breaks down complex concepts into simple, practical examples that make learning much less intimidating. Dr. Alvin is patient, knowledgeable, and always willing to answer questions to ensure everyone understands the material. The hands-on exercises gave me confidence to apply Python to real-world data analysis tasks. I highly recommend Dr. Alvin Ang to anyone looking to build a strong foundation in Python, data analysis, or AI. Thank you for an excellent course!',
       'Kian Yee Lim', NULL
FROM dual WHERE @rid6 > 0;
INSERT INTO review_store (review_id, store_id)
SELECT @rid6, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid6 > 0
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ═══ 5-star votes on every rating question (the five 5* reviews) ═══════
INSERT INTO rating_option_vote
    (option_id, remote_ip, remote_ip_long, customer_id, entity_pk_value, rating_id, review_id, percent, value)
SELECT ro.option_id, '', 0, NULL, r.entity_pk_value, ro.rating_id, r.review_id, 100, 5
FROM review r
JOIN review_detail d ON d.review_id = r.review_id
JOIN catalog_product_entity e ON e.entity_id = r.entity_pk_value
JOIN rating rt ON rt.entity_id = (SELECT entity_id FROM review_entity WHERE entity_code = 'product')
JOIN rating_option ro ON ro.rating_id = rt.rating_id AND ro.value = 5
WHERE @sg = 1
  AND r.is_featured = 1
  AND ((d.nickname = 'Aidie Fadlie' AND d.title = 'Takes his time to ensure students understand'        AND e.sku = 'TGS-2023036656')
    OR (d.nickname = 'Ding Dong'    AND d.title = 'Well organized and structured lesson'                AND e.sku = 'C469')
    OR (d.nickname = 'Li Ping Wu'   AND d.title = 'Patient trainer who explained things clearly'        AND e.sku = 'TGS-2026064862')
    OR (d.nickname = 'Darren Lim'   AND d.title = 'Interactive and interesting course'                  AND e.sku = 'TGS-2026064862')
    OR (d.nickname = 'Kian Yee Lim' AND d.title = 'Complex concepts broken down into practical examples' AND e.sku = 'TGS-2020504082'))
  AND NOT EXISTS (
      SELECT 1 FROM rating_option_vote v
      WHERE v.review_id = r.review_id AND v.rating_id = ro.rating_id
  );

-- ═══ 4-star votes for Mavis ═════════════════════════════════════════════
INSERT INTO rating_option_vote
    (option_id, remote_ip, remote_ip_long, customer_id, entity_pk_value, rating_id, review_id, percent, value)
SELECT ro.option_id, '', 0, NULL, r.entity_pk_value, ro.rating_id, r.review_id, 80, 4
FROM review r
JOIN review_detail d ON d.review_id = r.review_id
JOIN catalog_product_entity e ON e.entity_id = r.entity_pk_value AND e.sku = 'TGS-2026064862'
JOIN rating rt ON rt.entity_id = (SELECT entity_id FROM review_entity WHERE entity_code = 'product')
JOIN rating_option ro ON ro.rating_id = rt.rating_id AND ro.value = 4
WHERE @sg = 1
  AND r.is_featured = 1
  AND d.nickname = 'Mavis'
  AND d.title = 'Clear explanations with practical examples'
  AND NOT EXISTS (
      SELECT 1 FROM rating_option_vote v
      WHERE v.review_id = r.review_id AND v.rating_id = ro.rating_id
  );

-- ═══ Rebuild the product-page star summary for each touched course ══════
-- reviews_count = approved reviews; rating_summary = avg vote percent across
-- those reviews (reviews with no votes are ignored by AVG).
SET @p1 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023036656');
UPDATE review_entity_summary res
JOIN (
    SELECT COUNT(DISTINCT r.review_id) AS cnt, ROUND(AVG(v.percent)) AS avg_pct
    FROM review r
    LEFT JOIN rating_option_vote v ON v.review_id = r.review_id
    WHERE r.entity_pk_value = @p1 AND r.status_id = 1
) agg
SET res.reviews_count  = agg.cnt,
    res.rating_summary = COALESCE(agg.avg_pct, res.rating_summary)
WHERE @sg = 1
  AND res.entity_pk_value = @p1
  AND res.entity_type = (SELECT entity_id FROM review_entity WHERE entity_code = 'product');

SET @p2 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C469');
UPDATE review_entity_summary res
JOIN (
    SELECT COUNT(DISTINCT r.review_id) AS cnt, ROUND(AVG(v.percent)) AS avg_pct
    FROM review r
    LEFT JOIN rating_option_vote v ON v.review_id = r.review_id
    WHERE r.entity_pk_value = @p2 AND r.status_id = 1
) agg
SET res.reviews_count  = agg.cnt,
    res.rating_summary = COALESCE(agg.avg_pct, res.rating_summary)
WHERE @sg = 1
  AND res.entity_pk_value = @p2
  AND res.entity_type = (SELECT entity_id FROM review_entity WHERE entity_code = 'product');

SET @p3 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026064862');
UPDATE review_entity_summary res
JOIN (
    SELECT COUNT(DISTINCT r.review_id) AS cnt, ROUND(AVG(v.percent)) AS avg_pct
    FROM review r
    LEFT JOIN rating_option_vote v ON v.review_id = r.review_id
    WHERE r.entity_pk_value = @p3 AND r.status_id = 1
) agg
SET res.reviews_count  = agg.cnt,
    res.rating_summary = COALESCE(agg.avg_pct, res.rating_summary)
WHERE @sg = 1
  AND res.entity_pk_value = @p3
  AND res.entity_type = (SELECT entity_id FROM review_entity WHERE entity_code = 'product');

SET @p4 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020504082');
UPDATE review_entity_summary res
JOIN (
    SELECT COUNT(DISTINCT r.review_id) AS cnt, ROUND(AVG(v.percent)) AS avg_pct
    FROM review r
    LEFT JOIN rating_option_vote v ON v.review_id = r.review_id
    WHERE r.entity_pk_value = @p4 AND r.status_id = 1
) agg
SET res.reviews_count  = agg.cnt,
    res.rating_summary = COALESCE(agg.avg_pct, res.rating_summary)
WHERE @sg = 1
  AND res.entity_pk_value = @p4
  AND res.entity_type = (SELECT entity_id FROM review_entity WHERE entity_code = 'product');
