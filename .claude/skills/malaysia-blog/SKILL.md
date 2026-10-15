---
name: malaysia-blog
description: Create, publish or repair Tertiary Courses Malaysia blog posts and banners on tertiarycourses.com.my, using the current editorial banner template with Malaysia-only writes and live verification.
---

# Malaysia blog

Use the native `MMD_Blog` system on the isolated Malaysia installation. Follow `blog-publish` for article quality; apply these Malaysia-specific rules instead of its Singapore deployment workflow. Draft-only work stays local.

## Country boundary

- Resolve Malaysia SSH access from the ai-mms repository `.env` section `# MY SSH`; never print credentials. Discover the current web container on that server before each operation.
- Verify `MMS_COUNTRY_CODE=MY`, the sole non-admin store is `malaysia`, and the public domain is `tertiarycourses.com.my` before writes.
- Malaysia repairs use its own DB/media, not a shared migration or `git push` that also deploys Singapore. Never write to Singapore or overwrite shared R2 objects. Preserve article content, metadata, dates, tags, likes, course links and local HRD Corp content during a banner-only repair.
- Do not delete/recreate the blog to fix images. Match existing posts by their actual IDs/slugs and save a before snapshot.

## Latest banner template is mandatory

"Latest profile image" in this banner workflow means the latest blog banner design/template, not the author's portrait (confirmed 2026-10-13).

Every published Malaysia post needs a real generated editorial banner, including hand-written articles and migrated posts. A saved article or deployed migration alone does not finish publication.

1. Compare the Malaysia `app/code/local/MMD/Blog/Model/Hero.php` checksum with the current verified ai-mms renderer before rendering. If they differ, inspect the versions and arrange a Malaysia-only renderer update; do not use an older template or overwrite unrelated server code.
2. Render through `MMD_Blog_Model_Hero`, normally via `MMD_Blog_Helper_Image::generateHero($title, '', $kicker)`. Use the post's current title and a specific topic tag. Skip generic funding/WSQ/SkillsFuture tags when choosing the kicker, so they do not hijack the article's visual theme.
3. Require a 1600x900 PNG, topic-specific dark palette, technical grid, readable headline/kicker, accent line and topic motif. No course-cover substitution or text-only gradient fallback. Keep text within the renderer's safe band (approximately y=225..675) so both the 16:9 card and centered 32:9 article crop remain readable.
4. Preview the full image and article crop before publication, checking long headlines and several topic families. Upload with an immutable, country-specific `blog/auto-my-*` key for bulk repairs. Verify HTTP 200, `image/png`, dimensions and checksum before saving its URL.
5. Update only the intended Malaysia `hero_image_url` values, then flush the Malaysia application cache. Verify the DB, homepage, every blog listing page, every affected article and its `og:image` against the new URLs. Require zero empty/fallback banners and no fatal errors; read back all unrelated fields to prove preservation.

For a requested whole-blog refresh, include all published posts, not just the latest four homepage cards. Normally preserve custom/admin-uploaded images; a user request to regenerate **all** banners authorizes replacing them after preview and a backup. Do not overwrite existing image objects: new keys keep older versions and Singapore references intact.

## Bulk refresh helper

`scripts/refresh-heroes.php` runs only inside the verified Malaysia web container and refuses other installations. Copy it to a temporary container path; no repository deployment is required.

```bash
php /tmp/my-refresh-heroes.php audit
php /tmp/my-refresh-heroes.php stage /tmp/my-blog-heroes-<unique-run>
# Download and visually inspect the staged PNGs, full card and 32:9 center crop.
php /tmp/my-refresh-heroes.php publish /tmp/my-blog-heroes-<unique-run>
```

If R2 variables are missing in the CLI environment, inject only the five required `R2_*` values from the repository credential source into that one PHP process. Never print them, persist a credential-bearing script on the server, or accept the helper's local-media fallback as an R2 upload.

`stage` makes a full published-post snapshot and preview manifest without uploading or changing the DB. `publish` verifies that the renderer, previews and post snapshot are unchanged; uploads and publicly verifies every image; then updates only banner URLs in a transaction. Stop on a changed snapshot or failed upload instead of making a partial DB update. Keep the manifest and `published.json` as repair/rollback evidence. The helper is for explicitly requested whole-blog refreshes because it includes custom banners.

After publishing, fetch public HTML independently. The helper's success message alone is insufficient. Compare Singapore's public banner references before/after to confirm they are unchanged.
