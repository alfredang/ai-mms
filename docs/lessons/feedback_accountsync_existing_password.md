# Preserve the existing dashboard hash when adding a learner role

Type: feedback

Rule: When provisioning a storefront customer for an existing trainer/operator, copy the existing `admin_user.password` into the new customer's password hash. Do not generate a fresh customer password for that person.

Why: `MMD_AccountSync` observes customer saves and copies the customer's password hash back to the unified dashboard account. During the non-funded TMS handover implementation, adding an existing trainer as a learner would otherwise silently replace their dashboard password. The importer must preserve the account, existing roles and password without sending onboarding messages.

How to apply: In `app/code/local/MMD/Courses/Model/TmsImport.php::account()`, set `setPasswordHash($user['password'])` before the first customer save when a dashboard account already exists. Use a random password only for a genuinely new identity. Run `scripts/tests/tms-handover-integration.php` in its isolated fixture: it tests the trainer-to-learner transition, same-revision retries and stable-account email changes.

Related test-process lesson: Magento caches configuration on the store object as well as the global config. In same-process fixtures, `Mage::getConfig()->reinit()` alone does not invalidate values already read from `Mage::getStoreConfigFlag()`. Set the fixture store value explicitly or reset that store's config cache. Production requests still use the normal configuration lifecycle.
