-- 812: Add the Skills Framework section (TSC Title + TSC Code) to
-- TGS-2023035977 "WSQ - Agentic AI Automation with n8n", whose
-- short_description had no Skills Framework SECTION, so the storefront
-- "Skills Framework" card (TSC Title / TSC Code) never rendered.
--
--   TSC Title : Intelligent Reasoning-5
--   TSC Code  : ICT-ACE-5030-1.1
--
-- Back to the ICT framework after the IBF block (805-811). ICT-ACE-* is a
-- new second segment for this batch; confirmed against the 1 existing
-- ICT-ACE-* course, which uses "under ICT Skills Framework".
--
-- Guard is HEADING-based, not phrase-based -- a phrase guard silently
-- no-ops on any course whose OpenCerts bullet ends "...in the above Skills
-- Framework" while having no section. This course is one of the rows that
-- the batch's original phrase-based survey wrongly reported as covered.
-- See migration 803 and memory
-- feedback_skills_framework_detect_by_heading_not_phrase.
--
-- Same rendering contract as migrations 789-811: the product-view template
-- derives the card from this section by regex (app/design/frontend/ultimo/
-- default/template/catalog/product/view.phtml, "Skills Framework" extraction
-- ~line 362).
--
-- Partner-safe: keyed on a TGS- SKU, which only exists on SG; on MY/GH the
-- variable resolves to NULL and every statement matches zero rows.

SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023035977');

UPDATE catalog_product_entity_text
SET value = CONCAT(value, '\n', '<h2>Skills Framework</h2>
<p>This course follows the guideline of&nbsp;<strong>Intelligent Reasoning-5 ICT-ACE-5030-1.1 TSC</strong> under ICT Skills Framework</p>')
WHERE entity_id = @e
  AND @e IS NOT NULL
  AND @a_sdesc IS NOT NULL
  AND attribute_id = @a_sdesc
  AND value NOT REGEXP '<h2>[[:space:]]*Skills[[:space:]]*Framework';
