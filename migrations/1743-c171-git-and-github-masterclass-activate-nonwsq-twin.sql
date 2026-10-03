-- C171: "Git and Github Masterclass" (disabled, still on a recycled NumPy entity) re-enabled as the
-- 1-day non-WSQ twin of TGS-2025053207 (WSQ - Github Foundations Certification Training).
--
-- 1. status -> Enabled. Fee $350, 7.5 h, 1 session (all scope rows), level Beginner (as the parent).
-- 2. url_key/url_path python-numpy-and-scipy-training -> git-and-github-masterclass; cover alt and
--    gallery labels (still "Python Numpy & SciPy ..."); meta description without a day count.
-- 3. About + topics + who-should-attend copied from the WSQ parent (opener names this course; the
--    parent's "Final Assesment" block dropped; no day count). Literal upserts at store 0.
-- 4. Course Info: the NumPy prerequisites (Basic Python, Python 3, Sublime Text) replaced with the
--    Git toolchain; the corrupt byte in the hardware line goes with it.
-- 5. Funding block -> the WSQ twin.
-- 6. 301s: system rows renamed in place; every old path 301s one hop to the new bare slug; legacy
--    RP rows flattened onto it. Search terms c171/c0171 follow the course; the NumPy search terms
--    that redirected here are cleared (a NumPy search must not land on a Git course).
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): schedule template A14 (gid 117) -> A15 (gid 167) via the
-- controller code path (user's choice; the parent runs 2 days on (SG) WSQ-B15), then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C171' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025053207' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @title    := 'Git and Github Masterclass';
SET @old_slug := 'python-numpy-and-scipy-training';
SET @new_slug := 'git-and-github-masterclass';

SET @a_status  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'status');
SET @a_level   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'level');
SET @a_price   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'price');
SET @a_dur     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @a_sess    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'sessions');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_who     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
SET @o_beginner := (SELECT o.option_id FROM eav_attribute_option o
                      JOIN eav_attribute_option_value v ON v.option_id = o.option_id AND v.store_id = 0
                     WHERE o.attribute_id = @a_level AND v.value = 'Beginner' LIMIT 1);

-- ------------------------------------------------------ enable / level -----
UPDATE catalog_product_entity_int SET value = 1
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_status AND store_id = 0;

UPDATE catalog_product_entity_int SET value = @o_beginner
 WHERE @ok AND @o_beginner IS NOT NULL AND entity_id = @pid AND attribute_id = @a_level AND store_id = 0;

DELETE FROM catalog_product_entity_int
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_status, @a_level) AND store_id <> 0;

-- ----------------------------------------------- fee / hours / sessions -----
UPDATE catalog_product_entity_decimal SET value = 350
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price;

UPDATE catalog_product_entity_varchar SET value = '7.5'
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_dur;

UPDATE catalog_product_entity_varchar SET value = '1'
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_sess;

-- ------------------------------------------------------------- slug -------
UPDATE catalog_product_entity_varchar SET value = @new_slug
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlkey;

UPDATE catalog_product_entity_varchar SET value = CONCAT(@new_slug, '.html')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlpath;

-- ------------------------------------------------------ image labels -----
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
   AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label')
   SET v.value = @title
 WHERE @ok AND v.entity_id = @pid;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @title
 WHERE @ok AND g.entity_id = @pid;

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, @title FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Master Git and GitHub for version control and team collaboration. Learn commits, branches, merges, pull requests and GitHub Actions in this hands-on masterclass at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_mtitle, @a_mdesc, @a_urlkey, @a_dur, @a_sess) AND store_id <> 0;

-- ------------------------------- About + topics + audience + prerequisites ----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Master the fundamentals of GitHub with this comprehensive Git and Github Masterclass. Gain hands-on experience with version control, GitHub repositories, and collaboration tools, including pull requests, branching, and managing issues. Participants will learn how to manage repository changes, configure GitHub workflows, and explore advanced tools like GitHub Actions, Copilot, and Codespaces for modern development.</p>\n<p>This course also covers critical aspects of GitHub security, privacy, and administration. Learners will be able to authenticate user identities, conduct code and dependency scanning, and maintain a secure repository. By the end of the course, you will acquire the skills to analyze and improve deployment processes, configure software products, and implement modifications to enhance functionality, making you proficient in GitHub for real-world applications.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<h3 class="course-topic-h3">Topic 1. Introduction to Git and GitHub</h3>\n<ul>\n<li>What is vesion control</li>\n<li>Basic Git commands</li>\n<li>What is GitHub?</li>\n<li>Components of the GitHub flow</li>\n<li>GitHub is a collaborative platform</li>\n<li>GitHub platform management</li>\n</ul>\n<h3 class="course-topic-h3">Topic 2. Working with GitHub Repository</h3>\n<ul>\n<li>Repository management</li>\n<li>Create a new GitHub Repository</li>\n<li>Clone a repository</li>\n<li>Create a new branch</li>\n<li>Add files to a repository</li>\n<li>Manage repository changes by using pull requests on GitHub</li>\n<li>View repository insights</li>\n</ul>\n<h3 class="course-topic-h3">Topic 3. Collaboration Features</h3>\n<ul>\n<li>Managing issues and discussions</li>\n<li>Forking and pull requests</li>\n<li>GitHub pages</li>\n<li>Markdown Features</li>\n<li>Link a PR to an Issue</li>\n<li>Identify how to assign Issues.</li>\n<li>Code reviews</li>\n<li>Managing issues and discussions</li>\n</ul>\n<h3 class="course-topic-h3">Topic 4. Modern Development</h3>\n<ul>\n<li>GitHub Actions</li>\n<li>GitHub Copilot</li>\n<li>GitHub Codespaces</li>\n</ul>\n<h3 class="course-topic-h3">Topic 5 GitHub Project</h3>\n<ul>\n<li>Projects versus Projects Classic</li>\n<li>How to create a project</li>\n<li>How to organize your project</li>\n<li>How to organize and automate your project</li>\n<li>Insight and automation with projects</li>\n</ul>\n<h3 class="course-topic-h3">Topic 6. Privacy, Security and Administration</h3>\n<ul>\n<li>Introduction to GitHub administration</li>\n<li>Authenticate and authorize user identities on GitHub</li>\n<li>Dependency management</li>\n<li>Code scanning</li>\n<li>Secret scanning</li>\n<li>How to maintain a secure GitHub repository</li>\n<li>Automated security</li>\n<li>InnerSouce</li>\n</ul>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_who, 0, @pid, '<ul>\n<li>Software Developer</li>\n<li>Version Control Specialist</li>\n<li>DevOps Engineer</li>\n<li>Configuration Manager</li>\n<li>Software Deployment Engineer</li>\n<li>Software Release Coordinator</li>\n<li>Quality Assurance Specialist</li>\n<li>Repository Administrator</li>\n<li>GitHub Project Manager</li>\n<li>Collaboration Tools Specialist</li>\n<li>Automation Engineer</li>\n<li>Code Reviewer</li>\n<li>IT Support Specialist</li>\n<li>GitHub Security Analyst</li>\n<li>Development Team Lead</li>\n<li>Open Source Contributor</li>\n<li>IT Systems Administrator</li>\n<li>Agile Project Manager</li>\n<li>Technical Consultant</li>\n<li>Software Development Trainer</li>\n</ul>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_prereq, 0, @pid, '<h2>Promotion Code</h2>\n<p>Your will get 10% discount voucher for 2nd course onwards if you write us a <span style="text-decoration: underline;"><a href="https://g.page/r/CeH-OtN8J4r9EB0/review" target="_blank">Google review</a>.</span></p>\n<h2>Minimum Entry Requirement</h2>\n<p>Knowledge and Skills</p>\n<ul>\n<li>Able to operate using computer functions</li>\n<li>Minimum 3 GCE &lsquo;O&rsquo; Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li>\n</ul>\n<p>Attitude</p>\n<ul>\n<li>Positive Learning Attitude</li>\n<li>Enthusiastic Learner</li>\n</ul>\n<p>Experience</p>\n<ul>\n<li>Minimum of 1 year of working experience.</li>\n</ul>\n<p>This is a beginner level course. No prior knowledge of Git or GitHub is required.</p>\n<p>Target Age Group: 18-65 years old</p>\n<h2>Minimum Software/Hardware Requirement</h2>\n<p><strong>Software:</strong></p>\n<ul>\n<li>Git <a href="https://git-scm.com/install/" title="Git" target="_blank">https://git-scm.com/install/</a></li>\n<li>GitHub Desktop <a href="https://desktop.github.com/download/" title="GitHub Desktop" target="_blank">https://desktop.github.com/download/</a></li>\n<li>A free GitHub account <a href="https://github.com/signup" title="GitHub" target="_blank">https://github.com/signup</a></li>\n</ul>\n<p><strong>Hardware:</strong>&nbsp;Windows or Mac Laptops</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_who, @a_prereq) AND store_id <> 0;

-- ------------------------------------------------------ funding block -----
UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-github-foundations-certification-training.html" title="WSQ - Github Foundations Certification Training">WSQ - Github Foundations Certification Training</a></span></p>',
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C171_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c171_old;
CREATE TEMPORARY TABLE tmp_c171_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c171_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 2) Rename the system rows in place, so the new slug resolves immediately.
UPDATE core_url_rewrite
   SET request_path = REPLACE(request_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'))
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 3) Legacy RP rows that pointed at any old-slug path -> the new bare slug (one hop).
UPDATE core_url_rewrite
   SET target_path = CONCAT(@new_slug, '.html')
 WHERE @ok AND options = 'RP'
   AND (target_path = CONCAT(@old_slug, '.html') OR target_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 4) Every old path 301s to the new bare slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT o.store_id, CONCAT('manual-301-', MD5(o.request_path), '-', o.store_id), o.request_path,
       CONCAT(@new_slug, '.html'), 0, 'RP'
  FROM tmp_c171_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c171_old;

-- ---------------------------------------------------- search redirects ----
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND LOWER(query_text) IN ('c171', 'c0171')
   AND redirect = CONCAT('https://www.tertiarycourses.com.sg/', @old_slug, '.html');

UPDATE catalogsearch_query
   SET redirect = NULL
 WHERE @ok AND redirect = CONCAT('https://www.tertiarycourses.com.sg/', @old_slug, '.html');
