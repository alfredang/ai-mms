-- List "Github Foundations Certification Training" (C385) under Microsoft
-- certification instead of Linux certification (GitHub is a Microsoft product).
-- Removes it from "Linux Foundation Certification Exam Prep" and adds it to
-- "Microsoft Certification Exam Prep". Categories resolved by NAME so it is
-- partner-safe (ids differ per site). Keeps its Git & GitHub / DevOps / GitHub
-- Certification Prep categories. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C385');

DELETE cp FROM catalog_category_product cp
JOIN catalog_category_entity_varchar v ON v.entity_id=cp.category_id AND v.store_id=0
JOIN eav_attribute ca ON ca.attribute_id=v.attribute_id AND ca.entity_type_id=3 AND ca.attribute_code='name'
WHERE cp.product_id=@e AND v.value IN ('Linux Foundation Certification Exam Prep', 'Linux Foundation Cert Prep');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT v.entity_id, @e, 0 FROM catalog_category_entity_varchar v
JOIN eav_attribute ca ON ca.attribute_id=v.attribute_id AND ca.entity_type_id=3 AND ca.attribute_code='name'
WHERE v.store_id=0 AND v.value='Microsoft Certification Exam Prep' AND @e IS NOT NULL;
