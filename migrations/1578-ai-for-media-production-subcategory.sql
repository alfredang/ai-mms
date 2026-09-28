-- 1578: AI Applications Series - add "AI for Media Production" after
-- AI for Healthcare (the two-column flyout ships as CSS in the same commit).
--
-- A) Repurpose the deactivated category 'XiaoHongshu'
--    (xiaohongshu-social-commerce-courses, inactive, out of the menu) as
--    AI for Media Production (ai-for-media-production) under AI Applications
--    Series. Its one old course (C927) is dropped from it - C927 keeps its
--    Video Marketing / Social Media listings. The old Perl image, description
--    and meta are replaced (see feedback_repurposed_category_keeps_old_content_
--    and_position). The old slug already 404s (inactive), so no 301 is added.
--
-- B) Order: AI for Media Production sits after AI for Healthcare:
--      1 Business  2 HR  3 Finance  4 Healthcare  5 Media Production
--      6 Robotics  7 Manufacturing  8 Retail  9 Educators  10 STEM  11 ML
--    Computer Vision / RL stay hidden at 90/91.
--
-- C) Membership: TGS-2020505925 "Create Short Video Film using AI" goes into
--    AI for Media Production, and onto the AI Applications Series parent above
--    its C-block (MIN(C position) - 1, TGS-first rule; parent is curated).
--
-- D) The two-column AI Applications flyout is CSS (skin/.../css/custom.css),
--    not data: umm_dd_columns is only honoured for Mega dropdowns, and a Mega
--    panel nested in the classic AI Courses dropdown overlaps its parent.
--
-- SG-guarded; all keys are SG-only url_keys (partner no-op). Idempotent: the
-- category is resolved by its new url_key first, and the source is only taken
-- while it is still the inactive XiaoHongshu category.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @a_cname    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @a_curlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @a_curlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_path');
SET @a_cactive  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'is_active');
SET @a_cmenu    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'include_in_menu');
SET @a_canchor  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'is_anchor');
SET @a_cimage   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'image');
SET @a_cdesc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'description');
SET @a_cmetat   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_title');
SET @a_cmetad   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_description');
SET @a_cmetak   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_keywords');

SET @apps := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-applications-series' LIMIT 1);
SET @appspath := (SELECT path FROM catalog_category_entity WHERE entity_id = @apps);

SET @has_flat := (
  SELECT COUNT(*) FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_1'
);

-- ===== A: XiaoHongshu -> AI for Media Production =====

SET @media := IF(@is_sg > 0 AND @apps IS NOT NULL, COALESCE(
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-media-production' LIMIT 1),
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   JOIN catalog_category_entity_int a ON a.entity_id = v.entity_id AND a.attribute_id = @a_cactive
     AND a.store_id = 0 AND a.value = 0
   WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
     AND v.value = 'xiaohongshu-social-commerce-courses' LIMIT 1)
), NULL);

SET @m_oldpath := (SELECT path FROM catalog_category_entity WHERE entity_id = @media);
SET @m_move := IF(@media IS NOT NULL
  AND (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @media) <> @apps, 1, 0);

UPDATE catalog_category_entity
SET children_count = children_count - 1
WHERE @m_move = 1 AND FIND_IN_SET(entity_id, REPLACE(@m_oldpath, '/', ','))
  AND entity_id <> @media AND NOT FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','));

UPDATE catalog_category_entity
SET children_count = children_count + 1
WHERE @m_move = 1 AND FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','))
  AND NOT FIND_IN_SET(entity_id, REPLACE(@m_oldpath, '/', ','));

UPDATE catalog_category_entity
SET parent_id = @apps,
    path = CONCAT(@appspath, '/', entity_id),
    level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, '/', ''))) + 1
WHERE @m_move = 1 AND entity_id = @media;

-- identity (store overrides removed so store 0 is authoritative)
DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @media AND attribute_id IN (@a_cname, @a_cmetat) AND store_id <> 0 AND @media IS NOT NULL;

DELETE FROM catalog_category_entity_int
WHERE entity_id = @media AND attribute_id IN (@a_cactive, @a_cmenu) AND store_id <> 0 AND @media IS NOT NULL;

DELETE FROM catalog_category_entity_text
WHERE entity_id = @media AND attribute_id IN (@a_cdesc, @a_cmetad, @a_cmetak) AND store_id <> 0 AND @media IS NOT NULL;

-- the old Perl programming image does not belong to this category
DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @media AND attribute_id = @a_cimage AND @media IS NOT NULL;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cname, 0, @media, 'AI for Media Production' FROM dual WHERE @media IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_curlkey, 0, @media, 'ai-for-media-production' FROM dual WHERE @media IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity_varchar
SET value = 'ai-for-media-production.html'
WHERE entity_id = @media AND attribute_id = @a_curlpath AND @media IS NOT NULL;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cactive, 0, @media, 1 FROM dual WHERE @media IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmenu, 0, @media, 1 FROM dual WHERE @media IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_canchor, 0, @media, 1 FROM dual WHERE @media IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- landing copy and meta
INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cdesc, 0, @media, '<p>Generative AI has changed how video, images, voice and music are made. The <strong>AI for Media Production</strong> courses show content creators, marketers and communications teams how to plan and produce media with AI - from story, script and storyboard to consistent characters and scenes, AI-generated video, voiceover, music and the final edit.</p><p>Courses in this collection are hands-on and project-based: you finish with work you have actually produced, such as a complete AI-assisted short film, and a repeatable workflow you can take back to your organisation. No prior video-production or programming experience is required.</p>' FROM dual WHERE @media IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetad, 0, @media, 'AI courses for media production - plan, generate and edit short films, video, images, voiceover and music with generative AI tools. Hands-on, project-based training.' FROM dual WHERE @media IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetak, 0, @media, 'AI for media production, AI video, AI short film, generative AI video, AI filmmaking, AI voiceover, AI content creation' FROM dual WHERE @media IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetat, 0, @media, 'AI for Media Production Courses in Singapore | Tertiary Courses' FROM dual WHERE @media IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ===== B: order under AI Applications Series =====

UPDATE catalog_category_entity e
JOIN catalog_category_entity_varchar v
  ON v.entity_id = e.entity_id AND v.attribute_id = @a_curlkey AND v.store_id = 0
SET e.position = CASE v.value
    WHEN 'ai-for-business'           THEN 1
    WHEN 'ai-for-hr-courses'         THEN 2
    WHEN 'ai-for-finance-courses'    THEN 3
    WHEN 'ai-for-healthcare-courses' THEN 4
    WHEN 'ai-for-media-production'   THEN 5
    WHEN 'ai-for-robotics'           THEN 6
    WHEN 'ai-for-manufacturing'      THEN 7
    WHEN 'ai-for-retail-courses'     THEN 8
    WHEN 'ai-for-educators'          THEN 9
    WHEN 'ai-for-stem'               THEN 10
    WHEN 'ai-for-machine-learning'   THEN 11
  END
WHERE e.parent_id = @apps AND @media IS NOT NULL
  AND v.value IN ('ai-for-business', 'ai-for-hr-courses', 'ai-for-finance-courses',
                  'ai-for-healthcare-courses', 'ai-for-media-production', 'ai-for-robotics',
                  'ai-for-manufacturing', 'ai-for-retail-courses', 'ai-for-educators',
                  'ai-for-stem', 'ai-for-machine-learning');

-- ===== C: membership =====

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020505925' LIMIT 1);

DELETE cp FROM catalog_category_product cp
WHERE cp.category_id = @media AND cp.product_id <> @pid AND @media IS NOT NULL AND @pid IS NOT NULL;

DELETE i FROM catalog_category_product_index i
WHERE i.category_id = @media AND i.product_id <> @pid AND @media IS NOT NULL AND @pid IS NOT NULL;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @media, @pid, 1 FROM dual WHERE @media IS NOT NULL AND @pid IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @media, @pid, 1, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE i.product_id = @pid AND @media IS NOT NULL AND @pid IS NOT NULL
GROUP BY i.store_id;

SET @apps_pos := (SELECT COALESCE(MIN(cp.position) - 1, MAX(cp.position) + 1)
  FROM catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @apps AND p.sku LIKE 'C%');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @apps, @pid, COALESCE(@apps_pos, 1) FROM dual WHERE @media IS NOT NULL AND @pid IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @apps, @pid, COALESCE(@apps_pos, 1), 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE i.product_id = @pid AND @media IS NOT NULL AND @pid IS NOT NULL
GROUP BY i.store_id;

-- ===== flat mirror (the storefront reads catalog_category_flat_store_1) =====

SET @sql := IF(@has_flat > 0 AND @media IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET parent_id = @apps, path = CONCAT(@appspath, ''/'', entity_id), level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, ''/'', ''''))) + 1, is_active = 1, include_in_menu = 1, is_anchor = 1, name = ''AI for Media Production'', url_key = ''ai-for-media-production'', url_path = ''ai-for-media-production.html'', image = NULL WHERE entity_id = @media',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := IF(@has_flat > 0 AND @media IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 f JOIN catalog_category_entity e ON e.entity_id = f.entity_id SET f.position = e.position WHERE e.parent_id = @apps',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
