-- Repurpose course C1143 (entity_id 1143) from "React Essential Training" to
-- "React AI Vibe Coding for React Development". Same SKU, same 2-day duration
-- (15h), same price ($600). The topic outline is condensed from 8 topics to
-- 4 topics (2 per day) and reframed around AI-assisted "vibe coding" for React.
-- Overview (short_description) and SEO meta fields are rewritten to match.
--
-- Scope: store_id = 0 only — this is the SG single-store site (the only name
-- row on this entity is store_id 0). url_key is intentionally NOT changed so
-- the existing /react-essential-training.html URL (and its rankings/backlinks)
-- keep resolving; price and duration are left untouched.
--
-- The course cover image (course_image_url on R2) is rendered from `name` by
-- the admin AI Covers tool and cannot be regenerated from SQL — regenerate it
-- on production after this deploys (that also refreshes the flat index for the
-- product so the new name/overview/topics publish to the storefront).
--
-- Idempotent: re-running writes the same values (INSERT ... ON DUPLICATE KEY
-- UPDATE). apply.php note: no content line ends in a semicolon (the runner
-- splits statements on semicolon-at-EOL).

SET @entity_id := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1143');

SET @attr_name             := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @attr_short_description := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @attr_description       := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @attr_meta_title        := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @attr_meta_description  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @attr_meta_keyword      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @attr_course_image_url  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

-- name (varchar)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_name, 0, @entity_id, 'React AI Vibe Coding for React Development')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- short_description / overview (text)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_short_description, 0, @entity_id, '<p>Step into the future of front-end development with React AI Vibe Coding for React Development. This hands-on 2-day course teaches you how to build modern React applications using AI coding assistants such as Cursor, GitHub Copilot and Claude. Instead of memorising boilerplate, you will learn to vibe code &mdash; describing what you want in plain language and letting AI generate, refactor and debug React components while you steer the design and logic. You will still master the React essentials of JSX, components, props, state, hooks and routing, but at the speed and flow that AI-assisted development unlocks.</p>
<p>Through a series of practical projects, participants will scaffold a React app from a prompt, compose reusable components, wire up state and navigation, fetch live data, and debug and deploy a working single-page application &mdash; all with an AI pair programmer at their side. Just as importantly, you will learn to review, test and improve AI-generated code so your apps stay clean, correct and production ready. By the end of the course, you will be able to ship React applications faster and more confidently by combining solid fundamentals with an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- description / topics (text) — 4 topics, 2 per day for the 2-day course.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_description, 0, @entity_id, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for React</h3>
<ul>
<li>Introduction to Vibe Coding and AI-Assisted Development</li>
<li>Setting Up AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Scaffolding a React App from a Prompt</li>
<li>Effective Prompting for React Code Generation</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building React Components and UI with AI</h3>
<ul>
<li>Generating Function Components and JSX with AI</li>
<li>Composing and Reusing Components</li>
<li>Passing Data with Props and Handling Events</li>
<li>Styling Components with AI-Generated CSS</li>
</ul>
<h3 class="course-topic-h3">Topic 3 State, Hooks and Routing with AI Assistance</h3>
<ul>
<li>Managing State with useState and useEffect</li>
<li>Building Multi-Page Apps with React Router</li>
<li>Fetching and Rendering API Data</li>
<li>Reviewing and Refactoring AI-Generated Code</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Debugging, Testing and Deploying React Apps with AI</h3>
<ul>
<li>AI-Assisted Debugging and Error Fixing</li>
<li>Generating Unit Tests with AI</li>
<li>Optimising and Documenting Your Code</li>
<li>Building and Deploying the React App</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_title (varchar)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_title, 0, @entity_id, 'React AI Vibe Coding for React Development | Tertiary Courses Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_description (varchar)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_description, 0, @entity_id, 'Build modern React apps with AI vibe coding. Master JSX, components, hooks and routing using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 2-day React course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_keyword (text)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_keyword, 0, @entity_id, 'React, AI Vibe Coding, React Development, Cursor, GitHub Copilot, Claude, JSX, React Hooks, React Router, AI Coding, React Components')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- course_image_url (varchar) — new branded cover rendered from the new `name`
-- and uploaded to the shared R2 bucket (the PNG already exists at this URL).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_course_image_url, 0, @entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1143-20260711-061111.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
