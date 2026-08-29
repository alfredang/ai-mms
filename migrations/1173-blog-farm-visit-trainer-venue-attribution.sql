-- 1173: Add the venue and trainer attribution to the 15 Feb 2020 hydroponics
--       farm-visit post (1169).
--
-- Admin request 2026-08-29: state explicitly that the class was held at
-- Kok Fah Technology Farm and taught by Mr Chen Jun Wei, a veteran plant grower
-- in Singapore.
--
-- The post already named Kok Fah in ONE figcaption. This migration:
--   1. Names the venue + trainer in the opening paragraph, where a reader
--      actually looks for it, rather than only under a photo.
--   2. Credits Mr Chen by name in the "learning at the bench" section, which is
--      precisely the passage about asking a working grower why the system is
--      built the way it is - previously it said "someone who runs the system
--      daily", which is exactly who he is.
--
-- Scope: `content` only, on the one post. Two targeted REPLACE() calls against
-- string literals quoted verbatim from 1169, so nothing else can be touched.
--
-- IDEMPOTENT: each REPLACE is a no-op once applied, because the search string no
-- longer matches. The LOCATE guard additionally skips the whole statement if the
-- attribution is already present, so a re-run cannot double-insert.
--
-- Pure ASCII (em-dash as the &mdash; entity, matching the surrounding content) -
-- see feedback_migration_applyphp_utf8_outage. SG-only guard via @mms_instance.
--
-- NOTE: only the `content` column changes. `excerpt` and `meta_description` are
-- deliberately untouched - they are plain-text surfaces (see 1161/1164) and the
-- trainer's name is not needed in a search snippet.

SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

-- 1. Opening paragraph: name the farm and the trainer up front.
UPDATE `mmd_blog_post`
   SET `content` = REPLACE(
        `content`,
        'For our learners on <strong>15 February 2020</strong>, it happened walking into a greenhouse and seeing several thousand lettuces growing in water, in rows that ran further than the eye comfortably followed.</p>',
        'For our learners on <strong>15 February 2020</strong>, it happened walking into a greenhouse and seeing several thousand lettuces growing in water, in rows that ran further than the eye comfortably followed.</p> <p>The class was held at <strong>Kok Fah Technology Farm</strong> and taught by <strong>Mr Chen Jun Wei</strong>, a veteran plant grower in Singapore &mdash; which is why the day was less a tour than a working explanation of how a commercial hydroponic operation is actually run.</p>'
       ),
       `updated_at` = NOW()
 WHERE @is_sg > 0
   AND `url_key` = 'hydroponics-commercial-farm-visit-singapore-february-2020'
   AND LOCATE('Mr Chen Jun Wei', `content`) = 0;

-- 2. "Learning at the bench" section: credit Mr Chen where the post talks about
--    asking a working grower why the system is built the way it is.
UPDATE `mmd_blog_post`
   SET `content` = REPLACE(
        `content`,
        'The most useful stretch of any farm visit is unstructured &mdash; standing at a bench asking someone who runs the system daily why it is built the way it is.',
        'The most useful stretch of any farm visit is unstructured &mdash; standing at a bench asking someone who runs the system daily why it is built the way it is. Mr Chen Jun Wei has grown plants commercially in Singapore for years, and that experience is what the questions were really for.'
       ),
       `updated_at` = NOW()
 WHERE @is_sg > 0
   AND `url_key` = 'hydroponics-commercial-farm-visit-singapore-february-2020'
   AND LOCATE('Mr Chen Jun Wei has grown plants commercially', `content`) = 0;
