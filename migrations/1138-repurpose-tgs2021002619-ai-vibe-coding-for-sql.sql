-- 1138: Repurpose TGS-2021002619
--   "WSQ - Vibe Coding a Full Stack NoSQL Web Apps"
--     -> "WSQ - AI Vibe Coding for SQL"
--
-- SKU unchanged (every SkillsFuture / SFEC / SFC / PSEA deep link is keyed on
-- it). Admin-supplied 2026-08-27: new title, LO1-LO4, 4 outline topics and the
-- About This Course narrative. This is a REPURPOSE (subject moved from NoSQL
-- full-stack web apps to relational SQL), so content + taxonomy surfaces move
-- too, per the 998 precedent (ScikitLearn -> AI Vibe Coding for Data Analytics).
--
-- Pre-write EAV sweep of BOTH value tables + rewrites + search redirects +
-- categories run against LIVE SG prod 2026-08-27 (entity_id 1168). Nothing was
-- pre-applied; every surface below verified still on the old topic.
--
-- Surfaces touched:
--   name, url_key (+ url_path DELETE at every scope), meta_title (also fixes
--   the baked-in "WSQ ... | Tertiary Courses Singapore" 853-bug shape),
--   meta_description, meta_keyword, short_description (About This Course, full
--   replace -- prose-only sdesc, sections already stripped to cms blocks),
--   description (Course Outline, headings-only house format per 960/967/997/999),
--   learning_outcomes cms_block (admin-supplied tool-neutral LO1-LO4),
--   image/small/thumbnail LABELS + media-gallery label (alt text, plain title),
--   prerequisite (ONE <li>: MongoDB download link -> MySQL; funding apparatus
--   untouched -- deep-link counts preserved: myskillsfuture=4, ntuc=2, mom=1),
--   trainerprofile (course-teaching paragraphs only, one single-line REPLACE
--   per bio -- blob is CRLF, multi-line REPLACE would silently no-op),
--   the old bare slug's 301 (is_system=1 row DELETEd first or INSERT IGNORE
--   no-ops on the shared id_path and the new slug gets a -1168 suffix),
--   chain-flatten of every is_system=0 alias targeting the old filename,
--   catalogsearch_query rows pointing at the old slug (topically retargeted:
--   mongo/nosql intent -> nosql-courses.html category page, because the NoSQL /
--   MongoDB Essential Training products 917/918 are DISABLED; "vibe coding
--   full stack" intent -> the live sibling WSQ AI Vibe Coding for Full Stack
--   Web Applications; only the bare course code follows this course),
--   categories: DROP 340 NoSQL + 333 WSQ Web Design & Full Stack (both now
--   misdescribe the course), ADD 339 Relational SQL -- mirrored into
--   catalog_category_product_index (963 shape).
--
-- Deliberately NOT touched (verified against live data before writing):
--   - sku, price, duration (8), sessions (1) -- accredited course params.
--   - whoshouldattend: the 15 roles are DB/data roles (Database Administrator,
--     Data Analyst, ...) with zero NoSQL mentions -- they fit the SQL course
--     as-is; rewriting would be churn.
--   - skills_framework cms_block ("Data Engineering ICT-DES-3008-1.1 TSC"):
--     registered against the UNCHANGED SKU and the new LOs (modelling,
--     processing, aggregation, mapping to warehouse) align to it BETTER than
--     the old web-apps content did.
--   - funding_and_grant / certification / brochure cms_blocks: keyed on the
--     unchanged SKU; fee table and OpenCerts wording unaffected.
--   - badge tags (WSQ, SkillsFuture Credit, SFEC, Absentee Payroll, MCES).
--   - image/small_image/thumbnail PATHS (/w/s/wsq-vibe-coding-...jpg):
--     filesystem paths, not display text; renaming them 404s the file. The
--     storefront renders course_image_url (updated below to the new R2 cover).
--   - trainer credential paragraphs: "leveraging NoSQL databases ... at Janio
--     Asia", "MongoDB, Cassandra, and Redis" delivery history etc. are FACTS,
--     remaining NoSQL mentions in para 1 of each bio are the PASS condition of
--     the post-apply grep, not leaks.
--
-- NEW SLUG COLLISION CHECK: url_key LIKE '%vibe-coding-for-sql%' returned zero
-- rows on live SG; the WSQ family convention is wsq-ai-vibe-coding-for-<topic>
-- (siblings: ...-data-analytics, ...-ui-ux, ...-excel-vba, ...).
--
-- PARTNER SAFETY: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement below is a guarded no-op there.
--
-- IDEMPOTENT: full-target-value writes, NOT EXISTS-guarded inserts, and
-- REPLACE()s whose old string no longer exists after the first run.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2021002619' LIMIT 1);

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_sdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_ilabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_slabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_tlabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='prerequisite');
SET @a_trainer := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='trainerprofile');

-- ---------------------------------------------------------------------------
-- 1. name (keep the "WSQ - " prefix -- the storefront H1 wants it)
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'WSQ - AI Vibe Coding for SQL'
WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 2. url_key + url_path (delete url_path at EVERY scope so the URL Rewrites
--    indexer regenerates; live SG holds rows at store 0 AND store 1)
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'wsq-ai-vibe-coding-for-sql'
WHERE entity_id = @e AND attribute_id = @a_urlkey AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND attribute_id = @a_urlpath AND @e IS NOT NULL;

-- Drop any is_system=0 squatter on the NEW path (INSERT IGNORE / the indexer
-- silently defer to a stale row -- the 647 trap).
DELETE FROM core_url_rewrite
WHERE request_path = 'wsq-ai-vibe-coding-for-sql.html' AND is_system = 0 AND @e IS NOT NULL;

-- Drop the is_system=1 row holding the OLD bare slug: it shares id_path
-- product/1168 with the 301 below, so INSERT IGNORE would no-op against it AND
-- the refresh would mint a -1168 suffix for the new slug (memory
-- feedback_repurpose_301_needs_system_row_delete).
DELETE FROM core_url_rewrite
WHERE product_id = @e AND request_path = 'wsq-vibe-coding-a-full-stack-nosql-web-apps.html'
  AND is_system = 1 AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug. The indexer auto-301s the category paths
-- from its rewrite history; only the bare slug needs seeding.
INSERT IGNORE INTO core_url_rewrite
    (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT 1, NULL, @e,
       CONCAT('product/', @e),
       'wsq-vibe-coding-a-full-stack-nosql-web-apps.html',
       'wsq-ai-vibe-coding-for-sql.html',
       0, 'RP', 'Repurpose 1138: old NoSQL Web Apps slug -> AI Vibe Coding for SQL'
FROM dual
WHERE @e IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
    WHERE x.request_path = 'wsq-vibe-coding-a-full-stack-nosql-web-apps.html'
      AND x.store_id = 1 AND x.is_system = 0
);

-- Chain-flatten: ~20 is_system=0 aliases (wsq-mongodb-nosql-course.html family,
-- deep legacy category paths, vibe-coding-courses/... etc.) still TARGET the
-- old filename and would 301-chain. Anchored on the FULL old filename so the
-- sibling nosql-essential-training / mongodb-essential-training aliases are
-- untouched (memory feedback_rename_chain_flatten_must_anchor_request_path).
UPDATE core_url_rewrite
SET target_path = REPLACE(target_path,
      'wsq-vibe-coding-a-full-stack-nosql-web-apps.html',
      'wsq-ai-vibe-coding-for-sql.html')
WHERE is_system = 0
  AND target_path LIKE '%wsq-vibe-coding-a-full-stack-nosql-web-apps.html'
  AND request_path <> 'wsq-vibe-coding-a-full-stack-nosql-web-apps.html'
  AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 3. meta_title / meta_description / meta_keyword
--    meta_title is the PLAIN title: MMD_Seotitle prepends "WSQ funded" and
--    appends the brand suffix at render time. The old value baked in both.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'AI Vibe Coding for SQL'
WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
SET value = 'Learn AI Vibe Coding for SQL - design, query and manage relational databases with AI coding assistants. Build schemas, run queries and dashboards. WSQ course in Singapore. Enjoy up to 70% WSQ funding subsidy.'
WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
SET value = 'AI Vibe Coding, SQL course Singapore, relational database training, WSQ SQL course, AI coding assistant, SQL queries, data modelling, data aggregation, data warehouse, dashboard development, AI-assisted coding, WSQ funded IT course'
WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 4. short_description -- About This Course (admin-supplied, full replace).
--    Live sdesc is prose-only (sections were stripped to cms blocks in the
--    2026-07-21 prod strip), so a full replace is the correct shape here.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<p>AI Vibe Coding for SQL equips learners with practical skills to design, query and manage relational databases using natural-language instructions and AI coding assistants. Participants will learn how to translate business and application requirements into database structures and working SQL statements without having to write every command manually.</p>
<p>The course covers essential SQL concepts, including tables, relationships, data types, primary and foreign keys, data insertion, filtering, sorting, joins, aggregation and subqueries. Learners will use AI-assisted workflows to generate, explain, refine and optimise SQL queries for common data management and reporting tasks.</p>
<p>Through hands-on exercises, participants will create relational database schemas, import and organise data, perform CRUD operations and connect databases to applications and interactive dashboards. They will also apply AI tools to troubleshoot query errors, identify data-quality issues and recommend improvements to database performance.</p>
<p>Emphasis is placed on validating AI-generated SQL for accuracy, efficiency and security. By the end of the course, participants will be able to use AI Vibe Coding techniques to develop database solutions, analyse structured data and produce meaningful reports that support business and application needs.</p>'
WHERE entity_id = @e AND attribute_id = @a_sdesc AND @e IS NOT NULL;

-- Drop any store-scoped override so the store 0 value renders everywhere.
DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 5. description -- Course Outline, headings-only house format (960/967/997/999
--    shape; the stale LSN_DATA comment is dropped with the old body).
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<h3 class="course-topic-h3">Topic 1: AI-Assisted SQL Data Modelling and Database Design</h3>
<h3 class="course-topic-h3">Topic 2: SQL Data Processing, Querying and Analysis</h3>
<h3 class="course-topic-h3">Topic 3: SQL Data Aggregation and Transformation</h3>
<h3 class="course-topic-h3">Topic 4: Data Mapping, Warehousing and Dashboard Development</h3>'
WHERE entity_id = @e AND attribute_id = @a_desc AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND attribute_id = @a_desc AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 6. learning_outcomes cms_block -- admin-supplied tool-neutral LO1-LO4 (the
--    old block named MongoDB NoSQL per outcome). Guarded-INSERT first (931
--    shape: the block might not exist on a rebuilt DB), then UPDATE converges.
-- ---------------------------------------------------------------------------
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2021002619 — Learning Outcomes', 'course_TGS-2021002619_learning_outcomes', '', NOW(), NOW(), 1
FROM dual
WHERE @e IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM cms_block) b
                   WHERE b.identifier = 'course_TGS-2021002619_learning_outcomes');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b
WHERE b.identifier = 'course_TGS-2021002619_learning_outcomes' AND @e IS NOT NULL;

UPDATE cms_block
SET content = '<p dir="ltr"><span>By end of the course, learners should be able to</span></p>
<ul>
<li>LO1: Apply data modelling</li>
<li>LO2: Apply data processing and analysis</li>
<li>LO3: Apply data aggregation and transformation.</li>
<li>LO4: Perform data mapping to data warehouse</li>
</ul>'
WHERE identifier = 'course_TGS-2021002619_learning_outcomes' AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 7. Alt-text labels + media-gallery label -- PLAIN title (the cover PNG
--    strips the "WSQ - " prefix itself).
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'AI Vibe Coding for SQL'
WHERE entity_id = @e AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel) AND @e IS NOT NULL;

UPDATE catalog_product_entity_media_gallery_value v
JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
SET v.label = 'AI Vibe Coding for SQL'
WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 7b. Cover image -- new R2 render (generated + uploaded live 2026-08-27 with
--     badges WSQ, SkillsFuture Credit, SFEC, Absentee Payroll, MCES). Baked in
--     so a rebuilt DB serves the new-title cover. Store-scoped overrides
--     cleared so the store 0 value renders everywhere.
-- ---------------------------------------------------------------------------
SET @a_cover := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');

UPDATE catalog_product_entity_varchar
SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021002619-20260826-171929.png'
WHERE entity_id = @e AND attribute_id = @a_cover AND store_id = 0 AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND attribute_id = @a_cover AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 8. prerequisite -- swap ONLY the <li> holding the MongoDB tool link.
--    Everything else (PWM, funding tables, all gov deep links) untouched.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = REPLACE(value,
      '<li><u><a href="https://www.simplilearn.com/tutorials/mongodb-tutorial/install-mongodb-on-windows" rel="noopener noreferrer" target="_blank">MongoDB</a></u></li>',
      '<li><u><a href="https://dev.mysql.com/downloads/installer/" rel="noopener noreferrer" target="_blank">MySQL</a></u></li>')
WHERE entity_id = @e AND attribute_id = @a_prereq AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 9. trainerprofile -- retarget the COURSE-TEACHING paragraph of each of the 5
--    bios; credential paragraphs (real NoSQL delivery history) stay factual.
--    One exact single-line REPLACE per bio (the blob is CRLF).
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = REPLACE(value,
      'In his NoSQL training, Afiq emphasizes the practical use of document-based and key-value databases such as MongoDB and Redis. His sessions guide learners through database design, CRUD operations, and integration with applications, ensuring they understand both the theory and real-world implementation of NoSQL systems. By combining entrepreneurial experience with technical expertise, he helps participants confidently apply NoSQL in scalable web and enterprise applications.',
      'In his SQL training, Afiq emphasizes the practical use of relational databases such as MySQL and PostgreSQL. His sessions guide learners through AI-assisted database design, CRUD operations, and integration with applications, ensuring they understand both the theory and real-world implementation of relational database systems. By combining entrepreneurial experience with technical expertise, he helps participants confidently apply SQL in scalable business and enterprise applications.')
WHERE entity_id = @e AND attribute_id = @a_trainer AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
SET value = REPLACE(value,
      'In his NoSQL courses, Ken introduces beginners to the concepts of non-relational databases, including schema flexibility, indexing, and scalability. His training covers real-world use cases where NoSQL systems outperform traditional relational databases, particularly in handling unstructured and large-scale datasets. With his combined industry and training expertise, Ken ensures participants gain the confidence to use NoSQL tools effectively for business and analytics applications.',
      'In his SQL courses, Ken introduces beginners to the concepts of relational databases, including data modelling, indexing, and query optimisation. His training covers real-world use cases where SQL and AI coding assistants accelerate reporting, dashboarding, and analysis of structured business data. With his combined industry and training expertise, Ken ensures participants gain the confidence to use SQL tools effectively for business and analytics applications.')
WHERE entity_id = @e AND attribute_id = @a_trainer AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
SET value = REPLACE(value,
      'In his NoSQL training, Dr Ang focuses on helping learners understand the principles of distributed and non-relational databases in modern AI and data science workflows. His sessions cover working with document, columnar, and graph-based databases, as well as integrating NoSQL systems into machine learning pipelines. By combining academic depth with applied projects, he equips learners with both the conceptual understanding and practical skills to leverage NoSQL databases for advanced analytics and scalable applications.',
      'In his SQL training, Dr Ang focuses on helping learners understand the principles of relational databases in modern AI and data science workflows. His sessions cover data modelling, querying, and aggregation, as well as integrating SQL databases into analytics and machine learning pipelines with AI coding assistants. By combining academic depth with applied projects, he equips learners with both the conceptual understanding and practical skills to leverage SQL databases for advanced analytics and scalable applications.')
WHERE entity_id = @e AND attribute_id = @a_trainer AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
SET value = REPLACE(value,
      'In &ldquo;Mastering NoSQL Fundamentals for Beginners,&rdquo; Fritz introduces learners to the core concepts of NoSQL database design, data modeling, and query optimization. His sessions focus on understanding document-oriented, key-value, and graph-based databases, providing participants with the knowledge to choose and implement the right database type for various applications. Through guided exercises and real-world examples, he equips learners with the skills to store, manage, and analyze unstructured data effectively using modern NoSQL technologies.',
      'In &ldquo;AI Vibe Coding for SQL,&rdquo; Fritz introduces learners to the core concepts of relational database design, data modeling, and query optimization. His sessions focus on understanding tables, relationships, and keys, providing participants with the knowledge to design and implement the right database schema for various applications. Through guided exercises and real-world examples, he equips learners with the skills to store, manage, and analyze structured data effectively using SQL and modern AI coding assistants.')
WHERE entity_id = @e AND attribute_id = @a_trainer AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
SET value = REPLACE(value,
      'In &ldquo;Mastering NoSQL Fundamentals for Beginners,&rdquo; Terence guides participants through the practical implementation of NoSQL databases, emphasizing flexibility, scalability, and performance optimization. His sessions cover schema design, CRUD operations, indexing, and aggregation pipelines, helping learners build real-world database solutions. By integrating best practices and hands-on projects, he empowers participants to confidently work with NoSQL technologies and apply them to web applications, data analytics, and cloud-based solutions.',
      'In &ldquo;AI Vibe Coding for SQL,&rdquo; Terence guides participants through the practical implementation of relational databases, emphasizing accuracy, efficiency, and performance optimization. His sessions cover schema design, CRUD operations, indexing, and aggregation queries, helping learners build real-world database solutions with AI assistance. By integrating best practices and hands-on projects, he empowers participants to confidently work with SQL technologies and apply them to business applications, data analytics, and cloud-based solutions.')
WHERE entity_id = @e AND attribute_id = @a_trainer AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 10. Search redirects pointing at the old slug (16 live rows). Topically
--     retargeted, NOT blindly course-followed: NoSQL/MongoDB Essential
--     Training (917/918) are DISABLED, so mongo/nosql intent goes to the
--     nosql-courses.html category page (live, holds the DP-900 data courses),
--     full-stack vibe-coding intent goes to the live sibling course; only the
--     bare course code follows this course to its new slug.
-- ---------------------------------------------------------------------------
-- 10a. mongo / nosql intent -> NoSQL category page
UPDATE catalogsearch_query
SET redirect = 'https://www.tertiarycourses.com.sg/nosql-courses.html'
WHERE store_id = 1
  AND redirect LIKE '%/wsq-vibe-coding-a-full-stack-nosql-web-apps.html'
  AND (LOWER(query_text) LIKE '%mong%' OR LOWER(query_text) LIKE '%nosq%')
  AND @e IS NOT NULL;

-- 10b. the "nosq;" row still chains through the pre-2025 slug
UPDATE catalogsearch_query
SET redirect = 'https://www.tertiarycourses.com.sg/nosql-courses.html'
WHERE store_id = 1
  AND redirect LIKE '%/wsq-mongodb-nosql-course.html'
  AND @e IS NOT NULL;

-- 10c. full-stack vibe-coding intent -> the live sibling that still teaches it
UPDATE catalogsearch_query
SET redirect = 'https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-full-stack-web-applications.html'
WHERE store_id = 1
  AND redirect LIKE '%/wsq-vibe-coding-a-full-stack-nosql-web-apps.html'
  AND LOWER(query_text) LIKE '%vibe coding%full stack%'
  AND @e IS NOT NULL;

-- 10d. whatever remains on the old slug (the bare course code) follows the
--      course -- guarantees zero rot into the repurposed slug's 301.
UPDATE catalogsearch_query
SET redirect = 'https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-sql.html'
WHERE store_id = 1
  AND redirect LIKE '%/wsq-vibe-coding-a-full-stack-nosql-web-apps.html'
  AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 11. Categories. DROP the two that now misdescribe the course; ADD 339
--     Relational SQL (the exact subject listing, sibling of dropped 340 under
--     110 Databases). Every change mirrored into catalog_category_product_index
--     (963 shape). Broad parents (3, 15, 55, 110, 252, 292, 301) and 414
--     AI Vibe Coding Series stay.
-- ---------------------------------------------------------------------------
DELETE FROM catalog_category_product       WHERE category_id IN (340, 333) AND product_id = @e AND @e IS NOT NULL;
DELETE FROM catalog_category_product_index WHERE category_id IN (340, 333) AND product_id = @e AND @e IS NOT NULL;

INSERT INTO catalog_category_product (category_id, product_id, position)
SELECT 339, @e, (SELECT COALESCE(MAX(position), 0) + 1 FROM (SELECT * FROM catalog_category_product) c WHERE c.category_id = 339)
 WHERE @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM catalog_category_product) x
                    WHERE x.category_id = 339 AND x.product_id = @e);

INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, cp.product_id, cp.position, 1, 1, 4
  FROM catalog_category_product cp
 WHERE cp.product_id = @e AND cp.category_id = 339 AND @e IS NOT NULL;
