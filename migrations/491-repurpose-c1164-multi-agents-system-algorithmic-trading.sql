-- Repurpose course C1164 from "Machine Learning for Algorithmic Trading"
-- to "Multi Agents System for Algorithmic Trading" (2 days / 15h / 4 topics —
-- agentic AI teams that research, backtest and execute trading strategies).
-- name, overview, topics, meta, url_key, cover, image labels.
-- Price ($700) and duration (15h) intentionally kept.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C1164.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1164');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Multi Agents System for Algorithmic Trading' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Algorithmic trading is entering the agentic AI era. Instead of a single model predicting prices, a multi agents system deploys a team of specialised AI agents&mdash;a market research agent, a technical analysis agent, a strategy agent, a risk manager and a trade executor&mdash;that collaborate, debate and cross-check each other before any trading decision is made. In this hands-on 2-day course, you will learn how to design and build such agent teams using leading multi-agent frameworks.</p>
<p>Through guided exercises, you will build agents that pull live market data, analyse technical indicators and news sentiment, generate and backtest trading strategies, and execute simulated trades under explicit risk-management guardrails. By the end of the course, you will have a working multi-agent trading crew and a practical blueprint for applying agentic AI to your own investment and trading workflows.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Overview of Multi Agents Systems for Trading</h3>
<ul>
<li>From Machine Learning to Agentic AI in Trading</li>
<li>What Is a Multi Agents System</li>
<li>LLM Agents, Tools and Function Calling</li>
<li>Multi-Agent Frameworks: AutoGen, CrewAI and LangGraph</li>
<li>Architecture of a Trading Agent Team</li>
<li>Setting Up the Development Environment and Market Data APIs</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Market Research and Analysis Agents</h3>
<ul>
<li>Building a Market Data Agent for Prices and Fundamentals</li>
<li>Technical Analysis Agent with Indicators and Chart Patterns</li>
<li>News and Sentiment Analysis Agent</li>
<li>Agent Collaboration: Debate, Critique and Consensus</li>
<li>Producing an AI-Generated Research Report</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Strategy and Backtesting Agents</h3>
<ul>
<li>Strategy Agent: Generating Trading Rules and Signals</li>
<li>Backtesting Agent with Historical Market Data</li>
<li>Evaluating Strategies: Returns, Drawdown and Sharpe Ratio</li>
<li>Iterating Strategies with Agent Feedback Loops</li>
<li>Avoiding Overfitting and Lookahead Bias</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Trade Execution and Risk Management Agents</h3>
<ul>
<li>Risk Manager Agent: Position Sizing, Stop Loss and Exposure Limits</li>
<li>Trade Execution Agent with Paper Trading</li>
<li>Orchestrating the Full Multi-Agent Trading Workflow</li>
<li>Monitoring, Logging and Human-in-the-Loop Controls</li>
<li>Responsible and Compliant Use of AI in Trading</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Multi Agents System for Algorithmic Trading' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Build a multi agents system for algorithmic trading in this hands-on 2-day course. Create AI agent teams that research markets, backtest strategies and execute trades with risk controls.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Multi Agents System, Algorithmic Trading, Agentic AI, AI Agents, AutoGen, CrewAI, LangGraph, Trading Strategy, Backtesting, Risk Management, Quantitative Trading, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'multi-agents-system-for-algorithmic-trading' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1164-20260717-101111.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image alt labels still carried the old "Machine Learning and Deep Learning
-- for Trading" title (store 1 carried per-store copies).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Multi Agents System for Algorithmic Trading' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Multi Agents System for Algorithmic Trading' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Multi Agents System for Algorithmic Trading' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_img, @a_il, @a_sil, @a_til);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
