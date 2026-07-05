# Font fix — no serif flash, matches SG (Oswald)

## Symptom
A partner storefront intermittently renders in **serif/Times after a refresh** while SG is
fine. NOT a CSS-merge 404 (all `/skin/.../css/*.css` return 200; there's no `/media/css/<hash>`).

## Root cause
Ultimo's `app/design/frontend/base/default/template/infortis/ultimo/css/design.phtml` (~L278),
when `ultimo_design/font/primary_font_family_group == 'google'`, emits
`font-family: "Oswald", georgia, serif;` AND `head.phtml` (~L286) injects
`<link href='//fonts.googleapis.com/css?family=Oswald'>`. When that external font is slow/blocked
in-country (reliable from Singapore, flaky from Ghana) the browser falls back to **georgia/serif**.
SG and the partner share the identical config — the only difference is network reliability to
`fonts.googleapis.com`. Also: the partner renders font-family from a static exported file
`_config/design_<country>.css` (baked into the image; the DB config does NOT regenerate it, and an
in-container edit is wiped on redeploy) — so the fix must supply the "Oswald" face itself.

## R2 self-hosting FAILS (CORS)
`pub-*.r2.dev` sends NO `Access-Control-Allow-Origin`; cross-origin `@font-face` requires CORS →
browser refuses the font → still serif. Setting R2 bucket CORS needs bucket-admin creds the S3
object token / `R2_API_TOKEN` don't have. So DON'T self-host fonts on R2. (Images are fine — `<img>`
needs no CORS; fonts are the exception.)

## The fix (DB-only, GH-only, no SG impact)
1. **Config** @ `core_config_data default/0`: `ultimo_design/font/primary_font_family_group`=`custom`
   (stops the flaky `<link>`; switches design.phtml to the custom branch with NO serif) + INSERT
   `ultimo_design/font/primary_font_family_custom` = `"Oswald", Arial, "Helvetica Neue", Helvetica, sans-serif`.
2. **Serve Oswald.** Two options, both zero-SG-impact:
   - **Inline base64 data URI** in the partner WEBSITE-scope `design/head/includes` (`scripts/font_inline.py`).
     No network, no CORS, no `font-display`, no flash — the font is present the instant the (render-blocking)
     `<head>` CSS parses. GOTCHA: `core_config_data.value` is TEXT (65 KB) → inline ONLY the **latin** subset
     (~38 KB); both subsets (~70 KB) overflow → `ERROR 1406 Data too long`. Drop unicode-range (latin covers
     the English nav). **Preferred.**
   - **Same-origin from the media volume**: the web container mounts a persistent Docker volume at
     `/var/www/html/media` (survives restarts+redeploys; entrypoint only clears media/css|js|full_page_cache).
     Pipe the woff2 in: `ssh $HOST "docker exec -i $WEB sh -c 'cat > /var/www/html/media/fonts/oswald-latin.woff2'" < file`,
     `chown www-data`, then `@font-face src:url('/media/fonts/oswald-latin.woff2')` in head-includes. Served
     same-origin (200, no redirect → an EXISTING file bypasses the media/.htaccess R2 fallback) so no CORS.
3. Flush cache.

## FOUT note
An async `@font-face url()` (even same-origin) still swaps: `font-display:swap` shows fallback then swaps;
`block` shows invisible then the font. Both are a visible flash on hard-refresh. **Inlining as a data URI is
the only truly flash-free option** (font available synchronously with the CSS).

## Verify on prod
Homepage HTML: `1` × `data:font/woff2;base64` (inline route) OR `2` × `/media/fonts/oswald` (volume route);
`0` × `fonts.googleapis.com`; `0` × `r2.dev/fonts`; `0` × `font-display`; `0` × `georgia, serif`.
Tell the user to hard-refresh (browser cached the failed font).

Source memory: feedback_ultimo_google_font_serif_fallback.
