-- C699: "Advanced QuickBooks Online Plus Training" -> "QuickBooks Accounting Masterclass", the
-- 2-day non-WSQ twin of TGS-2023018989 (WSQ - Advanced Transactional Accounting with Quickbooks Online).
--
-- 1. name, url_key/url_path (advanced-quickbooks-online-plus-training -> quickbooks-accounting-masterclass),
--    cover alt/gallery labels, meta_title/description/keyword.
-- 2. Fee $350 -> $700; Duration tile 7.5 -> 15 hrs; Sessions tile 1 -> 2.
-- 3. "What's This Course About" and course topics follow the WSQ parent (its 3 About paragraphs,
--    "WSQ Advanced Transactional Accounting with Quickbooks Online course" -> "QuickBooks Accounting
--    Masterclass", and its 3 topics, LSN_DATA JSON + HTML). Written as ASCII literals, not a parent join.
-- 4. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 5. Funding block: "No funding" now points at the WSQ twin.
-- 6. 301s: the product's system rows are renamed in place to the new slug; every old path, bare or
--    category-prefixed, 301s one hop to the new BARE slug; legacy RP rows and search redirects are
--    flattened onto it.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): refreshProductRewrite, schedule template -> B05 via the code path,
-- then flat/price reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C699' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023018989' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'QuickBooks Accounting Masterclass';
SET @old_slug  := 'advanced-quickbooks-online-plus-training';
SET @new_slug  := 'quickbooks-accounting-masterclass';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_cover   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_price   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'price');
SET @a_dur     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @a_sess    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'sessions');

-- ------------------------------------------------------- name / slug -----
UPDATE catalog_product_entity_varchar SET value = @new_title
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_name;

UPDATE catalog_product_entity_varchar SET value = @new_slug
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlkey;

UPDATE catalog_product_entity_varchar SET value = CONCAT(@new_slug, '.html')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlpath;

-- ------------------------------------------- fee / duration / sessions -----
UPDATE catalog_product_entity_decimal SET value = 700
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price;

UPDATE catalog_product_entity_varchar SET value = '15'
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_dur;

UPDATE catalog_product_entity_varchar SET value = '2'
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_sess;

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

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, @new_title
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Master QuickBooks Online accounting in this hands-on masterclass: double-entry transactions, bank reconciliation, InvoiceNow e-invoicing, financial reports and accounting standards at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'QuickBooks Accounting Masterclass, QuickBooks Online, QuickBooks Course, QuickBooks Training, Transactional Accounting, Double Entry Accounting, Bank Reconciliation, InvoiceNow, E-Invoicing, Financial Reporting, Bookkeeping, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Boost your accounting proficiency with our QuickBooks Accounting Masterclass. Aimed at professionals and business owners, this course provides in-depth coverage of advanced accounting topics like account reconciliation, detailed financial reporting, and efficient bookkeeping. You will gain hands-on experience using Quickbooks Online to manage complex transactions, generate financial statements, and maintain accurate records, setting you on the path to become an accounting expert.</p>\n<p>Expand your accounting toolkit with the latest techniques and best practices in transactional accounting. The course explores vital topics including accounts payable and receivable, inventory tracking, and tax planning using Quickbooks Online. Whether you are an accountant, financial analyst, or business owner, this course equips you with the skills to optimize financial operations, enhance data accuracy, and improve financial decision-making, thereby contributing to business success.</p>\n<p>The course also covers InvoiceNow, Singapore\'s nationwide e-invoicing network built on Peppol, which is now available natively inside Quickbooks Online. You will learn how to enable e-invoicing from Quickbooks settings, complete the consent and Peppol registration process, issue InvoiceNow-compliant e-invoices that transmit straight to your customer\'s accounting system and are reported to IRAS, and receive supplier e-invoices directly into Quickbooks as bills for review and approval. This prepares you to meet Singapore\'s e-invoicing requirements while cutting manual data entry and shortening your collection cycle.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Transactional Accounting","subsecs":[{"title":"What is double entry accounting?","links":[]},{"title":"Work with the charts of accounts","links":[]},{"title":"Create bank accounts and credit cards","links":[]},{"title":"Setup sales tax","links":[]},{"title":"Create inventory and non-inventory products","links":[]},{"title":"Setup customers, suppliers, employees","links":[]},{"title":"Create projects","links":[]},{"title":"Day to day operations","links":[]},{"title":"Enter timesheets","links":[]},{"title":"View reminders for overdue invoices","links":[]},{"title":"Send statements to customers","links":[]},{"title":"Record Depreciation and Inventory Adjustment","links":[]},{"title":"Setup bank rules","links":[]},{"title":"Reconcile bank accounts","links":[]},{"title":"Setup InvoiceNow e-invoicing in Quickbooks Online","links":[]},{"title":"Complete Peppol registration and the e-invoicing consent process","links":[]},{"title":"Send InvoiceNow compliant e-invoices to customers","links":[]},{"title":"Receive supplier e-invoices into Quickbooks as bills","links":[]},{"title":"Handle special cases","links":[]},{"title":"Issue refunds","links":[]},{"title":"Handle customer credits","links":[]},{"title":"Automate recurring transactions","links":[]}]},{"title":"Topic 2: Financial Reporting","subsecs":[{"title":"Review financial info in the dashboard","links":[]},{"title":"Use tags to categorise your finances","links":[]},{"title":"Run financial reports","links":[]},{"title":"Pay sale tax","links":[]},{"title":"Record deprecation","links":[]},{"title":"Track e-invoicing activity with the InvoiceNow report","links":[]},{"title":"Reconcile IRAS reported e-invoices against your accounts","links":[]},{"title":"Analyze management reports","links":[]},{"title":"Customize and memorize reports","links":[]}]},{"title":"Topic 3: Accounting Principles and Standards","subsecs":[{"title":"Overview of accounting principles and GAAP","links":[]},{"title":"The accrual principle","links":[]},{"title":"Impact of financial standards on financial statements","links":[]}]}] -->\n<p><strong>Topic 1: Transactional Accounting</strong></p>\n<p><em>What is double entry accounting?</em></p>\n<p><em>Work with the charts of accounts</em></p>\n<p><em>Create bank accounts and credit cards</em></p>\n<p><em>Setup sales tax</em></p>\n<p><em>Create inventory and non-inventory products</em></p>\n<p><em>Setup customers, suppliers, employees</em></p>\n<p><em>Create projects</em></p>\n<p><em>Day to day operations</em></p>\n<p><em>Enter timesheets</em></p>\n<p><em>View reminders for overdue invoices</em></p>\n<p><em>Send statements to customers</em></p>\n<p><em>Record Depreciation and Inventory Adjustment</em></p>\n<p><em>Setup bank rules</em></p>\n<p><em>Reconcile bank accounts</em></p>\n<p><em>Setup InvoiceNow e-invoicing in Quickbooks Online</em></p>\n<p><em>Complete Peppol registration and the e-invoicing consent process</em></p>\n<p><em>Send InvoiceNow compliant e-invoices to customers</em></p>\n<p><em>Receive supplier e-invoices into Quickbooks as bills</em></p>\n<p><em>Handle special cases</em></p>\n<p><em>Issue refunds</em></p>\n<p><em>Handle customer credits</em></p>\n<p><em>Automate recurring transactions</em></p>\n<p><strong>Topic 2: Financial Reporting</strong></p>\n<p><em>Review financial info in the dashboard</em></p>\n<p><em>Use tags to categorise your finances</em></p>\n<p><em>Run financial reports</em></p>\n<p><em>Pay sale tax</em></p>\n<p><em>Record deprecation</em></p>\n<p><em>Track e-invoicing activity with the InvoiceNow report</em></p>\n<p><em>Reconcile IRAS reported e-invoices against your accounts</em></p>\n<p><em>Analyze management reports</em></p>\n<p><em>Customize and memorize reports</em></p>\n<p><strong>Topic 3: Accounting Principles and Standards</strong></p>\n<p><em>Overview of accounting principles and GAAP</em></p>\n<p><em>The accrual principle</em></p>\n<p><em>Impact of financial standards on financial statements</em></p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey, @a_mdesc) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover, @a_dur, @a_sess) AND store_id <> 0;

DELETE FROM catalog_product_entity_decimal
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C699-20261001-062055.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C699 - Funding and Grant', 'course_C699_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C699_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C699_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C699_funding_and_grant');

UPDATE cms_block
   SET content = '<p>No funding is available for this course.</p> <p>For WSQ funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-advanced-transactional-accounting-with-quickbooks-online.html" title="WSQ - Advanced Transactional Accounting with Quickbooks Online">WSQ - Advanced Transactional Accounting with Quickbooks Online</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C699_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c699_old;
CREATE TEMPORARY TABLE tmp_c699_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c699_old
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
  FROM tmp_c699_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c699_old;

-- 5) On-site search terms that sent people to the old slug.
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html');
