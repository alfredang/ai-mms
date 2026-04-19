-- Reset every admin_user password to "admin123".
-- Hash is Mage_Core_Helper_Data::getHash version 2 —
-- sha256(salt + password):salt — validated via validateHash on
-- OpenMage 20.x before embedding.
--
-- WARNING: this resets YOUR OWN admin password too. After this
-- migration runs, every admin logs in with "admin123".
UPDATE admin_user
SET password = '824f0e975e73a81727fb4827b87bd2ef5bf81b23b4c64d2d2eada4a900162b65:NW';
