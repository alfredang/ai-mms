-- Redirect generic "cyber security" / "cybersecurity" searches to the
-- Cybersecurity & Threat Analysis category page.
--
-- Scope is deliberately tight: only UNQUALIFIED variants of the term, i.e.
-- "cyber", "cyber security", "cybersecurity", optionally followed by
-- course/courses/training. Qualified searches (e.g. "basic cyber security
-- course", "wsq cyber", "comptia cybersecurity analyst") keep their own,
-- more specific targets and are NOT matched by the anchored regex below.
--
-- NULL-safe guard: NOT (redirect <=> @tgt) fills unset rows AND overwrites
-- rows previously pointing at cyber-security-digital-forensic-training-courses,
-- while no-opping on rows already correct. A bare `redirect <> @tgt` would
-- silently skip every redirect IS NULL row.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/cybersecurity-threat-analysis-courses.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(TRIM(query_text)) REGEXP '^cyber([ -]?security)?[ ]*(course|courses|training|trainings|training course)?[ ]*[.]?$';
