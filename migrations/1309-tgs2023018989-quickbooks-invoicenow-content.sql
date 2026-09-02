-- 1309: TGS-2023018989 "WSQ - Advanced Transactional Accounting with Quickbooks
--       Online" -- add InvoiceNow (Peppol e-invoicing) coverage to the two
--       storefront content blocks the admin asked for.
--
-- Driver: Intuit shipped native InvoiceNow e-invoicing inside QuickBooks Online
-- for Singapore (announcement 27 Aug 2026) -- send/receive Peppol e-invoices and
-- report them to IRAS from within QBO. IRAS' InvoiceNow requirement phases in for
-- GST-registered businesses, so an ADVANCED transactional accounting course now
-- has to cover the setup. This is the content update for that.
--
-- Two attributes, both rendered verbatim on the product page:
--   * short_description (attr 73) -> the "About the Course" copy in the primary
--     column (view.phtml renders short_description; description does NOT appear
--     there).
--   * description (attr 72) -> the "What You'll Learn" card
--     (view/description.phtml line 65 + productAttribute(..., 'description')).
--     That card is the ONLY place `description` renders.
--
-- Unlike 999 / 997 / 967 / 960 (which trimmed newer courses to headings-only),
-- this course is one of the older ones that still lists <p><em> sub-bullets
-- under each <p><strong>Topic N</strong></p> heading. The request is to ADD a
-- sub topic, so the existing shape is preserved verbatim and the InvoiceNow
-- items are inserted into it:
--   * Topic 1 gains four setup/operation bullets (enable e-invoicing, Peppol ID
--     registration + consent, send compliant e-invoices, receive supplier
--     invoices as bills).
--   * Topic 2 gains two reporting bullets (the e-invoicing activity report and
--     IRAS transmission/reconciliation), which is where reporting belongs.
-- No topic is added or removed -- still Topics 1-3, so the 3-topic lesson-plan
-- and assessment mapping is untouched.
--
-- The leading LSN_DATA JSON comment is a mirror of the visible markup. Nothing
-- in the codebase reads it (grep of app/design/frontend + app/code/local/MMD
-- finds no consumer -- same finding as 999), but on a course that KEEPS its
-- sub-bullets a stale mirror would misdescribe the card, so it is rewritten in
-- lockstep rather than dropped.
--
-- ASCII-only on both values -- no smart quotes, no NBSP. apply.php connects
-- utf8 and aborts the whole chain on error 1366
-- ([[feedback_migration_applyphp_utf8_outage]]).
--
-- Partner-safe: TGS- SKUs exist only on SG, so @e IS NULL on MY/GH and every
-- statement below is a guarded no-op there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023018989' LIMIT 1);

-- ---------------------------------------------------------------- About the Course
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, 73, 0, @e,
'<p>Boost your accounting proficiency with our WSQ Advanced Transactional Accounting with Quickbooks Online course. Aimed at professionals and business owners, this course provides in-depth coverage of advanced accounting topics like account reconciliation, detailed financial reporting, and efficient bookkeeping. You will gain hands-on experience using Quickbooks Online to manage complex transactions, generate financial statements, and maintain accurate records, setting you on the path to become an accounting expert.</p>
<p>Expand your accounting toolkit with the latest techniques and best practices in transactional accounting. The course explores vital topics including accounts payable and receivable, inventory tracking, and tax planning using Quickbooks Online. Whether you are an accountant, financial analyst, or business owner, this course equips you with the skills to optimize financial operations, enhance data accuracy, and improve financial decision-making, thereby contributing to business success.</p>
<p>The course also covers InvoiceNow, Singapore''s nationwide e-invoicing network built on Peppol, which is now available natively inside Quickbooks Online. You will learn how to enable e-invoicing from Quickbooks settings, complete the consent and Peppol registration process, issue InvoiceNow-compliant e-invoices that transmit straight to your customer''s accounting system and are reported to IRAS, and receive supplier e-invoices directly into Quickbooks as bills for review and approval. This prepares you to meet Singapore''s e-invoicing requirements while cutting manual data entry and shortening your collection cycle.</p>'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND attribute_id = 73 AND store_id <> 0 AND @e IS NOT NULL;

-- ------------------------------------------------------------- What You'll Learn
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, 72, 0, @e,
'<!-- LSN_DATA: [{"title":"Topic 1: Transactional Accounting","subsecs":[{"title":"What is double entry accounting?","links":[]},{"title":"Work with the charts of accounts","links":[]},{"title":"Create bank accounts and credit cards","links":[]},{"title":"Setup sales tax","links":[]},{"title":"Create inventory and non-inventory products","links":[]},{"title":"Setup customers, suppliers, employees","links":[]},{"title":"Create projects","links":[]},{"title":"Day to day operations","links":[]},{"title":"Enter timesheets","links":[]},{"title":"View reminders for overdue invoices","links":[]},{"title":"Send statements to customers","links":[]},{"title":"Record Depreciation and Inventory Adjustment","links":[]},{"title":"Setup bank rules","links":[]},{"title":"Reconcile bank accounts","links":[]},{"title":"Setup InvoiceNow e-invoicing in Quickbooks Online","links":[]},{"title":"Complete Peppol registration and the e-invoicing consent process","links":[]},{"title":"Send InvoiceNow compliant e-invoices to customers","links":[]},{"title":"Receive supplier e-invoices into Quickbooks as bills","links":[]},{"title":"Handle special cases","links":[]},{"title":"Issue refunds","links":[]},{"title":"Handle customer credits","links":[]},{"title":"Automate recurring transactions","links":[]}]},{"title":"Topic 2: Financial Reporting","subsecs":[{"title":"Review financial info in the dashboard","links":[]},{"title":"Use tags to categorise your finances","links":[]},{"title":"Run financial reports","links":[]},{"title":"Pay sale tax","links":[]},{"title":"Record deprecation","links":[]},{"title":"Track e-invoicing activity with the InvoiceNow report","links":[]},{"title":"Reconcile IRAS reported e-invoices against your accounts","links":[]},{"title":"Analyze management reports","links":[]},{"title":"Customize and memorize reports","links":[]}]},{"title":"Topic 3: Accounting Principles and Standards","subsecs":[{"title":"Overview of accounting principles and GAAP","links":[]},{"title":"The accrual principle","links":[]},{"title":"Impact of financial standards on financial statements","links":[]}]}] -->
<p><strong>Topic 1: Transactional Accounting</strong></p>
<p><em>What is double entry accounting?</em></p>
<p><em>Work with the charts of accounts</em></p>
<p><em>Create bank accounts and credit cards</em></p>
<p><em>Setup sales tax</em></p>
<p><em>Create inventory and non-inventory products</em></p>
<p><em>Setup customers, suppliers, employees</em></p>
<p><em>Create projects</em></p>
<p><em>Day to day operations</em></p>
<p><em>Enter timesheets</em></p>
<p><em>View reminders for overdue invoices</em></p>
<p><em>Send statements to customers</em></p>
<p><em>Record Depreciation and Inventory Adjustment</em></p>
<p><em>Setup bank rules</em></p>
<p><em>Reconcile bank accounts</em></p>
<p><em>Setup InvoiceNow e-invoicing in Quickbooks Online</em></p>
<p><em>Complete Peppol registration and the e-invoicing consent process</em></p>
<p><em>Send InvoiceNow compliant e-invoices to customers</em></p>
<p><em>Receive supplier e-invoices into Quickbooks as bills</em></p>
<p><em>Handle special cases</em></p>
<p><em>Issue refunds</em></p>
<p><em>Handle customer credits</em></p>
<p><em>Automate recurring transactions</em></p>
<p><strong>Topic 2: Financial Reporting</strong></p>
<p><em>Review financial info in the dashboard</em></p>
<p><em>Use tags to categorise your finances</em></p>
<p><em>Run financial reports</em></p>
<p><em>Pay sale tax</em></p>
<p><em>Record deprecation</em></p>
<p><em>Track e-invoicing activity with the InvoiceNow report</em></p>
<p><em>Reconcile IRAS reported e-invoices against your accounts</em></p>
<p><em>Analyze management reports</em></p>
<p><em>Customize and memorize reports</em></p>
<p><strong>Topic 3: Accounting Principles and Standards</strong></p>
<p><em>Overview of accounting principles and GAAP</em></p>
<p><em>The accrual principle</em></p>
<p><em>Impact of financial standards on financial statements</em></p>'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND attribute_id = 72 AND store_id <> 0 AND @e IS NOT NULL;
