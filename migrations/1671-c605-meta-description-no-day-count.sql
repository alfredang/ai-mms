-- C605: meta_description written by 1669 stated a day count ("in this 2-day masterclass").
-- Non-WSQ conversions never state a day count in meta_description (it feeds <meta>,
-- og:description and JSON-LD); the Duration/Sessions tiles carry it. SG-only, idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C605' LIMIT 1);
SET @a_mdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');

UPDATE catalog_product_entity_varchar
   SET value = 'Learn semiconductor device physics, process modules, manufacturing process flows, layout and design rules, and solve process integration, yield and reliability issues in this hands-on masterclass at Tertiary Courses Singapore.'
 WHERE @sg = 1 AND entity_id = @pid AND attribute_id = @a_mdesc AND store_id = 0;
