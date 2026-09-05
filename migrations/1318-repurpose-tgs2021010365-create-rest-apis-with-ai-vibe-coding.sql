-- 1318 : Repurpose TGS-2021010365 (product 1266)
--        "WSQ - Create RESTful APIs and Web Apps with Python Flask"
--     -> "WSQ - Create REST APIs with AI Vibe Coding"
--
-- SKU is UNCHANGED, so every SkillsFuture / SFEC / SFC / PSEA / UTAP deep link
-- keyed on TGS-2021010365 stays valid, and the funding_and_grant block needs no edit.
-- Funding validity 22-12-2021 -> 21-12-2027 already matches news_from/to_date; no change.
--
-- Surfaces touched: name, meta_title (also fixes the pre-existing duplicated "WSQ"
-- + brand suffix that MMD_Seotitle adds at render time), meta_description,
-- meta_keyword, url_key/url_path + 301, image/small_image/thumbnail labels,
-- media-gallery label, short_description, description (course outline),
-- learning_outcomes cms_block, whoshouldattend, trainerprofile (para-2 teaching
-- claims only), categories, tags, search redirects.
--
-- Deliberately NOT touched:
--  * prerequisite  - its software list is Python / VS Code / Anaconda / Colab,
--                    all still in scope for AI-assisted REST API work; the blob
--                    also carries the whole funding apparatus (PWM, eligibility
--                    table, SkillsFuture/PSEA/SFEC/UTAP deep links).
--  * funding_and_grant / certification / skills_framework cms_blocks - the
--    accredited competency (Applications Integration ICT-DIT-3003-1.1 TSC) and
--    the fee table are registered against the UNCHANGED SKU.
--  * image / small_image / thumbnail  - filesystem paths, renaming 404s them.
--  * review_detail rows - genuine learner testimonials, none name Flask.
--  * trainer career-history credentials (para 1 of each bio) - real facts.
--
-- SG-only. Partner sites (MY/GH) never held this SKU; the @is_sg guard makes
-- this a no-op there.

SET @is_sg := (SELECT COUNT(*) FROM core_config_data
               WHERE path = 'web/unsecure/base_url' AND value LIKE '%tertiarycourses.com.sg%');

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2021010365');
SET @et := 4;

SET @a_name        := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='name');
SET @a_urlkey      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='url_key');
SET @a_urlpath     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='url_path');
SET @a_mtitle      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='meta_title');
SET @a_mdesc       := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='meta_description');
SET @a_mkw         := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='meta_keyword');
SET @a_ilabel      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='image_label');
SET @a_slabel      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='small_image_label');
SET @a_tlabel      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='thumbnail_label');
SET @a_sdesc       := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='short_description');
SET @a_desc        := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='description');
SET @a_who         := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='whoshouldattend');
SET @a_trainer     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='trainerprofile');

SET @newname  := 'WSQ - Create REST APIs with AI Vibe Coding';
SET @newslug  := 'wsq-create-rest-apis-with-ai-vibe-coding';
SET @oldslug  := 'wsq-create-restful-apis-and-web-apps-with-python-flask';
SET @plaintitle := 'Create REST APIs with AI Vibe Coding';

-- ---------------------------------------------------------------- 1. name
UPDATE catalog_product_entity_varchar
   SET value = @newname
 WHERE entity_id = @e AND attribute_id = @a_name AND @is_sg > 0 AND @e IS NOT NULL;

-- ------------------------------------------- 2. meta_title (PLAIN, no "WSQ", no brand)
-- MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs and appends the brand postfix
-- at render time. The stored value had both baked in, producing
-- "WSQ funded WSQ Web API Integration ... | Tertiary Courses Singapore".
UPDATE catalog_product_entity_varchar
   SET value = @plaintitle
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @is_sg > 0 AND @e IS NOT NULL;

-- ------------------------------------------------------- 3. meta_description (<=255)
UPDATE catalog_product_entity_varchar
   SET value = 'Build, test and secure REST APIs with AI Vibe Coding. Learn endpoints, HTTP methods, JSON, CRUD, database integration and API security. Up to 70% WSQ funding.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @is_sg > 0 AND @e IS NOT NULL;

-- ------------------------------------------------------------------ 4. meta_keyword
UPDATE catalog_product_entity_text
   SET value = 'REST API, AI Vibe Coding, WSQ, API Integration, HTTP Methods, JSON, CRUD, Postman, API Security'
 WHERE entity_id = @e AND attribute_id = @a_mkw AND @is_sg > 0 AND @e IS NOT NULL;

-- ------------------------------------------------------- 5. alt-text labels (no "WSQ - ")
UPDATE catalog_product_entity_varchar
   SET value = @plaintitle
 WHERE entity_id = @e AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel)
   AND @is_sg > 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @plaintitle
 WHERE g.entity_id = @e AND @is_sg > 0 AND @e IS NOT NULL;

-- -------------------------------------------------------------- 6. short_description
-- Sections were long since extracted to cms_blocks, so sdesc is intro prose only
-- (no "<h2>Course Brochure</h2>" tail) -> full replace is the correct shape.
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<p>The WSQ Create REST APIs with AI Vibe Coding course equips learners with practical skills to design, build, test, and integrate REST APIs using modern <strong>AI-assisted coding techniques</strong>. Through hands-on activities, participants will use AI coding tools to accelerate development, generate code, troubleshoot errors, and refine API functionality while developing a strong understanding of REST API fundamentals.</p>',
'<p>Learners will explore key API concepts including <strong>endpoints, routes, HTTP methods, request and response handling, status codes, JSON data, and URL structures</strong>. They will build REST APIs that support common operations such as creating, retrieving, updating, and deleting data, and use tools such as <strong>Postman</strong> to test and validate API behaviour.</p>',
'<p>The course also covers <strong>database integration and CRUD operations</strong>, enabling learners to connect APIs to persistent data sources and manage application data effectively. Participants will explore authentication, input validation, error handling, and API security practices to develop more reliable and secure solutions.</p>',
'<p>Throughout the course, learners will apply <strong>AI Vibe Coding</strong> in practical development workflows&mdash;using natural-language instructions and iterative AI-assisted coding to rapidly create, test, debug, and improve APIs. By the end of the course, participants will be able to develop functional REST APIs and integrate them with web applications, databases, and external services.</p>')
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0
   AND @is_sg > 0 AND @e IS NOT NULL;

-- ------------------------------------------------------- 7. description (Course Outline)
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<h3 class="course-topic-h3">Topic 1: REST API Fundamentals with AI Vibe Coding</h3>',
'<ul><li>Understand REST API Principles, Endpoints and Routes</li>',
'<li>Set Up an AI-Assisted Development Workflow</li>',
'<li>Generate a First Working REST API with Natural-Language Prompts</li>',
'<li>Run and Inspect API Responses</li></ul>',
'<h3 class="course-topic-h3">Topic 2: Data, Functions and API Response Handling</h3>',
'<ul><li>Integrate Data and Variables into API Responses</li>',
'<li>Implement Functions and Control Structures with AI Assistance</li>',
'<li>Handle Request Parameters and Input Data</li>',
'<li>Apply Error Handling and Input Validation</li></ul>',
'<h3 class="course-topic-h3">Topic 3: REST API Integration with JSON and HTTP Methods</h3>',
'<ul><li>Work with JSON Data Structures</li>',
'<li>Apply HTTP Methods and Status Codes</li>',
'<li>Implement Variable Rules and URL Structures</li>',
'<li>Integrate REST APIs with Web Applications and External Services</li></ul>',
'<h3 class="course-topic-h3">Topic 4: Database Connectivity and CRUD Operations</h3>',
'<ul><li>Connect a REST API to a Database</li>',
'<li>Serialize and Map Data Between API and Database</li>',
'<li>Implement Create, Retrieve, Update and Delete Operations</li>',
'<li>Troubleshoot Connection Errors with AI Coding Tools</li></ul>',
'<h3 class="course-topic-h3">Topic 5: API Testing, Authentication and Security</h3>',
'<ul><li>Test and Validate API Behaviour with Postman</li>',
'<li>Implement Registration and Login Authentication</li>',
'<li>Apply API Security Practices and Access Control</li>',
'<li>Review and Refine AI-Generated Code for Reliability</li></ul>')
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0
   AND @is_sg > 0 AND @e IS NOT NULL;

-- ----------------------------------------------------- 8. whoshouldattend (tool-neutral)
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<ul><li>Back-End Developer</li>',
'<li>Full Stack Developer</li>',
'<li>REST API Developer</li>',
'<li>Web Application Developer</li>',
'<li>Software Engineer (with web focus)</li>',
'<li>API Integration Specialist</li>',
'<li>System Integration Specialist</li>',
'<li>Microservices Developer</li>',
'<li>Data Engineer (web data pipelines)</li>',
'<li>Front-End Developer (expanding skills to backend)</li>',
'<li>Automation Engineer (building or consuming APIs)</li>',
'<li>DevOps Engineer (building or maintaining APIs)</li>',
'<li>Cloud Solutions Architect (with a focus on web services)</li>',
'<li>Technical Product Manager (overseeing API development)</li>',
'<li>IT Professional adopting AI-assisted development.</li></ul>')
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0
   AND @is_sg > 0 AND @e IS NOT NULL;

-- --------------------------------------- 9. learning_outcomes cms_block (guarded insert)
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2021010365 - Learning Outcomes', 'course_TGS-2021010365_learning_outcomes', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @is_sg > 0
   AND NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block
                   WHERE identifier = 'course_TGS-2021010365_learning_outcomes') x);

SET @lo_block := (SELECT block_id FROM cms_block
                  WHERE identifier = 'course_TGS-2021010365_learning_outcomes' LIMIT 1);

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT @lo_block, 0 FROM DUAL WHERE @is_sg > 0 AND @lo_block IS NOT NULL;

UPDATE cms_block
   SET content = CONCAT(
'<p>By the end of the course, learners will be able to&nbsp;</p>',
'<ul>',
'<li>LO1: Identify and assess REST API to create connections</li>',
'<li>LO2: Integrate data and functions with REST API.</li>',
'<li>LO3: Support REST API integration</li>',
'<li>LO4: Perform tests and checks on the connection to databases</li>',
'<li>LO5: Modify the REST API to enhance integration and security.</li>',
'</ul>'),
       update_time = NOW()
 WHERE block_id = @lo_block AND @is_sg > 0 AND @lo_block IS NOT NULL;

-- ------------------------------------------------------------ 10. brochure block title
UPDATE cms_block
   SET title = 'Course Brochure - TGS-2021010365'
 WHERE identifier = 'course_TGS-2021010365_brochure' AND @is_sg > 0;

-- ------------------------------- 11. trainerprofile: retarget para-2 teaching claims only
-- Para 1 of each bio is career-history CREDENTIALS (real Flask/Python experience)
-- and stays untouched. Only the "In <old title>, ..." paragraph retargets.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
'<p>In &ldquo;Create RESTful APIs and Web Apps with Python Flask,&rdquo; Afiq teaches participants how to design, develop, and deploy dynamic web applications using Python. His sessions cover essential Flask components such as routing, templating, and database integration, with a strong focus on REST API best practices and JSON-based communication. Through real-world coding exercises, he helps learners understand how to create efficient, modular, and scalable Flask applications suitable for data-driven and enterprise use cases.</p>',
'<p>In &ldquo;Create REST APIs with AI Vibe Coding,&rdquo; Afiq teaches participants how to design, build and test REST APIs using AI-assisted coding workflows. His sessions cover endpoints and routes, HTTP methods and status codes, JSON request and response handling, and database-backed CRUD operations. Through real-world coding exercises, he helps learners use natural-language prompting to accelerate development while reviewing AI-generated code for correctness, modularity and scalability.</p>')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0
   AND @is_sg > 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
'<p>In &ldquo;Create RESTful APIs and Web Apps with Python Flask,&rdquo; Dr. Ang guides learners through the architecture and implementation of scalable APIs and data-centric web solutions. His sessions highlight Flask&rsquo;s modular design and its integration with AI-driven backends and databases. By combining theoretical understanding with practical examples, he enables participants to develop secure, efficient web services that can support advanced analytics, automation, and machine learning workflows.</p>',
'<p>In &ldquo;Create REST APIs with AI Vibe Coding,&rdquo; Dr. Ang guides learners through the architecture and implementation of scalable REST APIs built with AI coding assistants. His sessions highlight endpoint design, JSON data contracts and integration with databases and external services. By combining theoretical understanding with practical examples, he enables participants to develop secure, efficient web services that can support advanced analytics, automation, and machine learning workflows.</p>')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0
   AND @is_sg > 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
'<p>In &ldquo;Create RESTful APIs and Web Apps with Python Flask,&rdquo; Hwee Theng focuses on the application of API-based architectures in AI and analytics-driven workflows. Her sessions explore how Python Flask can be used to connect machine learning models, automate data pipelines, and expose services for business intelligence applications. By combining her expertise in AI strategy and system integration, she empowers learners to design web applications that intelligently interact with data and predictive services.</p>',
'<p>In &ldquo;Create REST APIs with AI Vibe Coding,&rdquo; Hwee Theng focuses on the application of API-based architectures in AI and analytics-driven workflows. Her sessions explore how AI-assisted development can rapidly produce REST endpoints that connect machine learning models, automate data pipelines, and expose services for business intelligence applications. By combining her expertise in AI strategy and system integration, she empowers learners to design applications that intelligently interact with data and predictive services.</p>')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0
   AND @is_sg > 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
'<p>In &ldquo;Create RESTful APIs and Web Apps with Python Flask,&rdquo; Chee Yong introduces learners to the fundamentals of Python web development and API creation. He covers Flask&rsquo;s key features&mdash;such as routing, template rendering, and RESTful communication&mdash;while emphasizing clean architecture and reusable code. Through guided projects, he helps participants gain hands-on experience in developing end-to-end Flask applications for data sharing and automation.</p>',
'<p>In &ldquo;Create REST APIs with AI Vibe Coding,&rdquo; Chee Yong introduces learners to the fundamentals of REST API creation with AI coding assistants. He covers routing, request and response handling, status codes and RESTful communication&mdash;while emphasizing clean architecture, reusable code and validation of AI-generated output. Through guided projects, he helps participants gain hands-on experience in developing end-to-end APIs for data sharing and automation.</p>')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0
   AND @is_sg > 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
'<p>In &ldquo;Create RESTful APIs and Web Apps with Python Flask,&rdquo; Bernard teaches participants how to build and deploy APIs that connect applications, data sources, and analytical platforms. His sessions emphasize using Flask to enable communication between front-end interfaces and back-end systems while ensuring security and scalability. By combining technical knowledge with real-world insights, Bernard helps learners develop robust web solutions for analytics, automation, and AI-driven decision-making.</p>',
'<p>In &ldquo;Create REST APIs with AI Vibe Coding,&rdquo; Bernard teaches participants how to build and deploy APIs that connect applications, data sources, and analytical platforms. His sessions emphasize using AI-assisted coding to enable communication between front-end interfaces and back-end systems while ensuring authentication, security and scalability. By combining technical knowledge with real-world insights, Bernard helps learners develop robust API solutions for analytics, automation, and AI-driven decision-making.</p>')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0
   AND @is_sg > 0 AND @e IS NOT NULL;

-- ------------------------------------------------------ 12. url_key + url_path + 301
-- Clear any is_system=0 squatter already sitting on the NEW path.
DELETE FROM core_url_rewrite
 WHERE request_path = CONCAT(@newslug, '.html') AND is_system = 0
   AND @is_sg > 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = @newslug
 WHERE entity_id = @e AND attribute_id = @a_urlkey AND @is_sg > 0 AND @e IS NOT NULL;

-- Drop url_path at EVERY scope so the URL Rewrites indexer regenerates it.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlpath AND @is_sg > 0 AND @e IS NOT NULL;

-- The old bare slug is held by an is_system=1 row whose id_path is the SAME
-- (product/1266) the 301 needs -> INSERT IGNORE would silently no-op. Delete it first.
DELETE FROM core_url_rewrite
 WHERE product_id = @e AND request_path = CONCAT(@oldslug, '.html') AND is_system = 1
   AND @is_sg > 0 AND @e IS NOT NULL;

INSERT IGNORE INTO core_url_rewrite
  (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT 1, NULL, @e, CONCAT('product/', @e), CONCAT(@oldslug, '.html'), CONCAT(@newslug, '.html'), 0, 'RP', NULL
  FROM DUAL WHERE @is_sg > 0 AND @e IS NOT NULL;

-- Flatten the existing 301 chains: aliases that pointed at the OLD bare slug now
-- point straight at the new one (no 301 -> 301 hop).
UPDATE core_url_rewrite
   SET target_path = CONCAT(@newslug, '.html')
 WHERE target_path = CONCAT(@oldslug, '.html') AND is_system = 0 AND options = 'RP'
   AND request_path <> CONCAT(@oldslug, '.html')
   AND @is_sg > 0 AND @e IS NOT NULL;

UPDATE core_url_rewrite
   SET target_path = REPLACE(target_path, CONCAT('/', @oldslug, '.html'), CONCAT('/', @newslug, '.html'))
 WHERE target_path LIKE CONCAT('%/', @oldslug, '.html') AND is_system = 0 AND options = 'RP'
   AND @is_sg > 0 AND @e IS NOT NULL;

-- Category-path aliases on the OLD slug -> 301 to the new bare slug.
UPDATE core_url_rewrite
   SET target_path = CONCAT(@newslug, '.html'), is_system = 0, options = 'RP', category_id = NULL
 WHERE product_id = @e AND is_system = 1
   AND request_path LIKE CONCAT('%/', @oldslug, '.html')
   AND @is_sg > 0 AND @e IS NOT NULL;

-- ------------------------------------------------------------------- 13. categories
-- ADD: 252 AI Courses, 414 AI Vibe Coding Series, 425 WSQ AI Vibe Coding Courses
--      (every WSQ AI Vibe Coding sibling sits in all three).
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT c.cid, @e, COALESCE((SELECT MAX(position) FROM catalog_category_product x
                            WHERE x.category_id = c.cid), 0) + 1
  FROM (SELECT 252 AS cid UNION ALL SELECT 414 UNION ALL SELECT 425) c
 WHERE @is_sg > 0 AND @e IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, cp.product_id, cp.position, 1, 1, 4
  FROM catalog_category_product cp
 WHERE cp.product_id = @e AND cp.category_id IN (252, 414, 425)
   AND @is_sg > 0 AND @e IS NOT NULL;

-- DROP: 32 Python, 352 Web Framework - the course no longer teaches Python Flask
-- as its subject. Kept: 4 Web Development, 31 Programming, 388 REST API, 333 WSQ
-- Web Design & Full Stack, and every broad WSQ listing.
DELETE FROM catalog_category_product
 WHERE product_id = @e AND category_id IN (32, 352) AND @is_sg > 0 AND @e IS NOT NULL;

DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND category_id IN (32, 352) AND @is_sg > 0 AND @e IS NOT NULL;

-- ------------------------------------------------------------------------ 14. tags
-- UTAP is banned in outbound marketing but the on-page badge follows funding
-- eligibility; sibling WSQ vibe courses carry WSQ / SkillsFuture Credit / SFEC /
-- MCES / Absentee Payroll / PSEA. Existing tag set already matches - no change.

-- --------------------------------------------------------------- 15. search redirects
-- Old-title intent ("Python Flask", "NICF Web API integration with Python Flask")
-- should NOT land on a course that no longer teaches Flask. Retarget those to the
-- topically-correct live sibling; only the bare course code and generic API terms
-- follow the renamed course.
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @newslug, '.html')
 WHERE store_id = 1 AND @is_sg > 0
   AND query_text IN ('TGS-2021010365', 'APIs', 'wsq api');

UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/ai-vibe-coding-for-python.html'
 WHERE store_id = 1 AND @is_sg > 0
   AND query_text IN ('wsq flask',
                      'NICF Web API integration with Python Flask',
                      'WSQ - Web API integration with Python Flask',
                      'Create RESTful APIs and Web Apps with Python Flask',
                      'WSQ - Create RESTful APIs and Web Apps with Python Flask');
