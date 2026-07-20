-- Disable the empty "Software Defined Networks (SDN)" category (url_key
-- software-defined-networks-courses). On SG its only C-course (C660) is disabled
-- and no product surfaces on the storefront, so the category page renders empty.
-- Sets is_active=0 + include_in_menu=0 at store 0 so it drops off the storefront
-- and the mega-menu.
--
-- PARTNER-SAFE / CONDITIONAL: only deactivates the category if it has ZERO
-- products in the STOREFRONT INDEX across all stores on THIS instance
-- (catalog_category_product_index — the table the listing actually reads). On a
-- partner site where the SDN course (e.g. M678) is live, that course IS in the
-- partner store's index, so the guard is false and this migration is a no-op
-- there — a live partner category is never blindly hidden. This is more accurate
-- than a store-0 status count: M-prefix products carry status=1 at store 0 but
-- are excluded from SG's storefront index, so the index is the true emptiness
-- test. Resolved by url_key. Idempotent. No content line ends in a semicolon.

SET @cat := (SELECT uk.entity_id FROM catalog_category_entity_varchar uk
  JOIN eav_attribute ea ON ea.attribute_id=uk.attribute_id AND ea.entity_type_id=3 AND ea.attribute_code='url_key'
  WHERE uk.store_id=0 AND uk.value='software-defined-networks-courses' LIMIT 1);

SET @a_active := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='is_active');
SET @a_menu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='include_in_menu');

-- Storefront-index product count in this category on THIS instance (any store).
SET @indexed_in_cat := (
  SELECT COUNT(*) FROM catalog_category_product_index WHERE category_id=@cat);

-- Deactivate only when the category is empty on the storefront.
UPDATE catalog_category_entity_int
SET value=0
WHERE entity_id=@cat AND store_id=0 AND attribute_id=@a_active
  AND @indexed_in_cat = 0 AND @cat IS NOT NULL;

UPDATE catalog_category_entity_int
SET value=0
WHERE entity_id=@cat AND store_id=0 AND attribute_id=@a_menu
  AND @indexed_in_cat = 0 AND @cat IS NOT NULL;
