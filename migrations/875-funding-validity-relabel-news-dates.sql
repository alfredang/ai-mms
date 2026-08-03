-- 875: Repurpose Magento's "Set Product as New" dates (news_from_date /
-- news_to_date, previously relabelled "Registration Start/End Date") as the
-- WSQ Funding Validity window. Labels become "Funding Validity Start Date" /
-- "Funding Validity End Date" — the values are populated per TGS- SKU from
-- the TPG master list by migration 876 and rendered as the storefront
-- "Funding Validity" card.
-- Safe on partner instances (MY/GH): pure relabel; partner sites carry no
-- TGS- SKUs and the admin editor only shows these fields for TGS- courses.

UPDATE eav_attribute SET frontend_label = 'Funding Validity Start Date'
WHERE attribute_code = 'news_from_date' AND entity_type_id = 4;

UPDATE eav_attribute SET frontend_label = 'Funding Validity End Date'
WHERE attribute_code = 'news_to_date' AND entity_type_id = 4;

-- Per-store label overrides (SG store row exists with the old label).
UPDATE eav_attribute_label l
JOIN eav_attribute a ON a.attribute_id = l.attribute_id
SET l.value = 'Funding Validity Start Date'
WHERE a.attribute_code = 'news_from_date' AND a.entity_type_id = 4;

UPDATE eav_attribute_label l
JOIN eav_attribute a ON a.attribute_id = l.attribute_id
SET l.value = 'Funding Validity End Date'
WHERE a.attribute_code = 'news_to_date' AND a.entity_type_id = 4;
