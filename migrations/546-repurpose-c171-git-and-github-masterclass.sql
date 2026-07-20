-- Re-enable course C171 (currently disabled) and repurpose it from
-- "NumPy and SciPy Essential Training" to "Git and Github Masterclass"
-- (1 day / 2 topics). name, overview, topics, meta (title/description/keyword),
-- duration 7.5h, cover, url_key, status=1 (enabled). Moves it OUT of the Python
-- category and INTO the "Git & Github" category (both resolved by NAME so it is
-- partner-safe; ids differ per site). Price unchanged ($350 SG). Points the
-- Funding block at WSQ - Github Foundations Certification Training (validated
-- 200 on www.tertiarycourses.com.sg). Clears per-store overrides of the
-- rewritten attributes so partner store scopes can't shadow store 0. Store
-- scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C171');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_status:= (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Git and Github Masterclass') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Master version control with the Git and Github Masterclass. This hands-on 1-day course teaches you how to track changes, collaborate on code and manage projects with Git and GitHub &mdash; the tools every modern developer and team relies on. You will learn the core Git workflow from the ground up: initialising repositories, staging and committing changes, working with branches, and resolving merge conflicts with confidence.</p>
<p>Through practical exercises, participants will push and pull to GitHub, open and review pull requests, collaborate on a shared repository, and use branching strategies and GitHub features such as issues, forks and Actions to streamline teamwork. By the end of the course, you will be able to use Git and GitHub effectively to version, share and collaborate on any software or documentation project.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Git Fundamentals and the Core Workflow</h3>
<ul>
<li>Introduction to Version Control, Git and GitHub</li>
<li>Installing Git and Configuring Your Environment</li>
<li>Initialising Repositories, Staging and Committing Changes</li>
<li>Branching, Merging and Resolving Conflicts</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Collaborating on GitHub</h3>
<ul>
<li>Connecting Local Repositories to GitHub (Push and Pull)</li>
<li>Pull Requests, Code Review and Branching Strategies</li>
<li>Working with Issues, Forks and Collaborators</li>
<li>Introduction to GitHub Actions for Automation</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Git and Github Masterclass') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Master Git and GitHub for version control and team collaboration. Learn commits, branches, merges, pull requests and GitHub Actions in this hands-on 1-day masterclass at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Git, GitHub, Version Control, Pull Requests, Branching, Merge, GitHub Actions, Source Control, Collaboration, DevOps')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '7.5') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C171-20260717-192922.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'python-numpy-and-scipy-training') ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Re-enable (was disabled, status=2). Enable at store 0 and clear any per-store override.
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_status, 0, @e, 1) ON DUPLICATE KEY UPDATE value = VALUES(value);
DELETE FROM catalog_product_entity_int WHERE entity_id=@e AND store_id<>0 AND attribute_id=@a_status;

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_dur, @a_img, @a_url);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);

-- Remove from the "Python" category (no longer a Python course).
DELETE cp FROM catalog_category_product cp
JOIN catalog_category_entity_varchar v ON v.entity_id=cp.category_id AND v.store_id=0
JOIN eav_attribute ca ON ca.attribute_id=v.attribute_id AND ca.entity_type_id=3 AND ca.attribute_code='name'
WHERE cp.product_id=@e AND v.value = 'Python';

-- Add to the "Git & Github" category (resolved by name; partner-safe).
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT v.entity_id, @e, 0 FROM catalog_category_entity_varchar v
JOIN eav_attribute ca ON ca.attribute_id=v.attribute_id AND ca.entity_type_id=3 AND ca.attribute_code='name'
WHERE v.store_id=0 AND v.value = 'Git & Github' AND @e IS NOT NULL;

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-github-foundations-certification-training.html" title="WSQ - Github Foundations Certification Training">WSQ - Github Foundations Certification Training</a></span></p>'
WHERE identifier = 'course_C171_funding_and_grant';
