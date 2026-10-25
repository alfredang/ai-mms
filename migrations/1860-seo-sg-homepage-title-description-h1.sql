-- SG homepage SEO (2026-10-25).
--
-- Before: <title> was 112 chars with a double space ("Accredited WSQ and IBF Funded Courses for Industrial
-- 4.0 Skill Upgrade in Singapore  | Tertiary Courses Singapore") and the page had NO <h1>.
-- After:
--   title           BARE "WSQ and IBF Funded Training Courses in Singapore" (MMD_Seotitle appends
--                   "| Tertiary Courses Singapore" at render time).
--   meta_description 156 chars, highlights the funding (WSQ / IBF / CASL, SkillsFuture Credit, UTAP).
--   content_heading the page's single <h1>, centred with the same scoped inline <style> the MY homepage
--                   (cms_page 15 on the MY DB) uses; the style is prepended once.
--
-- SG-only (store guard on the store-1 'home' page) -> no-op on MY/GH. Idempotent. Post-deploy: cache flush.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @home := (SELECT p.page_id FROM cms_page p JOIN cms_page_store s ON s.page_id = p.page_id
               WHERE p.identifier = 'home' AND s.store_id = 1 ORDER BY p.is_active DESC, p.page_id LIMIT 1);
SET @ok := (@sg = 1 AND @home IS NOT NULL);

UPDATE cms_page
   SET title            = 'WSQ and IBF Funded Training Courses in Singapore',
       meta_description = 'Instructor-led WSQ, IBF and CASL courses in AI, data, cybersecurity and business. Up to 70% funding; SkillsFuture Credit and UTAP claimable. Register today.',
       meta_keywords    = 'WSQ courses Singapore, IBF courses Singapore, CASL courses, SkillsFuture Credit courses, UTAP claimable courses, AI courses Singapore, IT training Singapore, corporate training Singapore',
       content_heading  = 'WSQ and IBF Funded Training Courses in Singapore'
 WHERE @ok AND page_id = @home;

UPDATE cms_page
   SET content = CONCAT('<style>.cms-index-index .page-title, .cms-index-index .page-title h1{text-align:center;}</style>\n', content)
 WHERE @ok AND page_id = @home AND content NOT LIKE '%.cms-index-index .page-title%';
