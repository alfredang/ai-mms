-- 1583: restore four legacy java-programming-courses 301s that the catalog_url
-- reindex after 1582 deleted.
--
-- WHY: those save-history RP rows still carried product_id + category_id = 75
-- (Java, now Rust). 1582 took the products out of cat 75, and the catalog_url
-- reindex prunes every rewrite whose (product_id, category_id) pair is no
-- longer in catalog_category_product -- RP rows included. The old URLs then 404'd.
-- Recreated with product_id/category_id NULL so no future reindex can prune
-- them, each one hop to its final destination.
--
-- SG-guarded, url_key/SKU-resolved, insert-if-absent: idempotent.

SET @is_sg := (SELECT COUNT(*) FROM core_store WHERE code = 'singapore');

SET @android := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024048313' LIMIT 1);
SET @android_url := (SELECT request_path FROM core_url_rewrite
  WHERE @is_sg > 0 AND id_path = CONCAT('product/', @android) AND store_id = 1
    AND is_system = 1 AND options IS NULL LIMIT 1);
SET @prog_url := (SELECT request_path FROM core_url_rewrite
  WHERE @is_sg > 0 AND store_id = 1 AND is_system = 1 AND options IS NULL
    AND request_path = 'programming-courses.html' LIMIT 1);

INSERT INTO core_url_rewrite (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options)
SELECT 1, NULL, NULL, CONCAT('mmd_cat_rename_', MD5(m.src)), m.src, m.dst, 0, 'RP'
FROM (SELECT 'java-programming-courses/java-programming-methodologies.html' AS src, @android_url AS dst
      UNION ALL SELECT 'java-programming-courses/wsq-java-programming-methodologies.html', @android_url
      UNION ALL SELECT 'java-programming-courses/wsq-native-android-apps-development-with-java-and-vibe-coding.html', @android_url
      UNION ALL SELECT 'adult-training-courses/computer-programming-and-infocomm-courses/programming-courses/java-programming-courses/pearson-vue-certified-it-specialist-java.html', @prog_url) m
WHERE @is_sg > 0 AND m.dst IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite) x
                  WHERE x.request_path = m.src AND x.store_id = 1);
