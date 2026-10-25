-- C728: "AI Vibe Coding for Algorithmic Trading" -> "AI Powered Quantitative Trading Fundamentals", and the
-- slug ai-vibe-coding-for-algorithmic-trading -> ai-powered-quantitative-trading-fundamentals. C728 is now
-- the non-WSQ twin of TGS-2023018794 (IBF - Machine Learning 101 for Financial Trading); its courseware
-- was converted from the IBF v2.7 low-code set as v2.0 on 2026-10-25 (2 days, 15 h, 20 Trading Simulator labs).
--
-- 1. name, url_key/url_path, cover alt + gallery labels, meta_title (bare)/meta_description/meta_keyword.
-- 2. About (short_description) + topics (description, LSN_DATA) written from the converted courseware's
--    four topics and their sub-topics -- the IBF parent's storefront topics are its pre-v2.0 syllabus, so
--    they are not copied. Neither text states a day count. whoshouldattend = the Lesson Plan audience.
-- 3. prerequisite: the course is low-code (no Python needed) -> Prerequisite + Software/Hardware rewritten
--    (Trading Simulator via uv/Docker, free Alpaca paper + TradingView accounts, PC or Mac).
-- 4. trainerprofile: course-specific bio lines retitled in place.
-- 5. Cover re-rendered with the new title (R2). Funding block -> the IBF twin.
-- 6. 301s: C728's system rows renamed in place, every old path 301s to the new bare slug, legacy RP rows
--    into an old path flattened onto it; search redirects repointed.
-- Duration 15 / sessions 2 / $700 are already correct and untouched.
--
-- SG-only (store guard) -> no-op on MY/GH. Idempotent.
-- Post-deploy: refreshProductRewrite(728), flat + url reindex, cache flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C728' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL);

SET @old_title := 'AI Vibe Coding for Algorithmic Trading';
SET @new_title := 'AI Powered Quantitative Trading Fundamentals';
SET @old_slug  := 'ai-vibe-coding-for-algorithmic-trading';
SET @new_slug  := 'ai-powered-quantitative-trading-fundamentals';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title' AND backend_type = 'varchar');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description' AND backend_type = 'varchar');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword' AND backend_type = 'text');
SET @a_sdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_who     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
SET @a_tprof   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_cover   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

-- ------------------------------------------------------- name / slug -----
UPDATE catalog_product_entity_varchar SET value = @new_title
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_name;

UPDATE catalog_product_entity_varchar SET value = @new_slug
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlkey;

UPDATE catalog_product_entity_varchar SET value = CONCAT(@new_slug, '.html')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlpath;

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

-- ---------------------------------------------- meta (title stored bare) -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, 'AI Powered Quantitative Trading Fundamentals Course' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Learn AI powered quantitative trading: test hypotheses, build ML trading signals, backtest with costs and automate paper trading on Alpaca. No coding needed.' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'quantitative trading course, algorithmic trading course Singapore, AI trading, machine learning for trading, backtesting, paper trading, TradingView, Alpaca' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------- About / topics / audience -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sdesc, 0, @pid, '<p>AI Powered Quantitative Trading Fundamentals is a hands-on, low-code course on quant and algorithmic stock trading. You learn to turn a trading idea into a testable hypothesis, model it with machine learning, backtest it with realistic trading costs and run it as an automated paper-trading pipeline on Alpaca and TradingView. Every lab runs in the course''s Trading Simulator, so no programming is required: you own the hypothesis, the algorithm, the testing and the risk, while the software does the coding.</p><p>The course opens with quant success stories and the evolution of quant, from Ed Thorp and Renaissance to high-frequency trading, and the shift from machine learning to LLMs and multi-agent trading systems. You then build technical indicators and trading strategies on TradingView, define performance and risk metrics, train and A/B test machine-learning trading signals, find market regimes with clustering and PCA, and build a hedged pairs-trading strategy.</p><p>The final topic brings everything together in an end-to-end algorithmic trading pipeline: backtesting with costs, forward testing with automatic paper orders on Alpaca, TradingView webhook alerts, automated bias diagnostics and a performance tearsheet. Twenty hands-on labs build the pipeline one stage at a time. All trading is paper trading, and nothing in the course is investment advice.</p>' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title": "Topic 1: Foundations of Quant and Algorithmic Trading: From Thorp to AI Agents", "subsecs": [{"title": "Quant Success Stories: What Systematic Trading Has Achieved", "links": []}, {"title": "The Evolution of Quant: From Thorp and Renaissance to High-Frequency Trading", "links": []}, {"title": "The Paradigm Shift from Machine Learning to LLMs, and Its Impact on Quant", "links": []}, {"title": "Agentic AI versus AI Agents in Trading, and Multi-Agent Trading Systems", "links": []}, {"title": "Forms of Data within Financial Services and Big Data Applications in Trading", "links": []}, {"title": "Developing Hypotheses for Quant and Algorithmic Trading Models", "links": []}]}, {"title": "Topic 2: Technical Indicators, Trading Strategies and Metrics with TradingView and Alpaca", "subsecs": [{"title": "Technical Indicators: Trend, Momentum, Volatility and Volume", "links": []}, {"title": "Classification of Algorithmic Trading and Quant Algorithms", "links": []}, {"title": "Analytics Platforms and Tools: TradingView versus Alpaca, and Python", "links": []}, {"title": "Coding Languages for Algorithms and Signals, and Order Placement", "links": []}, {"title": "Performance and Risk Metric Definitions", "links": []}]}, {"title": "Topic 3: Machine Learning Models, Statistical Modelling and A/B Testing for Trading Signals", "subsecs": [{"title": "Types of Statistical Analyses, Data Models, Algorithms and Computational Methods", "links": []}, {"title": "Supervised Learning Models for Trading Signals", "links": []}, {"title": "Unsupervised Learning: Clustering and PCA for Market Regimes", "links": []}, {"title": "Statistical Modelling Techniques for Financial Time Series", "links": []}, {"title": "A/B Testing Trading Strategies", "links": []}, {"title": "Pairs Trading: Statistical Arbitrage as a Hedging Algorithm", "links": []}]}, {"title": "Topic 4: Building an End-to-End Algorithmic Trading Pipeline: Backtest, Forward Test and Performance Analysis", "subsecs": [{"title": "Architecture of an End-to-End Algorithmic Trading Pipeline", "links": []}, {"title": "Backtesting with Realistic Trading Costs", "links": []}, {"title": "Forward Testing with Automated Paper Trading", "links": []}, {"title": "Potential Reasons for Unintended Outcomes and How to Diagnose Them", "links": []}, {"title": "Performance Analysis, Insights and Reporting", "links": []}]}] -->\n<p><strong>Topic 1: Foundations of Quant and Algorithmic Trading: From Thorp to AI Agents</strong></p>\n<p><em>Quant Success Stories: What Systematic Trading Has Achieved</em></p>\n<p><em>The Evolution of Quant: From Thorp and Renaissance to High-Frequency Trading</em></p>\n<p><em>The Paradigm Shift from Machine Learning to LLMs, and Its Impact on Quant</em></p>\n<p><em>Agentic AI versus AI Agents in Trading, and Multi-Agent Trading Systems</em></p>\n<p><em>Forms of Data within Financial Services and Big Data Applications in Trading</em></p>\n<p><em>Developing Hypotheses for Quant and Algorithmic Trading Models</em></p>\n<p><strong>Topic 2: Technical Indicators, Trading Strategies and Metrics with TradingView and Alpaca</strong></p>\n<p><em>Technical Indicators: Trend, Momentum, Volatility and Volume</em></p>\n<p><em>Classification of Algorithmic Trading and Quant Algorithms</em></p>\n<p><em>Analytics Platforms and Tools: TradingView versus Alpaca, and Python</em></p>\n<p><em>Coding Languages for Algorithms and Signals, and Order Placement</em></p>\n<p><em>Performance and Risk Metric Definitions</em></p>\n<p><strong>Topic 3: Machine Learning Models, Statistical Modelling and A/B Testing for Trading Signals</strong></p>\n<p><em>Types of Statistical Analyses, Data Models, Algorithms and Computational Methods</em></p>\n<p><em>Supervised Learning Models for Trading Signals</em></p>\n<p><em>Unsupervised Learning: Clustering and PCA for Market Regimes</em></p>\n<p><em>Statistical Modelling Techniques for Financial Time Series</em></p>\n<p><em>A/B Testing Trading Strategies</em></p>\n<p><em>Pairs Trading: Statistical Arbitrage as a Hedging Algorithm</em></p>\n<p><strong>Topic 4: Building an End-to-End Algorithmic Trading Pipeline: Backtest, Forward Test and Performance Analysis</strong></p>\n<p><em>Architecture of an End-to-End Algorithmic Trading Pipeline</em></p>\n<p><em>Backtesting with Realistic Trading Costs</em></p>\n<p><em>Forward Testing with Automated Paper Trading</em></p>\n<p><em>Potential Reasons for Unintended Outcomes and How to Diagnose Them</em></p>\n<p><em>Performance Analysis, Insights and Reporting</em></p>' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_who, 0, @pid, '<ul>\n<li>Traders, dealers and investment or research analysts</li>\n<li>Quantitative, risk and data analysts in financial institutions</li>\n<li>Finance and technology professionals moving into algorithmic trading or AI roles</li>\n<li>Individual investors who want a disciplined, evidence-based approach to systematic trading</li>\n</ul>' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_prereq, 0, @pid, '<h2>Prerequisite</h2>\n<p>No programming is required - every lab runs in a low-code trading simulator. The following is assumed:</p>\n<ul>\n<li>Basic computer literacy</li>\n<li>A basic understanding of financial markets (stocks, ETFs, buying and selling)</li>\n</ul>\n<h2>Minimum Software/Hardware Requirement</h2>\n<p><strong>Software:</strong></p>\n<p>You will need the following for this course:</p>\n<ul>\n<li>The course <a href="https://github.com/alfredang/algorithmic-trader-bot" target="_blank">Trading Simulator</a> &ndash; free, installed in class with <a href="https://docs.astral.sh/uv/getting-started/installation/" target="_blank">uv</a> or <a href="https://www.docker.com/products/docker-desktop/" target="_blank">Docker Desktop</a></li>\n<li>An <a href="https://alpaca.markets/" target="_blank">Alpaca</a> paper-trading account &ndash; free, no deposit needed</li>\n<li>A <a href="https://www.tradingview.com/" target="_blank">TradingView</a> account &ndash; free plan</li>\n</ul>\n<p><strong>Hardware:</strong> Windows PC or Mac laptop</p>\n' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_text
   SET value = REPLACE(value, 'AI Vibe Coding for Algorithmic Trading', 'AI Powered Quantitative Trading Fundamentals')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_tprof AND value LIKE '%AI Vibe Coding for Algorithmic Trading%';

-- store-scoped overrides would shadow the store-0 values
DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_sdesc, @a_desc, @a_who, @a_prereq, @a_mkey) AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C728-20261025-053730.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------- funding block -> IBF twin -----
-- content-only UPDATE (a cms/block model save wipes cms_block_store)
UPDATE cms_block SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For IBF funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/ibf-machine-learning-101-for-financial-trading.html" title="IBF - Machine Learning 101 for Financial Trading">IBF - Machine Learning 101 for Financial Trading</a></span></p>'
 WHERE @ok AND identifier = 'course_C728_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 0) Squatters on a path C728 will occupy -> delete.
DROP TEMPORARY TABLE IF EXISTS tmp_c728_new;
CREATE TEMPORARY TABLE tmp_c728_new (store_id SMALLINT, p VARCHAR(255));
INSERT INTO tmp_c728_new
SELECT store_id, REPLACE(request_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'))
  FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

DELETE r FROM core_url_rewrite r
  JOIN tmp_c728_new n ON n.store_id = r.store_id AND n.p = r.request_path
 WHERE @ok AND r.is_system = 0 AND (r.product_id IS NULL OR r.product_id <> @pid);

DROP TEMPORARY TABLE IF EXISTS tmp_c728_new;

-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c728_old;
CREATE TEMPORARY TABLE tmp_c728_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c728_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 2) Rename those system rows in place, so the new slug resolves immediately.
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
  FROM tmp_c728_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c728_old;

-- ------------------------------------------------- search redirects -----
UPDATE catalogsearch_query
   SET redirect = REPLACE(redirect, CONCAT('/', @old_slug, '.html'), CONCAT('/', @new_slug, '.html'))
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html');
