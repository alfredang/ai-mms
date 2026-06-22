-- 225: Remove the "AWS APN Training Partner" section (We are AWS Authorised APN
--      Training Partner ...) from product short_descriptions. AWS only — Microsoft,
--      Pearson Vue and all other content are left intact. Byte-exact REPLACE() via
--      hex, content-matched so it removes the block from any product that carries
--      it (idempotent; no-op once gone).

UPDATE catalog_product_entity_text t JOIN eav_attribute ea ON ea.attribute_id = t.attribute_id AND ea.attribute_code = 'short_description' AND ea.entity_type_id = 4 SET t.value = REPLACE(t.value, 0x0d0a3c68323e4157532041504e20547261696e696e6720506172746e65723c2f68323e0d0a3c703e576520617265266e6273703b3c7374726f6e673e41575320417574686f72697365642041504e20547261696e696e6720506172746e65722e3c2f7374726f6e673e266e6273703b546f2067657420746865206f6666696369616c2063657274696669636174696f6e2c20706c65617365207265676973746572206f6e2050656172736f6e2056756520546573742043656e7465723c2f703e, '') WHERE t.value LIKE '%<h2>AWS APN Training Partner</h2>%';
