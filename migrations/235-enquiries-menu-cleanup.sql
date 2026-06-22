-- 235: Remove unused Enquiries submenu link categories (all empty, all under 1/2/172):
--   Workplace Learning (269), Group Training (115), Project Consultancy (275),
--   New Course Collaboration (261), Training Opportunity Colloboration (273),
--   Internship (272), Website Feedback (266).

DELETE FROM catalog_category_entity WHERE entity_id IN (269,115,275,261,273,272,266) AND path LIKE '1/2/172/%';
