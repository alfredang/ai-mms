<?php
/**
 * Allows admin users to log in with either their email address or username.
 * The core login form only passes one field (name="login[username]") so we
 * resolve it to the actual admin_user row by matching email first, then
 * falling back to the original username lookup.
 */
class MMD_EmailLogin_Model_Resource_User extends Mage_Admin_Model_Resource_User
{
    public function loadByUsername($identifier)
    {
        $adapter = $this->_getReadAdapter();

        // If it looks like an email, try email first
        if (strpos($identifier, '@') !== false) {
            $select = $adapter->select()
                ->from($this->getMainTable())
                ->where('email = :id')
                ->limit(1);
            $row = $adapter->fetchRow($select, ['id' => $identifier]);
            if ($row) {
                return $row;
            }
        }

        // Fall back to original username lookup
        return parent::loadByUsername($identifier);
    }
}
