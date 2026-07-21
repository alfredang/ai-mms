-- Disable the top-level "Bootcamp" category (entity_id 321, path 1/2/321).
--
-- Sets is_active = 0 and include_in_menu = 0 at the default scope (store_id 0)
-- and flips any per-store override rows off too, so the category disappears
-- from the storefront and the main nav on every store. Idempotent.
--
-- Because flat category catalog is enabled, run the "Category Flat Data" +
-- "Catalog URL Rewrites" indexers and flush cache after deploy for the change
-- to show on the storefront.

SET @is_active_attr := (
  SELECT attribute_id FROM eav_attribute
  WHERE entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_category')
    AND attribute_code = 'is_active'
);
SET @include_in_menu_attr := (
  SELECT attribute_id FROM eav_attribute
  WHERE entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_category')
    AND attribute_code = 'include_in_menu'
);
SET @cat_entity_type := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_category');

-- Default scope (store_id 0): ensure rows exist and are disabled.
INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @cat_entity_type, @is_active_attr, 0, 321, 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @cat_entity_type, @include_in_menu_attr, 0, 321, 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Flip any per-store override rows off as well.
UPDATE catalog_category_entity_int
SET value = 0
WHERE entity_id = 321
  AND attribute_id IN (@is_active_attr, @include_in_menu_attr);
