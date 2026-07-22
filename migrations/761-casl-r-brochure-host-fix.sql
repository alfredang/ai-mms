-- 761: Fix the brochure host for TGS-2026064475 (CASL - Data Analytics and
-- Visualization with R). The block linked ai-mms.tertiaryinfo.tech, whose
-- redirect to www.tertiarycourses.com.sg DROPS the /media prefix -> 404
-- (see the RPA conversion block, already on the SG domain). Serve the PDF
-- from the SG domain directly. Idempotent; partner-safe (identifier absent
-- on MY/GH).

UPDATE cms_block
  SET content = REPLACE(content, 'https://ai-mms.tertiaryinfo.tech/media/courses/brochures/TGS-2026064475-SG.pdf', 'https://www.tertiarycourses.com.sg/media/courses/brochures/TGS-2026064475-SG.pdf')
  WHERE identifier = 'course_TGS-2026064475_brochure';
