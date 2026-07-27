-- 803: Add the Skills Framework section (TSC Title + TSC Code) to
-- TGS-2023036088 "WSQ - End to End Creative Video Creation with Agentic AI
-- and Vibe Coding", whose short_description had no Skills Framework SECTION,
-- so the storefront "Skills Framework" card (TSC Title / TSC Code) never
-- rendered.
--
--   TSC Title : Video Editing-4
--   TSC Code  : MED-MPN-4005-1.1
--
-- MED-MPN-* maps to "under Media Skills Framework" (5 existing courses carry
-- that exact phrasing).
--
-- WHY THIS COURSE WAS MISSED EARLIER: the original survey for this batch
-- flagged missing cards with `short_description REGEXP 'Skills Framework'`.
-- That is a FALSE NEGATIVE for any course whose OpenCerts certification
-- bullet ends "...achieved the Competency Standard(s) in the above Skills
-- Framework" -- the bare phrase is present, but there is no
-- <h2>Skills Framework</h2> section and therefore no TSC card. Migration 743
-- added that OpenCerts bullet to this course while explicitly omitting the
-- Skills Framework section ("TSC codes not on file"), which is exactly the
-- combination that defeats the phrase-only check.
--
-- The correct detector is the HEADING, not the phrase:
--   WHERE value NOT REGEXP '<h2>[[:space:]]*Skills[[:space:]]*Framework'
-- Use that when auditing the remaining courses.
--
-- The guard below is likewise heading-based, NOT phrase-based -- a
-- phrase-based guard ("value NOT LIKE '%Skills Framework%'", as used in
-- 789-802) would match the OpenCerts bullet and silently skip this row.
--
-- Same rendering contract as migrations 789-802: the product-view template
-- derives the card from this section by regex (app/design/frontend/ultimo/
-- default/template/catalog/product/view.phtml, "Skills Framework" extraction
-- ~line 362).
--
-- Guarded: appends only while no Skills Framework HEADING exists, so re-runs
-- are no-ops and an existing/edited section is never overwritten.
-- Partner-safe: keyed on a TGS- SKU, which only exists on SG; on MY/GH the
-- variable resolves to NULL and every statement matches zero rows.

SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023036088');

UPDATE catalog_product_entity_text
SET value = CONCAT(value, '\n', '<h2>Skills Framework</h2>
<p>This course follows the guideline of&nbsp;<strong>Video Editing-4 MED-MPN-4005-1.1 TSC</strong> under Media Skills Framework</p>')
WHERE entity_id = @e
  AND @e IS NOT NULL
  AND @a_sdesc IS NOT NULL
  AND attribute_id = @a_sdesc
  AND value NOT REGEXP '<h2>[[:space:]]*Skills[[:space:]]*Framework';
