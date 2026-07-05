#!/usr/bin/env python3
"""Fix the intermittent serif-flash and match SG's Oswald font — DB-only, zero-flash.
Generates SQL to inline the Oswald latin subset as a base64 data URI into the partner
website-scope design/head/includes. No network, no CORS, no font-display swap. PARTNER-ONLY.

Prereq: download Oswald latin woff2 (variable, covers all weights) into $WORK/oswald-latin.woff2:
  UA='Mozilla/5.0 ... Chrome/120'
  curl -s "https://fonts.googleapis.com/css2?family=Oswald:wght@200..700" -H "User-Agent: $UA" -o oswald.css
  # take the /* latin */ block's woff2 URL, curl it -> oswald-latin.woff2
Also set the font config (do once, separately) so Ultimo stops the flaky google <link> and
emits a sans (never serif) fallback:
  core_config_data @ default/0:
    ultimo_design/font/primary_font_family_group = custom
    ultimo_design/font/primary_font_family_custom = "Oswald", Arial, "Helvetica Neue", Helvetica, sans-serif

Output: font_inline.sql  (apply; then flush). NOTE core_config_data.value is TEXT (65KB) ->
inline ONLY the latin subset (~38KB). latin-ext would overflow (ERROR 1406).
"""
import base64, sys
W = sys.argv[1] if len(sys.argv) > 1 else "/tmp/parity"
WEBSITE_ID = sys.argv[2] if len(sys.argv) > 2 else "3"
b64 = base64.b64encode(open(f"{W}/oswald-latin.woff2", "rb").read()).decode()
style = ('<style>@font-face{font-family:"Oswald";font-style:normal;font-weight:200 700;'
         f'src:url(data:font/woff2;base64,{b64}) format("woff2");}}</style>')
# Cut any prior font/preload injection (from '<link rel="preload"' or the font <style>) then append.
sql = ("UPDATE core_config_data SET value = CONCAT("
       "SUBSTRING(value, 1, IFNULL(NULLIF(LOCATE('<link rel=\"preload\"', value),0),LENGTH(value)+1) - 1), "
       f"'{style}') "
       f"WHERE path='design/head/includes' AND scope='websites' AND scope_id={WEBSITE_ID} "
       "AND value NOT LIKE '%data:font/woff2;base64%';\n")
open(f"{W}/font_inline.sql", "w").write(sql)
print(f"wrote font_inline.sql ({len(sql)} bytes; latin b64={len(b64)})")
