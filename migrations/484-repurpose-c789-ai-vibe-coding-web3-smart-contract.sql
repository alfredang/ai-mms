-- Repurpose course C789 from "Ethereum Smart Contract Programming with
-- Solidity and Web3 (Python)" to "AI Vibe Coding for Web 3 Smart Contract"
-- (AI Vibe Coding Series, 2 days / 15h / 4 topics). name, overview, topics,
-- meta, cover image, duration, image labels.
-- Price already $700 and duration already 15 — set idempotently anyway.
-- url_key intentionally UNCHANGED (series rule — preserves URL + SEO).
-- Badge set here directly (edited shared migration 342 would never re-run on
-- prod); funding block link fixed in 485.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C789.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C789');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');
SET @a_badge := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_series_badge');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'AI Vibe Coding for Web 3 Smart Contract' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Build and ship Web 3 smart contracts without writing every line of Solidity yourself. In this hands-on 2-day course you will use AI coding assistants&mdash;Cursor, GitHub Copilot and Claude&mdash;to vibe code Ethereum smart contracts end to end: describe the contract you want in plain English, let the AI generate the Solidity code, then review, test and iterate with follow-up prompts. You will learn the prompting patterns that keep AI-generated smart contract code correct, secure and gas-efficient.</p>
<p>Over four practical topics you will vibe code the full Web 3 journey&mdash;from Solidity fundamentals and your first deployed contract, to ERC-20 tokens and ERC-721 NFTs with OpenZeppelin, and finally a decentralised app (dApp) that connects wallets and interacts with your contracts through Web3. By the end of the course, you will have a portfolio of deployed smart contracts and a repeatable AI vibe coding workflow you can apply to any blockchain project.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 AI Vibe Coding for Solidity Fundamentals</h3>
<ul>
<li>What Is AI Vibe Coding</li>
<li>Setting Up Cursor, GitHub Copilot and Claude for Web 3 Development</li>
<li>Overview of Ethereum, Smart Contracts and the EVM</li>
<li>Prompting Patterns for Correct Solidity Code</li>
<li>Vibe Coding Your First Solidity Contract in Remix</li>
<li>Reviewing and Debugging AI-Generated Solidity Code</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Vibe Coding Smart Contracts</h3>
<ul>
<li>Solidity Data Types, Functions, Modifiers and Events</li>
<li>Vibe Coding Contract Logic from Plain-English Prompts</li>
<li>Generating Unit Tests and Deployment Scripts with Hardhat</li>
<li>Smart Contract Security Review with AI Assistance</li>
<li>Deploying to an Ethereum Testnet</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Vibe Coding Tokens and NFTs</h3>
<ul>
<li>Overview of Token Standards: ERC-20 and ERC-721</li>
<li>Vibe Coding an ERC-20 Token with OpenZeppelin</li>
<li>Vibe Coding an ERC-721 NFT Collection with Metadata</li>
<li>Minting, Transferring and Managing Tokens</li>
<li>Iterating on Token Contracts with Follow-Up Prompts</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Vibe Coding Web 3 dApps</h3>
<ul>
<li>Connecting to Ethereum with Web3 Libraries</li>
<li>Vibe Coding a dApp Frontend with Wallet Integration</li>
<li>Reading and Writing Contract State from the dApp</li>
<li>Handling Transactions, Gas and Events</li>
<li>Packaging and Demoing a Complete Web 3 Project</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'AI Vibe Coding for Web 3 Smart Contract' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Vibe code Web 3 smart contracts with Cursor, GitHub Copilot and Claude in this hands-on 2-day course. Build Solidity contracts, ERC-20 tokens, NFTs and a full dApp from plain-English prompts.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'AI Vibe Coding, Web3, Smart Contract, Solidity, Ethereum, Blockchain, ERC-20, NFT, ERC-721, dApp, Cursor, GitHub Copilot, Claude, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C789-20260717-092718.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @e, '15' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_badge, 0, @e, 'AI Vibe Coding Series' FROM DUAL WHERE @e IS NOT NULL AND @a_badge IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image alt labels still carried the old Ethereum course title (store 0 + 1).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'AI Vibe Coding for Web 3 Smart Contract' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'AI Vibe Coding for Web 3 Smart Contract' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'AI Vibe Coding for Web 3 Smart Contract' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_img, @a_dur, @a_badge, @a_il, @a_sil, @a_til);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
