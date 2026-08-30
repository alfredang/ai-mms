-- 1217: AI Infrastructure Series — rename the three DevOps courses, complete
-- the category membership, and pin the requested non-WSQ order.
--
-- A) Renames (SKUs unchanged; new name, new url_key + 301, fresh branded R2
--    cover). Content is unchanged:
--      C1285 AI Devops with Docker     -> Deploy Docker with AI
--      C922  AI Devops with Jenkins    -> Deploy Jenkins with AI
--      C742  AI Devops with Kubernetes -> Deploy Kubernetes with AI
--    ("Deploy Docker wih AI" in the request is read as "with".)
--
-- B) Nine courses in the requested order were not members of this category
--    (the four AI Vibe Coding courses, AI-901, AI-103, AI-200, AWS AIF-C01,
--    AWS ML Specialty) — they are assigned here so the order is complete.
--    They keep every existing category membership.
--
-- C) Pin the requested non-WSQ order at 101..114, after every WSQ/CASL/IBF
--    course, and add 'ai-infrastructure-series' to
--    mmd/category_ordering/curated_url_keys so the sweep preserves it.
--    NOTE: the requested list ends with "DP-100 Azure Data Scientist
--    Associate Training", which no longer exists as a non-WSQ course —
--    C840 was converted to "AI for Product Development" by 1204. The WSQ
--    DP-100 course remains in this category's WSQ block, so DP-100 is still
--    represented; only the non-WSQ entry is omitted.
--
-- D) Add C1762 (AI-300) to the AI Applications Series and its AI for
--    Machine Learning subcategory.
--
-- SG-guarded; C-prefix SKUs and these url_keys are SG-only (partner no-op).
-- Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @a_pname   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_purlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_pmetat  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_pcimg   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @infra := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-infrastructure-series' LIMIT 1);
SET @apps := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-applications-series' LIMIT 1);
SET @ml := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-machine-learning' LIMIT 1);

-- ===== A: C1285 -> Deploy Docker with AI =====

SET @e_C1285 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1285' LIMIT 1);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e_C1285, 'Deploy Docker with AI' FROM dual WHERE @e_C1285 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C1285 AND attribute_id = @a_pname AND store_id <> 0 AND @e_C1285 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e_C1285, 'deploy-docker-with-ai' FROM dual WHERE @e_C1285 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C1285 AND attribute_id = @a_purlkey AND store_id <> 0 AND @e_C1285 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e_C1285, 'Deploy Docker with AI | Tertiary Courses Singapore' FROM dual WHERE @e_C1285 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e_C1285, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1285-20260830-071932.png' FROM dual WHERE @e_C1285 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM core_url_rewrite
WHERE request_path = 'ai-devops-with-docker.html' AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/c1285-301', 'ai-devops-with-docker.html', 'deploy-docker-with-ai.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e_C1285) AND store_id = 1
  AND request_path <> 'deploy-docker-with-ai.html' AND @e_C1285 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e_C1285), 'deploy-docker-with-ai.html', CONCAT('catalog/product/view/id/', @e_C1285), 1, @e_C1285
FROM dual WHERE @e_C1285 IS NOT NULL AND @is_sg > 0;

-- ===== A: C922 -> Deploy Jenkins with AI =====

SET @e_C922 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C922' LIMIT 1);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e_C922, 'Deploy Jenkins with AI' FROM dual WHERE @e_C922 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C922 AND attribute_id = @a_pname AND store_id <> 0 AND @e_C922 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e_C922, 'deploy-jenkins-with-ai' FROM dual WHERE @e_C922 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C922 AND attribute_id = @a_purlkey AND store_id <> 0 AND @e_C922 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e_C922, 'Deploy Jenkins with AI | Tertiary Courses Singapore' FROM dual WHERE @e_C922 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e_C922, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C922-20260830-071933.png' FROM dual WHERE @e_C922 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM core_url_rewrite
WHERE request_path = 'ai-devops-with-jenkins.html' AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/c922-301', 'ai-devops-with-jenkins.html', 'deploy-jenkins-with-ai.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e_C922) AND store_id = 1
  AND request_path <> 'deploy-jenkins-with-ai.html' AND @e_C922 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e_C922), 'deploy-jenkins-with-ai.html', CONCAT('catalog/product/view/id/', @e_C922), 1, @e_C922
FROM dual WHERE @e_C922 IS NOT NULL AND @is_sg > 0;

-- ===== A: C742 -> Deploy Kubernetes with AI =====

SET @e_C742 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C742' LIMIT 1);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e_C742, 'Deploy Kubernetes with AI' FROM dual WHERE @e_C742 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C742 AND attribute_id = @a_pname AND store_id <> 0 AND @e_C742 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e_C742, 'deploy-kubernetes-with-ai' FROM dual WHERE @e_C742 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C742 AND attribute_id = @a_purlkey AND store_id <> 0 AND @e_C742 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e_C742, 'Deploy Kubernetes with AI | Tertiary Courses Singapore' FROM dual WHERE @e_C742 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e_C742, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C742-20260830-071933.png' FROM dual WHERE @e_C742 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM core_url_rewrite
WHERE request_path = 'ai-devops-with-kubernetes.html' AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/c742-301', 'ai-devops-with-kubernetes.html', 'deploy-kubernetes-with-ai.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e_C742) AND store_id = 1
  AND request_path <> 'deploy-kubernetes-with-ai.html' AND @e_C742 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e_C742), 'deploy-kubernetes-with-ai.html', CONCAT('catalog/product/view/id/', @e_C742), 1, @e_C742
FROM dual WHERE @e_C742 IS NOT NULL AND @is_sg > 0;

-- ===== B: assign the nine missing courses to the AI Infrastructure Series =====

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @infra, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @infra IS NOT NULL AND @is_sg > 0
  AND p.sku IN (
    'C1071',
    'C1759',
    'C188',
    'C19',
    'C279',
    'C430',
    'C539',
    'C592',
    'C926'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @infra, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @infra IS NOT NULL AND @is_sg > 0
  AND p.sku IN (
    'C1071',
    'C1759',
    'C188',
    'C19',
    'C279',
    'C430',
    'C539',
    'C592',
    'C926'
  )
GROUP BY p.entity_id, s.store_id;

-- ===== C: curated non-WSQ order (101..114) =====

UPDATE core_config_data
SET value = CONCAT(value, ',ai-infrastructure-series')
WHERE path = 'mmd/category_ordering/curated_url_keys'
  AND scope = 'default' AND scope_id = 0
  AND value NOT LIKE '%ai-infrastructure-series%';

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C1285' THEN 101
  WHEN 'C742' THEN 102
  WHEN 'C922' THEN 103
  WHEN 'C430' THEN 104
  WHEN 'C592' THEN 105
  WHEN 'C188' THEN 106
  WHEN 'C539' THEN 107
  WHEN 'C1071' THEN 108
  WHEN 'C926' THEN 109
  WHEN 'C1759' THEN 110
  WHEN 'C1762' THEN 111
  WHEN 'C19' THEN 112
  WHEN 'C1330' THEN 113
  WHEN 'C279' THEN 114
END
WHERE cp.category_id = @infra
  AND p.sku IN (
    'C1285',
    'C742',
    'C922',
    'C430',
    'C592',
    'C188',
    'C539',
    'C1071',
    'C926',
    'C1759',
    'C1762',
    'C19',
    'C1330',
    'C279'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C1285' THEN 101
  WHEN 'C742' THEN 102
  WHEN 'C922' THEN 103
  WHEN 'C430' THEN 104
  WHEN 'C592' THEN 105
  WHEN 'C188' THEN 106
  WHEN 'C539' THEN 107
  WHEN 'C1071' THEN 108
  WHEN 'C926' THEN 109
  WHEN 'C1759' THEN 110
  WHEN 'C1762' THEN 111
  WHEN 'C19' THEN 112
  WHEN 'C1330' THEN 113
  WHEN 'C279' THEN 114
END
WHERE i.category_id = @infra
  AND p.sku IN (
    'C1285',
    'C742',
    'C922',
    'C430',
    'C592',
    'C188',
    'C539',
    'C1071',
    'C926',
    'C1759',
    'C1762',
    'C19',
    'C1330',
    'C279'
  );

-- any other non-WSQ member sorts after the pinned block
UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = 200 + cp.product_id
WHERE cp.category_id = @infra AND p.sku NOT LIKE 'TGS-%'
  AND p.sku NOT IN (
    'C1285',
    'C742',
    'C922',
    'C430',
    'C592',
    'C188',
    'C539',
    'C1071',
    'C926',
    'C1759',
    'C1762',
    'C19',
    'C1330',
    'C279'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = 200 + i.product_id
WHERE i.category_id = @infra AND p.sku NOT LIKE 'TGS-%'
  AND p.sku NOT IN (
    'C1285',
    'C742',
    'C922',
    'C430',
    'C592',
    'C188',
    'C539',
    'C1071',
    'C926',
    'C1759',
    'C1762',
    'C19',
    'C1330',
    'C279'
  );

-- ===== D: AI-300 into the AI Applications Series + AI for Machine Learning =====

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT c.id, p.entity_id, 9999
FROM catalog_product_entity p
JOIN (SELECT @apps AS id UNION ALL SELECT @ml) c ON c.id IS NOT NULL
WHERE p.sku = 'C1762' AND @is_sg > 0;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT c.id, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN (SELECT @apps AS id UNION ALL SELECT @ml) c ON c.id IS NOT NULL
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE p.sku = 'C1762' AND @is_sg > 0
GROUP BY c.id, p.entity_id, s.store_id;

-- slot AI-300 after AI-200 in the AI for Machine Learning curated order
UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C430'  THEN 101
  WHEN 'C592'  THEN 102
  WHEN 'C193'  THEN 103
  WHEN 'C188'  THEN 104
  WHEN 'C539'  THEN 105
  WHEN 'C1071' THEN 106
  WHEN 'C926'  THEN 107
  WHEN 'C1759' THEN 108
  WHEN 'C1762' THEN 109
  WHEN 'C19'   THEN 110
  WHEN 'C1330' THEN 111
  WHEN 'C279'  THEN 112
END
WHERE cp.category_id = @ml
  AND p.sku IN ('C430','C592','C193','C188','C539','C1071','C926','C1759','C1762','C19','C1330','C279');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C430'  THEN 101
  WHEN 'C592'  THEN 102
  WHEN 'C193'  THEN 103
  WHEN 'C188'  THEN 104
  WHEN 'C539'  THEN 105
  WHEN 'C1071' THEN 106
  WHEN 'C926'  THEN 107
  WHEN 'C1759' THEN 108
  WHEN 'C1762' THEN 109
  WHEN 'C19'   THEN 110
  WHEN 'C1330' THEN 111
  WHEN 'C279'  THEN 112
END
WHERE i.category_id = @ml
  AND p.sku IN ('C430','C592','C193','C188','C539','C1071','C926','C1759','C1762','C19','C1330','C279');

