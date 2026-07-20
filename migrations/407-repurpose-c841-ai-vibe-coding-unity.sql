-- Rename course C841 from "Unity Certified User (Programmer) Training" to
-- "AI Vibe Coding for Unity Game Development" (3 days / 6 topics). Part of the
-- AI Vibe Coding series (badge). name, overview, topics, meta, cover, url_key,
-- duration, badge. Price unchanged (1200 SG). Store scope 0. Idempotent. No
-- content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C841');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_badge := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_series_badge');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI Vibe Coding for Unity Game Development') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Build games in Unity with AI Vibe Coding for Unity Game Development. This hands-on 3-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to build game mechanics, gameplay scripts and full game systems in Unity with C#. Instead of memorising the Unity API and C# syntax, you will vibe code &mdash; describing what you want in plain language and letting AI generate, refactor and debug your game code while you design the gameplay and experience.</p>
<p>Through practical projects, participants will set up a Unity project, build scenes and game objects, script player controls, physics, animation and UI, add game systems such as scoring and enemies, and build and deploy a playable game &mdash; all with an AI pair programmer at their side. You will also learn to review, test and optimise AI-generated game code so your game runs smoothly. By the end of the course, you will be able to build and ship Unity games faster with an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for Unity</h3>
<ul>
<li>Introduction to Unity, C# and Vibe Coding</li>
<li>Setting Up Unity and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Navigating the Unity Editor with AI Guidance</li>
<li>Effective Prompting for Unity and C# Code Generation</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building Scenes and Game Objects with AI</h3>
<ul>
<li>Creating Scenes, GameObjects and Prefabs</li>
<li>Working with Components and the Inspector</li>
<li>Generating Level and Environment Setups with AI</li>
<li>Organising Assets and Project Structure</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Scripting Gameplay with C# and AI</h3>
<ul>
<li>Writing MonoBehaviour Scripts with AI</li>
<li>Player Input, Movement and Controls</li>
<li>Handling Game State and Events</li>
<li>Debugging and Explaining C# Scripts with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Physics, Animation and UI with AI</h3>
<ul>
<li>Colliders, Rigidbodies and Physics Interactions</li>
<li>Animating Characters and Objects</li>
<li>Building Menus, HUD and UI with AI</li>
<li>Adding Audio and Visual Effects</li>
</ul>
<h3 class="course-topic-h3">Topic 5 Game Systems and AI-Assisted Debugging</h3>
<ul>
<li>Scoring, Health and Inventory Systems</li>
<li>Enemies, Spawning and Simple Game AI</li>
<li>Saving and Loading Game Data</li>
<li>Reviewing, Testing and Refactoring AI-Generated Code</li>
</ul>
<h3 class="course-topic-h3">Topic 6 Building, Optimising and Deploying Your Game</h3>
<ul>
<li>Optimising Performance with AI</li>
<li>Building for Desktop, WebGL and Mobile</li>
<li>Packaging and Publishing Your Game</li>
<li>Next Steps for Your Unity Game Projects</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Vibe Coding for Unity Game Development') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Build Unity games with AI vibe coding. Script gameplay, physics, UI and game systems in C# using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 3-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Vibe Coding, Unity, Game Development, C#, Game Programming, Cursor, GitHub Copilot, Claude, Unity Games, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '22.5') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C841-20260712-031712.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-vibe-coding-for-unity-game-development') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_badge, 0, @e, 'AI Vibe Coding Series') ON DUPLICATE KEY UPDATE value = VALUES(value);
