-- 1287: Mirror the sort fix from 1286 into the per-store category flat tables,
-- and make 'position' an ALLOWED sort option on those categories.
--
-- 1286 set default_sort_by='position' in EAV for the six WSQ parent categories,
-- but the storefront reads catalog_category_flat_store_N, which still held
-- 'sku' — so WSQ IT & Security, Finance & Accounting, Media & Marketing, Soft
-- Skill & Business, Funded Courses and Mfg & Green kept sorting by SKU and kept
-- ignoring every pinned position. (Quality Assurance and Semiconductor looked
-- correct only because their flat rows were already NULL.)
--
-- There is deliberately NO reindex here: a full catalog reindex re-derives
-- anchor-only index rows and would undo the curated positions from 1264-1286.
-- Writing flat directly is the safe route.
--
-- TWO attributes matter, not one. Even with default_sort_by='position',
-- Magento falls back to the first AVAILABLE option when 'position' is not in
-- available_sort_by — these categories carry 'name,sku', which is why a
-- default_sort_by-only fix still produced an alphabetical listing (observed on
-- localhost after 1286). So set available_sort_by to include position, in EAV
-- (store 0) and in flat.
--
-- HARD RULE observed: never name a bare/absent flat table — which flat tables
-- exist differs per instance, and a missing one aborts apply.php and 502s every
-- route. Every statement is guarded via information_schema, so this is a clean
-- no-op on an instance lacking the table or the column.

SET @a_dsb := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'default_sort_by');

DROP TEMPORARY TABLE IF EXISTS tmp_dsb_cats;
CREATE TEMPORARY TABLE tmp_dsb_cats (entity_id INT PRIMARY KEY);
INSERT IGNORE INTO tmp_dsb_cats (entity_id)
SELECT uk.entity_id FROM catalog_category_entity_varchar uk
JOIN eav_attribute a ON a.attribute_id = uk.attribute_id
 AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
WHERE uk.store_id = 0 AND uk.value IN (
  'wsq-it-security-courses','wsq-finance-accounting-courses',
  'wsq-media-marketing-courses',
  'wsq-soft-skill-and-critical-core-skill-project-management-courses',
  'wsq-ibf-skillsfuture-utap-funded-courses','wsq-finance-mfg-green-courses');

-- Make 'position' selectable (EAV, store 0). Only touches rows that exist and
-- currently omit position; a category with no row inherits the config default.
SET @a_asb := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'available_sort_by');

UPDATE catalog_category_entity_varchar v
JOIN tmp_dsb_cats t ON t.entity_id = v.entity_id
SET v.value = CONCAT('position,', v.value)
WHERE v.attribute_id = @a_asb
  AND v.value IS NOT NULL AND v.value <> ''
  AND FIND_IN_SET('position', v.value) = 0;

-- store 1
SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1'
      AND COLUMN_NAME='default_sort_by') > 0,
  "UPDATE catalog_category_flat_store_1 f JOIN tmp_dsb_cats t ON t.entity_id=f.entity_id
     SET f.default_sort_by='position',
         f.available_sort_by = IF(f.available_sort_by IS NULL OR f.available_sort_by='' OR FIND_IN_SET('position', f.available_sort_by)>0,
                                  f.available_sort_by, CONCAT('position,', f.available_sort_by))
   WHERE f.default_sort_by <> 'position' OR FIND_IN_SET('position', COALESCE(f.available_sort_by,'position'))=0", 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- store 2
SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2'
      AND COLUMN_NAME='default_sort_by') > 0,
  "UPDATE catalog_category_flat_store_2 f JOIN tmp_dsb_cats t ON t.entity_id=f.entity_id
     SET f.default_sort_by='position',
         f.available_sort_by = IF(f.available_sort_by IS NULL OR f.available_sort_by='' OR FIND_IN_SET('position', f.available_sort_by)>0,
                                  f.available_sort_by, CONCAT('position,', f.available_sort_by))
   WHERE f.default_sort_by <> 'position' OR FIND_IN_SET('position', COALESCE(f.available_sort_by,'position'))=0", 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- store 3
SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3'
      AND COLUMN_NAME='default_sort_by') > 0,
  "UPDATE catalog_category_flat_store_3 f JOIN tmp_dsb_cats t ON t.entity_id=f.entity_id
     SET f.default_sort_by='position',
         f.available_sort_by = IF(f.available_sort_by IS NULL OR f.available_sort_by='' OR FIND_IN_SET('position', f.available_sort_by)>0,
                                  f.available_sort_by, CONCAT('position,', f.available_sort_by))
   WHERE f.default_sort_by <> 'position' OR FIND_IN_SET('position', COALESCE(f.available_sort_by,'position'))=0", 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

DROP TEMPORARY TABLE IF EXISTS tmp_dsb_cats;
