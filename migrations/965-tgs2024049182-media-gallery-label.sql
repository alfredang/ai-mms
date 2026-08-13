-- 964: TGS-2024049182 media-gallery alt text follow-up to 961.
-- 961 updated image_label / small_image_label / thumbnail_label but NOT the
-- media-gallery row's own `label`, which is what the product page actually
-- renders as the cover's alt attribute -- so the repurposed page still carried
-- alt="WSQ - Driving Digital Transformation with Microsoft 365 Copilot ...".
-- Plain title (no "WSQ - " prefix): the cover itself strips the segment prefix
-- (CourseImage/Model/Cover.php::cleanTitle), so the alt text matches the image.
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024049182' LIMIT 1);

UPDATE catalog_product_entity_media_gallery_value v
  JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
   SET v.label = 'Business Transformation with Agentic AI and AI Agents'
 WHERE g.entity_id = @e
   AND @e IS NOT NULL
   AND v.label LIKE '%Microsoft 365 Copilot%';
