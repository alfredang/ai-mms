-- 746: CASL funding badge for TGS-2026065050 (CASL - Generative AI for
-- Finance and Fintech): seed the canonical 'CASL' tag and swap this
-- product's WSQ badge tag for CASL. Pairs with the code change adding
-- 'CASL' to MMD_CourseImage getAllBadges()/getBadgeCssClass() + the
-- .course-badge--casl CSS pill.
-- Partner-safe: TGS- SKU absent on MY/GH => @e NULL => guarded no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026065050');

INSERT INTO tag (name, status, first_store_id)
  SELECT 'CASL', 1, 1 FROM dual
  WHERE NOT EXISTS (SELECT 1 FROM tag WHERE name = 'CASL');

SET @casl := (SELECT tag_id FROM tag WHERE name = 'CASL' LIMIT 1);
SET @wsq  := (SELECT tag_id FROM tag WHERE name = 'WSQ' LIMIT 1);

INSERT INTO tag_relation (tag_id, customer_id, product_id, store_id, active, created_at)
  SELECT @casl, NULL, @e, 1, 1, NOW() FROM dual
  WHERE @e IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM tag_relation WHERE tag_id = @casl AND product_id = @e);

DELETE FROM tag_relation WHERE tag_id = @wsq AND product_id = @e AND @e IS NOT NULL;

-- Fresh cover rendered with the CASL chip replacing WSQ
SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026065050-20260722-175427.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;
