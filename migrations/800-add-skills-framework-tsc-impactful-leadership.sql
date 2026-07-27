-- 800: Add the Skills Framework section (TSC Title + TSC Code) to
-- TGS-2025054484 "WSQ - Impactful Leadership Framework", whose
-- short_description had no Skills Framework block, so the storefront
-- "Skills Framework" card (TSC Title / TSC Code) never rendered.
--
--   TSC Title : Service Leadership-4
--   TSC Code  : RET-CEX-4014-1.1
--
-- Second non-ICT framework (after 799's HRS-HRM Human Resource). The code is
-- RET-*, which this site already words as "under Retail Skills Framework"
-- (19 existing courses carry that exact phrasing), so the trailing framework
-- name follows suit rather than defaulting to ICT. No existing RET-CEX-*
-- course exists to copy from, but the RET- prefix -> Retail mapping is
-- unambiguous and already established in the catalogue.
--
-- Note: the course NAME ends in "Framework" ("Impactful Leadership
-- Framework"), which is unrelated to the Skills Framework section -- the
-- section is keyed on the <h2> heading, not the product name, so there is no
-- interaction between the two.
--
-- Same shape as migrations 789-799: the product-view template derives the
-- card from this section by regex (app/design/frontend/ultimo/default/
-- template/catalog/product/view.phtml, "Skills Framework" extraction
-- ~line 362).
--
-- Guarded: appends only while 'Skills Framework' is absent from the row, so
-- re-runs are no-ops and an existing/edited section is never overwritten.
-- Partner-safe: keyed on a TGS- SKU, which only exists on SG; on MY/GH the
-- variable resolves to NULL and every statement matches zero rows.

SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025054484');

UPDATE catalog_product_entity_text
SET value = CONCAT(value, '\n', '<h2>Skills Framework</h2>
<p>This course follows the guideline of&nbsp;<strong>Service Leadership-4 RET-CEX-4014-1.1 TSC</strong> under Retail Skills Framework</p>')
WHERE entity_id = @e
  AND @e IS NOT NULL
  AND @a_sdesc IS NOT NULL
  AND attribute_id = @a_sdesc
  AND value NOT LIKE '%Skills Framework%';
