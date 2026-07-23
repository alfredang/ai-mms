-- React category (url_key react-js-courses): new vibe-coding banner image
-- and a rewritten description centred on learning React with the AI
-- vibe-coding methodology. Mirrors 639 (Python category).
--
-- The image value is the bare filename (stock category image attribute); on SG
-- the MMD_CourseImage getImageUrl() rewrite serves it from R2
-- (catalog/category/react-vibe-coding-courses.png, uploaded + verified 200),
-- and the media/.htaccess 302 fallback covers instances without R2_PUBLIC_URL.
-- Category resolved by url_key so this no-ops if the category is absent.
-- Idempotent (INSERT ... ON DUPLICATE KEY UPDATE at store 0).
-- apply.php note: no content line ends in a semicolon.

SET @react_cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'react-js-courses' LIMIT 1);

SET @cat_image := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'image');
SET @cat_description := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'description');

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @cat_image, 0, @react_cat, 'react-vibe-coding-courses.png'
FROM DUAL WHERE @react_cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @cat_description, 0, @react_cat, '<p>Vibe coding is a new way of building software: instead of memorising syntax and APIs, you describe what you want in plain language and let AI coding assistants such as Cursor, GitHub Copilot and Claude generate, explain, refactor and debug the code while you stay in control of the design and logic. React, the world&rsquo;s most popular library for building user interfaces, is a perfect fit for this workflow &mdash; you describe the components, state and interactions you want, and the AI helps you express them as clean, reusable React code.</p>
<p>Our React vibe coding courses teach you React through this AI-assisted methodology from day one. Guided by experienced trainers, you will prompt, review and refine AI-generated components, hooks and full applications &mdash; from JSX fundamentals, props and state to routing, API integration and deploying complete React apps to the web. Along the way you will learn to read, test and improve the code your AI assistant produces, so your interfaces stay fast, accessible and maintainable and you genuinely understand the React behind them.</p>
<p>Whether you are a complete beginner building your first web app or an experienced developer looking to multiply your front-end productivity, our hands-on React vibe coding courses will help you learn React faster, ship polished user interfaces sooner, and master the AI-assisted workflow that is rapidly becoming the way modern software is written.</p>'
FROM DUAL WHERE @react_cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
