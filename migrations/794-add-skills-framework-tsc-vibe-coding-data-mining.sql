-- 794: Add the Skills Framework section (TSC Title + TSC Code) to
-- TGS-2022014977 "WSQ - AI Vibe Coding for Data Mining", whose
-- short_description had no Skills Framework block, so the storefront
-- "Skills Framework" card (TSC Title / TSC Code) never rendered.
--
--   TSC Title : Text Analytics and Processing-4
--   TSC Code  : ICT-DIT-4029-1.1
--
-- Note: the Vibe Coding siblings do NOT share one TSC. So far:
--   790/791 Computational Modelling-3     ICT-DIT-3001-1.1 (Python, Multi Agents)
--   792     Pattern Recognition Sys-4     ICT-DIT-4026-1.1 (Machine Learning)
--   793     Applications Development-3    ICT-DIT-3002-1.1 (React)
--   794     Text Analytics & Processing-4 ICT-DIT-4029-1.1 (Data Mining, this file)
-- Each course's TSC is supplied per-course; never inferred from a sibling.
--
-- Same shape as migrations 789-793: the product-view template derives the
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
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2022014977');

UPDATE catalog_product_entity_text
SET value = CONCAT(value, '\n', '<h2>Skills Framework</h2>
<p>This course follows the guideline of&nbsp;<strong>Text Analytics and Processing-4 ICT-DIT-4029-1.1 TSC</strong> under ICT Skills Framework</p>')
WHERE entity_id = @e
  AND @e IS NOT NULL
  AND @a_sdesc IS NOT NULL
  AND attribute_id = @a_sdesc
  AND value NOT LIKE '%Skills Framework%';
