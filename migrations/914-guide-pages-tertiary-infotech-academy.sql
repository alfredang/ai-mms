-- 914: guide pages — "Tertiary Infotech" -> "Tertiary Infotech Academy"
-- Scope: the three how-to guide pages (SWDA SOA download, SkillsFuture Credit
-- claim, WSQ registration) touched by migration 913. Collapse-then-expand
-- REPLACE so re-runs never produce "Academy Academy". Data-only; partner-safe.

UPDATE cms_page
SET content = REPLACE(REPLACE(content, 'Tertiary Infotech Academy', 'Tertiary Infotech'), 'Tertiary Infotech', 'Tertiary Infotech Academy'),
    meta_description = REPLACE(REPLACE(IFNULL(meta_description, ''), 'Tertiary Infotech Academy', 'Tertiary Infotech'), 'Tertiary Infotech', 'Tertiary Infotech Academy'),
    update_time = NOW()
WHERE identifier IN ('how-to-download-swda-soa.html', 'how-to-claim-skillsfuture-credit.html', 'how-to-register-wsq-course.html');
