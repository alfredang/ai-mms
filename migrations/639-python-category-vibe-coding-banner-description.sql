-- Python category (url_key python-programming): new vibe-coding banner image
-- and a rewritten description centred on learning Python with the AI
-- vibe-coding methodology.
--
-- The image value is the bare filename (stock category image attribute); on SG
-- the MMD_CourseImage getImageUrl() rewrite serves it from R2
-- (catalog/category/python-vibe-coding-courses.png, uploaded + verified 200),
-- and the media/.htaccess 302 fallback covers instances without R2_PUBLIC_URL.
-- Category resolved by url_key so this no-ops if the category is absent.
-- Idempotent (INSERT ... ON DUPLICATE KEY UPDATE at store 0).
-- apply.php note: no content line ends in a semicolon.

SET @python_cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'python-programming' LIMIT 1);

SET @cat_image := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'image');
SET @cat_description := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'description');

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @cat_image, 0, @python_cat, 'python-vibe-coding-courses.png'
FROM DUAL WHERE @python_cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @cat_description, 0, @python_cat, '<p>Vibe coding is a new way of learning and writing software: instead of memorising syntax, you describe what you want in plain language and let AI coding assistants such as Cursor, GitHub Copilot and Claude generate, explain, refactor and debug the code while you stay in control of the design and logic. Python, with its simple readable syntax and huge ecosystem of libraries for web development, data analysis, machine learning and automation, is the ideal language to learn this way &mdash; you focus on what the program should do, and the AI helps you express it in clean, working Python.</p>
<p>Our Python vibe coding courses teach you Python through this AI-assisted methodology from day one. Guided by experienced trainers, you will prompt, review and refine AI-generated Python code to build real projects &mdash; from fundamentals, scripts and automation to data analysis, machine learning and complete applications deployed on the web. Along the way you will learn to read, test and improve the code your AI assistant produces, so your programs stay correct, robust and maintainable and you genuinely understand the Python behind them.</p>
<p>Whether you are a complete beginner writing your first program or an experienced developer looking to multiply your productivity, our hands-on Python vibe coding courses will help you learn Python faster, build useful applications sooner, and master the AI-assisted workflow that is rapidly becoming the way modern software is written.</p>'
FROM DUAL WHERE @python_cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
