-- 1565: TGS-2023039924 -> "WSQ - AI Vibe Coding with Rust"
--
-- Repurposes the course from "AI-Assisted C Programming for Arduino" to
-- "AI Vibe Coding with Rust" (admin request 2026-09-27). The SKU and the
-- accredited TSC (Software Design ICT-DES-3005-1.1, cms_block
-- course_TGS-2023039924_skills_framework) are UNCHANGED, so every
-- SkillsFuture / SFEC / SFC / PSEA / UTAP deep link, the funding table, the
-- certification block and the brochure block stay valid and are not touched.
--
-- Pre-write probe (SG prod, entity 1308) found EVERY surface still on the
-- Arduino / embedded-C topic: name, url_key, meta_*, short_description,
-- description (LSN_DATA outline), whoshouldattend, the 3 alt labels + gallery
-- label, the learning_outcomes block ("C programming" inserted into each LO),
-- the course-teaching paragraph of all 4 trainer bios, 4 hardware categories,
-- 21 search-term redirects and the cover PNG. All of them change here.
--
-- Funding Validity: news_from_date 2023-11-15 / news_to_date 2027-11-14 already
-- equal the supplied "15-11-2023 - 14-11-2027" window -- nothing to write.
--
-- SLUG: `wsq-ai-vibe-coding-with-rust` -- probe found no product name or
-- url_key containing "Rust" and no core_url_rewrite row on the new path
-- (the only rust rewrites are the retired `basic-rust-programming-course`
-- aliases of entity 998, now an MS-4007 course, left alone). The old bare slug
-- 301s to the new one; the 26 pre-existing 301s from this entity's earlier
-- lives (iasa-...-cita-a-1308, it-architecture-core-ac-cita-f,
-- wsq-methodologies-in-c-programming, the long category paths) are flattened
-- to point at the new slug in ONE hop. The old filename is unique to this
-- product, so no foreign alias is repointed.
--
-- CATEGORIES: the Arduino / robotics / C listings no longer describe the
-- course and are dropped (73 Arduino, 56 Robotics & IoT, 327 WSQ Robotics &
-- IoT, 80 C/C++/C#). The three homes shared by 12 of the 14 live
-- "WSQ - AI Vibe Coding ..." siblings are added (325 WSQ AI Courses, 414 AI
-- Vibe Coding Series, 425 WSQ AI Vibe Coding Courses). 3 / 15 / 31 / 55 / 252
-- / 292 / 301 are kept. Both changes are mirrored into
-- catalog_category_product_index.
--
-- SEARCH REDIRECTS: rows pointing at the old slug follow the course EXCEPT the
-- ones whose intent is the old topic -- Arduino-intent terms go to the live
-- WSQ Arduino course (wsq-practical-electronics-design-with-arduino-
-- microcontroller.html, 200 / 0 redirects), and C-programming-intent terms go
-- to the Programming category page (no live C course exists on SG; the former
-- c-programming-training.html now 301s to an interviewing course). The three
-- existing Rust queries ("Rust" with no redirect, "Basic Rust Programming
-- Course" -> category page, "basic rust programming" -> the dead C page) are
-- pointed at the new page.
--
-- COVER: the cover is a PRE-RENDERED PNG on R2 with the title baked in.
-- Re-rendered via MMD_CourseImage_Model_Cover with the product's OWN badge set
-- (WSQ, SkillsFuture Credit, PSEA, UTAP, SFEC, Absentee Payroll, MCES -- all 7
-- chips preserved) and uploaded to shared R2 before this file was written:
--   course-covers/TGS-2023039924-20260926-161443.png  (155610 bytes, HTTP 200)
-- The superseded object is left on R2 so reverting is just repointing the URL.
--
-- The stored meta_title carried a baked-in "WSQ ... | Tertiary Courses
-- Singapore", so the live <title> double-printed "WSQ funded WSQ ...". Fixed
-- here: meta_title is the PLAIN title (MMD_Seotitle adds both at render time).
--
-- POST-DEPLOY (code paths a migration cannot run, on the SG web container):
--   1. Mage::getSingleton('catalog/url')->refreshProductRewrite(1308)
--      then catalog_product_flat reindex + cache flush -- the NEW slug 404s
--      until this runs, even though the old slug already 301s.
--   2. scripts/seo/generate-sitemaps.php so the sitemap lists the new slug.
--
-- SG production only; keyed by SKU so a partner site with no TGS-2023039924
-- no-ops. Idempotent: plain UPDATEs, INSERT IGNORE, guarded REPLACE()s.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023039924' LIMIT 1);
SET @et := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

-- ---------------------------------------------------------------------------
-- 1. Identity: name, url_key, url_path
-- ---------------------------------------------------------------------------

-- name: keeps the `WSQ - ` prefix (the storefront H1 wants it)
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'name' AND entity_type_id = @et);
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - AI Vibe Coding with Rust'
 WHERE attribute_id = @a_name AND entity_id = @e AND @e IS NOT NULL;

-- url_key
SET @a_url := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'url_key' AND entity_type_id = @et);
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-ai-vibe-coding-with-rust'
 WHERE attribute_id = @a_url AND entity_id = @e AND @e IS NOT NULL;

-- url_path: DELETE at every scope (store 0 AND store 1 rows exist) so the URL
-- Rewrites indexer regenerates it
SET @a_upath := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'url_path' AND entity_type_id = @et);
DELETE FROM catalog_product_entity_varchar
 WHERE attribute_id = @a_upath AND entity_id = @e AND @e IS NOT NULL AND @a_upath IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 2. Meta
-- ---------------------------------------------------------------------------

-- meta_title: PLAIN title -- no leading "WSQ", no brand suffix (see header)
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_title' AND entity_type_id = @et);
UPDATE catalog_product_entity_varchar
   SET value = 'AI Vibe Coding with Rust'
 WHERE attribute_id = @a_mt AND entity_id = @e AND @e IS NOT NULL;

-- meta_description: varchar(255) -- this value is 224 chars
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_description' AND entity_type_id = @et);
UPDATE catalog_product_entity_varchar
   SET value = 'Learn Rust programming with AI vibe coding. Use AI coding assistants to generate, debug and refine Rust code, manage Cargo projects and build reliable command-line applications. Up to 70% WSQ funding subsidy.'
 WHERE attribute_id = @a_md AND entity_id = @e AND @e IS NOT NULL;

-- meta_keyword
SET @a_mk := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_keyword' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = 'Rust programming course Singapore, WSQ Rust course, AI vibe coding Rust, AI-assisted Rust development, Rust Cargo projects, Rust ownership and borrowing, Rust error handling, AI coding assistant, Rust command-line applications, WSQ funded programming course'
 WHERE attribute_id = @a_mk AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 3. Content: About narrative, Course Outline, Who Should Attend, prerequisite
-- ---------------------------------------------------------------------------

-- short_description ("What's This Course About"): the supplied four-paragraph
-- Rust narrative. This course's sections were extracted to cms_block rows, so
-- short_description holds ONLY the intro copy -- a full replace is correct
-- (no <h2>Course Brochure</h2> tail to splice around). The red "Arduino kit is
-- used for the training" note is dropped: no kit is needed for Rust.
SET @a_sd := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'short_description' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<p>This WSQ AI Vibe Coding with Rust course equips learners with practical Rust programming skills while introducing AI-assisted development techniques to accelerate the coding process. Participants will learn the fundamentals of Rust, including variables, data types, functions, control structures, ownership, borrowing, error handling, and commonly used data structures, while using AI coding tools to generate, explain, debug, and refine Rust code.</p>',
'\n<p>The course emphasizes hands-on vibe coding, where learners translate ideas and functional requirements into working Rust applications through natural-language instructions, AI-generated code, rapid testing, and iterative improvement. Rather than focusing only on programming syntax, participants learn how to understand AI-generated code, identify errors, modify program logic, and validate that applications meet intended requirements.</p>',
'\n<p>Learners will gain practical experience in setting up the Rust development environment, creating and managing projects with Cargo, working with Rust modules and packages, handling program errors, and building functional command-line and application-based projects. AI coding assistants will be incorporated throughout the development workflow to support code generation, troubleshooting, refactoring, documentation, and testing.</p>',
'\n<p>By the end of the course, learners will be able to combine Rust programming fundamentals with AI Vibe Coding workflows to develop reliable applications more efficiently. The course is suitable for learners who want practical experience in modern software development using Rust and AI-assisted coding techniques.</p>')
 WHERE attribute_id = @a_sd AND entity_id = @e AND @e IS NOT NULL;

-- description (Course Outline): LSN_DATA JSON + rendered markup kept in the
-- shape the admin outline editor writes (one source, both forms). The supplied
-- outline is five topic titles, so subsecs are empty (same as 1548).
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'description' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<!-- LSN_DATA: [{"title":"Topic 1: Rust Programming Fundamentals and Software Components","subsecs":[]},{"title":"Topic 2: AI Vibe Coding for Rust Application Development","subsecs":[]},{"title":"Topic 3: Rust Programming Controls, Functions and Features","subsecs":[]},{"title":"Topic 4: Testing, Debugging and Integrating Rust Components","subsecs":[]},{"title":"Topic 5: AI-Assisted Rust Software Design and Documentation","subsecs":[]}] -->',
'\n<p><strong>Topic 1: Rust Programming Fundamentals and Software Components</strong></p>',
'\n<p><strong>Topic 2: AI Vibe Coding for Rust Application Development</strong></p>',
'\n<p><strong>Topic 3: Rust Programming Controls, Functions and Features</strong></p>',
'\n<p><strong>Topic 4: Testing, Debugging and Integrating Rust Components</strong></p>',
'\n<p><strong>Topic 5: AI-Assisted Rust Software Design and Documentation</strong></p>',
'\n')
 WHERE attribute_id = @a_desc AND entity_id = @e AND @e IS NOT NULL;

-- whoshouldattend: the job-role list named the OLD subject (C Programmer,
-- Firmware Developer, Robotics Engineer, IoT Developer ...). Re-pointed at
-- Rust / systems-programming equivalents; broad roles that remain accurate
-- (Application Developer, Game Developer, Software Architect, Cybersecurity
-- Analyst, Computer Science Educator) are kept.
SET @a_wsa := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'whoshouldattend' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<ul>',
'\n<li>Rust Developer</li>',
'\n<li>Software Developer</li>',
'\n<li>Systems Programmer</li>',
'\n<li>Backend Developer</li>',
'\n<li>Application Developer</li>',
'\n<li>Embedded Systems Developer</li>',
'\n<li>Command-Line Tool Developer</li>',
'\n<li>Game Developer</li>',
'\n<li>Software Architect</li>',
'\n<li>DevOps Engineer</li>',
'\n<li>Cybersecurity Analyst</li>',
'\n<li>Computer Science Educator</li>',
'\n<li>Developer moving from C or C++ to Rust</li>',
'\n<li>AI-Assisted Coding Practitioner</li>',
'\n</ul>')
 WHERE attribute_id = @a_wsa AND entity_id = @e AND @e IS NOT NULL;

-- prerequisite ("Minimum Software/Hardware Requirement"): the software list
-- held only Visual Studio Code, which is tool-neutral and stays. Add the Rust
-- toolchain as one <li> in front of it. This blob is ALSO the whole funding
-- apparatus (PWM, eligibility table, SkillsFuture/PSEA/UTAP deep links, Appeal
-- Process), so it is never rewritten wholesale. Guarded on LOCATE so re-runs
-- do not duplicate the <li>.
SET @a_pre := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'prerequisite' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<li><a href="https://code.visualstudio.com/" target="_blank"><span style="text-decoration: underline;">Visual Studio Code</span></a></li>',
       CONCAT('<li><a href="https://rustup.rs/" target="_blank"><span style="text-decoration: underline;">Rust toolchain (rustup, which installs cargo and rustc)</span></a></li>',
              '\n<li><a href="https://code.visualstudio.com/" target="_blank"><span style="text-decoration: underline;">Visual Studio Code</span></a></li>'))
 WHERE attribute_id = @a_pre AND entity_id = @e AND @e IS NOT NULL
   AND LOCATE('rustup.rs', value) = 0;

-- ---------------------------------------------------------------------------
-- 4. Learning outcomes block: the supplied LOs are the tool-neutral form of
--    the live ones (the live block had "C programming" inserted into each).
--    Content-only UPDATE -- never ->save() a cms/block model.
-- ---------------------------------------------------------------------------
UPDATE cms_block
   SET content = CONCAT(
         '<p>By end of the course, learners should be able to:</p>', '\n',
         '<ul>', '\n',
         '<li>LO1: Determine basic software components using programming methodologies to meet functional specifications.</li>', '\n',
         '<li>LO2: Apply programming methodologies and tools for software creation.</li>', '\n',
         '<li>LO3: Select essential programming controls and features to meet software design requirements.</li>', '\n',
         '<li>LO4: Examine the interoperability and functionality of programming components.</li>', '\n',
         '<li>LO5: Generate programming design documentation aligned with user specifications.</li>', '\n',
         '</ul>')
 WHERE identifier = 'course_TGS-2023039924_learning_outcomes';

-- ---------------------------------------------------------------------------
-- 5. Trainer bios: retarget ONLY the course-teaching paragraph (para 2) of
--    each of the 4 bios. Para 1 credentials (40 years of C/C++/embedded,
--    Arduino/ESP32 automation projects, ...) are facts and stay.
-- ---------------------------------------------------------------------------
SET @a_tp := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'trainerprofile' AND entity_type_id = @et);

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<p>In his C programming courses, Richard emphasizes rigorous fundamentals such as data types, functions, arrays, pointers, and memory management. He integrates real-world applications from embedded systems and software engineering, ensuring learners not only gain programming proficiency but also develop computational thinking skills applicable in technical domains.</p>',
       '<p>In &ldquo;AI Vibe Coding with Rust,&rdquo; Richard grounds learners in the Rust fundamentals that make AI-generated code safe to trust: data types, functions, ownership, borrowing, and error handling. Drawing on decades of systems and embedded work, he shows how to read, question, and refine what an AI coding assistant produces, so participants gain both Rust proficiency and the computational thinking to judge generated code.</p>')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<p>In his C programming training, Sin Fatt emphasizes structured problem-solving and the application of programming concepts to real-world scenarios. He guides learners through algorithm design, modular programming, and debugging, while embedding agile and design thinking principles into the learning process. His approach ensures participants not only understand the technical aspects of C but also cultivate adaptable and innovative mindsets for software development.</p>',
       '<p>In &ldquo;AI Vibe Coding with Rust,&rdquo; Sin Fatt emphasizes structured problem-solving and turning functional requirements into working Rust applications with AI assistance. He guides learners through Cargo projects, modular program design, and debugging AI-generated code, while embedding agile and design thinking principles into the learning process. His approach ensures participants not only understand the technical aspects of Rust but also cultivate adaptable and innovative mindsets for AI-assisted software development.</p>')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<p>In &ldquo;AI-Assisted C Programming for Arduino,&rdquo; Noel teaches participants how to leverage generative AI tools to accelerate embedded software development and hardware prototyping. His sessions focus on AI-guided code generation, debugging, and optimization techniques to streamline C programming workflows. Through hands-on exercises involving real-world Arduino projects, he equips learners with the skills to design intelligent systems that blend classical programming with modern AI-driven development approaches.</p>',
       '<p>In &ldquo;AI Vibe Coding with Rust,&rdquo; Noel teaches participants how to leverage generative AI tools to accelerate Rust application development. His sessions focus on AI-guided code generation, debugging, and refactoring techniques to streamline Rust workflows. Through hands-on exercises building real command-line and application projects, he equips learners with the skills to validate AI-generated Rust code and ship reliable software that blends classical programming with modern AI-driven development approaches.</p>')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<p>In &ldquo;AI-Assisted C Programming for Arduino,&rdquo; Dr. Ang introduces learners to the convergence of artificial intelligence and embedded programming. His sessions explore how AI tools can enhance C-based coding efficiency, hardware control, and automation design. By combining academic rigor with hands-on experimentation, he guides participants to build smarter, more adaptive Arduino projects that demonstrate the potential of AI in next-generation embedded systems development.</p>',
       '<p>In &ldquo;AI Vibe Coding with Rust,&rdquo; Dr. Ang introduces learners to the convergence of artificial intelligence and systems programming. His sessions explore how AI coding assistants can enhance Rust coding efficiency, from generating and explaining code to testing and documentation. By combining academic rigor with hands-on experimentation, he guides participants to build reliable Rust applications that demonstrate the potential of AI in next-generation software development.</p>')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 6. Cover image + alt text
-- ---------------------------------------------------------------------------

-- image alt-text labels: plain title, no `WSQ - ` prefix (the cover itself
-- strips it via Cover.php::cleanTitle)
UPDATE catalog_product_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @et
    SET v.value = 'AI Vibe Coding with Rust'
  WHERE v.entity_id = @e AND @e IS NOT NULL
    AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label');

-- media gallery label -- the real alt text on the product image (the stored
-- file PATH is left alone: renaming it 404s the file)
UPDATE catalog_product_entity_media_gallery_value gv
   JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
    SET gv.label = 'AI Vibe Coding with Rust'
  WHERE g.entity_id = @e AND @e IS NOT NULL;

-- cover image: repoint at the regenerated PNG (global scope; clear any
-- store-scoped row that would shadow it)
SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'course_image_url' AND entity_type_id = @et);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_ciu, 0, @e,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023039924-20260926-161443.png'
  WHERE @e IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id <> 0
   AND @e IS NOT NULL AND @a_ciu IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 7. Categories: drop the hardware / C listings, add the AI Vibe Coding homes
-- ---------------------------------------------------------------------------
DELETE FROM catalog_category_product
 WHERE product_id = @e AND @e IS NOT NULL
   AND category_id IN (73, 56, 327, 80);

DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND @e IS NOT NULL
   AND category_id IN (73, 56, 327, 80);

-- Append at MAX(position)+1 so the category-ordering sweep can renumber later.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT c.cid, @e, COALESCE((SELECT MAX(position) FROM catalog_category_product WHERE category_id = c.cid), 0) + 1
  FROM (SELECT 325 AS cid UNION SELECT 414 UNION SELECT 425) c
 WHERE @e IS NOT NULL
   AND EXISTS (SELECT 1 FROM catalog_category_entity ce WHERE ce.entity_id = c.cid);

INSERT IGNORE INTO catalog_category_product_index
       (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, cp.product_id, cp.position, 1, s.store_id, 4
  FROM catalog_category_product cp
  CROSS JOIN core_store s
 WHERE cp.product_id = @e AND cp.category_id IN (325, 414, 425)
   AND s.store_id > 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 8. URL rewrites: 301 the old slug, flatten the chain history
-- ---------------------------------------------------------------------------
SET @sid := (SELECT store_id FROM core_store WHERE store_id > 0 ORDER BY store_id LIMIT 1);

-- The old bare slug is held by the canonical is_system=1 row on
-- id_path='product/<e>'. INSERT IGNORE would silently no-op against it, so
-- DELETE it first; refreshProductRewrite re-mints the canonical row at the
-- NEW slug post-deploy.
DELETE FROM core_url_rewrite
 WHERE product_id = @e AND is_system = 1
   AND request_path = 'wsq-ai-assisted-c-programming-for-arduino.html'
   AND @e IS NOT NULL;

-- Clear any is_system=0 squatter sitting on the NEW path
DELETE FROM core_url_rewrite
 WHERE request_path = 'wsq-ai-vibe-coding-with-rust.html'
   AND is_system = 0;

-- Permanent 301: old bare slug -> new bare slug. The indexer auto-301s the
-- category-prefixed paths once the rewrites are refreshed.
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT @sid, CONCAT('tgs2023039924-rust-bare-', @e),
       'wsq-ai-assisted-c-programming-for-arduino.html',
       'wsq-ai-vibe-coding-with-rust.html',
       0, 'RP', '1565: TGS-2023039924 repurposed to AI Vibe Coding with Rust'
 WHERE @e IS NOT NULL AND @sid IS NOT NULL;

-- Flatten the PRE-EXISTING 301s that point at the OLD slug (this entity's
-- earlier lives + the long category paths) so they redirect in ONE hop.
-- The old filename is unique to this product (verified: all 26 matching rows
-- belong to entity 1308), so no foreign alias is repointed.
UPDATE core_url_rewrite
   SET target_path = REPLACE(target_path,
                             'wsq-ai-assisted-c-programming-for-arduino.html',
                             'wsq-ai-vibe-coding-with-rust.html')
 WHERE is_system = 0
   AND target_path LIKE '%wsq-ai-assisted-c-programming-for-arduino.html'
   AND id_path NOT LIKE 'tgs2023039924-rust-%';

-- ---------------------------------------------------------------------------
-- 9. Search-term redirects (SG data; partner sites have no matching rows)
-- ---------------------------------------------------------------------------

-- Old-topic intent FIRST, before the generic follow-the-course sweep.
-- Arduino intent -> the live WSQ Arduino course.
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/wsq-practical-electronics-design-with-arduino-microcontroller.html'
 WHERE redirect LIKE '%wsq-ai-assisted-c-programming-for-arduino.html'
   AND query_text IN ('Mechatronics  and Arduino Programming', 'AI arduino',
                      'AI-Assisted C Programming for Arduino',
                      'WSQ - AI-Assisted C Programming for Arduino',
                      'Ai assisted c programming for arduino');

-- C-programming intent -> the Programming category page (no live C course).
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/programming-courses.html'
 WHERE redirect LIKE '%wsq-ai-assisted-c-programming-for-arduino.html'
   AND query_text IN ('c programing', 'Methodologies in C Programming',
                      'c programming essential', 'AI-Assisted C Programming');

-- Everything else on the old slug (the bare course code, the generic
-- "AI-assisted programming" family) follows the course.
UPDATE catalogsearch_query
   SET redirect = REPLACE(redirect,
                          'wsq-ai-assisted-c-programming-for-arduino.html',
                          'wsq-ai-vibe-coding-with-rust.html')
 WHERE redirect LIKE '%wsq-ai-assisted-c-programming-for-arduino.html';

-- Existing Rust queries now have a Rust product page to land on.
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-with-rust.html'
 WHERE query_text IN ('Rust', 'Basic Rust Programming Course', 'basic rust programming')
   AND (redirect IS NULL OR redirect = ''
        OR redirect LIKE '%/programming-courses.html'
        OR redirect LIKE '%/c-programming-training.html');
