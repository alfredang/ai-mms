-- ATC / partner-accreditation multi-select (2026-08).
--
-- Adds the `atc_partners` product attribute: a comma-separated list of
-- canonical partner-accreditation keys. Vocabulary + storefront card copy
-- live in MMD_CourseImage_Helper_Data::getAtcPartners():
--   microsoft_lp, comptia_adp, linux_foundation_atp, autodesk_atc,
--   pearson_vue_atp, pearson_vue_test_center, kryterion_atc, psi_atc
--
-- The Edit Course "ATC" checkboxes write this attribute; the storefront
-- renders one accreditation card per selected key below the course
-- description (view.phtml also strips the legacy inline "Autodesk ATC"
-- remark from short_description at render time — data untouched).
--
-- Backfill (requested 2026-08-18): select the family accreditation for all
-- Autodesk, CompTIA, Linux Foundation and Microsoft courses, matched by
-- course name keywords OR the legacy partner blurb already present in
-- short_description. Standalone Exam Voucher products are excluded.
-- Partner-safe: pure pattern matching, no SKU lists; INSERT IGNORE never
-- overwrites an existing per-course selection; only ASCII generated values
-- are inserted (no legacy bytes round-tripped).

-- ---------------------------------------------------------------------------
-- 1) Create the attribute (plain text backend — keys are code-managed).
-- ---------------------------------------------------------------------------
SET @existing_atc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='atc_partners' LIMIT 1);
INSERT INTO eav_attribute (entity_type_id, attribute_code, backend_type, backend_model, source_model, frontend_input, frontend_label, is_required, is_user_defined, is_unique, note)
SELECT 4, 'atc_partners', 'text', NULL, NULL, 'text', 'ATC Partner Accreditations', 0, 1, 0,
       'Comma-separated canonical ATC partner keys (vocabulary in MMD_CourseImage_Helper_Data::getAtcPartners()). Managed by the Edit Course ATC checkboxes; renders one accreditation card per key below the course description.'
FROM DUAL WHERE @existing_atc IS NULL;
SET @aid_atc := IFNULL(@existing_atc, LAST_INSERT_ID());

INSERT IGNORE INTO catalog_eav_attribute (attribute_id, is_global, is_visible, used_in_product_listing)
VALUES (@aid_atc, 1, 1, 0);

-- ---------------------------------------------------------------------------
-- 2) Attach to every product attribute set, under "Course Sections"
--    (group created by migration 149; same placement as assessment_methods).
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO eav_entity_attribute (entity_type_id, attribute_set_id, attribute_group_id, attribute_id, sort_order)
SELECT 4, eag.attribute_set_id, eag.attribute_group_id, @aid_atc, 55
FROM eav_attribute_group eag
JOIN eav_attribute_set eas ON eas.attribute_set_id = eag.attribute_set_id
WHERE eag.attribute_group_name = 'Course Sections' AND eas.entity_type_id = 4;

-- ---------------------------------------------------------------------------
-- 3) Backfill by partner family. One row per matched course at store 0,
--    value = comma-joined keys in canonical order (a course can match
--    several families). INSERT IGNORE keeps any pre-existing value.
-- ---------------------------------------------------------------------------
SET @attr_sd := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description' LIMIT 1);
SET @attr_nm := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name' LIMIT 1);

INSERT IGNORE INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @aid_atc, 0, x.entity_id, x.val
FROM (
    SELECT e.entity_id,
        NULLIF(CONCAT_WS(',',
            CASE WHEN nm.value LIKE '%Microsoft%'
                   OR sd.value LIKE '%Microsoft Learning Partner%'
                 THEN 'microsoft_lp' END,
            CASE WHEN nm.value LIKE '%CompTIA%'
                   OR sd.value LIKE '%CompTIA Delivery Partner%'
                   OR sd.value LIKE '%Authorised CompTIA%'
                   OR sd.value LIKE '%Authorized CompTIA%'
                 THEN 'comptia_adp' END,
            CASE WHEN nm.value LIKE '%Linux Foundation%'
                   OR nm.value LIKE '%LFCA%'
                   OR nm.value LIKE '%LFCS%'
                 THEN 'linux_foundation_atp' END,
            CASE WHEN nm.value LIKE '%AutoCAD%'
                   OR nm.value LIKE '%Autodesk%'
                   OR nm.value LIKE '%Revit%'
                   OR nm.value LIKE '%Fusion 360%'
                   OR nm.value LIKE '%3ds Max%'
                   OR nm.value LIKE '%Navisworks%'
                   OR sd.value LIKE '%Autodesk ATC%'
                   OR sd.value LIKE '%Autodesk Authori%'
                   OR sd.value LIKE '%autodesk-atc%'
                 THEN 'autodesk_atc' END
        ), '') AS val
    FROM catalog_product_entity e
    LEFT JOIN catalog_product_entity_text sd
           ON sd.entity_id = e.entity_id AND sd.attribute_id = @attr_sd AND sd.store_id = 0
    LEFT JOIN catalog_product_entity_varchar nm
           ON nm.entity_id = e.entity_id AND nm.attribute_id = @attr_nm AND nm.store_id = 0
    WHERE (nm.value IS NULL OR nm.value NOT LIKE '%Exam Voucher%')
) x
WHERE x.val IS NOT NULL;
