-- 632: clear search-term redirects that point at DISABLED courses (404 dead-ends).
--
-- WHY: a search redirect is set once by hand and never revisited when the course is
-- later disabled, so the term keeps 302-ing to a product page that now 404s. Verified
-- by HTTP on production, not inferred:
--     mailchimp (464 searches) -> create-email-marketing-campaigns-...  HTTP 404
--     cyber     (452)          -> advanced-cyber-security-course.html   HTTP 404
--     mysql     (394)          -> mysql-essential-training-in-sg.html   HTTP 404
--     Magento   (351)          -> build-and-grow-your-e-business-...    HTTP 404
--     C009      (111)          -> notion-essential-training.html        HTTP 404
-- Scope on prod at time of writing: 3,359 redirects / 39,759 searches, of which 45
-- are course-code (C####) terms.
--
-- WHAT IT DOES: sets redirect = '' so Magento falls back to normal search results.
-- That is strictly better than a 404, and most of these terms still have a live
-- replacement course that search surfaces -- e.g. "mailchimp" ->
-- "WSQ - Creating High-Converting Email Campaigns with Mailchimp", "flask" ->
-- "WSQ - Create RESTful APIs and Web Apps with Python Flask", "inventor" ->
-- "WSQ - Product Design with Autodesk Inventor". Terms with no live match (django,
-- magento) get an ordinary empty-result page instead of an error.
--
-- COMPUTED AT APPLY TIME, NOT HARDCODED: the dead set is derived by joining
-- catalogsearch_query.redirect -> core_url_rewrite -> product status, so this stays
-- correct on every instance and does not bake in a 3,359-row ID list that would be
-- stale by the time it deploys.
--
-- ONLY touches redirects whose target resolves to a rewrite owned by a product whose
-- status <> 1 (disabled). Category targets, CMS targets and any redirect with no
-- matching rewrite are left completely alone -- this is why the huge "series" and
-- category redirects added by 621-631 are not affected.
--
-- Partner-safe: guard matches the SG store by its store code, so MY/GH are a no-op.
-- Idempotent: re-running finds nothing new once the rows are cleared.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

SET @status_attr := (
  SELECT attribute_id FROM eav_attribute
  WHERE attribute_code = 'status'
    AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product')
  LIMIT 1
);

-- NOTE ON THE JOIN SHAPE: a request_path can own MORE THAN ONE core_url_rewrite row
-- (duplicate/legacy rewrites). A plain JOIN then matches an arbitrary one, which on
-- production silently missed 14 genuinely-dead rows (e.g. "golang" and the
-- wsq-developing-ethical-strategies-... slug, both HTTP 404). So instead of joining,
-- the predicate below requires that the target resolves to at least one product
-- rewrite AND that NO live (status = 1) product owns that path.

UPDATE catalogsearch_query q
SET q.redirect = ''
WHERE @sg = 1
  AND q.store_id = 1
  AND q.redirect IS NOT NULL
  AND q.redirect <> ''
  -- the target path is owned by at least one PRODUCT rewrite ...
  AND EXISTS (
    SELECT 1 FROM core_url_rewrite r
    WHERE r.store_id = 1
      AND r.product_id IS NOT NULL
      AND r.request_path = TRIM(BOTH '/' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(q.redirect, '://', -1), '/', -1))
  )
  -- ... and NO enabled product owns it (so every owner is disabled)
  AND NOT EXISTS (
    SELECT 1 FROM core_url_rewrite r2
    JOIN catalog_product_entity_int s2
      ON s2.entity_id = r2.product_id
     AND s2.attribute_id = @status_attr
     AND s2.store_id = 0
     AND s2.value = 1
    WHERE r2.store_id = 1
      AND r2.product_id IS NOT NULL
      AND r2.request_path = TRIM(BOTH '/' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(q.redirect, '://', -1), '/', -1))
  );
