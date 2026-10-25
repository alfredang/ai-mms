-- C728 AI Powered Quantitative Trading Fundamentals: metas re-asserted, plus Who Should Attend and the Attitude / Experience entry
-- requirements copied from its IBF twin TGS-2023018794 (user request 2026-10-25). The About and topics stay
-- as written from the converted courseware in 1848 (the IBF page still lists its older 3-topic syllabus), and
-- nothing IBF/funding-related is copied (promo-code, subsidy, SkillsFuture, UTAP sections). The IBF page's
-- "Basic Python" requirement is not copied: the C728 labs are low-code.
--
--
-- Also re-asserts C728's metas from 1848: the SG meta refresh 1844 carried C728's pre-rename metas and was
-- applied on prod AFTER 1848 (2026-10-25 05:59 vs 05:45), reverting the title/description to "AI Vibe Coding".
--
-- SG-only (store guard) -> no-op on MY/GH. Idempotent. Post-deploy: flat update + cache flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C728' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023018794' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_who    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_prereq := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');

-- Who Should Attend: the IBF twin's list (no funding wording in it)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, s.attribute_id, 0, @pid, s.value
  FROM catalog_product_entity_text s
 WHERE @ok AND s.entity_id = @src AND s.store_id = 0 AND s.attribute_id = @a_who
   AND s.value NOT LIKE '%IBF%' AND s.value NOT LIKE '%fund%'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_prereq, 0, @pid, '<h2>Prerequisite</h2>\n<p>No programming is required - every lab runs in a low-code trading simulator.</p>\n<p>Knowledge and Skills</p>\n<ul>\n<li>Able to operate using computer functions</li>\n<li>A basic understanding of financial markets (stocks, ETFs, buying and selling)</li>\n</ul>\n<p>Attitude</p>\n<ul>\n<li>Positive Learning Attitude</li>\n<li>Enthusiastic Learner</li>\n</ul>\n<p>Experience</p>\n<ul>\n<li>Minimum of 1 year of working experience.</li>\n</ul>\n<h2>Minimum Software/Hardware Requirement</h2>\n<p><strong>Software:</strong></p>\n<p>You will need the following for this course:</p>\n<ul>\n<li>The course <a href="https://github.com/alfredang/algorithmic-trader-bot" target="_blank">Trading Simulator</a> &ndash; free, installed in class with <a href="https://docs.astral.sh/uv/getting-started/installation/" target="_blank">uv</a> or <a href="https://www.docker.com/products/docker-desktop/" target="_blank">Docker Desktop</a></li>\n<li>An <a href="https://alpaca.markets/" target="_blank">Alpaca</a> paper-trading account &ndash; free, no deposit needed</li>\n<li>A <a href="https://www.tradingview.com/" target="_blank">TradingView</a> account &ndash; free plan</li>\n</ul>\n<p><strong>Hardware:</strong> Windows PC or Mac laptop</p>\n' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- metas (1844 ran after 1848 on prod and restored the pre-rename values)
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title' AND backend_type = 'varchar');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description' AND backend_type = 'varchar');
SET @a_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword' AND backend_type = 'text');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, 'AI Powered Quantitative Trading Fundamentals Course' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Learn AI powered quantitative trading: test hypotheses, build ML trading signals, backtest with costs and automate paper trading on Alpaca. No coding needed.' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'quantitative trading course, algorithmic trading course Singapore, AI trading, machine learning for trading, backtesting, paper trading, TradingView, Alpaca' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_mtitle, @a_mdesc) AND store_id <> 0;
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_who, @a_prereq, @a_mkey) AND store_id <> 0;
