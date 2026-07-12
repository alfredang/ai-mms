-- Rename course C1319 from "Blockchain and DeFi 101 for Fintech Executives" to
-- "AI Vibe Coding for Crypto Tokens" (1 day / 2 topics). Part of the AI Vibe
-- Coding series (badge). name, overview, topics, meta (title/description/keyword),
-- cover, url_key, badge. Price unchanged (already 350 SG). Store scope 0.
-- Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1319');
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
VALUES (4, @a_name, 0, @e, 'AI Vibe Coding for Crypto Tokens') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Create and deploy your own crypto tokens with AI Vibe Coding for Crypto Tokens. This hands-on 1-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to write, test and deploy ERC-20 and other token smart contracts. Instead of memorising Solidity and token standards, you will vibe code &mdash; describing what you want in plain language and letting AI generate, refactor and debug your token code while you design the tokenomics.</p>
<p>Through practical projects, participants will set up a token development environment, generate and deploy a crypto token, add minting, transfers and supply logic, and test and secure the token contract &mdash; all with an AI pair programmer at their side. You will also learn to review, audit and improve AI-generated token code so your tokens stay safe and correct. By the end of the course, you will be able to build and deploy crypto tokens faster with an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for Crypto Tokens</h3>
<ul>
<li>Introduction to Crypto Tokens, Token Standards and Vibe Coding</li>
<li>Setting Up AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Generating and Deploying an ERC-20 Token with AI</li>
<li>Effective Prompting for Token Code Generation</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building and Securing Crypto Tokens with AI</h3>
<ul>
<li>Adding Minting, Transfers and Supply Logic</li>
<li>Testing and Debugging Token Contracts with AI</li>
<li>Reviewing, Auditing and Securing AI-Generated Tokens</li>
<li>Deploying and Interacting with Your Crypto Token</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Vibe Coding for Crypto Tokens') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Create and deploy crypto tokens with AI vibe coding. Generate, test, audit and deploy ERC-20 tokens using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Vibe Coding, Crypto Tokens, ERC-20, Token, Smart Contract, Solidity, Blockchain, Web3, Cursor, GitHub Copilot, Claude')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '7.5') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1319-20260712-030428.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-vibe-coding-for-crypto-tokens') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_badge, 0, @e, 'AI Vibe Coding Series') ON DUPLICATE KEY UPDATE value = VALUES(value);
