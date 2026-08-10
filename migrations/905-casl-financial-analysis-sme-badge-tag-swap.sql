-- 905: CASL funding badge for TGS-2026064860 (CASL - Financial Analysis for
-- Small and Medium Enterprises): swap this product's WSQ badge tag for the
-- canonical CASL tag (seeded by 746; re-seeded here guarded for safety).
-- Storefront chips + cover (set in 904) now both say CASL.
-- Partner-safe: TGS- SKU absent on MY/GH => @e NULL => guarded no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026064860');

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
