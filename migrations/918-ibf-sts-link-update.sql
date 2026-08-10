-- 918: Fix the last dead ibf.org.sg link on the IBF course pages. 917 fixed the
-- two .aspx links inside the About IBF Certification cms/blocks; the same
-- retired SharePoint-era pattern also appears as the IBF-STS link in the 7 IBF
-- courses' short_description (href + visible anchor text, 14 occurrences).
-- Old URL 404s; replacement verified HTTP 200 with no redirect chain.
-- Substring REPLACE is idempotent and partner-safe (no-op where absent).

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'https://www.ibf.org.sg/programmes/Pages/IBF-STS.aspx',
       'https://www.ibf.org.sg/home/for-individuals/skills-and-jobs-development/training-support/IBF-STS')
 WHERE value LIKE '%www.ibf.org.sg/programmes/Pages/IBF-STS.aspx%';
