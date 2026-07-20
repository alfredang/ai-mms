-- Repurpose two more courses into the AI Vibe Coding series (both 2 days / 4 topics):
--   C356  AI Vibe Coding for Java                (was Full Java Programming Training)
--   C728  AI Vibe Coding for Algorithmic Trading (was Algorithmic Trading Fundamentals with Python)
-- Each: name, overview, topics, meta, duration 15h, cover, url_key, series badge.
-- Per-market price (700/2200/3000) and SG-only funding blocks applied direct on
-- each prod DB. Store scope 0. Idempotent. No content line ends in a semicolon.

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
-- C356 - AI Vibe Coding for Java
-- =========================================================================
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C356');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI Vibe Coding for Java') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Build real Java applications with AI Vibe Coding for Java. This hands-on 2-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to write, run and debug Java code. Instead of memorising syntax and boilerplate, you will vibe code &mdash; describing what you want in plain language and letting AI generate, explain, refactor and fix Java code while you learn the fundamentals and stay in control of the logic.</p>
<p>Through practical projects, participants will set up a Java development environment, work with variables, control flow, methods, classes, objects, collections and exceptions, and build a small application &mdash; all with an AI pair programmer at their side. You will also learn to review, test and improve AI-generated code so your programs are correct and maintainable. By the end of the course, you will be able to write and understand Java confidently and use an effective AI vibe-coding workflow to build applications faster.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for Java</h3>
<ul>
<li>Introduction to Java and Vibe Coding</li>
<li>Setting Up the JDK and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Writing and Running Your First Java Program from a Prompt</li>
<li>Effective Prompting for Java Code Generation</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Java Fundamentals with AI</h3>
<ul>
<li>Variables, Data Types and Operators</li>
<li>Control Flow, Loops and Methods</li>
<li>Working with Arrays and Strings</li>
<li>Debugging and Explaining Code with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Object-Oriented Java with AI</h3>
<ul>
<li>Classes, Objects and Encapsulation</li>
<li>Inheritance and Interfaces</li>
<li>Collections and Generics</li>
<li>Exception Handling</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Building and Testing Java Applications with AI</h3>
<ul>
<li>Reading and Writing Files</li>
<li>Building a Console Application</li>
<li>Testing and Improving Your Code with AI</li>
<li>Compiling, Packaging and Running Your Project</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Vibe Coding for Java | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Learn Java programming with AI vibe coding. Master syntax, methods, classes, inheritance, collections and exceptions using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Vibe Coding, Java, JDK, Cursor, GitHub Copilot, Claude, Object-Oriented, Collections, Classes, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '15') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C356-20260711-093604.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-vibe-coding-for-java') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_badge, 0, @e, 'AI Vibe Coding Series') ON DUPLICATE KEY UPDATE value = VALUES(value);

-- =========================================================================
-- C728 - AI Vibe Coding for Algorithmic Trading
-- =========================================================================
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C728');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI Vibe Coding for Algorithmic Trading') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Build algorithmic trading strategies with AI Vibe Coding for Algorithmic Trading. This hands-on 2-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to write Python code for quantitative trading. Instead of wrestling with libraries and APIs, you will vibe code &mdash; describing the strategy and analysis you want in plain language and letting AI generate, explain, refactor and debug your trading code while you stay in control of the logic and risk.</p>
<p>Through practical projects, participants will set up a Python trading environment, fetch and analyse market data, build and backtest trading strategies, evaluate performance, and connect to a broker API &mdash; all with an AI pair programmer at their side. You will also learn to review, test and validate AI-generated code so your strategies are sound and reproducible. By the end of the course, you will be able to design, test and run algorithmic trading strategies faster and more confidently with an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for Trading</h3>
<ul>
<li>Introduction to Algorithmic Trading and Vibe Coding</li>
<li>Setting Up Python, Trading Libraries and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Fetching and Exploring Market Data from a Prompt</li>
<li>Effective Prompting for Trading Code Generation</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Analysing Markets with AI</h3>
<ul>
<li>Working with Price Data and Indicators</li>
<li>Visualising Market Data</li>
<li>Building Trading Signals</li>
<li>Debugging and Explaining Code with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Building and Backtesting Strategies with AI</h3>
<ul>
<li>Designing a Trading Strategy</li>
<li>Backtesting a Strategy</li>
<li>Measuring Performance and Risk</li>
<li>Reviewing and Refactoring AI-Generated Code</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Automating and Running Trading with AI</h3>
<ul>
<li>Optimising Strategy Parameters</li>
<li>Connecting to a Broker API</li>
<li>Testing and Validating Your Strategy</li>
<li>Running and Monitoring Your Trading Bot</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Vibe Coding for Algorithmic Trading | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Build algorithmic trading strategies with AI vibe coding. Master market data, indicators, backtesting, risk and broker APIs in Python using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Vibe Coding, Algorithmic Trading, Python, Cursor, GitHub Copilot, Claude, Backtesting, Trading Strategies, Quantitative Finance, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '15') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C728-20260711-093604.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-vibe-coding-for-algorithmic-trading') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_badge, 0, @e, 'AI Vibe Coding Series') ON DUPLICATE KEY UPDATE value = VALUES(value);
