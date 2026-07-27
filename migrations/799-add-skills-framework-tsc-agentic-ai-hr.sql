-- 799: Add the Skills Framework section (TSC Title + TSC Code) to
-- TGS-2024045795 "WSQ - Agentic AI for HR", whose short_description had no
-- Skills Framework block, so the storefront "Skills Framework" card
-- (TSC Title / TSC Code) never rendered.
--
--   TSC Title : Human Resource Digitalisation-4
--   TSC Code  : HRS-HRM-4031-1.1
--
-- FIRST NON-ICT FRAMEWORK in this batch (789-798 were all ICT-*). The
-- trailing framework name is NOT boilerplate -- the site already carries
-- per-framework wording (ICT 142, Retail 19, Accounting 16, Built
-- Environment 12, Media 10, Human Resource 2, ...). This course's code is
-- HRS-HRM-*, so the line reads "under Human Resource Skills Framework",
-- matching the exact wording already used by the 2 existing HR courses
-- rather than mislabelling it as ICT.
--
-- The template's code regex keys off the generic uppercase-dash-digits shape
-- plus the trailing " TSC" marker, not an ICT-specific prefix, and the title
-- extraction strips "under <anything> Skills Framework" -- so a non-ICT
-- framework parses identically; verified before applying.
--
-- Same shape as migrations 789-798: the product-view template derives the
-- card from this section by regex (app/design/frontend/ultimo/default/
-- template/catalog/product/view.phtml, "Skills Framework" extraction
-- ~line 362).
--
-- Guarded: appends only while 'Skills Framework' is absent from the row, so
-- re-runs are no-ops and an existing/edited section is never overwritten.
-- Partner-safe: keyed on a TGS- SKU, which only exists on SG; on MY/GH the
-- variable resolves to NULL and every statement matches zero rows.

SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024045795');

UPDATE catalog_product_entity_text
SET value = CONCAT(value, '\n', '<h2>Skills Framework</h2>
<p>This course follows the guideline of&nbsp;<strong>Human Resource Digitalisation-4 HRS-HRM-4031-1.1 TSC</strong> under Human Resource Skills Framework</p>')
WHERE entity_id = @e
  AND @e IS NOT NULL
  AND @a_sdesc IS NOT NULL
  AND attribute_id = @a_sdesc
  AND value NOT LIKE '%Skills Framework%';
