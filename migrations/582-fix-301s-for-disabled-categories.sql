-- Fix the 301s for the categories disabled by 577 / 578 / 580.
--
-- BUG BEING FIXED: 577/578/580 tried to add redirects with
--   INSERT IGNORE INTO core_url_rewrite (...)
-- but core_url_rewrite has a UNIQUE key on (request_path, store_id) and each of
-- those categories ALREADY owns its request_path via a system rewrite row
-- (is_system = 1, target catalog/category/view/id/N). So every INSERT collided
-- and IGNORE silently swallowed it — the categories ended up disabled with ZERO
-- redirects, i.e. dead URLs. Verified: 6 disabled categories, 0 redirects.
--
-- Lesson: INSERT IGNORE turns a unique-key collision into a silent no-op. When a
-- row may already exist, UPDATE the existing row (or use ON DUPLICATE KEY
-- UPDATE) and always assert the post-condition.
--
-- FIX: convert each disabled category's EXISTING rewrite row in place into a
-- 301 pointing at its parent's flat URL:
--   is_system = 0, options = 'RP', target_path = '<parent-url_key>.html'
-- Magento treats options='RP' as a 301 permanent redirect. Keeping the same row
-- preserves the unique key and avoids duplicate-path ambiguity.
--
-- Mapping (child -> parent it now redirects to):
--   RPA (219), Google Apps Script (240), Selenium (324)   -> RPA parent (202)
--   Linux (174), Windows (84)                             -> Linux parent (76)
--   Web Framework (352)                                   -> Web Development (4)
--
-- Resolved by url_key rather than hardcoded ids so it is partner-safe, and
-- guarded so it only touches rows still pointing at the disabled category
-- (idempotent — re-running finds them already converted).
-- No url_key is written anywhere: MMD_FlatCategoryUrl keeps every category at
-- /<url_key>.html and that rule is untouched.
-- After deploy: reindex catalog_url, flush block_html/FPC.

SET @uk := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

-- child_id -> parent_id map, resolved by url_key so ids may differ per site.
DROP TEMPORARY TABLE IF EXISTS mmd_301_map;
CREATE TEMPORARY TABLE mmd_301_map (child_key VARCHAR(255), parent_key VARCHAR(255));
INSERT INTO mmd_301_map VALUES
  ('rpa-courses',                      'rpa-api-it-automation-courses'),
  ('google-apps-script-courses',       'rpa-api-it-automation-courses'),
  ('selenium-training',                'rpa-api-it-automation-courses'),
  ('linux-operating-system-training',  'operating-systems-training-courses'),
  ('microsoft-windows-10-training',    'operating-systems-training-courses'),
  ('web-framework-courses',            'web-design-courses');

UPDATE core_url_rewrite r
JOIN mmd_301_map m
  ON r.request_path = CONCAT(m.child_key, '.html')
JOIN catalog_category_entity_varchar ck
  ON ck.attribute_id = @uk AND ck.store_id = 0 AND ck.value = m.child_key
JOIN catalog_category_entity_varchar pk
  ON pk.attribute_id = @uk AND pk.store_id = 0 AND pk.value = m.parent_key
SET r.is_system   = 0,
    r.options     = 'RP',
    r.target_path = CONCAT(m.parent_key, '.html'),
    r.description = 'Disabled category -> parent (577/578/580 consolidation)'
WHERE r.target_path = CONCAT('catalog/category/view/id/', ck.entity_id);

DROP TEMPORARY TABLE IF EXISTS mmd_301_map;
