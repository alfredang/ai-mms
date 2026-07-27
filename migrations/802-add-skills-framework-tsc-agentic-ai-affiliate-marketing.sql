-- 802: Add the Skills Framework section (TSC Title + TSC Code) to
-- TGS-2025060552 "WSQ - Agentic AI for Affiliate Marketing", whose
-- short_description had no Skills Framework block, so the storefront
-- "Skills Framework" card (TSC Title / TSC Code) never rendered.
--
--   TSC Title : Affiliate Marketing-2
--   TSC Code  : RET-OTO-2001-1.1
--
-- Retail framework, same as migration 800 (RET-CEX). Confirmed directly:
-- 4 existing RET-OTO-* courses already carry "under Retail Skills
-- Framework", so this is an exact-prefix match rather than an inference.
--
-- First level-2 TSC in this batch (789-801 were levels 3-5). The code regex
-- is level-agnostic -- it matches the uppercase-dash-digits shape plus the
-- trailing " TSC" marker -- so -2001- parses like any other; verified before
-- applying.
--
-- Same shape as migrations 789-801: the product-view template derives the
-- card from this section by regex (app/design/frontend/ultimo/default/
-- template/catalog/product/view.phtml, "Skills Framework" extraction
-- ~line 362).
--
-- Guarded: appends only while 'Skills Framework' is absent from the row, so
-- re-runs are no-ops and an existing/edited section is never overwritten.
-- Partner-safe: keyed on a TGS- SKU, which only exists on SG; on MY/GH the
-- variable resolves to NULL and every statement matches zero rows.

SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025060552');

UPDATE catalog_product_entity_text
SET value = CONCAT(value, '\n', '<h2>Skills Framework</h2>
<p>This course follows the guideline of&nbsp;<strong>Affiliate Marketing-2 RET-OTO-2001-1.1 TSC</strong> under Retail Skills Framework</p>')
WHERE entity_id = @e
  AND @e IS NOT NULL
  AND @a_sdesc IS NOT NULL
  AND attribute_id = @a_sdesc
  AND value NOT LIKE '%Skills Framework%';
