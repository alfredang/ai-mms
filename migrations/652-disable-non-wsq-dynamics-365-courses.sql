-- Disable all non-WSQ Microsoft (Certified) Dynamics 365 courses (status = 2):
--   C1753 - MB-230 Dynamics 365 Customer Service Functional Consultant Associate
--   C1754 - MB-240 Dynamics 365 Field Service Functional Consultant Associate
--   C1755 - MB-280 Dynamics 365 Customer Experience Analyst Associate
--   C1757 - MB-330 Dynamics 365 Supply Chain Management Functional Consultant Associate
--   C1758 - MB-335 Dynamics 365 Supply Chain Management Functional Consultant Expert
--   C1761 - MB-800 Dynamics 365 Business Central Functional Consultant Associate
--   C1764 - MB-920 Microsoft Dynamics 365 Fundamentals (ERP)
--
-- Requested 2026-07-22. C665 (MB-910 CRM) is already disabled; the WSQ course
-- TGS-2023040481 stays enabled. Same pattern as 649: set the default-scope
-- (store_id 0) status to Disabled and flip any per-store override rows too.
-- Idempotent; catalog reindex + cache flush after deploy makes it visible.

SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');

-- Default scope: ensure a store_id 0 row exists and is Disabled.
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2
FROM catalog_product_entity e
WHERE e.sku IN ('C1753','C1754','C1755','C1757','C1758','C1761','C1764')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Flip any per-store override rows to Disabled as well.
UPDATE catalog_product_entity_int i
JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2
WHERE i.attribute_id = @status_attr
  AND e.sku IN ('C1753','C1754','C1755','C1757','C1758','C1761','C1764');

-- Clear search-term redirects pointing at the now-disabled course pages so
-- those terms fall back to normal search results instead of 302-ing to a 404.
-- URL match is domain-agnostic so the same statement is correct on SG/MY/GH.
UPDATE catalogsearch_query
SET redirect = ''
WHERE redirect LIKE '%/mb-230-microsoft-certified-dynamics-365-customer-service-functional-consultant-associate.html%'
   OR redirect LIKE '%/mb-240-microsoft-certified-dynamics-365-field-service-functional-consultant-associate.html%'
   OR redirect LIKE '%/mb-280-microsoft-certified-dynamics-365-customer-experience-analyst-associate.html%'
   OR redirect LIKE '%/mb-330-microsoft-certified-dynamics-365-supply-chain-management-functional-consultant-associate.html%'
   OR redirect LIKE '%/mb-335-microsoft-certified-dynamics-365-supply-chain-management-functional-consultant-expert.html%'
   OR redirect LIKE '%/mb-800-microsoft-certified-dynamics-365-business-central-functional-consultant-associate.html%'
   OR redirect LIKE '%/mb-920-microsoft-dynamics-365-fundamentals-erp.html%';

-- NOTE: redirects to mb-310/mb-500/mb-700/mb-820 URLs are left untouched —
-- those slugs 301 to the live repurposed Microsoft AI certification courses.
