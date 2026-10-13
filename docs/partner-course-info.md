# Malaysia and Ghana Course Info

The 13 October 2026 update covers all 216 enabled Malaysia courses and all
328 enabled Ghana courses, including 79 Ghana courses whose existing visibility
is hidden. Visibility and the active catalogue are not changed.

Every course has separate **Prerequisite**, **Software Requirement**, and
**Hardware Requirement** sections. Every Malaysia course also has **How to Apply
for HRD Corp Funding**, with its course title/code, employer application steps,
supporting documents, approval lead times and claim guidance. Ghana carries no
HRD Corp section. Singapore-specific qualification/funding boilerplate and
software placeholders are removed from the updated Course Info.

Software uses Singapore's live course export when both SKU and course title
match. Other preparation guidance follows the local course topic. A matching
SKU alone is insufficient: several Ghana titles represent different courses.
Partner training-account availability and paid licences must be confirmed with
the trainer rather than inherited as a promise from the Singapore record.

HRD Corp application guidance was checked against its [official Claimable
Courses page](https://hrdcorp.gov.my/hrdcorp-claimable-courses) on 13 October 2026.
Public training currently starts at least three days after approval through
31 December 2026, reverting to 14 days from 1 January 2027. In-house training
requires 14 days. The guidance directs employers to confirm the programme,
eligibility, levy availability and current official rules before applying.

## Reviewed manifests

- [Malaysia: 216 courses](../scripts/maintenance/course-info/20261013-MY.json)
- [Ghana: 328 courses](../scripts/maintenance/course-info/20261013-GH.json)

These are immutable, reviewed release inputs, not an automatic sync job.
Each row includes the course identity, prior effective Course Info SHA-256,
replacement HTML and content-reference classification. No credentials or
private learner/trainer records are included.

## Applying an update

Back up the target country's database first. Run the CLI inside that country's
web container; dry-run is the default:

```bash
php scripts/maintenance/update-partner-course-info.php \
  --manifest=scripts/maintenance/course-info/20261013-MY.json
```

Review the complete manifest and dry-run result, then use `--apply`. Use the GH
manifest on Ghana. The script checks country mode, country/store identity,
the entire enabled SKU set, course titles, required headings and previous
content hashes. It refuses other countries and HTTP execution. Changes are
transactional and rerunning an applied manifest reports zero changes.

Only `catalog_product_entity_text.prerequisite` in the target store scope is
written. Default-store values, inactive courses, prices, schedules, visibility,
courseware, timestamps and Singapore are not written. The utility is not called
by deployment, cron or storefront requests; pushing these files does not apply
the manifests.

After applying, reindex `catalog_product_flat` and `catalog_category_flat` as
the web-server user and flush the country Magento cache. Verify every enabled
record against its manifest, compare all other product attributes and protected
tables against the snapshot, and check the public course pages. Hidden courses
are verified through their records without changing their visibility.

## Preservation checks

The release compared every product EAV value and timestamp, the website/URL
assignments, courseware links, product options (including dates and prices),
class runs and configuration. Only the reviewed country-store Course Info
values changed. Singapore's live export was compared before and after the
country updates: all 497 records were unchanged. All 465 public course pages
(216 Malaysia and 249 Ghana) returned HTTP 200 and matched the reviewed Course
Info HTML after text normalization, with no PHP fatal markers. The remaining
79 hidden Ghana courses passed record-level verification.
