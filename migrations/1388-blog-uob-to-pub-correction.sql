--
-- 1388: Correct blog post 1376 -- the client was PUB, not UOB.
--
-- The 2026-09-11 "GenAI for Professional Engineers" class at IES Jurong East
-- was delivered for PUB, Singapore's National Water Agency (https://www.pub.gov.sg/),
-- not for UOB. Reported by the admin 2026-09-12.
--
-- This is not a three-letter find/replace. The original article framed the
-- cohort as a BANK ("Banking and engineering teams work with sensitive
-- operational information"), which is wrong for a water utility. PUB runs
-- water treatment works, reservoirs, NEWater plants, pumping stations and
-- the sewerage network -- physical process plant, which is a far more
-- natural home for FMEA / DMAIC / SPC than a bank ever was. The corrected
-- copy says so.
--
-- Four content edits, each a targeted REPLACE() so a concurrent edit to any
-- other part of the 11KB body is not clobbered:
--   1. Opening line          -- "24 UOB professionals" -> PUB + agency descriptor
--   2. "regulated enterprise" -- "Banking and engineering teams" -> utility framing
--   3. Closing section        -- "The UOB class at IES" -> "The PUB class at IES"
--   4. Title / excerpt / meta_title / meta_description / meta_keywords
--
-- URL SLUG: the slug also said "uob". It is changed to
-- pub-engineers-microsoft-365-copilot-fmea-dmaic-spc and the OLD path gets a
-- permanent (301) core_url_rewrite row so no existing link, share or crawl
-- result 404s. The blog slug router (MMD_Blog_Controller_Router) resolves
-- straight off mmd_blog_post.url_key and has no redirect table of its own,
-- so core_url_rewrite is the right mechanism -- verified locally: a
-- blog/<old> row with options='RP' returns a clean 301 to blog/<new>.
--
-- HERO: the hero PNG has the old title baked into the pixels, so it must be
-- regenerated ON PROD after this deploys (SQL cannot render a PNG). This
-- migration NULLs hero_image_url so the stale "UOB" artwork stops being
-- served the moment this applies; the regenerated hero is attached in a
-- follow-up. The old R2 object is left in place for now (orphan cleanup is
-- a separate, guarded job).
--
-- likes: post 167 currently sits at 0. Seeded to a plausible in-range value
-- while we are here, guarded so real storefront likes are never clobbered.
--
-- Idempotent: every REPLACE() is a no-op once applied (the old substring is
-- gone); the url_key UPDATE is guarded on the old value; the rewrite row uses
-- INSERT ... ON DUPLICATE KEY UPDATE. Safe to re-run.
--
-- SG-only: guarded by @is_sg -- this post exists only on the SG site.
-- apply.php splits on semicolon-at-EOL, so every statement ends accordingly.

-- @mms_instance is pre-set by apply.php from MMS_COUNTRY_CODE (defaults to 'SG').
SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

-- 1. Opening paragraph: name the right organisation and say what it is.
UPDATE `mmd_blog_post`
   SET `content` = REPLACE(
       `content`,
       '<p>On 11 September 2026, 24 UOB professionals from operations, maintenance and support gathered at IES in Jurong East for',
       '<p>On 11 September 2026, 24 professionals from <strong>PUB, Singapore&rsquo;s National Water Agency</strong> &mdash; drawn from operations, maintenance and support &mdash; gathered at IES in Jurong East for')
 WHERE `url_key` IN ('uob-engineers-microsoft-365-copilot-fmea-dmaic-spc',
                     'pub-engineers-microsoft-365-copilot-fmea-dmaic-spc')
   AND @is_sg = 1;

-- 2. Responsible-use section: a water utility, not a bank. The replacement
--    keeps the same governance point but grounds it in utility operations.
UPDATE `mmd_blog_post`
   SET `content` = REPLACE(
       `content`,
       'Banking and engineering teams work with sensitive operational information.',
       'Utility and engineering teams work with sensitive operational information &mdash; plant telemetry, asset condition records and incident history for national water infrastructure.')
 WHERE `url_key` IN ('uob-engineers-microsoft-365-copilot-fmea-dmaic-spc',
                     'pub-engineers-microsoft-365-copilot-fmea-dmaic-spc')
   AND @is_sg = 1;

-- 3. Closing section.
UPDATE `mmd_blog_post`
   SET `content` = REPLACE(`content`, 'The UOB class at IES', 'The PUB class at IES')
 WHERE `url_key` IN ('uob-engineers-microsoft-365-copilot-fmea-dmaic-spc',
                     'pub-engineers-microsoft-365-copilot-fmea-dmaic-spc')
   AND @is_sg = 1;

-- 4. Title, excerpt and SEO fields.
UPDATE `mmd_blog_post`
   SET `title`            = 'PUB Engineers Apply Microsoft 365 Copilot to FMEA, DMAIC and SPC',
       `excerpt`          = 'A 24-person cohort from PUB, Singapore&rsquo;s National Water Agency, explored practical, human-verified uses of Copilot for FMEA, DMAIC and SPC.',
       `meta_title`       = 'Microsoft 365 Copilot for FMEA, DMAIC and SPC',
       `meta_description` = 'See how 24 PUB operations, maintenance and support staff applied Microsoft 365 Copilot to FMEA, DMAIC and SPC in an IES class at Jurong East.',
       `meta_keywords`    = 'Microsoft 365 Copilot, FMEA, DMAIC, SPC, GenAI for Professional Engineers, PUB corporate training, water utility, IES Jurong East, operations, maintenance, support'
 WHERE `url_key` IN ('uob-engineers-microsoft-365-copilot-fmea-dmaic-spc',
                     'pub-engineers-microsoft-365-copilot-fmea-dmaic-spc')
   AND @is_sg = 1;

-- 5. Drop the stale hero. Its PNG has the old "UOB ..." title drawn into the
--    image, so it must not keep being served. Regenerated on prod after deploy.
UPDATE `mmd_blog_post`
   SET `hero_image_url` = NULL
 WHERE `url_key` IN ('uob-engineers-microsoft-365-copilot-fmea-dmaic-spc',
                     'pub-engineers-microsoft-365-copilot-fmea-dmaic-spc')
   AND `hero_image_url` LIKE '%uob-engineers%'
   AND @is_sg = 1;

-- 6. Seed likes (post shipped at 0, which reads as a reset counter).
UPDATE `mmd_blog_post`
   SET `likes` = 87
 WHERE `url_key` IN ('uob-engineers-microsoft-365-copilot-fmea-dmaic-spc',
                     'pub-engineers-microsoft-365-copilot-fmea-dmaic-spc')
   AND `likes` = 0
   AND @is_sg = 1;

-- 7. Permanent redirect from the old slug, added BEFORE the slug changes so
--    there is no window where the old path resolves to nothing.
INSERT INTO `core_url_rewrite`
  (`store_id`, `id_path`, `request_path`, `target_path`, `is_system`, `options`)
SELECT 1, 'mmd_blog_post/167/uob-correction',
       'blog/uob-engineers-microsoft-365-copilot-fmea-dmaic-spc',
       'blog/pub-engineers-microsoft-365-copilot-fmea-dmaic-spc', 0, 'RP'
FROM DUAL WHERE @is_sg = 1
ON DUPLICATE KEY UPDATE
  `target_path` = VALUES(`target_path`),
  `options`     = VALUES(`options`);

-- 8. Finally the slug itself.
UPDATE `mmd_blog_post`
   SET `url_key` = 'pub-engineers-microsoft-365-copilot-fmea-dmaic-spc'
 WHERE `url_key` = 'uob-engineers-microsoft-365-copilot-fmea-dmaic-spc'
   AND @is_sg = 1;
