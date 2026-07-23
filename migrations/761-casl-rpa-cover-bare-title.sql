-- 761: Corrected cover for TGS-2026064721 (CASL - Robotics Process Automation
-- (RPA) for Beginners). The 753 cover baked the "CASL - " prefix into the
-- rendered title; house style (see TGS-2026065050 / TGS-2026064862 covers) is
-- the bare course title with the CASL chip carrying the branding. Re-rendered
-- and re-uploaded to R2; this repoints course_image_url.
-- Partner-safe: TGS- SKU absent on MY/GH => @e NULL => guarded no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026064721');
SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026064721-20260722-182012.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;
