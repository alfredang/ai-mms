-- Repurpose two ecommerce courses (1 day / 2 topics each, NO badge):
--   C441  Ecommerce with Shopify   (was Setup Shopify Online Shop Training)
--   C015  Ecommerce with WordPress (was Setup WordPress eCommerce Store Using WooCommerce)
-- Per-market price (350/1100/1500) direct on prod. Store scope 0. Idempotent.
-- No content line ends in a semicolon.

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

-- ===== C441 - Ecommerce with Shopify =====
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C441');
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Ecommerce with Shopify') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Launch your online store with Ecommerce with Shopify. This hands-on 1-day course teaches you how to set up, customise and run a professional online shop using Shopify. You will learn to add products, configure payments and shipping, customise your storefront, and start selling online.</p>
<p>Through practical exercises, participants will create a Shopify store, add and organise products, set up payments, shipping and taxes, customise the theme, and launch their shop. By the end of the course, you will be able to build and manage your own Shopify ecommerce store.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Setting Up Your Shopify Store</h3>
<ul>
<li>Introduction to Shopify and Ecommerce</li>
<li>Creating and Configuring Your Store</li>
<li>Adding and Organising Products</li>
<li>Setting Up Payments, Shipping and Taxes</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Customising and Launching Your Store</h3>
<ul>
<li>Customising Your Theme and Storefront</li>
<li>Managing Orders and Customers</li>
<li>Marketing and Apps</li>
<li>Launching and Growing Your Store</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Ecommerce with Shopify | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Build an online store with Shopify. Add products, set up payments and shipping, customise your storefront and launch in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Ecommerce, Shopify, Online Store, Payments, Dropshipping, Storefront, Retail')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '7.5') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C441-20260711-103144.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ecommerce-with-shopify') ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ===== C015 - Ecommerce with WordPress =====
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C015');
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Ecommerce with WordPress') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Build an online store on WordPress with Ecommerce with WordPress. This hands-on 1-day course teaches you how to create and run an ecommerce store using WordPress and WooCommerce. You will learn to set up WooCommerce, add products, configure payments and shipping, customise your shop, and start selling online.</p>
<p>Through practical exercises, participants will install and configure WooCommerce, add and manage products, set up payments, shipping and taxes, customise the store design, and launch their shop. By the end of the course, you will be able to build and manage your own WordPress WooCommerce store.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Setting Up WooCommerce on WordPress</h3>
<ul>
<li>Introduction to WordPress, WooCommerce and Ecommerce</li>
<li>Installing and Configuring WooCommerce</li>
<li>Adding and Organising Products</li>
<li>Setting Up Payments, Shipping and Taxes</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Customising and Launching Your Store</h3>
<ul>
<li>Customising Your Store Design</li>
<li>Managing Orders and Customers</li>
<li>Plugins and Marketing</li>
<li>Launching and Growing Your Store</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Ecommerce with WordPress | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Build an online store with WordPress and WooCommerce. Add products, set up payments and shipping, customise your shop and launch in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Ecommerce, WordPress, WooCommerce, Online Store, Payments, Storefront, Retail')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '7.5') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C015-20260711-103144.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ecommerce-with-wordpress') ON DUPLICATE KEY UPDATE value = VALUES(value);
