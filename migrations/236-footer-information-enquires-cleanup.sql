-- 236: Footer block 1 cleanup + consistency with the Enquiries dropdown.
--   * remove Clientele + Training Partners from the Information column
--   * remove WorkplaceTraining Enquiry (Workplace Learning removed from the menu)
--   * rename 'Regional Franchising Application' -> 'Regional Franchisee'
--   Byte-exact REPLACE() via hex from the live block; idempotent.

-- remove Clientele
UPDATE cms_block SET content = REPLACE(content, 0x0d0a3c6c693e3c6120687265663d227b7b73746f7265206469726563745f75726c3d22636c69656e74656c652e68746d6c227d7d223e436c69656e74656c653c2f613e3c2f6c693e, '') WHERE block_id = 1;

-- remove Training Partners
UPDATE cms_block SET content = REPLACE(content, 0x0d0a3c6c693e3c6120687265663d227b7b73746f72652075726c3d27277d7d656475636174696f6e616c2d706172746e6572732e68746d6c223e547261696e696e6720506172746e6572733c2f613e3c2f6c693e, '') WHERE block_id = 1;

-- remove WorkplaceTraining Enquiry
UPDATE cms_block SET content = REPLACE(content, 0x0d0a3c6c693e3c6120687265663d2268747470733a2f2f676f6f2e676c2f666f726d732f69516c307a69486a5a4b3546674946683122207461726765743d225f626c616e6b223e576f726b706c616365547261696e696e6720456e71756972793c2f613e3c2f6c693e, '') WHERE block_id = 1;

-- rename Regional Franchising Application -> Regional Franchisee
UPDATE cms_block SET content = REPLACE(content, 0x3e526567696f6e616c204672616e63686973696e67204170706c69636174696f6e3c, 0x3e526567696f6e616c204672616e6368697365653c) WHERE block_id = 1;

