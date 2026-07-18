-- Redirect the "hermes", "hermes agent" and "paperclip" search terms to the
-- WSQ autonomous-AI-agents course page.
--
-- Data-only (catalogsearch_query). Unlike 535, these terms may not exist yet in
-- catalogsearch_query on every site, so seed the row first (INSERT IGNORE relies
-- on the UNIQUE key on (query_text, store_id)) and then fill the redirect.
--
-- Only fills an empty redirect so an intentional product-page redirect is never
-- overwritten. store_id 1 = the site's own store; safe on partner DBs because the
-- UPDATE is keyed on query_text, which no partner site has as a live term.

INSERT IGNORE INTO catalogsearch_query
    (query_text, store_id, num_results, popularity, display_in_terms, is_active, is_processed)
VALUES
    ('hermes',       1, 0, 0, 0, 1, 1),
    ('hermes agent', 1, 0, 0, 0, 1, 1),
    ('paperclip',    1, 0, 0, 0, 1, 1);

UPDATE catalogsearch_query
SET redirect = 'https://www.tertiarycourses.com.sg/wsq-build-a-human-ai-workforce-with-autonomous-ai-agents.html'
WHERE query_text IN ('hermes', 'hermes agent', 'paperclip')
  AND store_id = 1
  AND (redirect IS NULL OR redirect = '');
