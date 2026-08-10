-- 917: Fix the two dead IBF links inside the course_<sku>_about_ibf_certification
-- cms/blocks (seeded by 916). The old SharePoint-era .aspx URLs now 404 on
-- ibf.org.sg; both replacements verified 200 with no redirect chain
-- (feedback_redirect_targets_need_final_status_check):
--   /programmes/Pages/MySkills-Portfolio.aspx
--     -> /home/for-individuals/resource-tools/myskills-portfolio
--   /certification/Pages/Why-be-Certified.aspx
--     -> /home/for-individuals/ibf-certification/why-be-ibf-certified
-- The URL appears as BOTH the href and the visible anchor text, so a plain
-- string REPLACE fixes each anchor in full (2 links x 7 blocks = 14 each).
-- Idempotent (REPLACE no-ops once swapped) and partner-safe (the blocks only
-- exist on SG; 0 rows elsewhere).

UPDATE cms_block
   SET content = REPLACE(content,
       'https://www.ibf.org.sg/programmes/Pages/MySkills-Portfolio.aspx',
       'https://www.ibf.org.sg/home/for-individuals/resource-tools/myskills-portfolio')
 WHERE identifier LIKE 'course_TGS-%_about_ibf_certification';

UPDATE cms_block
   SET content = REPLACE(content,
       'https://www.ibf.org.sg/certification/Pages/Why-be-Certified.aspx',
       'https://www.ibf.org.sg/home/for-individuals/ibf-certification/why-be-ibf-certified')
 WHERE identifier LIKE 'course_TGS-%_about_ibf_certification';
