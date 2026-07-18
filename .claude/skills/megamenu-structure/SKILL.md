---
name: megamenu-structure
description: Control the Infortis UltraMegamenu dropdown structure on the storefront — which category levels render as MEGA multi-column panels vs CLASSIC vertical lists, via the umm_dd_type category attribute. Use when asked to "make the menu classical", "convert the mega menu", "nested dropdown should be a plain list", "child categories are missing from the menu", "the menu column is empty", "fix the mega menu", or when a category flyout renders as a grid with empty columns. Covers the level map, the level-3 trap that hides all children, the EAV+flat dual write, and the reindex/flush needed for the menu to re-render.
---

# Mega-menu structure (Infortis UltraMegamenu)

Controls whether a category's dropdown renders as a multi-column **mega** panel
or a plain vertical **classic** list.

## The attribute

`umm_dd_type` — a **varchar** category attribute (`entity_type_id = 3`).

| Value | Meaning |
|-------|---------|
| `0` | None / inherit |
| `1` | Mega drop-down |
| `2` | Classic |
| `3` | Simple |

(`Infortis_UltraMegamenu_Block_Navigation::DDTYPE_*`)

## The level map — memorise this

```
level 2  top bar panels (ADULT COURSES / Software Training / WSQ / Enquiries)  -> MEGA
level 3  columns INSIDE the panel (Infocomm Technology, Media & Design,
         Robotics & IoT, Digital Marketing, Business & Soft Skills, ...)        -> MEGA  ← must stay
level 4  items in a column (Data Management, Programming, Cyber Security, ...)  -> CLASSIC
level 5+ their children (Data Engineering, Data Quality, ...)                   -> CLASSIC
```

## ⚠️ The level-3 trap (real outage)

**A level-3 category set to Classic (`2`) renders as a BARE HEADER with NONE of
its children showing.** The mega panel lays out level-3 categories as columns; a
classic level-3 stops expanding its column and the whole sub-tree vanishes from
the menu.

Incident (2026-07-18): a migration flipped `umm_dd_type` Mega→Classic for
`level >= 3`. INFOCOMM TECHNOLOGY, DIGITAL MARKETING and BUSINESS & SOFT SKILLS
became empty column headers on the live site while the untouched (`0`) columns
kept working. Fix was to revert level-3 to Mega and re-apply the change at
`level >= 4`.

**Rule: never set level 2 or level 3 to Classic.** Classic starts at level 4.

Diagnosing "children missing from the menu": check the level and dd_type of the
empty column header — if it is level 3 and `umm_dd_type = 2`, that is the bug.

```sql
SELECT entity_id, name, level, umm_dd_type
FROM catalog_category_flat_store_1 WHERE entity_id = <CAT>;
```

## Dual write: EAV **and** flat — both are mandatory

`store_id = 0` is authoritative, but the **storefront reads the FLAT category
tables** (flat categories are enabled here) and there is **no PHP reindex hook at
deploy**. A migration must write BOTH or the menu never changes:

1. `catalog_category_entity_varchar` — store 0 **and** any per-store override
   rows (or a store scope shadows the value).
2. `catalog_category_flat_store_N` for every store on the instance
   (SG=1, MY=2, GH=3) — guard each with `information_schema` so a missing flat
   table is a no-op on sites that lack that store.

Canonical implementation: `migrations/553-menu-classical-scope-to-adult-courses.sql`
(level predicate + subtree scope). Copy it for any future dropdown-type change;
only the level predicate, subtree and target value should differ. (`549` is the
broken level>=3 version, `551` its revert, `552` the unscoped level>=4 version —
do not copy those.)

## Scope changes to ONE top-level menu — roll out in phases

Menu changes are high-visibility; do **one top-level menu at a time** and confirm
before moving on. Always constrain by **subtree path**, not level alone — a bare
`level >= 4` predicate silently changes Enquiries, Exam Prep and WSQ Courses too.

Resolve the subtree from the level-2 category **name** (ids differ per site):

```sql
SET @adult_path := (SELECT c.path FROM catalog_category_entity c
  JOIN catalog_category_entity_varchar nv ON nv.entity_id=c.entity_id AND nv.store_id=0
    AND nv.attribute_id=(SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='name')
  WHERE nv.value='Adult Courses' AND c.level=2 LIMIT 1);
SET @adult_like := CONCAT(@adult_path, '/%');   -- e.g. '1/2/3/%'
```

Then add `AND e.path LIKE @adult_like` to the EAV updates. For the flat mirror
the prepared statement must interpolate it: `CONCAT("... AND path LIKE ", QUOTE(@adult_like))`.

Verify the scope held — the OUTSIDE count must be zero:

```sql
SELECT CASE WHEN path LIKE '1/2/3/%' THEN 'inside' ELSE 'OUTSIDE' END AS scope, COUNT(*)
FROM catalog_category_flat_store_1 WHERE level>=4 AND umm_dd_type='2' GROUP BY scope;
```

```sql
SET @a_ddtype := (SELECT attribute_id FROM eav_attribute
                  WHERE entity_type_id = 3 AND attribute_code = 'umm_dd_type');

UPDATE catalog_category_entity_varchar cv
JOIN catalog_category_entity e ON e.entity_id = cv.entity_id
SET cv.value = '2'
WHERE cv.attribute_id = @a_ddtype AND cv.store_id = 0 AND cv.value = '1' AND e.level >= 4;
-- repeat for cv.store_id <> 0

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES
              WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  "UPDATE catalog_category_flat_store_1 SET umm_dd_type='2' WHERE level>=4 AND umm_dd_type='1'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
```

Flip only rows at the **current** value (`value='1'`) so inherit(`0`) rows — which
already render correctly — are never disturbed. Level-based + value-based only
(no category-id / SKU list) so the same rule applies on every partner site.
Idempotent: re-running finds nothing left to flip.

## After applying — the menu will NOT change until you do this

```php
Mage::getModel('index/process')->load('catalog_category_flat','indexer_code')->reindexEverything();
foreach (array('block_html','full_page','collections','config') as $t)
    Mage::app()->getCacheInstance()->cleanType($t);
```

On prod the caches are Redis-backed — `cleanType` covers them. The entrypoint
clears file caches only, so a deploy alone can leave the old menu cached
(see `feedback_prod_cms_migration_needs_redis_flush`).

## Verify

```sql
-- No level-3 classic (would hide children); no level-4+ mega (would nest a grid).
SELECT COUNT(*) FROM catalog_category_flat_store_1 WHERE level=3  AND umm_dd_type='2'; -- expect 0
SELECT COUNT(*) FROM catalog_category_flat_store_1 WHERE level>=4 AND umm_dd_type='1'; -- expect 0
```

Then curl the homepage and confirm the level-4 names still appear in the nav
markup (`Data Management`, `Programming`, `Cyber Security`, …). If a column
header renders with no children, re-read the level-3 trap above.

## Urgent live fix

A broken menu is user-visible immediately and waiting for a Coolify build is too
slow. Apply the corrected SQL **directly on the prod DB** through the app
container (it already holds the credentials), then flush caches — and still ship
the migration so repo and prod stay in sync:

```bash
ssh root@<prod-ip> "docker exec <app-container> php -r '
  require \"/var/www/html/app/Mage.php\"; Mage::app();
  \$w = Mage::getSingleton(\"core/resource\")->getConnection(\"core_write\");
  /* ...the UPDATEs... */
  foreach(array(\"block_html\",\"full_page\",\"collections\",\"config\",\"eav\") as \$t)
      Mage::app()->getCacheInstance()->cleanType(\$t);
'"
```

Check the running image tag against your latest commit first — a "still broken"
report is often just prod running the pre-fix build:
`docker ps --format "{{.Names}}\t{{.Image}}"`.
