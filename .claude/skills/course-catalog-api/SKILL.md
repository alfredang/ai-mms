---
name: course-catalog-api
description: The read-only course catalog HTTP APIs on the SG storefront (MMD_Courses) — /courses/api_wsq (TGS- courses), /courses/api_nonwsq (C- courses), /courses/api_courses?sku= (one course), /courses/api_schedule (WSQ class dates). Use when asked to expose, consume, extend or debug a course feed; when a consumer (mobile app, WhatsApp bot, partner site) needs course data; or when someone asks "is there an API for courses", "how do I get all the courses", "the feed is empty", or wants to add a field to a course API.
---

# Course Catalog API (MMD_Courses)

Read-only, key-protected JSON feeds over the SG course catalog. Live on
`https://www.tertiarycourses.com.sg`.

## The endpoints

| Endpoint | Returns | Notes |
|---|---|---|
| `GET /courses/api_wsq` | ALL enabled **TGS-** (WSQ) courses | catalog data — fee, duration, badges, categories |
| `GET /courses/api_nonwsq` | ALL enabled **C-** (non-WSQ) courses | same shape; `funding_badges` is normally `[]` |
| `GET /courses/api_courses?sku=X` | ONE course, rich payload | any SKU; 400 without `sku` |
| `GET /courses/api_schedule` | WSQ courses + class dates | **TGS-only**; schedule data, not catalog |
| `GET /courses/api_schedule?sku=X` | one course's classes | works for any SKU |

Add `?fields=full` to the two list feeds for the long description, suitability,
prerequisites, assessment and certification.

**WSQ and non-WSQ are deliberately SEPARATE endpoints.** Do not merge them or add a
`?type=` switch to one endpoint — that split is a product decision, not an accident.

## Course code convention (load-bearing)

- **WSQ** course codes start with **`TGS-`**
- **non-WSQ** course codes start with **`C`**

`MMD_Courses_Helper_Catalogfeed::skuInTrack()` matches on these prefixes explicitly, so
anything that is neither (staging junk, test rows) appears in NEITHER feed. That is
intentional — do not "fix" it by making non-WSQ mean "not TGS-".

As of the last full check: **298 TGS- + 264 C- = 562** enabled courses, zero overlap.

## Auth

Header `X-API-Key`, compared against the Magento config path
`courses/general/wsq_schedule_api_key` (Admin → System → Configuration → Courses).
All the read endpoints share this one key.

- blank stored key → `503 api_disabled`
- wrong/missing key → `401 unauthorized`

To read the key locally: start `ai-mms-db_mysql-1` and select it from
`core_config_data`. Never print it in full, never commit it.

## Code layout

```
app/code/local/MMD/Courses/
  Helper/Catalogfeed.php                  ← ALL shared logic (auth, rows, envelope)
  controllers/Api/WsqController.php       ← thin: buildFeed(true, $full)
  controllers/Api/NonwsqController.php    ← thin: buildFeed(false, $full)
  controllers/Api/CoursesController.php   ← single-SKU (used by the WhatsApp bot)
  controllers/Api/ScheduleController.php  ← WSQ class dates
```

Magento's standard router maps `Api/FooController.php` → `/courses/api_foo`, so adding an
endpoint means adding a controller — no route config needed. Bump `<version>` in
`etc/config.xml` when the module changes.

**Put shared behaviour in the helper, not the controllers.** The two feeds must never
drift in shape.

## Traps that have already bitten

1. **Malformed UTF-8 empties the WHOLE feed.** Some rows contain invalid byte sequences
   (legacy Word paste). `json_encode()` then returns `false` and Magento ships an
   **empty body with HTTP 200** — which reads as "no courses" to a consumer, not as an
   error. C428 did exactly this. Mitigated in three places, keep all three:
   - `stripText()` scrubs via `mb_convert_encoding($s, 'UTF-8', 'UTF-8')`
   - `sanitizeUtf8()` walks the whole payload before returning
   - both controllers turn an encode failure into a **500 `encoding_error`**, never an empty 200
2. **Truncate with `mb_substr`, not `substr`.** Byte-slicing a multibyte character
   *creates* invalid UTF-8 — i.e. causes trap #1.
3. **Load products one at a time.** Storefront-scoped attributes (description, url_key,
   price) only resolve on a store-loaded model, and hydrating ~560 at once exhausts
   memory. The current loop peaks at ~118 MB and takes ~5 s per feed.
4. **`api_schedule` is TGS-only.** It cannot serve non-WSQ courses — that gap is exactly
   why `api_nonwsq` exists. Don't point a consumer at it for the full catalog.

## Verifying a change

Run the stack locally (`docker start ai-mms-db_mysql-1 ai-mms-redis-1 ai-mms-web-1`,
web on :8080) and check:

```bash
# counts, and that the two tracks never overlap
curl -s -H "X-API-Key: $KEY" localhost:8080/courses/api_wsq    | jq '.count, .track'
curl -s -H "X-API-Key: $KEY" localhost:8080/courses/api_nonwsq | jq '.count, .track'
# size MUST be non-zero — a 0-byte 200 is trap #1
curl -s -o /dev/null -w '%{http_code} %{size_download}\n' -H "X-API-Key: $KEY" \
  localhost:8080/courses/api_nonwsq
# auth still enforced
curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/courses/api_wsq   # → 401
# and the bot's endpoint is unregressed
curl -s -H "X-API-Key: $KEY" "localhost:8080/courses/api_courses?sku=TGS-2019503161" | jq '.data.name'
```

## Known consumers

- **Tertiary Courses iOS app** — syncs the catalog via a GitHub Action that calls both
  feeds and republishes them as a static JSON feed. The API key lives in the Action's
  secrets, never in the app (an IPA is extractable).
- **WhatsApp bot** — `api_courses?sku=` and `api_schedule`. Changing those response
  shapes breaks it; add fields, don't rename or remove.
