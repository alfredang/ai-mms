-- 787: Add the Skills Framework section (TSC Title + TSC Code) to
-- TGS-2021006714 "WSQ - End-to-End Creative Image Generation with Agentic AI
-- and Vibe Coding", whose short_description had no Skills Framework block, so
-- the storefront "Skills Framework" card (TSC Title / TSC Code) never rendered.
--
--   TSC Title : Computational Modelling-5
--   TSC Code  : ICT-DIT-5001-1.1
--
-- The product-view template derives the card from this section by regex
-- (app/design/frontend/ultimo/default/template/catalog/product/view.phtml,
-- "Skills Framework" extraction ~line 362), so the markup below deliberately
-- mirrors the house shape used by the other 283 WSQ courses:
--   <h2>Skills Framework</h2>
--   <p>This course follows the guideline of&nbsp;<strong>{Title} {Code} TSC</strong> under ICT Skills Framework</p>
-- The code matcher anchors on the trailing " TSC" marker, and the title is
-- whatever remains after the code and the "follows the guideline of / under /
-- Skills Framework" boilerplate are stripped.
--
-- Guarded: appends only while 'Skills Framework' is absent from the row, so
-- re-runs are no-ops and an existing/edited section is never overwritten.
-- Partner-safe: keyed on a TGS- SKU, which only exists on SG; on MY/GH the
-- variable resolves to NULL and every statement matches zero rows.

SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2021006714');

UPDATE catalog_product_entity_text
SET value = CONCAT(value, '\n', '<h2>Skills Framework</h2>
<p>This course follows the guideline of&nbsp;<strong>Computational Modelling-5 ICT-DIT-5001-1.1 TSC</strong> under ICT Skills Framework</p>')
WHERE entity_id = @e
  AND @e IS NOT NULL
  AND @a_sdesc IS NOT NULL
  AND attribute_id = @a_sdesc
  AND value NOT LIKE '%Skills Framework%';
