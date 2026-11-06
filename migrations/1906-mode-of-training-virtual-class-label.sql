-- 1906: SG Mode of Training label -> "Virtual Class by LiVE Instructor" (user directive 2026-11-06).
--
-- Replaces the three SG wordings of the online-delivery value:
--   "Synchronised Teaching using ZOOM"  (74 templates, ~1330 courses)
--   "Synchronised Training via ZOOM"    (template 303, 5 courses)
--   "Synchronised Teaching"             (template 266, 4 courses)
--
-- Two places hold the label, so both change:
--   catalog_product_option_type_title   what each course's dropdown renders today
--   custom_options_group.hash_options   the option template; a later template apply/switch copies from it
--
-- Notes for future editors:
--  * hash_options is PHP-serialized: each replacement includes the s:N: length prefix and
--    the closing quote, or the template stops unserializing.
--  * Purely a label. Class mode comes from course_runs.mode_of_training (integer), not this text.
--  * Past orders keep the wording they were placed with (snapshot in sales_flat_order_item).
--  * SG-only: MY/GH already carry their own label ("Virtual Class led by Live Instructors").
--  * Peer-safe + idempotent: only rows still holding an expected old value change.
--  * Rendered pages are cached in Redis: flush the cache after this reaches a live DB.

SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

UPDATE `catalog_product_option_type_title`
   SET `title` = 'Virtual Class by LiVE Instructor'
 WHERE @is_sg = 1
   AND `title` IN ('Synchronised Teaching using ZOOM', 'Synchronised Training via ZOOM', 'Synchronised Teaching');

UPDATE `custom_options_group`
   SET `hash_options` = REPLACE(REPLACE(REPLACE(`hash_options`,
         's:32:"Synchronised Teaching using ZOOM"', 's:32:"Virtual Class by LiVE Instructor"'),
         's:30:"Synchronised Training via ZOOM"',  's:32:"Virtual Class by LiVE Instructor"'),
         's:21:"Synchronised Teaching"',           's:32:"Virtual Class by LiVE Instructor"')
 WHERE @is_sg = 1
   AND `hash_options` LIKE '%"Synchronised T%';
