-- 801: Add the Skills Framework section (TSC Title + TSC Code) to
-- TGS-2025056988 "WSQ - Agentic AI for Digital Marketing", whose
-- short_description had no Skills Framework block, so the storefront
-- "Skills Framework" card (TSC Title / TSC Code) never rendered.
--
--   TSC Title : Digital Marketing-5
--   TSC Code  : WST-SNM-5042-1.1
--
-- Third non-ICT framework (after 799 Human Resource, 800 Retail). The code
-- is WST-*, which this site already words as "under Wholesale Trade Skills
-- Framework" (3 existing courses carry that exact phrasing), so the trailing
-- framework name follows suit rather than defaulting to ICT.
--
-- Note the second segment is SNM, same as the ICT-SNM-* codes in migrations
-- 795/797 -- but the FRAMEWORK is determined by the FIRST segment (WST), not
-- the second. ICT-SNM-* is ICT; WST-SNM-* is Wholesale Trade.
--
-- Same shape as migrations 789-800: the product-view template derives the
-- card from this section by regex (app/design/frontend/ultimo/default/
-- template/catalog/product/view.phtml, "Skills Framework" extraction
-- ~line 362).
--
-- Guarded: appends only while 'Skills Framework' is absent from the row, so
-- re-runs are no-ops and an existing/edited section is never overwritten.
-- Partner-safe: keyed on a TGS- SKU, which only exists on SG; on MY/GH the
-- variable resolves to NULL and every statement matches zero rows.

SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025056988');

UPDATE catalog_product_entity_text
SET value = CONCAT(value, '\n', '<h2>Skills Framework</h2>
<p>This course follows the guideline of&nbsp;<strong>Digital Marketing-5 WST-SNM-5042-1.1 TSC</strong> under Wholesale Trade Skills Framework</p>')
WHERE entity_id = @e
  AND @e IS NOT NULL
  AND @a_sdesc IS NOT NULL
  AND attribute_id = @a_sdesc
  AND value NOT LIKE '%Skills Framework%';
