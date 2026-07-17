-- Redirect the "crewai" search term to the WSQ CrewAI/Autogen/ADK course page.
-- Data-only (catalogsearch_query.redirect). Only fills an empty redirect so an
-- intentional product-page redirect is never overwritten.
UPDATE catalogsearch_query
SET redirect = 'https://www.tertiarycourses.com.sg/wsq-build-and-deploy-agentic-ai-apps-with-crewai-autogen-adk-and-streamlit.html'
WHERE query_text = 'crewai'
  AND (redirect IS NULL OR redirect = '');
