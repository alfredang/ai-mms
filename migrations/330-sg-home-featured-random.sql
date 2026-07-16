-- 330: SG homepage featured sliders → pick products RANDOMLY from their category.
-- The Ultimo featured block (Infortis_Ultimo_Block_Product_List_Featured) runs
-- ORDER BY RAND() on the category collection only when the CMS markup passes
-- is_random="1" (deliberately opt-in — unconditional RAND() across 3 blocks was a
-- documented ~8s pageload hotspot). SG's home blocks (cat 16/15/196) never passed it,
-- so each showed a FIXED first-N. Add is_random="1" so the set is a random pick from
-- the whole category (re-rolls on each block-cache regen — the 86400 cache is kept, so
-- no per-request RAND() perf cost).
--
-- SG-scoped by the SG-only "SkillsFuture Funded AI Courses" block name so this is a
-- no-op on the MY/GH partner DBs (which run the same codebase but whose home pages were
-- set is_random directly on their own servers). Idempotent via NOT LIKE '%is_random%'.
UPDATE cms_page
SET content = REPLACE(
        content,
        'template="catalog/product/list_featured_slider.phtml"',
        'template="catalog/product/list_featured_slider.phtml" is_random="1"')
WHERE identifier = 'home'
  AND content LIKE '%SkillsFuture Funded AI Courses%'
  AND content NOT LIKE '%is_random%';
