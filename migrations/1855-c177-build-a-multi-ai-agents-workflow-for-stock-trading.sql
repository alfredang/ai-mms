-- C177: "AI Agents for Stock Trading" -> "Build a Multi AI Agents Workflow for Stock Trading", slug ai-agents-for-stock-trading -> build-a-multi-ai-agents-workflow-for-stock-trading.
-- New 1-day (7.5 h, $350, schedule A17 unchanged) AI vibe coding course: learners build, from scratch, the eight-agent
-- trading workflow demonstrated in C728 (lead, finance research, news sentiment, trading strategy, signal generation,
-- stock trader, performance analysis, strategy review). Courseware v2.0 (repo tertiarycourses/
-- C177-Build-a-Multi-AI-Agents-Workflow-for-Stock-Trading).
--
-- name, url_key/url_path, cover + alt labels, metas, About + topics from the courseware, prerequisite: C728 is the
-- prerequisite (linked), software list rewritten for the vibe coding labs (entry requirements kept). 301s: system rows
-- renamed in place, old paths 301 to the new bare slug, legacy RP rows flattened, search redirects repointed.
--
-- SG-only (store guard) -> no-op on MY/GH. Idempotent. Post-deploy: refreshProductRewrite(177), flat update, flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C177' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL);

SET @new_title := 'Build a Multi AI Agents Workflow for Stock Trading';
SET @old_slug  := 'ai-agents-for-stock-trading';
SET @new_slug  := 'build-a-multi-ai-agents-workflow-for-stock-trading';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title' AND backend_type = 'varchar');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description' AND backend_type = 'varchar');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword' AND backend_type = 'text');
SET @a_sdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
SET @a_tprof   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_cover   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

-- ------------------------------------------------------- name / slug -----
UPDATE catalog_product_entity_varchar SET value = @new_title WHERE @ok AND entity_id = @pid AND attribute_id = @a_name;
UPDATE catalog_product_entity_varchar SET value = @new_slug WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlkey;
UPDATE catalog_product_entity_varchar SET value = CONCAT(@new_slug, '.html') WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlpath;

-- ------------------------------------------------------ image labels -----
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
   AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label')
   SET v.value = @new_title
 WHERE @ok AND v.entity_id = @pid;
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @new_title
 WHERE @ok AND g.entity_id = @pid;

-- ------------------------------------------------------------- metas -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, 'Build a Multi AI Agents Workflow for Stock Trading Course' FROM DUAL WHERE @ok ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Build a multi AI agents stock trading workflow with AI vibe coding: research, Reddit and news sentiment, strategy, signals, Alpaca paper orders, review loop.' FROM DUAL WHERE @ok ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'multi AI agents trading course, AI agents stock trading Singapore, AI vibe coding, trading bot, Alpaca paper trading, Reddit sentiment, Twelve Data, algorithmic trading' FROM DUAL WHERE @ok ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------- About / topics / prerequisite -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sdesc, 0, @pid, '<p>Build a Multi AI Agents Workflow for Stock Trading teaches you to build, from scratch, the multi AI agents trading system demonstrated in AI Powered Quantitative Trading Fundamentals. Using AI vibe coding, you design eight cooperating agents and direct an AI coding assistant such as Claude Code or OpenAI Codex to write each one, then review the code against a written contract and prove it with tests.</p><p>A lead agent orchestrates the flow. The finance research agent gathers Twelve Data candles at 1-minute, 15-minute and 1-hour intervals plus Yahoo Finance and Equibles company data, while the news sentiment agent reads Reddit through the Reddit API and headlines from NewsAPI. The trading strategy agent merges both reports into a strategy built on trend, momentum, volatility, VWAP, RSI, MACD or a mix of them, and the signal generation agent turns it into a long, short or null signal.</p><p>The stock trader agent then places the order on an Alpaca paper-trading account, the performance analysis agent reports return, Sharpe ratio, drawdown and win rate on a dashboard, and the strategy review agent studies the results and updates the trading strategy for the next run. You finish by publishing your project to your own GitHub repository. Every lab also runs offline on sample data. All trading is paper trading and nothing in the course is investment advice.</p>' FROM DUAL WHERE @ok ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title": "Topic 1: Designing a Multi AI Agents Trading Workflow", "subsecs": [{"title": "The Eight Agents and the Lead Agent that Orchestrates Them", "links": []}, {"title": "The Message Contract between Agents", "links": []}, {"title": "The AI Vibe Coding Loop: Spec, Prompt, Review, Test, Commit", "links": []}, {"title": "Lab 1: Scaffold the Project and the Agent Message Contract", "links": []}]}, {"title": "Topic 2: Building the Research and Decision Agents", "subsecs": [{"title": "Finance Research Agent: Twelve Data 1min, 15min and 1h Candles, Yahoo Finance and Equibles", "links": []}, {"title": "News Sentiment Agent: Reddit API and NewsAPI Sentiment", "links": []}, {"title": "Trading Strategy Agent: Trend, Momentum, Volatility, VWAP, RSI, MACD and Mixed Algorithms", "links": []}, {"title": "Signal Generation Agent: Long, Short or Null Signals", "links": []}, {"title": "Labs 2-5: Build the Finance Research, News Sentiment, Trading Strategy and Signal Generation Agents", "links": []}]}, {"title": "Topic 3: Execution, Performance and the Feedback Loop", "subsecs": [{"title": "Stock Trader Agent: Automated Orders on an Alpaca Paper Account", "links": []}, {"title": "Performance Analysis Agent: Return, Sharpe, Drawdown and Win Rate on a Dashboard", "links": []}, {"title": "Strategy Review Agent: the Feedback Loop that Updates the Strategy", "links": []}, {"title": "Lead Agent Orchestration and Publishing the Project to GitHub", "links": []}, {"title": "Labs 6-8: Build the Stock Trader, Performance Analysis, Strategy Review and Lead Agents", "links": []}]}] -->\n<p><strong>Topic 1: Designing a Multi AI Agents Trading Workflow</strong></p>\n<p><em>The Eight Agents and the Lead Agent that Orchestrates Them</em></p>\n<p><em>The Message Contract between Agents</em></p>\n<p><em>The AI Vibe Coding Loop: Spec, Prompt, Review, Test, Commit</em></p>\n<p><em>Lab 1: Scaffold the Project and the Agent Message Contract</em></p>\n<p><strong>Topic 2: Building the Research and Decision Agents</strong></p>\n<p><em>Finance Research Agent: Twelve Data 1min, 15min and 1h Candles, Yahoo Finance and Equibles</em></p>\n<p><em>News Sentiment Agent: Reddit API and NewsAPI Sentiment</em></p>\n<p><em>Trading Strategy Agent: Trend, Momentum, Volatility, VWAP, RSI, MACD and Mixed Algorithms</em></p>\n<p><em>Signal Generation Agent: Long, Short or Null Signals</em></p>\n<p><em>Labs 2-5: Build the Finance Research, News Sentiment, Trading Strategy and Signal Generation Agents</em></p>\n<p><strong>Topic 3: Execution, Performance and the Feedback Loop</strong></p>\n<p><em>Stock Trader Agent: Automated Orders on an Alpaca Paper Account</em></p>\n<p><em>Performance Analysis Agent: Return, Sharpe, Drawdown and Win Rate on a Dashboard</em></p>\n<p><em>Strategy Review Agent: the Feedback Loop that Updates the Strategy</em></p>\n<p><em>Lead Agent Orchestration and Publishing the Project to GitHub</em></p>\n<p><em>Labs 6-8: Build the Stock Trader, Performance Analysis, Strategy Review and Lead Agents</em></p>' FROM DUAL WHERE @ok ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_prereq, 0, @pid, '<h2>Prerequisite</h2>\n<p>You should complete <a href="https://www.tertiarycourses.com.sg/ai-powered-quantitative-trading-fundamentals.html" title="AI Powered Quantitative Trading Fundamentals">AI Powered Quantitative Trading Fundamentals (C728)</a> before taking this course. C728 demonstrates the multi AI agents trading system and the indicators, backtesting and paper trading it relies on; this course teaches you to build it from scratch.</p>\n<h2>Minimum Entry Requirement</h2><p>Knowledge and Skills</p><ul><li>Able to operate using computer functions</li><li>Minimum 3 GCE &lsquo;O&rsquo; Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li></ul><p>Attitude</p><ul><li>Positive Learning Attitude</li><li>Enthusiastic Learner</li></ul><p>Experience</p><ul><li>Minimum of 1 year of working experience.</li></ul><p>Target Age Group: 21-65 years old</p>\n<h2>Minimum Software/Hardware Requirement</h2>\n<p><strong>Software:</strong></p>\n<p>You will need the following for this course:</p>\n<ul>\n<li><a href="https://www.python.org/downloads/" target="_blank">Python 3.11 or later</a> &ndash; free</li>\n<li><a href="https://code.visualstudio.com/download" target="_blank">Visual Studio Code</a> &ndash; free</li>\n<li><a href="https://git-scm.com/downloads" target="_blank">Git</a> and a <a href="https://github.com/signup" target="_blank">GitHub</a> account &ndash; free</li>\n<li>An AI coding assistant &ndash; <a href="https://github.com/features/copilot/plans" target="_blank">GitHub Copilot Free</a> in Visual Studio Code works; Claude Code or OpenAI Codex if you already use one</li>\n<li>Optional free API keys for the live labs: <a href="https://twelvedata.com/" target="_blank">Twelve Data</a>, <a href="https://equibles.com/" target="_blank">Equibles</a>, <a href="https://newsapi.org/" target="_blank">NewsAPI</a>, a <a href="https://www.reddit.com/prefs/apps" target="_blank">Reddit</a> script app and an <a href="https://alpaca.markets/" target="_blank">Alpaca</a> paper-trading account &ndash; every lab also runs offline on sample data</li>\n</ul>\n<p><strong>Hardware:</strong> Windows PC or Mac laptop</p>\n' FROM DUAL WHERE @ok ON DUPLICATE KEY UPDATE value = VALUES(value);
UPDATE catalog_product_entity_text
   SET value = REPLACE(value, 'AI Agents for Stock Trading', 'Build a Multi AI Agents Workflow for Stock Trading')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_tprof AND value LIKE '%AI Agents for Stock Trading%'
   AND value NOT LIKE '%Build a Multi AI Agents Workflow for Stock Trading%';

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_sdesc, @a_desc, @a_prereq, @a_mkey) AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C177-20261025-064056.png' FROM DUAL WHERE @ok ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------- 301 rewrites ----
DROP TEMPORARY TABLE IF EXISTS tmp_c177_new;
CREATE TEMPORARY TABLE tmp_c177_new (store_id SMALLINT, p VARCHAR(255));
INSERT INTO tmp_c177_new
SELECT store_id, REPLACE(request_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'))
  FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));
DELETE r FROM core_url_rewrite r
  JOIN tmp_c177_new n ON n.store_id = r.store_id AND n.p = r.request_path
 WHERE @ok AND r.is_system = 0 AND (r.product_id IS NULL OR r.product_id <> @pid);
DROP TEMPORARY TABLE IF EXISTS tmp_c177_new;

DROP TEMPORARY TABLE IF EXISTS tmp_c177_old;
CREATE TEMPORARY TABLE tmp_c177_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c177_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

UPDATE core_url_rewrite
   SET request_path = REPLACE(request_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'))
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

UPDATE core_url_rewrite
   SET target_path = CONCAT(@new_slug, '.html')
 WHERE @ok AND options = 'RP'
   AND (target_path = CONCAT(@old_slug, '.html') OR target_path LIKE CONCAT('%/', @old_slug, '.html'));

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT o.store_id, CONCAT('manual-301-', MD5(o.request_path), '-', o.store_id), o.request_path,
       CONCAT(@new_slug, '.html'), 0, 'RP'
  FROM tmp_c177_old o;
DROP TEMPORARY TABLE IF EXISTS tmp_c177_old;

-- ------------------------------------------------- search redirects -----
UPDATE catalogsearch_query
   SET redirect = REPLACE(redirect, CONCAT('/', @old_slug, '.html'), CONCAT('/', @new_slug, '.html'))
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html');
