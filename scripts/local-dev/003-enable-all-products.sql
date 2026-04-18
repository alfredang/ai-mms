-- Enable all products so every course shows on the storefront.
-- Production had ~441 products disabled (discontinued/archived); for local
-- development we want all courses visible.

UPDATE catalog_product_entity_int cpei
JOIN eav_attribute ea ON cpei.attribute_id = ea.attribute_id
SET cpei.value = 1
WHERE ea.attribute_code = 'status' AND ea.entity_type_id = 4 AND cpei.value = 2;
