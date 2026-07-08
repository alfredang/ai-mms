#!/usr/bin/env bash
# Diff catalog SG(local backup) vs partner. `source lib.sh` first. Writes TSVs to $WORK.
set -euo pipefail
WORK="${WORK:-/tmp/parity}"; mkdir -p "$WORK"
UKq="(SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key' AND entity_type_id=3)"

# --- products by SKU ---
sgq "SELECT sku FROM catalog_product_entity WHERE sku LIKE 'C%'" | sort -u > "$WORK/sg_c_skus.txt"
gq  "SELECT sku FROM catalog_product_entity" | sort -u > "$WORK/partner_skus.txt"
echo "SG non-WSQ(C): $(wc -l <"$WORK/sg_c_skus.txt")  partner: $(wc -l <"$WORK/partner_skus.txt")"
echo "MISSING products (SG C has, partner lacks):"; comm -23 "$WORK/sg_c_skus.txt" "$WORK/partner_skus.txt" | tee "$WORK/missing_products.txt"
echo "  (check SG status: 1=enabled port-worthy, 2=disabled skip)"

# --- categories by url_key, per 4 roots ---
# Set the SG root entity_ids (find with: sgq "SELECT e.entity_id,uk.value FROM ... WHERE uk.value IN (...)").
SG_ROOTS="${SG_ROOTS:-3 53 182 321}"   # adult software certprep bootcamp (SG ids)
COND=$(for r in $SG_ROOTS; do printf " OR e.path LIKE '1/2/%s/%%'" "$r"; done | sed 's/^ OR //')
sgq "SELECT uk.value FROM catalog_category_entity e JOIN catalog_category_entity_varchar uk ON uk.entity_id=e.entity_id AND uk.attribute_id=$UKq AND uk.store_id=0 WHERE $COND" | sort -u > "$WORK/sg_cat_urlkeys.txt"
gq  "SELECT value FROM catalog_category_entity_varchar WHERE attribute_id=$(attr_id url_key) AND store_id=0" | sort -u > "$WORK/partner_cat_urlkeys.txt"
echo "SG 4-root cats: $(wc -l <"$WORK/sg_cat_urlkeys.txt")  partner cats: $(wc -l <"$WORK/partner_cat_urlkeys.txt")"
echo "MISSING categories (SG has, partner lacks):"; comm -23 "$WORK/sg_cat_urlkeys.txt" "$WORK/partner_cat_urlkeys.txt" | tee "$WORK/missing_categories.txt"
