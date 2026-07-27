-- 815: Add the Skills Framework section (TSC Title + TSC Code) to
-- TGS-2024048313 "WSQ - Native Android Apps Development with Java and Vibe
-- Coding", whose short_description had no Skills Framework SECTION, so the
-- storefront "Skills Framework" card (TSC Title / TSC Code) never rendered.
--
--   TSC Title : Software Design-4
--   TSC Code  : ICT-DES-4005-1.1
--
-- Level-4 sibling of migrations 798 (AI Vibe Coding with C#) and 813 (Native
-- iOS with C++), both Software Design-3 / ICT-DES-3005-1.1. Same competency
-- family, one level up -- supplied per-course, not inferred.
--
-- Closes the last of the three gaps migration 743 left open by design (743
-- added Brochure / Certification / WSQ Funding to this course but omitted
-- Skills Framework, "TSC codes not on file"). 743's OpenCerts bullet is also
-- why this course escaped the batch's original phrase-based survey -- it
-- contains the words "Skills Framework" without a section. The guard below
-- is HEADING-based accordingly. See migration 803 and memory
-- feedback_skills_framework_detect_by_heading_not_phrase.
--
-- Same rendering contract as migrations 789-814: the product-view template
-- derives the card from this section by regex (app/design/frontend/ultimo/
-- default/template/catalog/product/view.phtml, "Skills Framework" extraction
-- ~line 362).
--
-- Partner-safe: keyed on a TGS- SKU, which only exists on SG; on MY/GH the
-- variable resolves to NULL and every statement matches zero rows.

SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024048313');

UPDATE catalog_product_entity_text
SET value = CONCAT(value, '\n', '<h2>Skills Framework</h2>
<p>This course follows the guideline of&nbsp;<strong>Software Design-4 ICT-DES-4005-1.1 TSC</strong> under ICT Skills Framework</p>')
WHERE entity_id = @e
  AND @e IS NOT NULL
  AND @a_sdesc IS NOT NULL
  AND attribute_id = @a_sdesc
  AND value NOT REGEXP '<h2>[[:space:]]*Skills[[:space:]]*Framework';
