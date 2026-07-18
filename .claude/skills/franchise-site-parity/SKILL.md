---
name: franchise-site-parity
description: Bring a franchise partner storefront (Ghana .com.gh, Malaysia .com.my, or a new country) to full parity with Singapore for NON-WSQ courses — import courses, mirror the category tree + mega-menu, sync product↔category assignments, category banners/descriptions, currency switcher, remove SG-only funding text, fix fonts/banners, WhatsApp, contact/footer/trainer info, and the blog. Use when asked to "make GH same as Singapore", "port courses to the partner site", "the <country> categories/menu/blog/footer are different from SG", "add currency switcher / WhatsApp to <country>", "remove funding on <country>", or when onboarding/refreshing a franchisee site. Everything here is PARTNER-DB-ONLY (never a repo/code change, never touch SG).
---

# Franchise Site Parity (mirror Singapore, non-WSQ)

Playbook for making a franchise partner site (GH/MY/new country) match Singapore's
non-WSQ storefront. Distilled from the Ghana build-out. Pair with
[[add-country-store]] (which wires the domain → store view) — this skill handles the
CONTENT parity that comes after.

## HARD RULES (read first — violating these breaks production)

1. **Partner changes are DB-ONLY on the partner's OWN server. NEVER a repo/code change.**
   A `git push` deploys to SG too. Everything below is SQL / config / media on the
   partner DB. See memory `feedback_gh_changes_never_touch_sg_hard_rule`.
2. **Never SSH-write to SG.** Read SG only from the **local backup DB** (docker
   `courses_backupDB`) or public HTTP (`curl` a rendered page). Both are read-only and
   don't touch SG prod.
3. **Match products by SKU, categories by url_key.** Partner DBs are clones of SG so
   entity_ids DIFFER but SKUs and url_keys are stable join keys. url_keys are globally
   unique here (flat URLs — see `FlatCategoryUrl`).
4. **WSQ / IBF / SkillsFuture are Singapore-only.** Partners have only the non-WSQ
   `C`-prefix courses. Never create WSQ (`TGS-`) courses or WSQ/IBF categories on a partner.
5. **Flat catalog is ON** → after ANY category/product/menu write you MUST reindex
   `catalog_category_flat` (and `catalog_category_product` for assignments) and flush the
   Redis cache. Run the reindex as a SEPARATE step (it can exceed 2 min and time out).

## Access pattern (from repo `.env`)

```bash
# Partner SSH + DB (example: Ghana). Creds live in .env under "# GH SSH".
export SSHPASS='<partner-root-pw>'                 # from .env
GH="root@<partner-ip>"                             # partner server IP (from .env)
DB=<mysql-container>                               # docker ps | grep mysql:5.7  → db-...
WEB=<web-container>                                # docker ps | grep -v mysql   → web-...
# DB name is in the mysql container env: docker exec $DB sh -c 'echo $MYSQL_DATABASE'  (GH=mms_gh)

# Run SQL on the partner (pipe files via stdin to dodge quote hell):
sshpass -e ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 $GH \
  "docker exec -i $DB sh -c 'mysql -uroot -p\"\$MYSQL_ROOT_PASSWORD\" <dbname>'" < file.sql

# Reindex + flush via Mage (shell/indexer.php may be absent):
sshpass -e ssh ... $GH "docker exec $WEB php -r '
  require \"/var/www/html/app/Mage.php\"; Mage::app();
  foreach([\"catalog_category_flat\",\"catalog_category_product\",\"catalog_url\"] as \$c){
    \$p=Mage::getModel(\"index/indexer\")->getProcessByCode(\$c); if(\$p){\$p->reindexEverything();}}
  Mage::app()->getCacheInstance()->flush();'"

# SG reference (READ-ONLY, local backup — never touch SG prod):
docker exec ai-mms-db_mysql-1 sh -c "mysql -umagento -pmagento123 courses_backupDB -N -e \"<SELECT...>\""

# R2 (shared media, from .env R2_*): bucket tertiarycourses-media,
# public base https://pub-77c0dec029944b0386e40673ce81081f.r2.dev
```
Transient `Permission denied (publickey,password)` = SSH flake; just retry.

## EAV attribute ids (category, entity_type_id=3; confirm per DB, usually stable)
`name`=41 (or 41), `url_key`=43, `description`=44 (**text** table), `image`=45,
`include_in_menu`, `is_anchor`, `display_mode`; Infortis mega: `umm_dd_type`=185 (varchar),
`umm_dd_width`=186 (varchar), `umm_dd_proportions`=187 (varchar), `umm_dd_columns`=188 (int).
Always resolve ids per-DB: `SELECT attribute_id FROM eav_attribute WHERE attribute_code=? AND entity_type_id=3`.

---

## 1. Course catalog — import all non-WSQ (C-prefix) SG courses

The partner should hold every ENABLED SG `C`-prefix course. Usually already ~complete
(GH had 494/498; the 4 absent were `status=2` disabled/retired — skip those).

```bash
# SG C-SKUs vs partner SKUs → missing:
comm -23 <(grep '^C' sg_skus.txt|sort -u) <(sort -u partner_skus.txt)   # SG has, partner lacks
# Check status on SG: status=1 enabled, 2 disabled. Only port ENABLED (status=1) ones.
```
Porting a full product (rare) means recreating catalog_product_entity + all EAV + website
link + stock + custom options — a big per-product job; do it via the `catalog/product` model
in a PHP script, matched by SKU. Confirm the partner catalog is website-linked
(`catalog_product_website`) and `status=1`.

## 2. Category tree — same as Singapore

The 4 non-WSQ menu roots (SG ids → find partner ids by url_key):
`adult-training-courses`, `software-training-courses`, `certification-exam-prep-courses`,
`specialisation-courses` (Bootcamp — usually no subcats). See memory
`feedback_ultimo_megamenu_match_sg` for the full method. Do ALL of a–d for ALL 4 roots
(not just Adult — the classic bug is doing only Adult and leaving Software/Cert Prep empty):

**a) Create missing categories** (diff SG subtree vs partner by url_key). Use a PHP script
IN the web container via the `catalog/category` MODEL (not raw SQL — the model builds
path/url_rewrite/indexes):
```php
$c=Mage::getModel('catalog/category'); $c->setStoreId(0);
$c->addData(['name'=>$n,'url_key'=>$uk,'is_active'=>1,'include_in_menu'=>1,'is_anchor'=>0,
  'display_mode'=>'PRODUCTS','position'=>$p, 'image'=>$img?:null,'description'=>$desc?:null]);
$parent=/* load partner cat by parent url_key */;
$c->setPath($parent->getPath()); $c->setParentId($parent->getId());
$c->setLevel($parent->getLevel()+1); $c->save();   // Magento appends new id to path
```
**b) include_in_menu** — enable on every descendant of the 4 roots (SG has all in-menu):
```sql
SET @im:=(SELECT attribute_id FROM eav_attribute WHERE attribute_code='include_in_menu' AND entity_type_id=3);
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value)
SELECT 3,@im,0,e.entity_id,1 FROM catalog_category_entity e
WHERE e.path LIKE '1/2/<adultId>/%' OR e.path LIKE '1/2/<softwareId>/%'
   OR e.path LIKE '1/2/<certprepId>/%' OR e.path LIKE '1/2/<bootcampId>/%'
ON DUPLICATE KEY UPDATE value=1;
```
**c) names + positions** — the raw partner names ("Comptia Certification Exam Prep Courses")
differ from SG's clean nav labels ("CompTIA Certification Exam Prep"). SG uses the category
`name` itself as the label. Dump SG (url_key,position,name) for the 4-root subtree; for each,
`UPDATE catalog_category_entity SET position=?` and
`UPDATE catalog_category_entity_varchar SET value='<name>' WHERE attribute_id=<name> AND store_id=0`.
url_key/URLs stay untouched (no SEO churn). Double apostrophes for SQL.
**d) mega-menu layout (`umm_dd_*`)** — mega renders at ANY depth (e.g. Artificial
Intelligence is level-4 but opens its own mega sub-panel). Clear+set all four umm attrs for
EVERY 4-root category by url_key from SG. e.g. AI = `dd_type=1, cols=3, width=800px,
prop=4;4;4;`; the roots are `dd_type=1` with 5/4/3 cols. Verify: the `<li>` gains class
`mega`, `style="width:…px"`, `dd-itemgrid-Ncol`.

## 3. Product ↔ category assignments (same courses in same categories)

Match products by SKU, categories by url_key. WSQ/IBF cats don't exist on the partner →
auto-skipped. Deleting a category assignment NEVER deletes the course.
```
Dump SG catalog_category_product as (sku,url_key,position) for shared products & partner-existing cats.
Diff vs partner current. ADD missing + DELETE extra by (category_id,product_id) resolved via
partner sku→id / url_key→id maps. Reindex catalog_category_product + catalog_category_flat.
```
Watch for a partner category over-stuffed vs SG (GH had 305 in AI vs SG's 69 — 236 wrong).
Verify against SG's LIVE page before deleting, then confirm partner product COUNT is unchanged.

## 4. Category banners + descriptions (from shared R2)

Image files are already on the SHARED R2 bucket (SG uses them); nothing to upload — just
copy the `image`(45, varchar) + `description`(44, **text** table) attrs SG→partner by url_key.
```
Dump SG: url_key, image, REPLACE(REPLACE(TO_BASE64(description),'\n',''),'\r','')  -- STRIP TO_BASE64 wrapping!
INSERT ... ON DUPLICATE KEY UPDATE  into catalog_category_entity_varchar(45) / _text(44) at store_id=0.
```
Partner renders `/media/catalog/category/<file>` → the partner's `media/.htaccess`
302-redirects missing `catalog/category/*` to R2 (final 200). Verify a sample loads. See
memory `feedback_category_banners_on_r2`.

## 4b. Product course-cover images → R2 (compress + reupload for app speed)

Partner course tiles/product pages read the `course_image_url` EAV attribute (a **stored
full URL**, attribute in `catalog_product_entity_varchar`). On a fresh partner the covers
live on the partner's OWN Apache origin (`https://www.tertiarycourses.com.<cc>/media/course-covers/<sku>.png`)
— no CDN, served off a 2-CPU box → slow, and the 1600×900 RGBA PNGs are heavy. SG serves the
*same kind* of cover from Cloudflare R2 (`pub-77c0…r2.dev/course-covers/…`). Move the partner
onto the same R2 host — the CDN edge cache is the real speed win; recompression is a bonus.
**Partner covers are the partner's OWN SKU-named files** (`c024.png`), distinct from SG's
timestamped keys (`TGS-…-<stamp>.png` / `C193-…-<stamp>.png`) — so uploading them to the shared
bucket **cannot collide with or affect SG**. MY & GH covers are usually byte-identical (same
SG render batch) — compress once, upload once, both DB-swaps reuse it.

```bash
# 1. Pull the partner's covers to the Mac (web container has NO R2 env, so upload from here):
docker exec $WEB tar cf - -C /var/www/html/media course-covers | tar xf - -C ./src --strip-components=1
# 2. Compress: RGB + optimize at NATIVE 1600×900 (drops the unused alpha, ~17% lighter, pixel-identical).
#    Do NOT downscale (LANCZOS resample noise makes PNG BIGGER) and do NOT pngquant
#    (gradient+antialiased-text covers palette poorly — some grow). Pillow:
python3 -c 'import glob,os;from PIL import Image
[Image.open(p).convert("RGB").save("out/"+os.path.basename(p),"PNG",optimize=True) for p in glob.glob("src/*.png")]'
# 3. Upload to the SHARED bucket under course-covers/<same-filename> (creds from .env R2_*):
rclone copy out ":s3:$R2_BUCKET/course-covers/" --s3-provider Cloudflare \
  --s3-access-key-id $R2_ACCESS_KEY_ID --s3-secret-access-key $R2_SECRET_ACCESS_KEY \
  --s3-endpoint $R2_ENDPOINT --s3-no-check-bucket --header-upload "Content-Type: image/png" --transfers 16
# verify a key: curl -I $R2_PUBLIC_URL/course-covers/c024.png  → 200, server: cloudflare
# 4. DB host-swap (keep filename): only the origin prefix changes.
#    UPDATE catalog_product_entity_varchar v JOIN eav_attribute a ON a.attribute_id=v.attribute_id
#      SET value=REPLACE(value,'https://www.tertiarycourses.com.<cc>/media/course-covers/',
#                              'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/')
#      WHERE a.attribute_code='course_image_url' AND value LIKE 'https://www.tertiarycourses.com.<cc>/media/course-covers/%';
#    (GH holds the value at BOTH store 0 AND store 3 → ~2× rows; swap all, don't filter store.)
```
Then **reindex `catalog_product_flat` + flush** — listing/featured tiles read the FLAT table,
so the EAV UPDATE alone leaves the homepage stale (`feedback_flat_catalog_reindex`):
`Mage::getSingleton('index/indexer')->getProcessByCode('catalog_product_flat')->reindexEverything();`
then `getCacheInstance()->flush()`. Verify: homepage + a product page emit `pub-77c0…r2.dev/course-covers/`
with **zero** `com.<cc>/media/course-covers` refs. GOTCHA: `docker exec -i` inside `bash -s < script`
steals the script's stdin — add `</dev/null` to every `docker exec` in a piped script.
See memory `feedback_partner_product_covers_to_r2`.

## 5. Currency switcher (local currency + USD)

Allowed currencies are usually already set (`currency/options/allow=GHS,USD`,
base/default = local). The switcher is hidden because there's **no exchange rate**:
```sql
INSERT INTO directory_currency_rate (currency_from,currency_to,rate) VALUES
 ('<LOCAL>','<LOCAL>',1),('<LOCAL>','USD',<usd_per_local>),('USD','USD',1),('USD','<LOCAL>',<local_per_usd>)
ON DUPLICATE KEY UPDATE rate=VALUES(rate);
```
Use an approximate rate and tell the admin to refresh to the live rate. Verify the homepage
HTML has a `currency-switcher` with both options.

## 6. Remove all SG-only funding (WSQ/IBF/SkillsFuture) from the partner

Funding text is Singapore-only and misleads partner users. Three surfaces, three techniques:
- **Course page** WSQ/funding policy cards: hidden per-website via CSS already in some sites
  (`.course-policy-card--wsq{display:none}` in `design/head/includes`). Add website-scope CSS
  in `core_config_data['design/head/includes']` to hide any funding card/tile classes.
- **Blog** CTA ("WSQ up to 70% SkillsFuture") is HARDCODED in shared templates
  (`mmd/blog/view.phtml`, `list.phtml`) → hide GH-only with head-includes CSS:
  `.mmd-blog-cta > p{display:none!important}.mmd-blog-sub{display:none!important}`.
- **Text that flows through `$this->__()`** (e.g. WhatsApp popup "Course Funding" /
  "SFC, WSQ, IBF, SFEC, UTAP, PSEA") → override PER-STORE via `core_translate` (no CSS, real
  text swap):
  ```sql
  INSERT INTO core_translate (store_id,locale,string,translate,crc_string) VALUES
   (<storeId>,'en_US','Course Funding','Course Info',CRC32('Course Funding')) ...
  ON DUPLICATE KEY UPDATE translate=VALUES(translate);
  ```
  Match the `__()` string EXACTLY; the load matches by `string`; flush cache.
  **CRITICAL — use the STORE's locale, not `en_US`.** `core_translate` rows must match the
  store's actual locale. GH = `en_US` but **MY = `en_GB`** (`SELECT value FROM core_config_data
  WHERE path='general/locale/code' AND scope='stores' AND scope_id=<id>`). An `en_US` row on an
  `en_GB` store silently does nothing (real MY miss).
- **REMOVE vs REPLACE depends on the partner's funding scheme.** GH has NO funding → hide the
  WSQ card + blog CTA (above). **MY uses HRD Corp** → still hide the SG WSQ funding card
  (`.course-policy-card--wsq`) but KEEP the partner's HRD Corp content (MY already had a
  "Grants and Subsidies" footer section + "Steps to Submit HRD Corp Grant"; `MMD_SG_PRICING`
  is already `active:false`). So hide the SG-specific funding card, leave local grant content.

## 6b. Top nav — trim partner-specific roots + sync the 4 keeper roots

A partner may carry extra top-level (level-2) roots SG/GH don't show — e.g. MY had
`latest-courses` ("Regional Franchisee", id 180) and `wsq-ibf-skillsfuture-utap-funded-courses`
("WSQ IBF SkillsFuture UTAP Funded Courses", id 181). Hide them: set `include_in_menu=0`
(`catalog_category_entity_int`, the store-0 row). The **4 keeper roots' own names/positions are
NOT touched by the descendant name-sync** (roots aren't under `1/2/N/%`), so set them explicitly
to match GH: Adult Courses(pos1)/CERT Prep Courses(2)/Software Training(3)/Bootcamp(4). Reindex
`catalog_category_flat`. GH & MY share the same root entity_ids (3/6/36/64/180/181 — clones).

## 6c. Trainers — swap to the partner's local trainer

The "About the Trainer"/Trainers tab reads the per-product **`trainerprofile`** attribute
(a TEXT attr; find its id: `attribute_code='trainerprofile'`). The tab splits the blob on
`<strong>Name:</strong>` boundaries and resolves each bio (from the `courses_trainers` table by
title match, else the blob text). To attribute all partner courses to one local trainer (MY =
"Saeid", like GH's Dr Siraj), set that attr on every product at store 0:
`INSERT INTO catalog_product_entity_text (entity_type_id,attribute_id,store_id,entity_id,value)
SELECT 4,<tpAttr>,0,e.entity_id,'<p dir="ltr"><strong>Saeid:</strong> …bio…</p>' FROM
catalog_product_entity e ON DUPLICATE KEY UPDATE value=VALUES(value);` then reindex
`catalog_product_flat` + flush. GOTCHA: the trainer's photo may 500/404 everywhere (no original
on disk) — use a text-only bio or source/upload the image first. Get the bio from the partner's
HRD/trainer page if present. The trainer often already exists as an `admin_user`.

See memory `feedback_gh_whatsapp_currency_homepage_config`.

## 7. Font — no serif-flash, matches SG (Oswald)

Ultimo's google-font group emits `font-family:"Oswald", georgia, serif` and loads Oswald from
`fonts.googleapis.com` (flaky in-country → serif flash). Fix DB-only + partner media volume:
serve Oswald **same-origin** from `/var/www/html/media/fonts/` (persistent volume) OR inline
it as a **base64 data URI** in `design/head/includes` (zero flash, no CORS). Set font group
`custom` + stack `"Oswald", Arial, …, sans-serif`. `core_config_data.value` is TEXT (65 KB) —
inline only the **latin** subset. Full detail: memory `feedback_ultimo_google_font_serif_fallback`.

## 8. Homepage banners + carousel (from R2)

Partner carousel slides are cms_blocks (GH = 58/59/102/103). Compress banners (Pillow;
`convert`/`magick` not on Mac), `rclone` to R2 `wysiwyg/`, point the cms_block `<img src>` at
the **direct `pub-*.r2.dev` URL** (not `/media/wysiwyg`, which isn't baked on the partner).
Homepage course rails = `cms_page` (GH home = page 34) `product_list_featured` widgets — swap
`category_id`+`block_name` together to re-theme a rail. Memory
`feedback_partner_banners_via_direct_r2_url`.

**CAROUSEL SLIDE COUNT/ORDER = the `ultraslideshow/general/blocks` config, NOT `is_active`.**
Infortis UltraSlideshow renders one slide per CMS-block identifier in the comma-separated
`ultraslideshow/general/blocks` config (per website AND store scope). MY had
`block_slide4_malaysia,block_slide1_malaysia,block_slide2_malaysia,block_slide3_malaysia` — 4
slides, and because `block_slide4_malaysia` (disabled) was listed FIRST it rendered an EMPTY
leading slide. Toggling a block's `is_active` does NOT remove its slot (a disabled block just
renders empty). To show exactly N slides in a given order, set the config to those N block ids:
`UPDATE core_config_data SET value='block_slide1_malaysia,block_slide2_malaysia,block_slide3_malaysia'
WHERE path='ultraslideshow/general/blocks' AND scope IN ('stores','websites') AND scope_id=<id>;`
then flush. The rendered `.the-slideshow` is loaded lazily so grepping the raw homepage HTML
for slide `<li>`s is unreliable — trust the config + a banner-img count.

**Full-block cms rewrites re-introduce literal `\n`/`\t`.** `mysql -N` dumps a cms_block/page's
real newlines as the 2-char `\n`; if you rebuild the whole value and UPDATE it, those become
literal `\n`/`\t` that render as visible text (real MY footer bug). Prefer surgical `REPLACE()`
over full-content rewrites; if you must rewrite, `REPLACE(REPLACE(content,'\\n','\n'),'\\t','\t')`
afterward.

## 9. WhatsApp (floating widget + header + footer)

`MMD_Whatsapp` is config-driven: set `mmd_whatsapp/general/enabled=1` + `.../number` at the
partner WEBSITE scope. Header WhatsApp = cms_block `block_header_top_left`; footer = the
`contacts` block (page) AND `block_footer_row2_column5`/footer blocks. Use the SG **blue**
icon `#1e3a8a` (not WhatsApp green) to match SG. `wa.me/<digits>` links.

**Header nav contact line — match SG's icon-only style (no "Call/Email/WhatsApp" words).**
`block_header_top_left` is a MULTI-STORE block — the clone has one row PER store view, so pick
the block_id linked to the survivor store via `cms_block_store` (MY malaysia=**35**, GH
ghana=**62**; SG singapore=6/106). SG's format = **Ultimo icon font** for phone + email and an
inline WhatsApp SVG, all monochrome:
```html
<span class="ic ic-lg ic-phone"></span> +<phone>
<a href="mailto:<email>" title="Email us" style="color:inherit;"><span class="ic ic-lg ic-letter"></span> <email></a>
<a href="https://wa.me/<digits>" title="WhatsApp us" style="color:inherit;"><svg viewBox="0 0 24 24" width="14" height="14" fill="currentColor" style="vertical-align:middle;margin-right:3px;"><path d="M17.472 14.382c-.297-.149…"/></svg> +<whatsapp></a>
```
`ic-letter` is the envelope glyph; `fill="currentColor"` keeps the WA icon in the header text
colour (NOT green). Write as a single line (no newlines) to dodge the `mysql -N` literal-`\n`
bug. Copy the exact WA path from SG's `block_header_top_left` in the local backup.

## 10. Contact info, Our Websites, footer links, trainer info

- Contact "Contact Us Information" lives in BOTH the footer block and the `/contacts` page
  block — update both.
- Footer link columns + ECOBANK/payment + "Our Websites" live in the partner's
  `block_footer_row2_column5` (one big store-scoped block). Remove partner-inappropriate links
  (Clientele, Regional Franchising, Affiliate) there. GOTCHA: a payment image `src` may point
  at `.com.sg` (500) while the file exists on the partner domain — swap host to the partner's.
- "Our Websites" → copy SG's network list from SG's footer block by reading the SG backup.
- **Trainer info**: trainer profiles are keyed by SKU (`trainerprofile`/dashboard blobs). If a
  partner lost/needs them, restore/copy by SKU from the SG backup — see memory
  `reference_sg_server_access` (253 WSQ trainerprofiles restored by SKU).

## 11. Blog — partner-relevant, funnels to PARTNER courses

`mmd_blog_post` table. Partner blog is cloned SG → delete all, insert partner posts:
`DELETE FROM mmd_blog_post_vote; mmd_blog_post_tag; mmd_blog_post;` then INSERT. In-content
CTAs use `{{store direct_url='<url_key>.html'}}` (resolves to the partner domain; double the
single quotes inside the SQL literal). Never reference WSQ/SkillsFuture/Singapore. Hide the
hardcoded blog funding CTA via the head-includes CSS in §6.

## 12. Collapse the clone to ONE store (each partner = one store per server)

A partner box ships as a **full 6-website/6-store clone of SG** (admin + singapore/malaysia/
ghana/bhutan/india/infotech), all with **0 orders/0 customers**. The franchise model is one
store per server, so remove the other five. **The live store is chosen in `index.php` by the
`MMS_COUNTRY_CODE` env** (`Mage::run('malaysia','website')` etc.) — NOT by `core_website.
is_default` (which still points at website 1/base). So KEEP the website whose **code matches
the country map** (MY→malaysia id2, GH→ghana id3) + its group + store, make it default, delete
the rest.

Order of operations (`scripts/reduce_single_store.php <keepStore> <keepGroup> <keepWebsite>`):
1. `mysqldump | gzip > /root/mms_<c>_pre_store_reduction.sql.gz` (reversible — same host).
2. **Pre-flight `products per website`.** The survivor website may be under-linked — MY's
   malaysia had only **205 of 494** courses; the other 289 sat on website 1 (base). BEFORE
   deleting website 1: `INSERT IGNORE catalog_product_website SELECT product_id,<keepWebsite>
   FROM catalog_product_website WHERE website_id=1 AND sku NOT LIKE 'TGS-%'` → reindex → verify
   the live category counts grew. (GH already had 494 on website 3.)
3. Run the reduction: repoints defaults to survivor, then `FK_CHECKS=0` + DELETE every
   `store_id`/`website_id` row for the deleted ids across ALL tables (info_schema-driven, never
   id 0/survivor) + config scope rows + the topology rows. This is the orphan cleanup that
   `feedback_store_delete_orphans_and_infoschema_migration_502` demands (else admin grids
   "Invalid store code" crash).
4. Reindex ALL + flush. Verify homepage/category/product/admin = 200, 0 fatals, catalog count
   held.

**Run it DETACHED** — on GH the info_schema DELETE loop exceeds 2 min (big mmd_audit_issues /
url_rewrite), and a plain `docker exec` over SSH gets **killed when the SSH client times out**
(buffered output lost → looks like a no-op; it made 0 changes because it never reached the
first write): `docker exec -d $WEB sh -c 'php /tmp/reduce.php 3 3 3 > /tmp/reduce.log 2>&1'`,
then poll the log for `REMAIN websites`. Partner containers also **get recreated by Coolify
every 1–2 min** (name suffix changes, `/tmp` wiped, brief 503s) — re-`docker ps` each step.
See `feedback_partner_single_store_reduction`.

## 12b. Sitemap + robots (durable) — media volume, not docroot

Partner `/sitemap.xml` + `/robots.txt` are the **baked SG copies** (robots hardcodes the
com.sg sitemap; the served sitemap lists com.sg URLs). Only `/var/www/html/media` is a
persistent volume — **docroot edits revert on every redeploy** (frequent here). Durable fix,
DB+media only:
```php
$s = Mage::getModel('sitemap/sitemap')->load(<rowId>);   // MY row store2; GH pick the ghana row (store3)
$s->setSitemapFilename('sitemap.xml')->setSitemapPath('/media/')->save();
$s->generateXml();   // /var/www/html/media/sitemap.xml — own-domain locs, survives redeploys
```
→ `https://www.<partner>/media/sitemap.xml` (200, own domain). **Submit THAT URL in GSC.**
`cp` it to docroot + `sed` robots for immediate correctness, but both revert on redeploy; the
only permanent robots/root-sitemap fix is a host-aware repo change or a Coolify persistent
mount. `.htaccess` is already brotli/gzip/mod_expires/HSTS/faceted-noindex — leave it (shared
baked file; a change would hit SG). See `feedback_partner_sitemap_robots_media_volume`.

## 13. Schema migrations (when a change belongs in the repo, e.g. an SG/all-site change)

Most partner work is DB-only. But if a change is genuinely shared (SG + all partners), it
goes through the repo migration runner — and that runner is a **production tripwire**:

- Drop numbered `migrations/NNN-foo.sql`; `docker/entrypoint.sh` runs `migrations/apply.php`
  on deploy, tracked in `schema_migrations`. **Dry-run the REAL apply.php, never the mysql
  client** (`docker exec <web> php /var/www/html/migrations/apply.php`). apply.php's PDO is
  `charset=utf8` and ABORTS the whole chain on the first failed statement → container exits →
  **every host 502s**. The mysql client connects latin1 and hides the bug.
- **UTF-8**: any INSERT pulling from legacy tables (catalogsearch_query, old EAV) MUST be
  UTF-8-sanitised or apply.php dies `1366 Incorrect string value '\x96…'`. Cheapest filter for
  ASCII: `WHERE LENGTH(col)=CHAR_LENGTH(col)`. `QUOTE()` does NOT fix it.
- **Country-instance drift**: partner DBs LACK some SG-only tables (e.g. `smtppro_email_log`).
  Guard every table-touching stmt with `information_schema` existence check + `PREPARE`/`DO 0`,
  `FOREIGN_KEY_CHECKS=0`. A bare DELETE 502'd GH/MY/NG once. After a migration push, check
  `.com.my/.gh` too — not just SG.
- **Idempotent always**: `INSERT IGNORE` / `ON DUPLICATE KEY UPDATE`; `apply.php` splits on
  `;`-at-end-of-line so multi-line string values must not end a line with `;`.
- CMS-block `REPLACE()` migrations: generate hex/base64 PROGRAMMATICALLY (never hand-copy
  multi-KB hex); use `UNHEX()`/`FROM_BASE64` to bypass MySQL backslash-escape ambiguity.
- Encrypted config columns need `Mage::helper('core')->encrypt()` before save.
See memories `feedback_migration_applyphp_utf8_outage`, `feedback_migration_country_instance_table_differences`,
`feedback_apply_php_sql_splitter`, `feedback_db_sync_via_migration`, `feedback_cms_block_hex_replace_generate_programmatically`.

## 14. Course options + schedules (MMD_CustomOptions templates) — import from SG by SKU

Course-page options (Course Date, Course Time, Mode of Training, Sponsorship,
Additional Message) render via the **MMD_CustomOptions "custom option template"**
extension, NOT plain per-product options. A fresh MY/GH clone often has the
`custom_options_group`/`custom_options_relation` tables **EMPTY** → every course
shows a BLANK options area even though `catalog_product_option` rows exist. Fix =
replicate SG's option subsystem to the partner by SKU (partners are C-prefix SG
clones → SKUs match 1:1; verified 494/494 for MY and GH).

**Data model:** `custom_options_group` = a schedule TEMPLATE (`A01`…`E04` =
duration buckets A=1day…E=5day). `custom_options_relation(group_id,product_id,
option_id)` links a course to a group. Options are normal `catalog_product_option`
rows (product_id = course) with an `in_group_id` DISPLAY id (≠ group_id). The
dates/times are that option's `_type_value`/`_type_title` rows.

**THE gotcha — `custom_options_option_view_mode`.** The rewritten frontend
collection (`Model/Catalog/Product/Option.php` ~1325) DROPS every option whose
`view_mode==0`/absent ("0-Disable"). Import without a view_mode row = invisible
options. `has_options` is NOT the gate (SG renders with it unset).

**Import procedure (partner-DB-only; read SG from local backup):**
1. Build filter temp tables in the backup: `_f_opt` = option_ids of the shared
   products, `_f_type` = their option_type_ids.
2. `mysqldump` (flags: `--skip-lock-tables --no-tablespaces` and NO
   `--single-transaction`, else it HANGS at 0 bytes — the `magento` user lacks
   PROCESS/LOCK): `catalog_product_option(+_title,_price,_type_value,_type_title,
   _type_price)`, `custom_options_relation`, `custom_options_group(+_store)`, and
   the satellites **`custom_options_option_view_mode`,`_default`,`_description`**.
   Filter big tables via the small indexed temp-table subquery, never a 90 KB
   literal `IN(...)` arg.
3. On the partner: `SET FOREIGN_KEY_CHECKS=0`, DELETE those tables, load the dump
   (option_id/type_id/group_id preserved — no collision, tables were wiped), then
   remap ONLY `product_id` (SG→partner by SKU) in `catalog_product_option` +
   `custom_options_relation` via a `_idmap(sg_id,new_id)` temp-table JOIN. All
   other tables carry no product_id → verbatim.
4. Flush Redis (`getCacheInstance()->flush()`); curl a course page, expect 5
   `options[NNN]` form fields. CLI `getOptions()` FATALS ("Unable to start
   session" — module calls customer/session) — verify via HTTP, not CLI.
5. Relabel value titles per partner with plain `UPDATE/DELETE` on
   `catalog_product_option_type_title` keyed by the unique value string; when
   merging values (e.g. Sponsorship 4→2) dedup by keeping `MIN(option_type_id)`
   per option_id.

Options auto-flow into the **order email**: the `convertQuoteItemToOrderItem`
observer copies them to the order item; `email/order/items/order/default.phtml`
renders `getItemOptions()`. GH SSH: key rejected → use the `.env` `# GH SSH #PW:`
password via `sshpass`. See memory
`feedback_partner_course_options_via_custom_option_templates`.

## 14b. Course-page DEADSPACE after hiding WSQ cards → tabs `clear:none`

Hiding the SG WSQ funding cards (§6, `.course-policy-card--wsq{display:none}`)
shrinks the product page's left/center column. The bottom tabs
(`.product-view > .box-additional`, "Course Details / Info / …") use
`clear: both` (custom.css:613) which is tuned for SG where the left+center stack
(Certification + WSQ policy cards) is the TALLEST column. With WSQ hidden, the
right booking sidebar (Course Fee + options + gallery) becomes tallest, so
`clear:both` drops the tabs BELOW it → a large empty gap above the tabs. The
theme author documented the remedy inline: flip to `clear:none`. Apply
partner-scoped (never repo — SG must keep `clear:both`) by appending to the
partner `design/head/includes`:
`<style>.product-view > .box-additional{clear:none !important;}</style>` then
flush. Verify by eyeball (no Playwright — it hijacks the user's Chrome).

## 15. "Recommended Courses" block = Up-sell links (link_type_id=4)

The product-page "Recommended Courses" carousel is the Ultimo/theme rendering of
Magento **up-sell** products (`catalog_product_link` link_type_id=4), tabbed with
Related in `catalog/product/view.phtml`. A fresh MY/GH clone has **0** upsells so
the block is empty. Populate 5 per course (partner-DB-only):
- Generate 5 RELATED courses per course = pick from products sharing a SPECIFIC
  (small, size ≤60) category; fall back to broader categories, then random. Skip
  self-links; keep deterministic per product (`random.Random(product_id)`).
- Apply: `DELETE` existing link_type_id=4 (+ their `catalog_product_link_attribute_int`
  rows), `INSERT INTO catalog_product_link(product_id,linked_product_id,link_type_id=4)`,
  then `INSERT INTO catalog_product_link_attribute_int(product_link_attribute_id=4,
  link_id,value=0) SELECT ... WHERE link_type_id=4` for the position attr (SG uses 0).
- No reindex needed (links read directly); just flush Redis. Verify the course page
  shows the "Recommended Courses" heading + product tiles.
Do NOT copy SG's upsells verbatim — SG upsells link to WSQ (`TGS-`) courses that
don't exist on partners → broken tiles. Generate from the partner's own catalog.

## 15b. Strip SG-only add-on options + add MY HRD Corp branding

- **Remove SG-only add-on options** the import brought over that don't apply to a
  partner (e.g. "Exam Voucher" upsells). Delete by option title: collect
  `option_id`s where `catalog_product_option_title.title LIKE '%Voucher%'`, then
  delete their rows across `catalog_product_option(+_title,_price,_type_value,
  _type_title,_type_price)`, `custom_options_relation`, and the
  `custom_options_option_view_mode/_default/_description` satellites. Flush.
- **MY HRD Corp logos** (Malaysia only — HRD Corp is MY). Official seals:
  Claimable + "Registered Training Provider". Source clean transparent PNGs
  (fedelis.asia / modoku.tech host them), optimize with Pillow (the official
  Claimable PNG is 17344² — set `Image.MAX_IMAGE_PIXELS=None`), `rclone` to R2
  `wysiwyg/`. Place PARTNER-DB-ONLY: Claimable seal → inject into the HRDF card
  in `design/head/includes` (float:right img in the injected card HTML; rewrite
  the whole head value via base64 to dodge quote-hell); Registered-Training-
  Provider seal → the MY `home` + `about-us.html` cms_page content (base64
  UPDATE). Flush + verify by eyeball.

## 15c. Enquiry forms + footer "Enquiries" menu

Enquiry forms (Course Feedback, Trainer/Associate, Corporate On-Site, Customised,
Reschedule) are **CMS pages** whose content is just an intro `<div>` +
`{{block type="core/template" template="mmd_<module>/form.phtml"}}`. The templates
+ controllers (`mmd_coursefeedback`,`mmd_trainer`,`mmd_corporate`,`mmd_customised`,
`mmd_reschedule` → `<frontName>/index/post`) are SHARED repo code (exist on every
site), so creating a form on a partner is DB-only: `INSERT cms_page`
(root_template `one_column`, identifier `slug.html`, content via base64) +
`INSERT cms_page_store (page_id,<store or 0>)`. No url_rewrite needed — the CMS
router matches the identifier. Leads land in each module's admin grid.
- The footer **"Enquries"** column lives in cms_block `block_footer_row2_column5`
  (per-store: MY=33, GH=52, SG=1). Rewrite the `<ul class="bullet">` after the
  `Enquries</h6>` heading; links use `{{store url=''}}slug.html`.
- A partner clone may point these footer links at **Google Forms**
  (`docs.google.com/forms/...`) — replace with the native cms_page links.
- For a form with NO dedicated module (e.g. a simple Refund Request), don't add a
  module (repo change). Put a styled HTML form (reuse the reschedule `tcs-*` CSS)
  in the cms_page posting to core `{{store url='contacts/index/post'}}`, and
  assemble the custom fields (Course Title/Code/Date/Reason) into the `comment`
  field via a tiny inline JS `onsubmit` so they show in the contact email.

## 16. Seed course reviews (4-5 star) on a partner

A fresh partner has an EMPTY `rating` table (single-store reduction purged it) →
every course shows "Be the first to review". To seed 5-10 approved 4-5★ reviews
per course (partner-DB-only):
1. Recreate SG's 3 rating dimensions: `rating_entity`(1 product,2 product_review,
   3 review), `review_entity`(1 product,…), `rating`(ids 1,2,5 = expectation /
   trainer / environment), `rating_option` (5 per rating: ids 1-5, 6-10, 21-25 =
   value 1-5), `rating_store` (each rating → store 0 AND the partner store:
   MY=2, GH=3).
2. Per product insert `review`(entity_id=1, entity_pk_value=product, status_id=1
   approved), `review_detail`(store_id=partner, title/detail/nickname — use
   country-appropriate names), `review_store`(review→store), and 3
   `rating_option_vote` (one per rating; value 4|5, option_id = base+value-1,
   percent = value*20). Tables are empty → assign explicit sequential PKs.
3. Aggregate so stars/count DISPLAY: `review_entity_summary`(entity_pk_value,
   entity_type=1, reviews_count, rating_summary = avg percent, store rows for the
   partner store AND store 0) + `rating_option_vote_aggregated` per rating. Flush
   Redis; the product page reads review_entity_summary (rating_summary/20 = stars).
Keep dates ≤ today (no future-dated reviews). Verify a course shows N reviews and
4.x stars; confirm SG still shows ITS OWN counts (untouched).

## 17. MailerLite newsletter list (each partner owns their own list)

Order emails are pushed into a MailerLite subscriber group daily at 04:00 by
`mmd_marketing/cron_subscribersync`. **Every parameter is a Company Setting —
nothing about SG is hardcoded**, so a partner points the sync at THEIR list:

Admin → Dashboard → Company Setting → Integrations → **MailerLite**
| Field | Config path | Notes |
|---|---|---|
| MailerLite API Key | `mmd_company/mailerlite/api_key` | the partner's OWN MailerLite account key |
| Subscriber Group ID | `mmd_company/mailerlite/group_id` | **no default** — blank = sync refuses to run |
| Store ID | `mmd_company/mailerlite/store_id` | blank = current store (SG=1, MY=2, GH=3) |
| Daily Sync Enabled | `mmd_company/mailerlite/sync_enabled` | `1`/`0`, default **0** (inert until enabled) |

**Why there is deliberately NO fallback group**: defaulting to the SG group would
push a partner's learners into Singapore's list, and a subscriber import cannot be
un-sent. `getSyncGroupId()` returns `''` when unset and every caller treats that as
"do not sync" — keep it that way.

**Opt-outs are never re-added.** `POST /subscribers` is an UPSERT, so blindly
posting an address that unsubscribed resurrects it (a compliance breach).
`getSuppressedEmails()` pages the account's `unsubscribed`/`bounced`/`junk`
subscribers and the sync skips them. On the SG backfill this filtered 178 of
1,064 addresses — not a rounding error, so never "optimise away" that pre-fetch.

Historical backfill (run ONCE per site, always `--dry-run` first):
```bash
docker exec <web> php /var/www/html/scripts/maintenance/mailerlite-import-order-emails.php \
    --since=2026-01-01 --dry-run      # then re-run without --dry-run
# --group= / --store= override the Company Settings for a one-off import
```
Only the learner **email** (+ first/last name for personalisation) is ever sent —
no order, payment or password data. Log: `var/log/mailerlite.log`.
Group IDs are discoverable via `GET /api/groups` with that account's key.

**Rotating the API key**: paste the new key into the Company Setting field and save
(the admin save clears the config cache, so the next 4am run uses it). The Company
Setting **wins** over the legacy `mmd_marketing/api/mailerlite_key` path — that
precedence is deliberate, so rotating in the admin can't be silently ignored by an
older key still sitting in the legacy row.

**Daily monitoring — "did the emails really get added?"**
```bash
docker exec <web> php /var/www/html/scripts/maintenance/mailerlite-sync-status.php
# exit 0 = healthy, exit 1 = needs attention (drives a cron/monitor)
```
It prints the last run's recorded outcome AND independently queries the MailerLite
API to confirm the most recent order emails are really in the group — a cron
reporting success while the API rejects everything is the failure mode that matters.
Flags a missed run (>26h old), a disabled sync, a missing key/group, and any recent
order email absent from the group. `status=unsubscribed` while still group-listed is
CORRECT (they simply won't be mailed), not a fault. Real failures also email the
marketing reviewers; "added 0" and MailerLite refusing an opt-out do not alert.

## Deploy / ops gotchas (partner servers on Coolify)

- Partner sites auto-deploy on push to `main` via each Coolify instance's GitHub App source.
- Claude CAN'T trigger/watch Coolify deploys (no webhook in repo) — recovery is human-in-dashboard.
- After a push, watch `/version.txt` + poll the homepage until 200 (a failed migration = 502).
- No blocking work in `entrypoint.sh` before `exec apache2-foreground` (stalls healthcheck → 502).
- Coolify exit-255 = SSH-mux reaper (`SSH_MUX_ENABLED=false`); site 000 on 443 = Traefik
  wrong-network (`traefik.docker.network=${COOLIFY_RESOURCE_UUID}` label). Memories
  `feedback_coolify_ssh_mux_deploy_255`, `feedback_coolify_traefik_network_pin`,
  `feedback_entrypoint_blocking_step_502`, `feedback_no_cron_invocation_in_repo`.

## Bundled scripts (`scripts/` — copy, set the vars at top, run)

| Script | What it does |
|--------|--------------|
| `scripts/lib.sh` | Connection helpers: `gq`/`gsql` (partner query/apply via stdin), `reindex_flush`, `sgq` (SG backup read), `r2` (rclone to R2). Source it first. |
| `scripts/catalog_diff.sh` | SKU diff (products) + url_key diff (categories) SG↔partner; missing/extra reports. |
| `scripts/gen_create_categories.py` → `create_categories.php` | Generate + run the `catalog/category` model creation for categories SG has that the partner lacks. |
| `scripts/sync_names_positions.py` | Emit UPDATEs to set partner category `name`+`position` = SG (by url_key). |
| `scripts/sync_inmenu_umm.sql` | Enable `include_in_menu` on the 4-root subtree + copy `umm_dd_*` mega layout. |
| `scripts/sync_category_media.py` | Sync `image`(45)+`description`(44 text) SG→partner by url_key (handles TO_BASE64 wrapping). |
| `scripts/sync_product_categories.py` | Sync `catalog_category_product` (SKU×url_key): add missing + delete extra, count-safe. |
| `scripts/currency_rate.sql` | Insert the local↔USD `directory_currency_rate` rows. |
| `scripts/remove_funding.sql` | head-includes CSS (course + blog funding) + `core_translate` popup text swap. |
| `scripts/font_inline.py` → `font_inline.sql` | Fetch Oswald woff2, inline as base64 data URI into `design/head/includes`. |
| `scripts/blog_generator.py` | Build the DELETE-SG + INSERT-partner-posts SQL from a post list (funnels to partner courses). |
| `scripts/reduce_single_store.php` | Collapse the 6-store clone to ONE store (args: keepStore keepGroup keepWebsite). Repoints defaults, purges all store/website/scope rows (FK_CHECKS=0) + topology. Back up + link catalog to survivor website FIRST; run DETACHED (§12). |

Read `references/migrations.md` and `references/fonts.md` for the deep dives.

## Verification checklist (curl the partner prod, expect these)

- Homepage/menu 200; mega-menus show child items with SG labels; product count unchanged.
- Category pages 200 with banner image (final 200 after R2 redirect) + description.
- Currency switcher shows local + USD.
- 0 occurrences of `WSQ`/`SkillsFuture`/`.com.sg` in partner course/blog visible text
  (nav url_keys containing "skillsfuture" are harmless slugs).
- Header nav contact = icon-only (ic-phone / ic-letter / currentColor WhatsApp SVG), no words.
- WhatsApp launcher + header + footer present; blue icon; popup says "Course Info".
- Blog lists partner posts only; each funnels to a partner course page.
- Exactly ONE non-admin store/group/website remains, set default; own-domain sitemap at
  `/media/sitemap.xml` (200); admin + all pages 200 with 0 fatals.
- After every change: reindex `catalog_category_flat` (+`catalog_category_product`) + flush.

## Related memories (the source incidents, with exact SQL)
`feedback_gh_changes_never_touch_sg_hard_rule`, `project_franchise_one_store_per_site`,
`feedback_partner_single_store_reduction`, `feedback_partner_sitemap_robots_media_volume`,
`feedback_ultimo_megamenu_match_sg`, `feedback_category_banners_on_r2`,
`feedback_partner_banners_via_direct_r2_url`, `feedback_ultimo_google_font_serif_fallback`,
`feedback_gh_whatsapp_currency_homepage_config`, `feedback_store_delete_orphans_and_infoschema_migration_502`,
`reference_gh_server_access`, `reference_sg_server_access`, `feedback_flat_catalog_reindex`,
`feedback_magento_cache_lives_in_redis`.
