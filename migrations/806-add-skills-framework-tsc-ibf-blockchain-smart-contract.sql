-- 806: Add the Skills Framework section (TSC Title + TSC Code) to
-- TGS-2022601875 "IBF - Blockchain Smart Contract Programming for Financial
-- Services", whose short_description had no Skills Framework SECTION, so the
-- storefront "Skills Framework" card (TSC Title / TSC Code) never rendered.
--
--   TSC Title : Programming and Coding-3
--   TSC Code  : FSE-DIT-3018-1.1
--
-- Second IBF course (after 805). FSE-* maps to "under Financial Services
-- Skills Framework" -- 5 existing FSE-* courses use that phrasing, and an
-- FSE-DIT-4018-1.1 course was confirmed rendering the card live, so IBF
-- pages are not TSC-card-exempt.
--
-- Guard is HEADING-based, not phrase-based -- a phrase guard silently
-- no-ops on any course whose OpenCerts bullet ends "...in the above Skills
-- Framework" while having no section. See migration 803 and memory
-- feedback_skills_framework_detect_by_heading_not_phrase.
--
-- Same rendering contract as migrations 789-805: the product-view template
-- derives the card from this section by regex (app/design/frontend/ultimo/
-- default/template/catalog/product/view.phtml, "Skills Framework" extraction
-- ~line 362).
--
-- Partner-safe: keyed on a TGS- SKU, which only exists on SG; on MY/GH the
-- variable resolves to NULL and every statement matches zero rows.

SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2022601875');

UPDATE catalog_product_entity_text
SET value = CONCAT(value, '\n', '<h2>Skills Framework</h2>
<p>This course follows the guideline of&nbsp;<strong>Programming and Coding-3 FSE-DIT-3018-1.1 TSC</strong> under Financial Services Skills Framework</p>')
WHERE entity_id = @e
  AND @e IS NOT NULL
  AND @a_sdesc IS NOT NULL
  AND attribute_id = @a_sdesc
  AND value NOT REGEXP '<h2>[[:space:]]*Skills[[:space:]]*Framework';
