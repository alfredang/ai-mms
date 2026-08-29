-- 1164: Render em-dashes in blog `meta_description` as real characters instead of
--       the HTML entity `&mdash;`.
--
-- Why: meta_description is emitted into <meta name="description">, <meta
-- property="og:description"> and <meta name="twitter:description"> through
-- Magento's escaper, which escapes the ampersand again - so a stored `&mdash;`
-- ships to Google and to every social link preview as the literal text
-- "&amp;mdash;". The visible article body is unaffected (it is rendered as raw
-- HTML, where the entity resolves correctly).
--
-- This is the same failure mode migration 1161 fixed for `excerpt`, in the other
-- field that leaves the page as plain text. Affects three posts:
--   * 1160 ai-for-network-security-singapore-guide      (pre-existing)
--   * 1162 hydroponics-singapore-urban-farming-...      (shipped with the entity)
--   * 1163 hydroponics-grow-melons-singapore-...        (shipped with the entity)
--
-- Scope: the `meta_description` column ONLY. `content` deliberately stays pure
-- ASCII with HTML entities (see 1160 and feedback_migration_applyphp_utf8_outage)
-- because it is only ever rendered as HTML.
--
-- The em-dash is written via CHAR(0xE2,0x80,0x94 USING utf8mb4) rather than as a
-- literal byte, so this file itself stays ASCII and cannot trip apply.php's utf8
-- connection charset.
--
-- Idempotent: REPLACE() is a no-op once the entity is gone. Not store-guarded --
-- meta_description is per-post text and the same fix is correct on every site
-- that happens to carry these rows.

UPDATE `mmd_blog_post`
   SET `meta_description` = REPLACE(`meta_description`, '&mdash;', CHAR(0xE2,0x80,0x94 USING utf8mb4))
 WHERE `meta_description` LIKE '%&mdash;%';
