#!/usr/bin/env python3
"""Set partner category name+position = SG, matched by url_key (clean nav labels + order).
url_key/URLs stay untouched (no SEO churn). PARTNER-DB-ONLY.

Inputs:
  sg_names.tsv        : url_key <TAB> position <TAB> name   (SG 4-root subtree)
  partner_uk_id.tsv   : url_key <TAB> entity_id             (partner)
Output: names_positions.sql  (apply; then reindex catalog_category_flat + flush)
NAME_ATTR = the category 'name' attribute_id (usually 41 — confirm per DB).
"""
import sys
W = sys.argv[1] if len(sys.argv) > 1 else "/tmp/parity"
NAME_ATTR = int(sys.argv[2]) if len(sys.argv) > 2 else 41
gh = {}
for l in open(f"{W}/partner_uk_id.tsv"):
    p = l.rstrip("\n").split("\t")
    if len(p) >= 2: gh[p[0]] = p[1]
esc = lambda s: s.replace("\\", "\\\\").replace("'", "''")
out = []
for l in open(f"{W}/sg_names.tsv"):
    p = l.rstrip("\n").split("\t")
    if len(p) < 3: continue
    uk, pos, name = p[0], p[1], p[2]
    if uk not in gh: continue
    eid = gh[uk]
    out.append(f"UPDATE catalog_category_entity SET position={int(pos)} WHERE entity_id={eid};")
    out.append(f"UPDATE catalog_category_entity_varchar SET value='{esc(name)}' WHERE entity_id={eid} AND attribute_id={NAME_ATTR} AND store_id=0;")
open(f"{W}/names_positions.sql", "w").write("\n".join(out) + "\n")
print(f"wrote {len(out)} statements -> {W}/names_positions.sql")
