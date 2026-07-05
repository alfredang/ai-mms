#!/usr/bin/env python3
"""Sync category image(45,varchar) + description(44,text) SG -> partner, matched by url_key.
Images already on shared R2 (nothing to upload). PARTNER-DB-ONLY.

Inputs (dump these first — see comments):
  sg_catmedia.tsv     : url_key <TAB> image <TAB> base64(description)   (from SG local backup)
  partner_urlkey_id.tsv : url_key <TAB> entity_id                       (from partner)
Output: gh_catmedia.sql  (apply with gsql; then reindex_flush)

# --- dump commands (adjust attribute ids per DB) ---
# SG (STRIP TO_BASE64's 76-char newline wrapping or the TSV breaks):
#   sgq "SELECT uk.value, COALESCE(img.value,''),
#        COALESCE(REPLACE(REPLACE(TO_BASE64(txt.value),'\n',''),'\r',''),'')
#        FROM catalog_category_entity e
#        JOIN cce_varchar uk ON ... url_key ... store_id=0
#        LEFT JOIN cce_varchar img ON ... image(45) ... store_id=0
#        LEFT JOIN cce_text  txt ON ... description(44) ... store_id=0
#        WHERE (img.value<>'') OR (txt.value<>'')"  > sg_catmedia.tsv
# partner:  gq "SELECT value,entity_id FROM cce_varchar WHERE attribute_id=<url_key> AND store_id=0" > partner_urlkey_id.tsv
"""
import base64, sys
W = sys.argv[1] if len(sys.argv) > 1 else "/tmp/parity"
IMG_ATTR, DESC_ATTR = 45, 44   # confirm per DB
gh = {}
for l in open(f"{W}/partner_urlkey_id.tsv"):
    p = l.rstrip("\n").split("\t")
    if len(p) >= 2: gh[p[0]] = p[1]
esc = lambda s: s.replace("\\", "\\\\").replace("'", "''")
out = []
for l in open(f"{W}/sg_catmedia.tsv"):
    p = l.rstrip("\n").split("\t")
    uk = p[0]; img = p[1] if len(p) > 1 else ""; db64 = p[2] if len(p) > 2 else ""
    if uk not in gh: continue
    eid = gh[uk]
    if img:
        out.append(f"INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) VALUES (3,{IMG_ATTR},0,{eid},'{esc(img)}') ON DUPLICATE KEY UPDATE value=VALUES(value);")
    if db64:
        try: desc = base64.b64decode(db64).decode("utf-8", "replace")
        except Exception: continue
        out.append(f"INSERT INTO catalog_category_entity_text (entity_type_id,attribute_id,store_id,entity_id,value) VALUES (3,{DESC_ATTR},0,{eid},'{esc(desc)}') ON DUPLICATE KEY UPDATE value=VALUES(value);")
open(f"{W}/gh_catmedia.sql", "w").write("\n".join(out) + "\n")
print(f"wrote {len(out)} statements -> {W}/gh_catmedia.sql")
