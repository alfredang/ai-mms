-- Remove admin_rule rows that reference ACL resources from modules that were
-- uninstalled (Braintree, old API, sendfriend, recurring profile, billing
-- agreement, cms/poll, etc.). These resources are no longer registered, so
-- the admin dashboard was showing a "The following role resources are no
-- longer available..." warning on every page load.

DELETE FROM admin_rule WHERE
    resource_id LIKE '%braintree%'
 OR resource_id LIKE '%sendfriend%'
 OR resource_id LIKE '%api/consumer%'
 OR resource_id LIKE '%api/authorizedTokens%'
 OR resource_id LIKE '%recurring_profile%'
 OR resource_id LIKE '%billing_agreement%'
 OR resource_id LIKE '%checkoutagreement%'
 OR resource_id LIKE '%cms/poll%'
 OR resource_id LIKE '%sales/shipment%'
 OR resource_id LIKE '%sales/creditmemo%';
