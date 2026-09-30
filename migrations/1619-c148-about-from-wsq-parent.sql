-- C148: "What's This Course About" copied from the WSQ parent TGS-2023018988.
-- Follow-up to 1616, whose parent-join copy of short_description did not land on prod
-- (the live page still showed C148's old 1-day About). Writes the parent's About as an
-- ASCII/entity literal instead of a join, and drops any store-scope override of
-- short_description on C148 so store 0 is what renders. Guarded on the TGS- parent,
-- so partner sites are no-ops. Idempotent.

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, a.attribute_id, 0, c.entity_id, '<p>Elevate your SME\'s productivity with our comprehensive Google Workspace course. Gain skills to implement policies and manage content on Google Drive, ensuring your organization&rsquo;s data is well-organized and accessible. Learn to create and curate documents, spreadsheets, and presentations using Google Docs, Sheets, and Slides. Additionally, maintain and utilize tools such as Google Forms, Jamboard, Gmail, Calendar, and Meet to streamline your business operations.</p>\r\n<p>The course also covers advanced features like generating reports on key performance metrics and integrating useful Google Workspace add-ons to enhance your customer experience. By mastering these tools, you will be well-equipped to drive efficiency and collaboration within your SME, ultimately leading to improved business outcomes.</p>'
  FROM catalog_product_entity c
  JOIN eav_attribute a ON a.attribute_code = 'short_description' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2023018988'
 WHERE TRIM(c.sku) = 'C148'
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE t FROM catalog_product_entity_text t
  JOIN catalog_product_entity c ON c.entity_id = t.entity_id AND TRIM(c.sku) = 'C148'
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.attribute_code = 'short_description' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2023018988'
 WHERE t.store_id <> 0;
