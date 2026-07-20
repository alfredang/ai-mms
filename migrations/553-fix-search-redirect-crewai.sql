-- Corrective: fix WRONG search-term redirects that migration 535 could not repair.
--
-- 535 guarded with `AND (redirect IS NULL OR redirect = '')` so it never
-- overwrote an existing redirect. On SG prod the `crewai` row ALREADY had a
-- redirect -- pointing at the Autogen course -- so 535 silently skipped it and
-- the wrong destination stayed live. `crew AI` pointed at ai-for-healthcare.
--
-- These two rows are known-wrong, so this migration deliberately overwrites a
-- NON-empty redirect. It is therefore scoped to the exact wrong URLs, so it can
-- never clobber a redirect that someone has since corrected by hand.

-- 'crewai' -> the CrewAI/Autogen/ADK/Streamlit course (was: Autogen course)
UPDATE catalogsearch_query
SET redirect = 'https://www.tertiarycourses.com.sg/wsq-build-and-deploy-agentic-ai-apps-with-crewai-autogen-adk-and-streamlit.html'
WHERE query_text = 'crewai'
  AND store_id = 1
  AND (redirect IS NULL OR redirect = ''
       OR redirect = 'https://www.tertiarycourses.com.sg/wsq-develop-multi-agent-ai-applications-with-autogen.html');

-- 'crew AI' -> same CrewAI course (was: unrelated ai-for-healthcare page)
UPDATE catalogsearch_query
SET redirect = 'https://www.tertiarycourses.com.sg/wsq-build-and-deploy-agentic-ai-apps-with-crewai-autogen-adk-and-streamlit.html'
WHERE query_text = 'crew AI'
  AND store_id = 1
  AND (redirect IS NULL OR redirect = ''
       OR redirect = 'https://www.tertiarycourses.com.sg/ai-for-healthcare.html');
