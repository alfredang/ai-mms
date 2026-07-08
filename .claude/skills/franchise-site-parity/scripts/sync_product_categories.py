#!/usr/bin/env python3
"""Sync catalog_category_product SG -> partner (product by SKU, category by url_key).
ADD missing + DELETE extra so the partner's assignments == SG (for partner-existing cats).
Deleting an assignment NEVER deletes the course. PARTNER-DB-ONLY.

Inputs (dump first):
  desired_pos.tsv       : sku <TAB> url_key <TAB> position   (SG assignments for shared products & partner-existing cats)
  partner_cur.tsv       : sku <TAB> url_key                  (partner CURRENT assignments)
  partner_sku_id.tsv    : sku <TAB> product_id               (partner)
  partner_uk_id.tsv     : url_key <TAB> category_id          (partner)
Output: prodcat_sync.sql   (apply; then reindex catalog_category_product + catalog_category_flat + flush)
SAFETY: after apply, assert partner catalog_product_entity COUNT is unchanged, and per-category counts == SG.
"""
import sys
W = sys.argv[1] if len(sys.argv) > 1 else "/tmp/parity"
def load2(f):
    d = {}
    for l in open(f):
        p = l.rstrip("\n").split("\t")
        if len(p) >= 2: d[p[0]] = p[1]
    return d
sku2id, uk2id = load2(f"{W}/partner_sku_id.tsv"), load2(f"{W}/partner_uk_id.tsv")
pos = {}
desired = set()
for l in open(f"{W}/desired_pos.tsv"):
    p = l.rstrip("\n").split("\t")
    if len(p) < 3: continue
    desired.add((p[0], p[1])); pos[(p[0], p[1])] = p[2]
current = set(tuple(l.rstrip("\n").split("\t")[:2]) for l in open(f"{W}/partner_cur.tsv") if "\t" in l)
add, rem = desired - current, current - desired
out = []
for sku, uk in rem:
    if sku in sku2id and uk in uk2id:
        out.append(f"DELETE FROM catalog_category_product WHERE category_id={uk2id[uk]} AND product_id={sku2id[sku]};")
for sku, uk in add:
    if sku in sku2id and uk in uk2id:
        out.append(f"INSERT INTO catalog_category_product (category_id,product_id,position) VALUES ({uk2id[uk]},{sku2id[sku]},{int(pos.get((sku,uk),'0'))}) ON DUPLICATE KEY UPDATE position=VALUES(position);")
open(f"{W}/prodcat_sync.sql", "w").write("\n".join(out) + "\n")
print(f"ADD={len(add)} DELETE={len(rem)} statements={len(out)} -> {W}/prodcat_sync.sql")
