-- 813: Add the Skills Framework section (TSC Title + TSC Code) to
-- TGS-2023037545 "WSQ - Native iOS Apps Development with C++ and Vibe
-- Coding", whose short_description had no Skills Framework SECTION, so the
-- storefront "Skills Framework" card (TSC Title / TSC Code) never rendered.
--
--   TSC Title : Software Design-3
--   TSC Code  : ICT-DES-3005-1.1
--
-- Closes a gap migration 743 left open by design: 743 added the Course
-- Brochure / Certification / WSQ Funding sections to this course but
-- explicitly omitted Skills Framework ("TSC codes not on file"). The code is
-- now on file, so the section can be added.
--
-- 743 is also WHY this course escaped the batch's original survey: the
-- OpenCerts bullet it added ends "...in the above Skills Framework", so a
-- phrase-based check saw the words and reported the course as covered while
-- it rendered no card. The guard below is HEADING-based accordingly. See
-- migration 803 and memory
-- feedback_skills_framework_detect_by_heading_not_phrase.
--
-- Same TSC as migration 798 (AI Vibe Coding with C#) -- both are software
-- design courses; shared TSCs across courses are normal.
--
-- Same rendering contract as migrations 789-812: the product-view template
-- derives the card from this section by regex (app/design/frontend/ultimo/
-- default/template/catalog/product/view.phtml, "Skills Framework" extraction
-- ~line 362).
--
-- Partner-safe: keyed on a TGS- SKU, which only exists on SG; on MY/GH the
-- variable resolves to NULL and every statement matches zero rows.

SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023037545');

UPDATE catalog_product_entity_text
SET value = CONCAT(value, '\n', '<h2>Skills Framework</h2>
<p>This course follows the guideline of&nbsp;<strong>Software Design-3 ICT-DES-3005-1.1 TSC</strong> under ICT Skills Framework</p>')
WHERE entity_id = @e
  AND @e IS NOT NULL
  AND @a_sdesc IS NOT NULL
  AND attribute_id = @a_sdesc
  AND value NOT REGEXP '<h2>[[:space:]]*Skills[[:space:]]*Framework';
