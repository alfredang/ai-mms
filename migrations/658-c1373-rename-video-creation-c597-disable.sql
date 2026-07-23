-- 658-c1373-rename-video-creation-c597-disable.sql
-- Two SG catalog changes (idempotent, product-scoped):
--   1. C1373: rename "Generative AI for Tiktok Video Creation" ->
--             "Generative AI for Video Creation" (remove TikTok, broaden to
--             general short-form/social video); rewrite short_description,
--             image labels, url_key/url_path.
--   2. C597 "Generative AI with Video Editing": disable (status=2) — superseded
--             by the broadened C1373. Repoint its two search-term redirects
--             (c597, c0597) to C1373 so they don't rot to a 404.
-- Partner-safe: keyed by product SKU. M-prefix partner catalogs don't carry
-- C1373/C597, so every UPDATE matches zero rows there. No-op if re-run.

-- ---------------------------------------------------------------------------
-- 1. C1373 rename + overview rewrite
-- ---------------------------------------------------------------------------
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1373');

-- name (attribute_id resolved by code so this survives schema drift)
SET @attr_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id =
  (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product')
  AND attribute_code='name');
UPDATE catalog_product_entity_varchar
  SET value = 'Generative AI for Video Creation'
  WHERE entity_id = @pid AND attribute_id = @attr_name;

-- image labels (image_label / small_image_label / thumbnail_label)
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
  SET v.value = 'Generative AI for Video Creation'
  WHERE v.entity_id = @pid
    AND a.attribute_code IN ('image_label','small_image_label','thumbnail_label');

-- url_key + url_path
SET @attr_urlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id =
  (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product')
  AND attribute_code='url_key');
UPDATE catalog_product_entity_varchar
  SET value = 'generative-ai-for-video-creation'
  WHERE entity_id = @pid AND attribute_id = @attr_urlkey;

SET @attr_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id =
  (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product')
  AND attribute_code='url_path');
UPDATE catalog_product_entity_varchar
  SET value = 'generative-ai-for-video-creation.html'
  WHERE entity_id = @pid AND attribute_id = @attr_urlpath;

-- short_description (overview) — TikTok removed, broadened to short-form/social
SET @attr_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id =
  (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product')
  AND attribute_code='short_description');
UPDATE catalog_product_entity_text
  SET value = '<p>Create scroll-stopping videos with Generative AI for Video Creation. This hands-on 2-day course teaches you how to use generative AI tools to ideate, script, generate, edit and publish short-form videos that captivate audiences. Instead of spending hours on production, you will let AI accelerate scripting, voiceovers, visuals and editing while you focus on creativity and strategy.</p><p>Through practical projects, participants will use AI to generate video ideas and hooks, write scripts and captions, create visuals, voiceovers and B-roll, edit videos into polished clips, and plan a posting and growth strategy. You will also learn to prompt effectively, keep a consistent brand style, and analyse and improve performance. By the end of the course, you will be able to produce and scale engaging video content for social and marketing channels with a generative AI workflow.</p>'
  WHERE entity_id = @pid AND attribute_id = @attr_short;

-- ---------------------------------------------------------------------------
-- 2. C597 disable
-- ---------------------------------------------------------------------------
SET @c597 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C597');
SET @attr_status := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id =
  (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product')
  AND attribute_code='status');
-- status=2 (Disabled) at default store scope (store_id=0)
UPDATE catalog_product_entity_int
  SET value = 2
  WHERE entity_id = @c597 AND attribute_id = @attr_status AND store_id = 0;

-- Repoint C597's search-term redirects to the broadened C1373 so they don't 404.
-- Own-domain absolute URL (SG). Only touch the two known C597 redirects.
UPDATE catalogsearch_query
  SET redirect = 'https://www.tertiarycourses.com.sg/generative-ai-for-video-creation.html'
  WHERE query_text IN ('c597','c0597')
    AND redirect = 'https://www.tertiarycourses.com.sg/generative-ai-with-video-editing.html';
