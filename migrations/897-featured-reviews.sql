-- 897: Featured reviews — storefront testimonials (2026-08).
--
-- Adds an `is_featured` flag to the stock `review` table so admins can
-- hand-pick which course reviews are marketing-worthy, and seeds the four
-- testimonials collected from Google Business Profile + LinkedIn.
--
-- Why a column on `review` and not a new table: axiom — the review IS the
-- registration-side artefact; a parallel "testimonial" table would fork the
-- source of truth and break the existing All Reviews grid / moderation flow.
-- The storefront reads `review.is_featured = 1 AND status_id = 1` only.
--
-- Surfaces this feeds:
--   * Homepage "What our learners say" strip — 4 RANDOM featured reviews,
--     rendered in `postscript` immediately after the blog strip.
--   * /testimonials — every featured review.
--   * Admin All Reviews grid — Featured column + filter + massaction.
--
-- Partner safety: the ALTER is generic (review exists on every site). The
-- seeded testimonials are keyed off SG-only TGS- SKUs via a SELECT join, so
-- on MY/GH the INSERTs match zero products and no-op. Idempotent throughout
-- (PREPARE-guarded ALTER; NOT EXISTS on each seed).

-- ── 1. is_featured column (idempotent — information_schema guard) ────────
SET @col := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'review'
      AND COLUMN_NAME = 'is_featured'
);
SET @sql := IF(@col = 0,
    'ALTER TABLE review ADD COLUMN is_featured TINYINT(1) UNSIGNED NOT NULL DEFAULT 0',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Index so the storefront ORDER BY RAND() pre-filter stays cheap on 22k rows.
SET @idx := (
    SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'review'
      AND INDEX_NAME = 'IDX_REVIEW_IS_FEATURED'
);
SET @sql := IF(@idx = 0,
    'ALTER TABLE review ADD INDEX IDX_REVIEW_IS_FEATURED (is_featured, status_id)',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ── 2. Seed the four collected testimonials ─────────────────────────────
-- Each is inserted as a normal approved (status_id = 1) product review on the
-- course the learner names, flagged featured. Guarded by NOT EXISTS on the
-- (nickname, entity_pk_value) pair so a re-run never duplicates.
--
--   WAI MUN CHIA        Google  -> TGS-2023018794 IBF Machine Learning 101
--                                  for Financial Trading
--   Muhammad Iszan      Google  -> TGS-2020504082 WSQ Data Analytics and
--                                  Visualization with Python (Dr Alvin's
--                                  most-run Python course; the review names
--                                  the trainer, not a course)
--   Wanxin Wang         LinkedIn-> TGS-2026064475 CASL Data Analytics and
--                                  Visualization with R
--   Kian Yee Lim        LinkedIn-> TGS-2020504082 WSQ Data Analytics and
--                                  Visualization with Python

-- WAI MUN CHIA ----------------------------------------------------------
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-08-09 10:00:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE e.sku = 'TGS-2023018794'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Wai Mun Chia' AND r.entity_pk_value = e.entity_id
  );
SET @rid := LAST_INSERT_ID();
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid, 1,
       'A very engaging and knowledgeable trainer',
       'Dr Alvin Ang is a very engaging and knowledgeable trainer. During the course, Machine Learning 101 for Financial Trading he explains concepts clearly and uses practical examples that make the lessons easy to understand. He also show us where and how we can learn further. I enjoyed the class and learning is easy. Thank you for the great learning experience!',
       'Wai Mun Chia', NULL
FROM dual WHERE @rid > 0 AND EXISTS (SELECT 1 FROM review WHERE review_id = @rid);
INSERT INTO review_store (review_id, store_id)
SELECT @rid, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid > 0
  AND EXISTS (SELECT 1 FROM review WHERE review_id = @rid)
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- Muhammad Iszan --------------------------------------------------------
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-08-09 10:05:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE e.sku = 'TGS-2020504082'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Muhammad Iszan' AND r.entity_pk_value = e.entity_id
  );
SET @rid := LAST_INSERT_ID();
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid, 1,
       'Explains things clearly and patiently',
       'I would like to express my sincere appreciation to Dr. Alvin for being such a wonderful and dedicated teacher. He explains things clearly and patiently, making even difficult topics much easier to understand. Highly recommended!',
       'Muhammad Iszan', NULL
FROM dual WHERE @rid > 0 AND EXISTS (SELECT 1 FROM review WHERE review_id = @rid);
INSERT INTO review_store (review_id, store_id)
SELECT @rid, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid > 0
  AND EXISTS (SELECT 1 FROM review WHERE review_id = @rid)
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- Wanxin Wang -----------------------------------------------------------
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-08-06 10:00:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE e.sku = 'TGS-2026064475'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Wanxin Wang' AND r.entity_pk_value = e.entity_id
  );
SET @rid := LAST_INSERT_ID();
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid, 1,
       'Well-structured, engaging and easy to follow',
       'I had the pleasure of learning R Data Analytics and Visualization under Dr Alvin Ang at Tertiary Infotech. His lessons were well-structured, engaging, and easy to follow, allowing even complex R programming concepts to be understood with confidence. Through a combination of clear explanations, practical examples, and hands-on exercises, he created an enjoyable and highly effective learning experience. Throughout the course, Dr Alvin covered a comprehensive range of topics including data wrangling with the tidyverse, data visualization using ggplot2, data manipulation with dplyr, tidyr and readr, piping with %>%, text mining using wordcloud, and statistical analysis techniques that are highly relevant to real-world data analytics. He was always patient, approachable, and willing to answer questions, ensuring that every participant understood the concepts before moving forward. Beyond the classroom, Dr Alvin generously shared additional learning resources, industry insights, and practical career advice to support our continued learning journey. I would highly recommend Dr Alvin Ang to anyone looking to build a strong foundation in R programming, data analytics, and data visualization. His passion for teaching and depth of knowledge make him an outstanding trainer and mentor.',
       'Wanxin Wang', NULL
FROM dual WHERE @rid > 0 AND EXISTS (SELECT 1 FROM review WHERE review_id = @rid);
INSERT INTO review_store (review_id, store_id)
SELECT @rid, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid > 0
  AND EXISTS (SELECT 1 FROM review WHERE review_id = @rid)
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- Kian Yee Lim ----------------------------------------------------------
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-08-01 10:00:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE e.sku = 'TGS-2020504082'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Kian Yee Lim' AND r.entity_pk_value = e.entity_id
  );
SET @rid := LAST_INSERT_ID();
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid, 1,
       'Clear concepts, easy to follow for a beginner',
       'I had the pleasure of learning Data Analysis with Python under Dr. Alvin Ang. He explained the concepts clearly and made the lessons easy to follow, even for someone who was still new to Python and data analysis. His practical examples and step-by-step teaching approach helped me better understand how Python can be used to analyse data. Dr. Alvin was also patient, encouraging and always willing to clarify our questions. I would highly recommend him to anyone who wants to build a strong foundation in Python and data analysis.',
       'Kian Yee Lim', NULL
FROM dual WHERE @rid > 0 AND EXISTS (SELECT 1 FROM review WHERE review_id = @rid);
INSERT INTO review_store (review_id, store_id)
SELECT @rid, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid > 0
  AND EXISTS (SELECT 1 FROM review WHERE review_id = @rid)
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ── 3. Give the seeded reviews a 5-star vote on every rating question ────
-- So the storefront star display and the All Reviews grid rating columns are
-- populated exactly like an organically-submitted review.
INSERT INTO rating_option_vote
    (option_id, remote_ip, remote_ip_long, customer_id, entity_pk_value, rating_id, review_id, percent, value)
SELECT ro.option_id, '', 0, NULL, r.entity_pk_value, ro.rating_id, r.review_id, 100, 5
FROM review r
JOIN review_detail d ON d.review_id = r.review_id
JOIN rating rt ON rt.entity_id = (SELECT entity_id FROM review_entity WHERE entity_code = 'product')
JOIN rating_option ro ON ro.rating_id = rt.rating_id AND ro.value = 5
WHERE d.nickname IN ('Wai Mun Chia', 'Muhammad Iszan', 'Wanxin Wang', 'Kian Yee Lim')
  AND r.is_featured = 1
  AND NOT EXISTS (
      SELECT 1 FROM rating_option_vote v
      WHERE v.review_id = r.review_id AND v.rating_id = ro.rating_id
  );
