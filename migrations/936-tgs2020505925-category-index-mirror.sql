-- 936: Mirror TGS-2020505925's category placements into the category index.
--
-- Migration 934 repurposed this course (OpenCV -> Generative AI for Image and
-- Video Creation) and swapped its categories in catalog_category_product:
-- dropped Computer Vision / Robotics & IoT / Raspberry Pi / WSQ Mfg & Green,
-- added Media & Design / GenAI Video Creation / WSQ Generative AI Courses /
-- Generative AI Series / WSQ Graphics Design & Media.
--
-- catalog_category_product is the source of truth, but the STOREFRONT LISTING
-- reads catalog_category_product_index. That index is only refreshed by a full
-- "Category Products" reindex (a targeted per-product reindex does NOT pick up
-- membership changes), and a full reindex is off-limits here because it
-- scrambles anchor-only curated positions (see memory
-- feedback_full_reindex_scrambles_anchor_only_positions). So mirror the delta
-- explicitly, exactly as the category-ordering playbook does.
--
-- Without this the course is missing from its new GenAI category pages and
-- still listed on the retired computer-vision ones.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL elsewhere => no-op.
-- Idempotent - re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020505925' LIMIT 1);

-- ----------------------------------------- 1. drop the retired placements
DELETE i FROM catalog_category_product_index i
  JOIN catalog_category_entity_varchar v ON v.entity_id = i.category_id AND v.store_id = 0
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'name'
  WHERE i.product_id = @e AND @e IS NOT NULL
    AND v.value IN ('Computer Vision', 'Robotics & IoT', 'Raspberry Pi', 'WSQ Mfg & Green Courses')
    -- never touch a row the product legitimately still belongs to
    AND NOT EXISTS (
      SELECT 1 FROM catalog_category_product cp
      WHERE cp.product_id = @e AND cp.category_id = i.category_id);

-- ------------------------------------------- 2. add the new placements
-- visibility + is_parent copied from an existing index row for this product in
-- the same store, so the listing treats it identically to its other categories.
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, cp.product_id, cp.position, 0, s.store_id,
       (SELECT i2.visibility FROM catalog_category_product_index i2
         WHERE i2.product_id = @e AND i2.store_id = s.store_id LIMIT 1)
  FROM catalog_category_product cp
  CROSS JOIN core_store s
  WHERE cp.product_id = @e AND @e IS NOT NULL AND s.store_id > 0
    AND NOT EXISTS (
      SELECT 1 FROM catalog_category_product_index i3
      WHERE i3.category_id = cp.category_id
        AND i3.product_id = cp.product_id
        AND i3.store_id = s.store_id);
