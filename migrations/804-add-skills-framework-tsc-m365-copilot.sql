-- 804: Add the Skills Framework section (TSC Title + TSC Code) to
-- TGS-2024049182 "WSQ - Driving Digital Transformation with Microsoft 365
-- Copilot for Organizations", whose short_description had no Skills
-- Framework SECTION, so the storefront "Skills Framework" card
-- (TSC Title / TSC Code) never rendered.
--
--   TSC Title : Digital Technology Adoption and Innovation-4
--   TSC Code  : ACC-ICT-4004-1.1
--
-- ACC-ICT-* maps to "under Accounting Skills Framework" -- verified against
-- every existing ACC-ICT-* course, all of which use that phrasing.
--
-- Spelling note: the catalogue also contains two TYPO variants on other ACC-*
-- courses ("Accountacy" x1, "Accountacny" x1) alongside the correct
-- "Accounting" (x9). This migration uses the correct majority spelling; the
-- two typo rows are pre-existing and out of scope here.
--
-- Guard is HEADING-based, not phrase-based. A phrase guard
-- ("value NOT LIKE '%Skills Framework%'") silently no-ops on any course
-- whose OpenCerts bullet ends "...in the above Skills Framework" while
-- having no section -- the false-negative class that hid this course from
-- the batch's original survey. See migration 803 and memory
-- feedback_skills_framework_detect_by_heading_not_phrase.
--
-- Same rendering contract as migrations 789-803: the product-view template
-- derives the card from this section by regex (app/design/frontend/ultimo/
-- default/template/catalog/product/view.phtml, "Skills Framework" extraction
-- ~line 362).
--
-- Partner-safe: keyed on a TGS- SKU, which only exists on SG; on MY/GH the
-- variable resolves to NULL and every statement matches zero rows.

SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024049182');

UPDATE catalog_product_entity_text
SET value = CONCAT(value, '\n', '<h2>Skills Framework</h2>
<p>This course follows the guideline of&nbsp;<strong>Digital Technology Adoption and Innovation-4 ACC-ICT-4004-1.1 TSC</strong> under Accounting Skills Framework</p>')
WHERE entity_id = @e
  AND @e IS NOT NULL
  AND @a_sdesc IS NOT NULL
  AND attribute_id = @a_sdesc
  AND value NOT REGEXP '<h2>[[:space:]]*Skills[[:space:]]*Framework';
