-- 324: Strip the leading slash from the Custom Course Development mega-menu
--      target so it matches its Enquiries siblings (franchising-application.html,
--      customised-training.html, ...). A leading slash makes the Infortis menu
--      render a double slash (base_url + "/path" => "com.sg//path"); migration
--      322 seeded it with the slash, so normalise it here. Idempotent, partner-safe.

SET @tg := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='umm_cat_target');
UPDATE catalog_category_entity_varchar SET value='course-development-service.html'
  WHERE attribute_id=@tg AND value='/course-development-service.html';
