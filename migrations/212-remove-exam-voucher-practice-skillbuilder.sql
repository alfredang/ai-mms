-- 212: Remove Exam-Voucher + Practice-Exam + AWS Skill Builder categories and their
--      voucher/practice products. KEEPS every *Certification Exam Prep* category and the
--      real training courses inside them (guardrail: do not touch WSQ/adult/IBF/non-WSQ courses).
--
-- Categories removed (all leaf nodes under Cert Prep Training 1/2/182):
--   Exam Vouchers : 310 Microsoft, 136 Autodesk, 434 AWS, 257 CompTIA, 295 Pearson Vue
--   Practice Exams: 251 Microsoft, 39 Autodesk, 228 Cisco, 224 AWS, 35 CompTIA,
--                   168 Cloud Computing, 421 PMP & ITIL, 276 ISC2 & ISACA, 66 Google Cloud
--   Subscription  : 83 AWS Skill Builder
-- The vendor parent cats (135/222/223/227/30/...) and the "...Certification Exam Prep"
-- cats stay. 341 "Agile & Scrum Certification Exam" is NOT touched (it holds real
-- PMP/Scrum courses, not vouchers). 113 "Pearson Vue Exams" (empty, different tree) untouched.
-- The "AND path LIKE '1/2/182/%'" clause is a safety belt against entity_id drift.

DELETE FROM catalog_category_entity WHERE entity_id IN (310,136,434,257,295,83,251,39,228,224,35,168,421,276,66) AND path LIKE '1/2/182/%';

-- Voucher products (SKU V001-V027 / VM001-VM027). Double-keyed on entity_id + SKU prefix
-- so a stale id can never delete a real course.
DELETE FROM catalog_product_entity WHERE entity_id IN (1613,1614,1615,1616,1617,1618,1619,1620,1621,1622,1623,1624,1625,1626,1627,1628,1629,1630,1631,1632,1633,1634,1635,1636,1637,1638,1639,1640,1641,1642,1643,1644,1645,1646,1831,1832,1833,1834,1835,1836,1837,1838,1840,1842,1843,1844,1845,1846,1847,1848,1849,1850,1851,1852) AND (sku LIKE 'V0%' OR sku LIKE 'VM0%');

-- Practice-exam products (SKU P001-P042).
DELETE FROM catalog_product_entity WHERE entity_id IN (1647,1648,1649,1650,1651,1652,1653,1654,1655,1656,1657,1659,1660,1661,1662,1663,1664,1665,1666,1667,1668,1669,1670,1671,1674,1675,1676,1677,1678,1679,1680,1681,1682,1683,1684,1685,1686,1687,1688,1689,1690) AND sku LIKE 'P0%';
