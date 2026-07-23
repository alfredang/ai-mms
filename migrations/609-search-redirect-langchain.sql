-- Search term "langchain" -> WSQ Build LLM Applications Using Flowise and LangChain
-- Only fills an empty redirect; never overwrites an existing intentional target.
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/wsq-build-llm-applications-using-flowise-and-langchain.html'
 WHERE query_text = 'langchain'
   AND (redirect IS NULL OR redirect = '');
