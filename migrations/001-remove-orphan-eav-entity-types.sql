-- Remove EAV entity types with empty entity_model that were left over from
-- uninstalled modules (aitoc_checkout, mmd_checkout). In developer mode these
-- cause "Failed loading of eav entity type" exceptions that silently break
-- the homepage product sliders.

DELETE FROM eav_entity_type WHERE entity_type_code IN ('aitoc_checkout', 'mmd_checkout');
