-- 936: TGS-2025054471 ("WSQ - Autonomous AI Agents", renamed in 933) —
--      drop the two Pearson-VUE exam-prep category placements.
--
-- Migration 933 repurposed this course away from the Pearson VUE Certified IT
-- Specialist certification track to a general Autonomous AI Agents course. It
-- no longer prepares learners for a Pearson VUE exam, so it must not appear in
-- the exam-prep listings:
--
--   435 "Pearson VUE Certification Exam Prep"  (1/2/182/435)  — 19 of 20
--   402 "IT Specialists Exam Prep"             (1/2/182/435/402) — 19 of 20
--
-- Both are ~95% Pearson-VUE certification courses; leaving this course there
-- advertises an exam it no longer prepares for.
--
-- DELIBERATELY KEPT:
--   - 182 "Certification Exam Prep" — the broad parent (205 products, mixed
--     certification content, only 125 cert-titled); the course still carries a
--     WSQ Statement of Achievement, so the broad parent stays accurate.
--   - every AI / WSQ category (139, 252, 325, 292, 345, 301, 55, 15, 3) —
--     these describe the NEW content correctly.
--
-- Mirrors the delete into catalog_category_product_index so the storefront
-- listing updates without waiting on a full reindex (the index row is
-- regenerated on the next reindex either way).
--
-- Partner-safe: TGS- SKUs only exist on SG; on MY/GH @e IS NULL and every
-- statement no-ops. Idempotent — re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025054471' LIMIT 1);

DELETE FROM catalog_category_product
  WHERE @e IS NOT NULL AND product_id = @e AND category_id IN (402, 435);

DELETE FROM catalog_category_product_index
  WHERE @e IS NOT NULL AND product_id = @e AND category_id IN (402, 435);
