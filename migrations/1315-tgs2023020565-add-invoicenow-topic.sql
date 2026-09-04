-- 1315: TGS-2023020565 "WSQ - Advanced Transactional Accounting with Xero"
--       Add an InvoiceNow e-invoicing topic to the course outline.
--
-- Why: Singapore's GST InvoiceNow requirement is now live for new voluntary GST
-- registrants (since 1 Apr 2026) and rolls out to every GST-registered business
-- between 1 Apr 2028 and 1 Apr 2031. A Xero course aimed at accountants and
-- bookkeepers that says nothing about connecting Xero to the Peppol network is
-- missing the thing those learners are being compelled to do. Pairs with the blog
-- post in migration 1314, whose CTA promises this coverage.
--
-- Shape: the new material is added as its OWN topic (Topic 3), pushing the existing
-- "Accounting Standards" block down to Topic 4. Deliberately additive -- the three
-- existing topic blocks keep their exact titles, sub-bullets and wording, so the
-- approved WSQ learning units are untouched and only new content is introduced.
--
-- The "What You'll Learn" card renders the product `description` VERBATIM
-- (view/description.phtml -> productAttribute($p, $_description, 'description')), so
-- this is a pure data change -- no template edit. The LSN_DATA JSON comment at the
-- head of the value is regenerated in step with the visible markup so the two do not
-- drift (nothing currently reads it, but a stale copy describing a different topic
-- list would rot).
--
-- NOTE for the course owner: this updates the STOREFRONT outline only. The SSG/TGS
-- course record for TGS-2023020565 is a separate system -- if the approved syllabus
-- must also reflect the new topic, that is a separate submission to SSG.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => the statements
-- below are guarded no-ops there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023020565' LIMIT 1);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, 72, 0, @e,
'<!-- LSN_DATA: [{"title":"Topic 1: Prepare Accounting Treatments","subsecs":[{"title":"What is double entry accounting? ","links":[]},{"title":"Setting Up company & chart of accounts ","links":[]},{"title":"Setting up bank account ","links":[]},{"title":"Contact management ","links":[]},{"title":"Inventory management ","links":[]}]},{"title":"Topic 2: Produce Financial Statements","subsecs":[{"title":"Managing sales transactions ","links":[]},{"title":"Managing purchase transactions","links":[]},{"title":"Bank reconciliation","links":[]},{"title":"Financial reporting and tracking","links":[]},{"title":" Budget manager","links":[]}]},{"title":"Topic 3: InvoiceNow E-Invoicing","subsecs":[{"title":"Overview of InvoiceNow and the Peppol network","links":[]},{"title":"GST InvoiceNow requirement and compliance timeline","links":[]},{"title":"Setting up InvoiceNow in Xero and obtaining a Peppol ID","links":[]},{"title":"Sending and receiving e-invoices","links":[]}]},{"title":"Topic 4: Accounting Standards","subsecs":[{"title":"Overview of accounting principles and GAAP","links":[]},{"title":"The accrual principle ","links":[]},{"title":"Impact of financial standards on financial statements ","links":[]}]}] -->
<p><strong>Topic 1: Prepare Accounting Treatments</strong></p>
<p><em>What is double entry accounting? </em></p>
<p><em>Setting Up company &amp; chart of accounts </em></p>
<p><em>Setting up bank account </em></p>
<p><em>Contact management </em></p>
<p><em>Inventory management </em></p>
<p><strong>Topic 2: Produce Financial Statements</strong></p>
<p><em>Managing sales transactions </em></p>
<p><em>Managing purchase transactions</em></p>
<p><em>Bank reconciliation</em></p>
<p><em>Financial reporting and tracking</em></p>
<p><em> Budget manager</em></p>
<p><strong>Topic 3: InvoiceNow E-Invoicing</strong></p>
<p><em>Overview of InvoiceNow and the Peppol network</em></p>
<p><em>GST InvoiceNow requirement and compliance timeline</em></p>
<p><em>Setting up InvoiceNow in Xero and obtaining a Peppol ID</em></p>
<p><em>Sending and receiving e-invoices</em></p>
<p><strong>Topic 4: Accounting Standards</strong></p>
<p><em>Overview of accounting principles and GAAP</em></p>
<p><em>The accrual principle </em></p>
<p><em>Impact of financial standards on financial statements </em></p>'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Drop any store-scoped override so the store 0 value is what renders.
DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND attribute_id = 72 AND store_id <> 0 AND @e IS NOT NULL;
