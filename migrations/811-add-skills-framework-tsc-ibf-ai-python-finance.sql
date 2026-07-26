-- 811: Add the Skills Framework section (TSC Title + TSC Code) to
-- TGS-2025052659 "IBF - AI Assisted Python Programming for Finance", whose
-- short_description had no Skills Framework SECTION, so the storefront
-- "Skills Framework" card (TSC Title / TSC Code) never rendered.
--
--   TSC Title : Programming and Coding-3
--   TSC Code  : FSE-DIT-3018-1.1
--
-- Seventh and final IBF course in this batch (805-811). NOTE: this is the
-- SAME TSC as migration 806 (IBF - Blockchain Smart Contract Programming) --
-- expected, since both are programming courses mapping to the same
-- competency. Shared TSCs across courses are normal (cf. 790/791) and not a
-- copy-paste error.
--
-- FSE-* maps to "under Financial Services Skills Framework", confirmed
-- rendering live on an existing FSE-* page.
--
-- Guard is HEADING-based, not phrase-based -- a phrase guard silently
-- no-ops on any course whose OpenCerts bullet ends "...in the above Skills
-- Framework" while having no section. See migration 803 and memory
-- feedback_skills_framework_detect_by_heading_not_phrase.
--
-- Same rendering contract as migrations 789-810: the product-view template
-- derives the card from this section by regex (app/design/frontend/ultimo/
-- default/template/catalog/product/view.phtml, "Skills Framework" extraction
-- ~line 362).
--
-- Partner-safe: keyed on a TGS- SKU, which only exists on SG; on MY/GH the
-- variable resolves to NULL and every statement matches zero rows.

SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025052659');

UPDATE catalog_product_entity_text
SET value = CONCAT(value, '\n', '<h2>Skills Framework</h2>
<p>This course follows the guideline of&nbsp;<strong>Programming and Coding-3 FSE-DIT-3018-1.1 TSC</strong> under Financial Services Skills Framework</p>')
WHERE entity_id = @e
  AND @e IS NOT NULL
  AND @a_sdesc IS NOT NULL
  AND attribute_id = @a_sdesc
  AND value NOT REGEXP '<h2>[[:space:]]*Skills[[:space:]]*Framework';
