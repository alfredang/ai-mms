-- 1-day AI Vibe Coding language courses (1 day / 15h? no -> 7.5h, 2 topics).
-- Corrects C169 from the 2-day version set in migration 356, and repurposes
-- C178, C205, C1310. Each: name, overview, 2 topics, meta, duration 7.5,
-- cover, url_key (matching the new title) and the AI Vibe Coding Series badge.
--
--   C169   AI Vibe Coding with C     (correct 356 to 1 day / 2 topics)
--   C178   AI Vibe Coding for C++    (was C++ Essential Training)
--   C205   AI Vibe Coding for C#     (was Basic C# Programming for Beginners)
--   C1310  AI Vibe Coding for .NET   (was Basic ASP.NET Applications with C#)
--
-- Per-market PRICE (SG 350 / MY 1100 / GH 1500) and SG-only funding blocks are
-- applied direct on each prod DB, not here. url_key lands before the post-deploy
-- catalog_url reindex, which writes the 301s from the old slugs. Store scope 0.
-- Idempotent. No content line ends in a semicolon.

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

-- =========================================================================
-- C169 - correct to 1 day / 2 topics (name/meta_title/cover/url_key/badge
-- already correct from migration 356; only these attributes change).
-- =========================================================================
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C169');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Learn to write real C programs with AI Vibe Coding with C. This hands-on 1-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to write, compile and debug C code. Instead of getting stuck on syntax and pointers, you will vibe code &mdash; describing what you want in plain language and letting AI generate, explain, refactor and fix C code while you learn the fundamentals and stay in control of the logic.</p>
<p>Through practical exercises, participants will set up a C toolchain, work with variables, control flow, functions, arrays, pointers and structs, manage memory, and build a small command-line program &mdash; all with an AI pair programmer at their side. You will also learn to read, test and improve AI-generated code so your programs are correct and reliable. By the end of the course, you will be able to write and understand C confidently and use an effective AI vibe-coding workflow to build efficient programs faster.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started and C Fundamentals with AI Vibe Coding</h3>
<ul>
<li>Introduction to C and Vibe Coding</li>
<li>Setting Up a C Compiler and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Variables, Data Types, Operators and Control Flow</li>
<li>Functions, Debugging and Explaining Code with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Data, Pointers and Building C Programs with AI</h3>
<ul>
<li>Arrays, Strings and Structs</li>
<li>Pointers and Memory Management</li>
<li>Building a Command-Line Application</li>
<li>Testing, Compiling and Running Your Project</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '7.5') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Learn C programming with AI vibe coding. Master variables, control flow, functions, pointers, memory and files using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- =========================================================================
-- C178 - AI Vibe Coding for C++
-- =========================================================================
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C178');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI Vibe Coding for C++') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Learn to write real C++ programs with AI Vibe Coding for C++. This hands-on 1-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to write, compile and debug C++ code. Instead of getting stuck on syntax, classes and pointers, you will vibe code &mdash; describing what you want in plain language and letting AI generate, explain, refactor and fix C++ code while you learn the fundamentals and stay in control of the logic.</p>
<p>Through practical exercises, participants will set up a C++ toolchain, work with variables, control flow, functions, classes, objects, pointers and the STL, and build a small application &mdash; all with an AI pair programmer at their side. You will also learn to read, test and improve AI-generated code so your programs are correct and efficient. By the end of the course, you will be able to write and understand C++ confidently and use an effective AI vibe-coding workflow to build powerful programs faster.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started and C++ Fundamentals with AI Vibe Coding</h3>
<ul>
<li>Introduction to C++ and Vibe Coding</li>
<li>Setting Up a C++ Compiler and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Variables, Data Types, Control Flow and Functions</li>
<li>Debugging and Explaining Code with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Classes, Objects and Building C++ Programs with AI</h3>
<ul>
<li>Classes, Objects and Encapsulation</li>
<li>Pointers, References and Memory Management</li>
<li>The Standard Template Library (STL)</li>
<li>Building, Testing and Running a C++ Application</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Vibe Coding for C++ | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Learn C++ programming with AI vibe coding. Master syntax, functions, classes, pointers, memory and the STL using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Vibe Coding, C++ Programming, Cursor, GitHub Copilot, Claude, Classes, Objects, Pointers, STL, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '7.5') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C178-20260711-092514.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-vibe-coding-for-cpp') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_badge, 0, @e, 'AI Vibe Coding Series') ON DUPLICATE KEY UPDATE value = VALUES(value);

-- =========================================================================
-- C205 - AI Vibe Coding for C#
-- =========================================================================
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C205');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI Vibe Coding for C#') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Learn to build real C# applications with AI Vibe Coding for C#. This hands-on 1-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to write, run and debug C# code on .NET. Instead of memorising syntax, you will vibe code &mdash; describing what you want in plain language and letting AI generate, explain, refactor and fix C# code while you learn the fundamentals and stay in control of the logic.</p>
<p>Through practical exercises, participants will set up the .NET SDK, work with variables, control flow, methods, classes, objects, collections and LINQ, handle files and exceptions, and build a small application &mdash; all with an AI pair programmer at their side. You will also learn to read, test and improve AI-generated code so your programs are correct and maintainable. By the end of the course, you will be able to write and understand C# confidently and use an effective AI vibe-coding workflow to build applications faster.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started and C# Fundamentals with AI Vibe Coding</h3>
<ul>
<li>Introduction to C# and .NET with Vibe Coding</li>
<li>Setting Up the .NET SDK and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Variables, Data Types, Control Flow and Methods</li>
<li>Debugging and Explaining Code with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Object-Oriented C# and Building Apps with AI</h3>
<ul>
<li>Classes, Objects and Inheritance</li>
<li>Collections and LINQ</li>
<li>Handling Exceptions and Files</li>
<li>Building, Testing and Running a C# Application</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Vibe Coding for C# | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Learn C# programming with AI vibe coding. Master syntax, methods, classes, collections, LINQ and files on .NET using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Vibe Coding, C Sharp, .NET, Cursor, GitHub Copilot, Claude, Classes, LINQ, Object-Oriented, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '7.5') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C205-20260711-092515.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-vibe-coding-for-c-sharp') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_badge, 0, @e, 'AI Vibe Coding Series') ON DUPLICATE KEY UPDATE value = VALUES(value);

-- =========================================================================
-- C1310 - AI Vibe Coding for .NET
-- =========================================================================
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1310');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI Vibe Coding for .NET') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Build real .NET applications with AI Vibe Coding for .NET. This hands-on 1-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to build .NET apps in C#, from console tools to ASP.NET web applications. Instead of wrestling with framework boilerplate, you will vibe code &mdash; describing the features you want in plain language and letting AI generate, refactor and debug your .NET code while you direct the design.</p>
<p>Through practical projects, participants will scaffold a .NET application, build web APIs and pages with ASP.NET, work with data using Entity Framework, and test and deploy the app &mdash; all with an AI pair programmer at their side. You will also learn to review, test and secure AI-generated code so your applications stay reliable and production ready. By the end of the course, you will be able to build and ship .NET applications faster and more confidently with an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for .NET</h3>
<ul>
<li>Introduction to .NET and Vibe Coding</li>
<li>Setting Up the .NET SDK and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Building a .NET Console and Web App from a Prompt</li>
<li>Effective Prompting for .NET Code Generation</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building and Deploying .NET Applications with AI</h3>
<ul>
<li>Building Web APIs and Pages with ASP.NET</li>
<li>Working with Data and Entity Framework</li>
<li>Testing and Debugging with AI</li>
<li>Building, Running and Deploying Your .NET App</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Vibe Coding for .NET | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Build .NET applications with AI vibe coding. Master C#, ASP.NET, web APIs, Entity Framework and deployment using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Vibe Coding, .NET, ASP.NET, C Sharp, Cursor, GitHub Copilot, Claude, Web API, Entity Framework, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '7.5') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1310-20260711-092610.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-vibe-coding-for-dotnet') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_badge, 0, @e, 'AI Vibe Coding Series') ON DUPLICATE KEY UPDATE value = VALUES(value);
