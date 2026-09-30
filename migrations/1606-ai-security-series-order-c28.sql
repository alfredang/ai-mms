-- AI Security Series (category 214): slot C28 "AI Agent Security" into alphabetical
-- order among the non-WSQ courses (funded TGS- first at 1-10, untouched):
--   11 C28 AI Agent Security, 12 C434 AI for Cyber Security, 13 C356 AI for Network
--   Security, 14 C1440 AI Security and Governance, 15 C1750 CompTIA SecAI+ Training.
-- Mirrored into catalog_category_product_index. Joined on the SG-only WSQ twin
-- TGS-2025060473 so partner sites are no-ops. Idempotent.

UPDATE catalog_category_product cp
  JOIN catalog_product_entity e ON e.entity_id = cp.product_id
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2025060473'
   SET cp.position = CASE TRIM(e.sku) WHEN 'C28' THEN 11 WHEN 'C434' THEN 12 WHEN 'C356' THEN 13
                                      WHEN 'C1440' THEN 14 WHEN 'C1750' THEN 15 END
 WHERE cp.category_id = 214 AND TRIM(e.sku) IN ('C28','C434','C356','C1440','C1750');

UPDATE catalog_category_product_index ci
  JOIN catalog_category_product cp ON cp.category_id = ci.category_id AND cp.product_id = ci.product_id
  JOIN catalog_product_entity e ON e.entity_id = ci.product_id
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2025060473'
   SET ci.position = cp.position
 WHERE ci.category_id = 214 AND TRIM(e.sku) IN ('C28','C434','C356','C1440','C1750');
