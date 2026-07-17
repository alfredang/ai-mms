-- Repurpose course C613 from "IPv4 Network Administrator Training" to
-- "IPv4 Masterclass" (rebrand: name, overview, meta, url_key, image labels,
-- cover). The curriculum (description) and price ($350) are intentionally kept.
-- Cover re-rendered 2026-07-18 with the new title (no funding chips —
-- C613 carries no funding-badge tags) and uploaded to R2.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0, and drops url_path at every scope so the
-- Catalog URL Rewrites indexer regenerates the new URL (old URL 301s).
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C613.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C613');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'IPv4 Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Build a rock-solid command of the protocol that still carries most of the world&rsquo;s traffic in this hands-on IPv4 Masterclass. IPv4 remains the backbone of enterprise networks, data centres and the public internet, and administering it well is a non-negotiable skill for every network professional. Starting from the OSI Model, you will learn how data really moves across a network, then master IP subnetting&mdash;carving address space efficiently and reading subnet masks at a glance&mdash;before digging into the Address Resolution Protocol (ARP) and the full lifecycle of DHCP services configuration.</p>
<p>The masterclass then moves into basic IP routing&mdash;how routers select paths and forward packets so that networks communicate seamlessly. Through hands-on sessions and expert-led demonstrations, you will practise configuring, inspecting and troubleshooting live IPv4 networks rather than just reading about them. By the end of the course, you will be able to design a subnetting plan, stand up DHCP services and diagnose common addressing and routing faults with confidence&mdash;whether you are sharpening existing skills or building your networking foundation from scratch.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'IPv4 Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'IPv4 Masterclass, IPv4 Course, IPv4 Training, Network Administration, OSI Model, IP Subnetting, ARP, DHCP Configuration, IP Routing, TCP/IP, Networking Course, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'ipv4-masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- New cover rendered from the new title, uploaded to R2 2026-07-18
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C613-20260717-174621.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'IPv4 Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'IPv4 Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'IPv4 Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_url, @a_il, @a_sil, @a_til, @a_ciu);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_short, @a_mk);

-- Stale url_path rows point at the old ipv4-network-administrator-training URL;
-- drop them at every scope so the Catalog URL Rewrites indexer regenerates
DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND attribute_id=@a_up AND @a_up IS NOT NULL;
