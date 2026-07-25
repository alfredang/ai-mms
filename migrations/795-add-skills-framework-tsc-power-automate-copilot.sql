-- 795: Add the Skills Framework section (TSC Title + TSC Code) to
-- TGS-2022017524 "WSQ - Business Process Automation with Power Automate and
-- Copilot Studio Agents", whose short_description had no Skills Framework
-- block, so the storefront "Skills Framework" card (TSC Title / TSC Code)
-- never rendered.
--
--   TSC Title : Content Strategy-4
--   TSC Code  : ICT-SNM-4004-1.1
--
-- First ICT-SNM-* code in this batch (789-794 were all ICT-DIT-*). The
-- template's code regex keys off the generic uppercase-dash-digits shape
-- plus the trailing " TSC" marker, not a DIT-specific prefix, so SNM parses
-- identically; verified before applying.
--
-- Same shape as migrations 789-794: the product-view template derives the
-- card from this section by regex (app/design/frontend/ultimo/default/
-- template/catalog/product/view.phtml, "Skills Framework" extraction
-- ~line 362), so the markup mirrors the house form used by other WSQ courses:
--   <h2>Skills Framework</h2>
--   <p>This course follows the guideline of&nbsp;<strong>{Title} {Code} TSC</strong> under ICT Skills Framework</p>
--
-- Guarded: appends only while 'Skills Framework' is absent from the row, so
-- re-runs are no-ops and an existing/edited section is never overwritten.
-- Partner-safe: keyed on a TGS- SKU, which only exists on SG; on MY/GH the
-- variable resolves to NULL and every statement matches zero rows.

SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2022017524');

UPDATE catalog_product_entity_text
SET value = CONCAT(value, '\n', '<h2>Skills Framework</h2>
<p>This course follows the guideline of&nbsp;<strong>Content Strategy-4 ICT-SNM-4004-1.1 TSC</strong> under ICT Skills Framework</p>')
WHERE entity_id = @e
  AND @e IS NOT NULL
  AND @a_sdesc IS NOT NULL
  AND attribute_id = @a_sdesc
  AND value NOT LIKE '%Skills Framework%';
