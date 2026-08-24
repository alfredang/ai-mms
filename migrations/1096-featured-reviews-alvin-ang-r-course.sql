-- 1096: Featured reviews — Norsyafila Binte Abdullah + Anthony John Louis.
--
-- Seeds two LinkedIn recommendations for Dr Alvin Ang as approved product
-- reviews flagged `is_featured = 1` on TGS-2026064475 "CASL - Data Analytics
-- and Visualization with R" (same pattern as 897/911/920/928/1095), so they
-- show on the homepage "What our learners say" strip, /testimonials, and the
-- course's own review list.
--
--   * Norsyafila Binte Abdullah (2026-08-22) — attended his "R Tidyverse Data
--     Analytics and Visualization" training; the course title match is why
--     this SKU was chosen over C182 "Data Analytics with R".
--   * Anthony John Louis (2025-04-14) — a peer/LinkedIn endorsement of Dr
--     Alvin as a data scientist rather than an attendee review; placed on the
--     same flagship R course by explicit instruction.
--
-- Both texts are trimmed from the much longer LinkedIn recommendations to the
-- passages that read as testimonials, keeping the reviewers' own wording.
--
-- Also rebuilds the course's `review_entity_summary` rows from the live
-- review/vote data — raw-SQL seeds bypass Magento's aggregate().
--
-- Partner safety: TGS- SKUs are SG-only, and every statement is additionally
-- gated on @sg (store_id 1 = 'singapore'), which is false on partner servers —
-- the whole file no-ops there. Each `@rid` is derived from ROW_COUNT() so a
-- skipped seed can never attach detail/votes to an unrelated review. The
-- NOT EXISTS guards key on nickname + title so a reviewer who already has a
-- different review on this course is still seeded. Idempotent.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

-- ═══ Review 1 — Norsyafila Binte Abdullah ═══════════════════════════════
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-08-22 12:00:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg = 1
  AND e.sku = 'TGS-2026064475'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Norsyafila Binte Abdullah'
        AND d.title = 'Insightful and knowledgeable trainer'
        AND r.entity_pk_value = e.entity_id
  );
SET @rid1 := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid1, 1,
       'Insightful and knowledgeable trainer',
       'I had the opportunity to attend Dr Alvin Ang''s R Tidyverse Data Analytics and Visualization training, and I found him to be a very insightful and knowledgeable trainer. What I appreciated most was how he connected the technical concepts with practical, real-world applications. He went beyond simply teaching R and the Tidyverse tools, and shared valuable insights into how data analytics is actually applied in the industry. As someone who is relatively new to the data analytics field, I found his industry perspectives especially valuable. He gives practical perspectives on the skills, expectations, and continuous learning needed to progress in this field. He also took the time to share additional learning resources and introduce me to a social network of data scientists, giving me opportunities to continue learning even after the training has ended. Overall, I found Dr Alvin to be an engaging, practical, and supportive trainer with strong industry knowledge.',
       'Norsyafila Binte Abdullah', NULL
FROM dual WHERE @rid1 > 0;
INSERT INTO review_store (review_id, store_id)
SELECT @rid1, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid1 > 0
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ═══ Review 2 — Anthony John Louis ══════════════════════════════════════
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2025-04-14 12:00:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg = 1
  AND e.sku = 'TGS-2026064475'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Anthony John Louis'
        AND d.title = 'A luminary in the field of data science'
        AND r.entity_pk_value = e.entity_id
  );
SET @rid2 := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid2, 1,
       'A luminary in the field of data science',
       'Few can claim to know such a luminary in the field of data science as Dr Alvin Ang. Our correspondence has led me to realize the sheer breadth and depth of the field of data science. Only a true expert like Dr Ang could have revealed to me through his advocacy, teaching, publications, and real world experience how diverse the field truly is. From the very start I was star-struck, first by his academic achievements — a doctorate in Operations Research, a master''s in Logistics and a bachelor''s in Engineering, all from the world renowned Nanyang Technological University — and then by his experience in industry as well as in academia as a lecturer, trainer, consultant and analyst. He continues to impress and inspire me with his achievements. I highly recommend Dr Ang as the most reputable data scientist that I have been fortunate to know.',
       'Anthony John Louis', NULL
FROM dual WHERE @rid2 > 0;
INSERT INTO review_store (review_id, store_id)
SELECT @rid2, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid2 > 0
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ═══ 5-star votes on every rating question, for both reviews ════════════
INSERT INTO rating_option_vote
    (option_id, remote_ip, remote_ip_long, customer_id, entity_pk_value, rating_id, review_id, percent, value)
SELECT ro.option_id, '', 0, NULL, r.entity_pk_value, ro.rating_id, r.review_id, 100, 5
FROM review r
JOIN review_detail d ON d.review_id = r.review_id
JOIN catalog_product_entity e ON e.entity_id = r.entity_pk_value AND e.sku = 'TGS-2026064475'
JOIN rating rt ON rt.entity_id = (SELECT entity_id FROM review_entity WHERE entity_code = 'product')
JOIN rating_option ro ON ro.rating_id = rt.rating_id AND ro.value = 5
WHERE @sg = 1
  AND r.is_featured = 1
  AND ((d.nickname = 'Norsyafila Binte Abdullah' AND d.title = 'Insightful and knowledgeable trainer')
    OR (d.nickname = 'Anthony John Louis'        AND d.title = 'A luminary in the field of data science'))
  AND NOT EXISTS (
      SELECT 1 FROM rating_option_vote v
      WHERE v.review_id = r.review_id AND v.rating_id = ro.rating_id
  );

-- ═══ Rebuild the product-page star summary for this course ══════════════
-- reviews_count = all approved reviews; rating_summary = avg vote percent
-- across those reviews (reviews with no votes are ignored by AVG).
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026064475');
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
