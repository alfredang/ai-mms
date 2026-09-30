-- C138 AI Vibe Coding with Python: course topics follow the delivered courseware.
-- 1604 copied the WSQ parent's product-page topic list, but the courseware
-- (github.com/tertiarycourses/C138-AI-Vibe-Coding-with-Python, 20 CardGuard labs)
-- teaches a different five-topic outline. The page now lists the topics actually
-- taught, and meta_description/meta_keyword follow suit.
-- SG-only (store guard) and keyed by SKU. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C138' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL);

SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_mdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');

UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1 Vibe Coding Foundations","subsecs":[]},{"title":"Topic 2 Object-Oriented Programming in Python","subsecs":[]},{"title":"Topic 3 Data Analytics with pandas","subsecs":[]},{"title":"Topic 4 Data Modelling with Pydantic and FastAPI","subsecs":[]},{"title":"Topic 5 Packaging and Deployment","subsecs":[]}] -->\n<p><strong>Topic 1 Vibe Coding Foundations</strong></p>\n<p><strong>Topic 2 Object-Oriented Programming in Python</strong></p>\n<p><strong>Topic 3 Data Analytics with pandas</strong></p>\n<p><strong>Topic 4 Data Modelling with Pydantic and FastAPI</strong></p>\n<p><strong>Topic 5 Packaging and Deployment</strong></p>\n'
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_desc AND store_id = 0;

UPDATE catalog_product_entity_varchar
   SET value = 'Build and deploy a Python app with AI vibe coding. Master OOP, pandas analytics, Pydantic and FastAPI, then package and deploy with Docker in this hands-on course at Tertiary Courses Singapore.'
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc AND store_id = 0;

UPDATE catalog_product_entity_text
   SET value = 'AI Vibe Coding, Python, vibe coding, AI coding assistant, Python OOP, pandas, Pydantic, FastAPI, Streamlit, Docker, uv, build and deploy Python applications, Python programming Singapore'
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mkey AND store_id = 0;
