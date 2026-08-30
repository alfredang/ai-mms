-- 1231: Repair the C922 redirect chain broken by 1230.
--
-- 1217 renamed C922 "AI Devops with Jenkins" -> "Deploy Jenkins with AI" and
-- created a 301 with id_path 'custom/c922-301':
--     ai-devops-with-jenkins.html -> deploy-jenkins-with-ai.html
--
-- 1230 then renamed it again to "Fine Tuning Open Source LLM" and tried to
-- create ANOTHER 301 with the SAME id_path 'custom/c922-301'. INSERT IGNORE
-- silently skipped it (id_path+store is unique), so:
--   - deploy-jenkins-with-ai.html got no redirect at all -> 404
--   - ai-devops-with-jenkins.html still pointed at that now-dead URL,
--     i.e. a 301 into a 404.
--
-- Fix: repoint the existing 'custom/c922-301' row at the CURRENT url so the
-- oldest slug resolves in one hop, and add the middle hop under a distinct
-- id_path. Both old slugs then 301 straight to the live page — no chains.
--
-- Lesson for future renames of an already-renamed course: the
-- 'custom/<sku>-301' id_path is NOT unique across renames. Use a
-- slug-derived id_path, and never rely on INSERT IGNORE to tell you it
-- worked — verify the old URL returns 301 to the NEW page, not merely 301.
--
-- SG-guarded. Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

-- Oldest slug -> current page, in one hop.
UPDATE core_url_rewrite
SET target_path = 'fine-tuning-open-source-llm.html'
WHERE id_path = 'custom/c922-301'
  AND store_id = 1
  AND request_path = 'ai-devops-with-jenkins.html'
  AND @is_sg > 0;

-- Middle slug -> current page, under its own id_path.
DELETE FROM core_url_rewrite
WHERE request_path = 'deploy-jenkins-with-ai.html'
  AND store_id = 1
  AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/deploy-jenkins-with-ai-301',
       'deploy-jenkins-with-ai.html', 'fine-tuning-open-source-llm.html', 0, 'RP'
FROM dual
WHERE @is_sg > 0;
