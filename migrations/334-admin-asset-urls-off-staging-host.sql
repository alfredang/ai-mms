-- 334: Stop serving admin assets from the retired staging host.
-- The default-scope base_js_url / base_skin_url / base_media_url (secure +
-- unsecure) still point at https://ai-mms.tertiaryinfo.tech/ — the admin runs
-- at default scope, so every admin CSS/JS/media request 301-hops through that
-- old domain. Any DNS/cert/network trouble with it makes the admin appear
-- unreachable even though the server is healthy (reported 2026-07-06).
--
-- Repoint to the stock {{unsecure_base_url}}/{{secure_base_url}} placeholders
-- so assets always come from the site's own domain. Self-scoping: only rows
-- still carrying the staging host are touched, so this is a no-op on partner
-- DBs that already use their own values, and correct on any that still carry
-- the staging default (placeholder resolves to THEIR base_url). Idempotent.
UPDATE core_config_data
SET value = CASE path
      WHEN 'web/unsecure/base_js_url'    THEN '{{unsecure_base_url}}js/'
      WHEN 'web/unsecure/base_skin_url'  THEN '{{unsecure_base_url}}skin/'
      WHEN 'web/unsecure/base_media_url' THEN '{{unsecure_base_url}}media/'
      WHEN 'web/secure/base_js_url'      THEN '{{secure_base_url}}js/'
      WHEN 'web/secure/base_skin_url'    THEN '{{secure_base_url}}skin/'
      WHEN 'web/secure/base_media_url'   THEN '{{secure_base_url}}media/'
    END
WHERE scope = 'default' AND scope_id = 0
  AND path IN ('web/unsecure/base_js_url','web/unsecure/base_skin_url','web/unsecure/base_media_url',
               'web/secure/base_js_url','web/secure/base_skin_url','web/secure/base_media_url')
  AND value LIKE '%ai-mms.tertiaryinfo.tech%';
