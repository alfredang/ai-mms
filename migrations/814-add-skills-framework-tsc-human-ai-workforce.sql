-- 814: Add the Skills Framework section (TSC Title + TSC Code) to
-- TGS-2024043854 (the "Build a Human-AI Workforce with Autonomous AI Agents"
-- WSQ course), whose short_description had no Skills Framework SECTION, so
-- the storefront "Skills Framework" card (TSC Title / TSC Code) never
-- rendered.
--
--   TSC Title : Artificial Intelligence Application in Product Development-4
--   TSC Code  : ICT-TEM-4034-1.1
--
-- ICT-TEM-* maps to "under ICT Skills Framework", confirmed against the 5
-- existing ICT-TEM-* courses.
--
-- ENCODING NOTE: the product NAME contains a U+2013 EN DASH ("Human-AI" is
-- really "Human\xE2\x80\x93AI"). This file deliberately spells the course
-- name with a plain ASCII hyphen in comments and never references the name
-- in SQL -- the row is keyed by SKU. apply.php connects with charset=utf8
-- and ABORTS THE WHOLE CHAIN on a bad byte (real outage 2026-06-05, memory
-- feedback_migration_applyphp_utf8_outage), so every migration in this batch
-- is kept pure ASCII. The product name itself is untouched and keeps its
-- en dash (memory feedback_product_name_is_sacred).
--
-- The TSC title/code inserted below are pure ASCII.
--
-- Guard is HEADING-based, not phrase-based -- a phrase guard silently
-- no-ops on any course whose OpenCerts bullet ends "...in the above Skills
-- Framework" while having no section. See migration 803 and memory
-- feedback_skills_framework_detect_by_heading_not_phrase.
--
-- Same rendering contract as migrations 789-813: the product-view template
-- derives the card from this section by regex (app/design/frontend/ultimo/
-- default/template/catalog/product/view.phtml, "Skills Framework" extraction
-- ~line 362).
--
-- Partner-safe: keyed on a TGS- SKU, which only exists on SG; on MY/GH the
-- variable resolves to NULL and every statement matches zero rows.

SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024043854');

UPDATE catalog_product_entity_text
SET value = CONCAT(value, '\n', '<h2>Skills Framework</h2>
<p>This course follows the guideline of&nbsp;<strong>Artificial Intelligence Application in Product Development-4 ICT-TEM-4034-1.1 TSC</strong> under ICT Skills Framework</p>')
WHERE entity_id = @e
  AND @e IS NOT NULL
  AND @a_sdesc IS NOT NULL
  AND attribute_id = @a_sdesc
  AND value NOT REGEXP '<h2>[[:space:]]*Skills[[:space:]]*Framework';
