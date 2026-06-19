# Memory index

Grouped by topic. Pointers only — full content lives in the linked files.

## Admin UI / theme

- [<button> as a card row needs text-align:left + inherit](feedback_button_as_card_needs_text_align_left.md) — UA button defaults center the label and override fonts; also force wrapping `<form>` to display:block when it carries width:100%
- [Chrome icons need !important across the board](feedback_chrome_icons_need_important.md) — bare-glyph topbar icons lose to the generic admin button rule unless every visual property carries !important
- [Index Management + Cache Management row checkboxes are hidden](feedback_admin_hidden_row_checkboxes.md) — mass-action workflow does not work; provide a dedicated controller action instead
- [Varien mass-action needs checkbox.click()](feedback_varien_massaction_checkbox_click.md) — assigning .checked = true leaves the JS object at 0 selected; submit then alerts "no items selected"
- [Admin grid ?store= filter must run in _beforeLoadCollection](feedback_admin_grid_store_filter_before_load.md) — parent::_prepareCollection calls load() before addStoreFilter; SQL bakes store_id=0 unless hooked earlier
- ["Edit Course" page is NOT standard product-edit](feedback_dcf_editor_not_standard_product_edit.md) — dcf editor in dashboard/index.phtml hand-renders fields; EAV migration alone won't surface them

## Storefront (Ultimo theme)

- [Ultimo .box-additional clear policy](feedback_ultimo_box_additional_float_clear.md) — pick clear:both vs clear:none based on which product-view column is currently tallest (right-column dominant now → clear:none)
- [Mobile box-additional hide must be direct child](feedback_mobile_box_additional_hide_must_be_direct_child.md) — `.product-view > .box-additional` for bottom-tabs hide; unqualified `.box-additional` also kills options + Register CTA in the right column
- [phtml variable hoisting](feedback_phtml_variable_hoisting.md) — PHP 8 silently treats undefined vars as null in `if ($undef && …)`, so misordered phtml gates falsy-bypass without warning; hoist every referenced var above its first consumer
- [Quote-item product is a lite load](feedback_quote_item_product_lite_load.md) — `$item->getProduct()->getData($customAttr)` returns NULL in cart/checkout; re-fetch via `getAttributeRawValue` instead
- [Per-course course sections live in cms/block, not short_description regex or EAV](feedback_per_course_cms_block_sections.md) — id pattern `course_<sku>_<section>`; WSQ fees auto-calc, never enter manually
- [short_description has Unicode whitespace](feedback_short_description_unicode_whitespace.md) — Microsoft-pasted markup contains U+202F / NBSP before close tags; use Unicode-aware whitespace class with /u, not bare \s
- [Funding badges live in Magento tag system, not EAV](feedback_funding_badges_via_tags.md) — storefront chips read tag_relation; cover dialog writes via syncProductTags
- [Product `name` is sacred — never modify in templates](feedback_product_name_is_sacred.md) — H1, JSON-LD name, list tiles all echo `$_product->getName()` verbatim. SEO suffixes go in meta_title only
- [Live contact form template](reference_contact_form_template.md) — it's the ultimo contacts/form.phtml (recaptcha override has been removed)

## EAV / catalog data

- [Flat catalog must be reindexed after attribute writes](feedback_flat_catalog_reindex.md) — saveAttribute alone leaves storefront stale; reindex catalog_product_flat + flush block_html/FPC/collections
- [CLI saveAttribute writes at SG scope, not admin](feedback_eav_save_attribute_scope.md) — bulk migrations must target store_id=0 and clear per-store overrides; localhost curl with Host header 301s to prod
- [EAV multiselect needs source_model](feedback_eav_multiselect_source_model.md) — set source_model='eav/entity_attribute_source_table' or getSource() throws and admin dropdown is empty
- [catalogsearch_query.synonym_for is NULL not ''](feedback_catalogsearch_synonym_for_is_null.md) — `WHERE synonym_for = ''` matches zero rows; use `(synonym_for IS NULL OR synonym_for = '')` for both filters and migrations

## Migrations / DB sync

- [DB sync via migration scripts](feedback_db_sync_via_migration.md) — never propose dump/restore; always write a reviewable SQL migration
- [apply.php splits .sql on semicolon-at-end-of-line](feedback_apply_php_sql_splitter.md) — multi-line string values must never have a content line ending in ";"; guard rewrites with MD5(value)
- [Migration generator skipped strip-SQL when local was already migrated](feedback_migration_generator_skipped_strip.md) — emit unconditional strip statements; use UNHEX() for REPLACE() to bypass MySQL backslash-escape ambiguity
- [Encrypted config columns need explicit encrypt() before saveConfig](feedback_encrypted_config_column_save.md) — direct saveConfig bypasses backend_model, so plaintext writes corrupt the row and getStoreConfig returns garbage

## Email / lead capture

- [Custom email templates need a seeded core_email_template row](feedback_transactional_email_template_seeding.md) — config.xml file template alone is invisible in System → Transactional Emails; seed the DB row + config pointer
- [Lead auto-reply must brand and recommend per store](feedback_auto_reply_per_store.md) — seed general/store_information/name per store scope; pair setStoreId() with addStoreFilter() on the recommender collection
- [Auto-reply brand via {{var store_brand}}, not store.frontend_name](feedback_auto_reply_store_brand_var.md) — PHP-injected per-store-code map is immune to missing config; editing .html alone won't change prod — must migrate template_text in core_email_template

## SEO / multi-store

- [Cross-store SEO needs hreflang + per-host sitemaps together](feedback_seo_hreflang_per_store_sitemap.md) — head.phtml cluster, .htaccess sitemap rewrites, and generate-sitemaps.php must all ship as one unit, or MY/NG/GH stay invisible to Google
- [WSQ courses = TGS- SKU prefix](reference_wsq_course_tgs_sku.md) — the SKU is the SkillsFuture course reference; powers the lead auto-reply recommender
- ["Indexed though blocked by robots.txt" needs unblock + X-Robots-Tag noindex](feedback_apache_rewrite_e_flag_redirect_prefix.md) — robots.txt Disallow keeps the URL indexed (Google can't see noindex); Allow + RewriteRule [E=noindex_url:1] + Header env=REDIRECT_noindex_url is the pattern. Don't forget the REDIRECT_ prefix after the front-controller rewrite

## Ops / dev workflow

- [Repo root must stay clean](feedback_repo_root_must_be_clean.md) — no screenshots, scratch scripts, tmp/ dirs, or stale duplicates in repo root; save Playwright PNGs to /tmp not project root
- [Localhost curl + Host header follows 301 to prod](feedback_localhost_curl_host_header_redirects.md) — `curl -L http://localhost:8080 -H 'Host: tertiarycourses.com.sg'` reads PROD, not local. Drop -L or drop Host header when verifying local changes.
- [HTTP 500 on every route after container restart → mod_headers dropped](feedback_apache_500_mod_headers.md) — diagnostic checklist; permanent fix lives in docker/entrypoint.sh

## Multi-country instances

- [Country DB seed drift can break guest pricing and category menus per-country](feedback_country_seed_drift_menu_and_guest_pricing.md) — each country runs its own DB cloned from a seed; missing `customer_group_id=0` row and `include_in_menu=0` on nav categories silently break one country's storefront while looking like "nothing renders, no errors"

## External references

- [Magento.md — site customization playbook](../../../../../projects/tertiary/ai-mms/Magento.md) — repo-root field notebook on the non-obvious parts of this OpenMage install
