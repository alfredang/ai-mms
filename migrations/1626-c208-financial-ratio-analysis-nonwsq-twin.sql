-- C208 Financial Ratio Analysis: 1-day non-WSQ twin of TGS-2024049215
-- (WSQ - Mastering Financial Ratio Analysis: Unlocking Organizational Health).
--
-- "What's This Course About" and the course topics follow the WSQ parent, written as
-- literals (see 1619). About names this course instead of the WSQ title; neither text
-- states a day count. Already correct on prod and left alone: meta_description (no day
-- count), Duration 7.5 hrs, Sessions 1, $350, cover labels, and the funding block
-- course_C208_funding_and_grant (points at the WSQ twin).
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): schedule template -> A01 via the code path, then
-- flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C208' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024049215' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>The Financial Ratio Analysis course equips participants with the skills needed to analyze and interpret key financial ratios. By exploring liquidity, solvency, profitability, and valuation ratios, participants will gain the ability to assess an organization&rsquo;s financial health accurately. This course also covers a thorough review of financial statements, ensuring learners understand the foundational aspects of financial ratio analysis.</p>\r\n<p>In addition, the course delves into evaluating an organization&rsquo;s overall performance using ratio analysis. Participants will learn how to apply ratios in equity and credit analysis, forecast a company&rsquo;s performance, and assess the credit quality of debt investments. This comprehensive training provides the necessary tools to make informed financial decisions and evaluate an organization\'s financial stability and performance effectively.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<p><strong>Topic 1:&nbsp;</strong><strong>Assessing &nbsp;Organization&rsquo;s Profitability&nbsp;</strong></p>\r\n<ul>\r\n<li>Introduction to financial ratio analysis</li>\r\n<li>A Review of the Financial Statements</li>\r\n<li>Calculating and Interpreting Liquidity Ratios</li>\r\n<li>Calculating and Interpreting Solvency Ratios</li>\r\n<li>Calculating and Interpreting Profitability Ratios</li>\r\n<li>Calculating and Interpreting Valuation Ratios</li>\r\n</ul>\r\n<p><strong>Topic 2: Evaluating a Organization&rsquo;s Performance Using Ratio Analysis&nbsp;</strong></p>\r\n<ul>\r\n<li>Ratios Used in Equity Analysis</li>\r\n<li>Ratios Used in Credit Analysis</li>\r\n<li>Forecasting a Company\'s Performance</li>\r\n<li>Forecasting a Company\'s Net Income and Cash Flows</li>\r\n<li>Ratio Analysis &amp; Assessing the Credit Quality of Debt Investments</li>\r\n<li>Ratio Analysis &amp; Equity Investments</li>\r\n<li>Financial Analysis - Adjustments to the Financial Statements</li>\r\n</ul>\r\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0;
