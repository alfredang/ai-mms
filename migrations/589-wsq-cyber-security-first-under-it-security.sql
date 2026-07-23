-- Move "WSQ Cyber Security & PDPA" to be the FIRST child of "WSQ IT & Security Courses".
-- Resolved BY NAME (partner DBs may use different entity_ids), guarded so it is a no-op
-- where either category is absent. Idempotent: positions are recomputed, not incremented.

SET @it_sec := (
    SELECT e.entity_id
    FROM catalog_category_entity e
    JOIN catalog_category_entity_varchar v
      ON v.entity_id = e.entity_id AND v.store_id = 0
    JOIN eav_attribute a
      ON a.attribute_id = v.attribute_id
     AND a.attribute_code = 'name'
     AND a.entity_type_id = 3
    WHERE v.value = 'WSQ IT & Security Courses'
    LIMIT 1
);

SET @cyber := (
    SELECT e.entity_id
    FROM catalog_category_entity e
    JOIN catalog_category_entity_varchar v
      ON v.entity_id = e.entity_id AND v.store_id = 0
    JOIN eav_attribute a
      ON a.attribute_id = v.attribute_id
     AND a.attribute_code = 'name'
     AND a.entity_type_id = 3
    WHERE v.value = 'WSQ Cyber Security & PDPA'
    LIMIT 1
);

-- Push every existing sibling down one slot (renumber from their current order).
UPDATE catalog_category_entity e
JOIN (
    SELECT entity_id, (@r := @r + 1) AS pos
    FROM (SELECT @r := 1) init,
         (SELECT entity_id
          FROM catalog_category_entity
          WHERE parent_id = IFNULL(@it_sec, 0)
            AND entity_id <> IFNULL(@cyber, 0)
          ORDER BY position, entity_id) ordered
) x ON x.entity_id = e.entity_id
SET e.position = x.pos
WHERE @it_sec IS NOT NULL AND @cyber IS NOT NULL;

-- Cyber Security takes slot 1.
UPDATE catalog_category_entity
SET position = 1
WHERE entity_id = IFNULL(@cyber, 0)
  AND parent_id = IFNULL(@it_sec, 0);
