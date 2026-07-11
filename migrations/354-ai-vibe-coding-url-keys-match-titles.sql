-- Rename the url_key of the 6 repurposed AI Vibe Coding courses so the URL
-- slug matches the new course title. The old slugs (from the pre-repurpose
-- courses) are misleading.
--
--   C1143  react-essential-training                  -> react-ai-vibe-coding-for-react-development
--   C384   basic-react-js-training                   -> ai-vibe-coding-for-react-native
--   C683   basic-react-native-training               -> ai-vibe-coding-for-flutter-development
--   C1800  vibe-coding-for-full-stack-web-development -> ai-vibe-coding-for-full-stack-web-development
--   C138   python-3-essential-training(-in-singapore)-> ai-vibe-coding-with-python
--   C430   deep-learning-neural-network-tensorflow   -> ai-vibe-coding-for-machine-learning
--
-- Market-neutral, so it applies to SG/MY/GH (each partner keeps ITS own old
-- slug until this runs, then gets a 301 from it). Store scope 0.
--
-- IMPORTANT: this only changes the url_key attribute. The 301 (permanent)
-- redirect from the OLD slug to the new one is created when catalog URLs are
-- reindexed AFTER this migration (catalog/seo/save_rewrites_history = 1). Run
-- the reindex API (/reindex/api/run?token=...&flush=1) on each site after
-- deploy — it runs catalog_url reindexEverything, which writes the RP
-- (redirect-permanent) rows into core_url_rewrite. Verified on localhost.
--
-- Idempotent: re-running sets the same values.

SET @uk := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key' AND entity_type_id=4);

UPDATE catalog_product_entity_varchar v
JOIN catalog_product_entity e ON e.entity_id = v.entity_id
SET v.value = CASE e.sku
    WHEN 'C1143' THEN 'react-ai-vibe-coding-for-react-development'
    WHEN 'C384'  THEN 'ai-vibe-coding-for-react-native'
    WHEN 'C683'  THEN 'ai-vibe-coding-for-flutter-development'
    WHEN 'C1800' THEN 'ai-vibe-coding-for-full-stack-web-development'
    WHEN 'C138'  THEN 'ai-vibe-coding-with-python'
    WHEN 'C430'  THEN 'ai-vibe-coding-for-machine-learning'
END
WHERE v.attribute_id = @uk AND v.store_id = 0
  AND e.sku IN ('C1143', 'C384', 'C683', 'C1800', 'C138', 'C430');
