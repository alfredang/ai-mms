-- 816: Add the Skills Framework section (TSC Title + TSC Code) to
-- TGS-2024049214 "WSQ - CompTIA Certified Cloud+ Training", whose
-- short_description had no Skills Framework SECTION, so the storefront
-- "Skills Framework" card (TSC Title / TSC Code) never rendered.
--
--   TSC Title : Cloud Computing-5
--   TSC Code  : ICT-DIT-5020-1.1
--
-- Last WSQ course in this batch. ICT-DIT-* maps to "under ICT Skills
-- Framework" (the batch's most common framework).
--
-- Note: this is a vendor-certification course (CompTIA). Its per-course
-- cms_block `course_<sku>_certification` may carry a "Certification Exam at
-- Pearson Vue" supplement, which the product-view template appends to the
-- certification card -- that is a SEPARATE card from Skills Framework and is
-- unaffected by this migration.
--
-- Guard is HEADING-based, not phrase-based -- a phrase guard silently
-- no-ops on any course whose OpenCerts bullet ends "...in the above Skills
-- Framework" while having no section. See migration 803 and memory
-- feedback_skills_framework_detect_by_heading_not_phrase.
--
-- Same rendering contract as migrations 789-815: the product-view template
-- derives the card from this section by regex (app/design/frontend/ultimo/
-- default/template/catalog/product/view.phtml, "Skills Framework" extraction
-- ~line 362).
--
-- Partner-safe: keyed on a TGS- SKU, which only exists on SG; on MY/GH the
-- variable resolves to NULL and every statement matches zero rows.

SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024049214');

UPDATE catalog_product_entity_text
SET value = CONCAT(value, '\n', '<h2>Skills Framework</h2>
<p>This course follows the guideline of&nbsp;<strong>Cloud Computing-5 ICT-DIT-5020-1.1 TSC</strong> under ICT Skills Framework</p>')
WHERE entity_id = @e
  AND @e IS NOT NULL
  AND @a_sdesc IS NOT NULL
  AND attribute_id = @a_sdesc
  AND value NOT REGEXP '<h2>[[:space:]]*Skills[[:space:]]*Framework';
