# LMS Feedback Review API

Creates a product review from an LMS course-feedback submission, with
**moderation by score**. Learners scan the QR code on the in-house feedback
form; on submit, the LMS posts the result here and it appears (or waits) on
the course page at www.tertiarycourses.com.sg.

Implementation: `lms_feedback_review_api.php` at the site root.

> **This does not replace [`kael_review_api.php`](kael-review-api.md).** The Kael
> API is untouched and remains the proven path for manual and backfill review
> posting. This is a second, parallel endpoint on trial for the automated LMS
> flow. Retire nothing until this is proven in production.

## Endpoint

```
POST <site_base_url>/lms_feedback_review_api.php
```

Production (SG): `https://www.tertiarycourses.com.sg/lms_feedback_review_api.php`

## Authentication

Header `X-Api-Key`, using the **same key as the Kael review API** — Magento
config `mmd_company/api/kael_review_key`, falling back to env
`KAEL_REVIEW_API_KEY`. One shared secret, so nothing new to provision.

## Request

| Field | Type | Required | Notes |
|---|---|---|---|
| `sku` | string | yes\* | Course code (the TGS code the LMS holds). Resolved via `getIdBySku()`. |
| `product_id` | int | yes\* | Alternative to `sku` — Magento product `entity_id`. |
| `nickname` | string | yes | Learner name |
| `detail` | string | yes | The comment |
| `ratings` | object | yes | `{ "<rating_id>": <stars 1-5> }` |
| `title` | string | no | Defaults to `"Average Rating: X.X/5"` |
| `created_at` | string | no | Defaults to `NOW()` |
| `store_id` | int | no | Defaults to current store (SG = 1) |
| `customer_id` | int | no | Defaults to `null` (guest review) |
| `external_ref` | string | no | LMS `feedback_form_response.id` — enables idempotency |

\* Supply **either** `sku` or `product_id`.

### Rating IDs

Same three criteria as the storefront review form (verified against the live
product page, which posts `ratings[1]`, `ratings[2]`, `ratings[5]`):

| `rating_id` | Question |
|---|---|
| `1` | Course meets your expectation |
| `2` | Trainer knowledgeable |
| `5` | Training environment |

## Moderation — the key difference from the Kael API

The **average** of the supplied star ratings decides whether the review goes
live:

| Average | Status | Visible on the storefront? |
|---|---|---|
| **> 2.0** | `APPROVED` (1) | Yes, immediately |
| **≤ 2.0** | `PENDING` (2) | **No** — held for a human |

A held review waits in **Catalog → Reviews and Ratings → Pending Reviews** for
an admin to read and approve or reject. Magento aggregates only *approved*
reviews, so a pending one does not move the product's public star average;
approving it later re-aggregates automatically.

This matches the threshold applied retroactively by migration
`898-low-rated-reviews-to-pending.sql`, so historical and new reviews are
moderated by the same rule.

## Idempotency

Supply `external_ref` (the LMS response row id). The endpoint records it in
`mmd_lms_feedback_review` (migration `900-lms-feedback-review-refs.sql`) and,
on a repeat call with the same ref, returns the existing review with
`duplicate: true` rather than creating a second one. A `UNIQUE` key on
`external_ref` enforces this at the database level.

Without `external_ref` the behaviour matches the Kael API: every call creates a
new review.

## Responses

### 200 — Success

```json
{
  "success":        true,
  "duplicate":      false,
  "review_id":      22864,
  "product_id":     1079,
  "status":         "approved",
  "auto_published": true,
  "average_rating": 4.67,
  "created_at":     "2026-08-09 14:22:05",
  "store_id":       1,
  "message":        "Review created and approved"
}
```

A held review returns `"status": "pending"`, `"auto_published": false`.

### Errors

| HTTP | `error` | Cause |
|---|---|---|
| 400 | `validation_error` | Bad JSON, missing field, no usable ratings, bad `created_at` |
| 401 | `unauthorized` | Missing/invalid `X-Api-Key` |
| 404 | `not_found` | `sku`/`product_id` not on this site |
| 405 | `method_not_allowed` | Non-POST |
| 503 | `api_disabled` | No key configured server-side |
| 500 | `internal_error` | Server error |

## cURL example

```bash
curl -X POST 'https://www.tertiarycourses.com.sg/lms_feedback_review_api.php' \
  -H 'Content-Type: application/json' \
  -H "X-Api-Key: $KAEL_REVIEW_API_KEY" \
  -d '{
    "sku":          "TGS-2024045798",
    "nickname":     "John Tan",
    "detail":       "Great course, very informative!",
    "ratings":      {"1": 5, "2": 5, "5": 4},
    "external_ref": "3c232709-24d8-4b7e-870c-92caa051afc6"
  }'
```

## LMS caller

`lib/feedback/postReview.ts` in the ai-lms-tms repo, invoked from
`pages/api/feedback-form/submit.ts` after the response row is written. It needs
two env vars:

```
STOREFRONT_REVIEW_API_URL=https://www.tertiarycourses.com.sg/lms_feedback_review_api.php
STOREFRONT_REVIEW_API_KEY=<same as KAEL_REVIEW_API_KEY>
```

If either is unset the LMS silently skips posting — that is how a tenant which
does not publish reviews stays opted out.
