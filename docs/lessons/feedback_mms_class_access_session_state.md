# Recheck account state for imported MMS class access

Type: feedback

Rule: Authorize an imported class against the current account, current learner/trainer role and exact-run membership. A cached logged-in user object is insufficient after an account is blocked, its role is removed or its email changes.

Why: Class-entry links must remain safe when forwarded or reopened from an existing browser session. The account's `is_active` and email in the session can predate an operations change. A successful account import or OTP response does not establish current class access.

How to apply: `app/code/local/MMD/RoleManager/Helper/Handover.php::canAccessRun()` reads current `admin_user` state and participant roles before checking the mapped run. `ClassAccess.php` remembers only a numeric run ID through password/OTP/role selection, then applies the same guard. Its configured public origin must match dashboard URLs so login cookies stay on one site. The isolated `scripts/tests/tms-class-access-integration.php` captures actual OTP mail in Mailpit, follows the real role-selection form/CSRF token and verifies blocked/withdrawn access with the same browser session.
