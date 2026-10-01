-- C134: "QuickBooks Online Plus Training (Cloud Version)" -> "QuickBooks Fundamentals", the 1-day
-- non-WSQ twin of TGS-2026064181 (CASL - Quickbooks Accounting System for Small and Medium Enterprises).
--
-- 1. name, url_key/url_path (quickbooks-online-training -> quickbooks-fundamentals), cover
--    alt/gallery labels, meta_title/description/keyword.
-- 2. "What's This Course About" and course topics follow the CASL parent (its 2 About paragraphs,
--    "WSQ Quickbooks Accounting System for Small and Medium Enterprises course" -> "QuickBooks
--    Fundamentals course", and its 4 topics, LSN_DATA JSON + HTML). Written as ASCII literals.
-- 3. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 4. 301s: the product's system rows are renamed in place to the new slug; every old path, bare or
--    category-prefixed, 301s one hop to the new BARE slug; legacy RP rows and search redirects are
--    flattened onto it.
-- Fee ($350), Duration (7.5 hrs), Sessions (1) and the funding block (already -> the CASL twin)
-- are unchanged.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy: flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C134' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064181' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'QuickBooks Fundamentals';
SET @old_slug  := 'quickbooks-online-training';
SET @new_slug  := 'quickbooks-fundamentals';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
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

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, @new_title
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Learn QuickBooks Online fundamentals for SMEs: set up your company, customers and vendors, invoices and bills, GST, and P&L, balance sheet and aging reports at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'QuickBooks Fundamentals, QuickBooks Online, QuickBooks Course, QuickBooks Training, SME Accounting, Invoicing, Bills and Expenses, GST, Financial Reports, Bookkeeping, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Upgrade your financial management capabilities with our QuickBooks Fundamentals course. Designed to meet the unique accounting needs of SMEs, this course offers hands-on training on using Quickbooks for various accounting tasks, including invoicing, expense tracking, and financial reporting. You\'ll acquire the skills to set up and manage accounts, monitor cash flows, and generate accurate financial statements, empowering you to make data-driven decisions for business growth.</p>\n<p>Unleash the full potential of Quickbooks to streamline your SME\'s accounting processes. The course covers key functionalities such as accounts payable and receivable, inventory management, and payroll processing. Whether you\'re a business owner, an accountant, or someone involved in financial management, this course provides you with a comprehensive understanding of Quickbooks, enabling you to optimize financial operations, maintain compliance, and drive business success.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Introduction to Quickbooks Online Plus Accounting System","subsecs":[{"title":"Overview of Quickbooks Online Plus","links":[]},{"title":"Setup Company Profile on Quickbooks","links":[]},{"title":"Import data from QuickBooks Desktop","links":[]},{"title":"Set Up Customers and Vendors","links":[]},{"title":"Set Up to Products and Services","links":[]}]},{"title":"Topic 2: Input Data to Quickbooks","subsecs":[{"title":"Create Expenses and Bills","links":[]},{"title":"Create Recurring Expenses and Bills","links":[]},{"title":"Create Quotation, Invoices and Sales Receipt","links":[]},{"title":"Customize Invoice Template","links":[]},{"title":"Create Payments and Credit Memo to Invoices","links":[]},{"title":"Manage Overdue Invoices","links":[]}]},{"title":"Topic 3: Manage Goods and Services Tax (GST)","subsecs":[{"title":"Singapore Tax and Corporate Laws","links":[]},{"title":"Enter GST for Expenses and Invoices","links":[]}]},{"title":"Topic 4: Financial and Accounting Reports","subsecs":[{"title":"Profit and Loss (P&L) Report","links":[]},{"title":"Balance Sheet Report","links":[]},{"title":"Aging Report","links":[]},{"title":"GST Tax Return Report","links":[]},{"title":"Create Custom Reports","links":[]}]}] -->\n<p><strong>Topic 1: Introduction to Quickbooks Online Plus Accounting System</strong></p>\n<p><em>Overview of Quickbooks Online Plus</em></p>\n<p><em>Setup Company Profile on Quickbooks</em></p>\n<p><em>Import data from QuickBooks Desktop</em></p>\n<p><em>Set Up Customers and Vendors</em></p>\n<p><em>Set Up to Products and Services</em></p>\n<p><strong>Topic 2: Input Data to Quickbooks</strong></p>\n<p><em>Create Expenses and Bills</em></p>\n<p><em>Create Recurring Expenses and Bills</em></p>\n<p><em>Create Quotation, Invoices and Sales Receipt</em></p>\n<p><em>Customize Invoice Template</em></p>\n<p><em>Create Payments and Credit Memo to Invoices</em></p>\n<p><em>Manage Overdue Invoices</em></p>\n<p><strong>Topic 3: Manage Goods and Services Tax (GST)</strong></p>\n<p><em>Singapore Tax and Corporate Laws</em></p>\n<p><em>Enter GST for Expenses and Invoices</em></p>\n<p><strong>Topic 4: Financial and Accounting Reports</strong></p>\n<p><em>Profit and Loss (P&amp;L) Report</em></p>\n<p><em>Balance Sheet Report</em></p>\n<p><em>Aging Report</em></p>\n<p><em>GST Tax Return Report</em></p>\n<p><em>Create Custom Reports</em></p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey, @a_mdesc) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C134-20261001-063003.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c134_old;
CREATE TEMPORARY TABLE tmp_c134_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c134_old
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
  FROM tmp_c134_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c134_old;

-- 5) On-site search terms that sent people to the old slug.
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html');
