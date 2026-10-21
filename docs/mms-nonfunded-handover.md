# Receiving non-funded classes from TMS

Project branch: `feat/mms-for-non-funded-courses`, based on `main`. The matching TMS branch uses the same project name.

`POST /courses/api_tms_import` is a dedicated, credential-protected API. It applies complete, revisioned TMS snapshots to the existing MMS account, `course_runs`, and `course_run_enrolments` models. Funded `TGS` codes are rejected before business-data writes, including when a mapped course's current catalogue code has changed.

## Configuration

Apply `migrations/9999-nonfunded-tms-handover.sql` through the real `migrations/apply.php` runner. Its integration tables are idempotent and do not alter existing funded-course records. Configure the following Magento settings through the deployment's existing configuration/secret-provisioning mechanism:

| Config path | Purpose |
| --- | --- |
| `mmd/tms_handover/enabled` | Defaults off. Set to `1` only after deploying/configuring the import API. |
| `mmd/tms_handover/api_key` | Dedicated secret matching TMS `MMS_SYNC_API_KEY`; no default credential. |
| `mmd/tms_handover/provider_id` | Source provider; default `tertiary-sg`. |
| `mmd/tms_handover/calendar_id` | Source calendar; default `sales@tertiarycourses.com.sg`. |
| `mmd/tms_handover/website_id` | Allowed MMS website; default `1`. |
| `mmd/tms_handover/course_allowlist` | Explicit comma-separated pilot codes. Empty means no imports. |
| `mmd/tms_handover/access_verified` | Keep false until actual pilot trainer/learner login and Drive permissions have been tested. An unverified class reports incomplete readiness. |

Both enabled state and credential are required. Provider, calendar, website, pilot allowlist, source identity, current product code, participants, times, revision, and content hash are validated. A `dry_run: true` request previews create/adopt/update without writing accounts/classes/rosters.

## Delivery behavior

- Reuse an exact existing class when uniquely matched; retain its MMS class ID. Otherwise create a class using the current `nextClassId()` helper. Order materialization and import share a product-level lock.
- Match existing accounts by source-person link/email. Add the required learner/trainer role without dropping other roles. Existing passwords survive, including when a trainer becomes a storefront learner.
- Replaying the same revision reconciles the current target and refreshes readiness without creating a new class or resetting passwords. Unresolved independent-membership conflicts remain visible on retries.
- New learner accounts use the existing AccountSync/dashboard login flow. No TMS password or single sign-on is introduced. Administratively blocked accounts are exceptions, not automatically reactivated.
- Reconcile only imported memberships. Native orders and manual registrations set independent-membership provenance so a subsequent TMS withdrawal cannot erase them silently. Withdrawn provenance and prior attendance remain stored.
- Store the actual imported sessions, including non-consecutive dates. Attendance and Calendar rendering use those sessions. Session identities stay stable, and an edit that would relabel existing attendance is rejected for review.
- The imported run's TMS ownership blocks MMS Calendar creation and trainer invitations, including manual invitation paths. Cancellation removes active access and automatic certificate eligibility while preserving history.
- Teacher/learner access checks use the exact run. A different course/run URL does not grant access through a shared product catalogue.
- Populate missing approved courseware URLs. Route feedback to the exact mapped TMS form; suppress the native MMS QR when the mapped form is missing.

The pilot accepts supported `C` course codes and one confirmed trainer per run. Conflicting multi-trainer/session overrides and unsupported non-funded codes remain explicit exceptions until delivery support is extended. A successful database import can be incomplete because resource, trainer, feedback, or access checks still need resolution.

## Local verification

Verified on 21 October 2026: 12 standalone contract checks, 44 isolated database integration checks, five HTTP route/auth/dry-run checks, and a cross-runtime TMS JSON/content-hash check passed. All changed PHP/PHTML files linted cleanly. The real migration runner applied the handover schema and missing structural-seed prerequisites; a second run had no pending migrations. Actual production trainer/learner login, Google Drive permissions and the delivered-class pilot remain unverified rollout gates.

Standalone validation: `php scripts/tests/tms-handover-contract.php`.

The integration fixture uses a disposable MySQL database named exactly `mms_handover_test` on the container `mms-nonfunded-test-mysql`. The test configuration is `scripts/tests/fixtures/tms-handover-local.xml`; it must never replace real application configuration outside the test container. The test scripts reject any other DB identity.

Load the repository's structural `seed/country-base.sql.gz` into that disposable database, mount the test XML as the container's `app/etc/local.xml`, and set `MMS_HANDOVER_ISOLATED_TEST=1`. Run `scripts/tests/prepare-tms-handover-migration.php`, `migrations/apply.php`, and `scripts/tests/tms-handover-integration.php`. The preparation script marks historical migrations already represented by the seed and leaves the new handover migration plus missing schema-only prerequisites to the actual runner. The multi-store structural seed requires `MMS_SKIP_TOPOLOGY_CHECK=1` in the disposable test container only; production keeps its topology guard.

The test network should have no external access. Only the test process disables the external customer-email MX lookup for deterministic `example.com` fixtures; production email validation remains intact. No test sends invitations or changes a real Google Calendar.

Lint all changed PHP/PHTML files in the MMS PHP runtime. Verify the model/helper/controller aliases and affected routes before deployment. The feature is inactive until configured, and production pilot access verification remains an operations rollout step.
