<?php
/**
 * Add a learner to a class by name + email, creating their learner account if needed.
 * Shared by the /lmslogin class-code registration and the Practice Exam self-register page.
 */
class MMD_RoleManager_Helper_Enrol extends Mage_Core_Helper_Abstract
{
    /**
     * Make sure the learner has an account, then add them to the class roster
     * (course_run_enrolments, INSERT IGNORE = idempotent).
     * @param array $run needs run_id and product_id
     * @return bool true when the learner was newly added to the roster
     */
    public function enrolLearner($name, $email, array $run)
    {
        $res     = Mage::getSingleton('core/resource');
        $read    = $res->getConnection('core_read');
        $write   = $res->getConnection('core_write');
        $adminId = (int) $read->fetchOne(
            "SELECT user_id FROM `" . $res->getTableName('admin_user') . "` WHERE LOWER(email) = ? LIMIT 1",
            array($email)
        );
        $customer = $this->loadCustomerByEmail($email);
        if (!$customer) {
            Mage::throwException('Registration is unavailable right now. Please try again later.');
        }

        if ($customer->getId()) {
            // Existing storefront learner — make sure the dashboard account exists.
            Mage::helper('mmd_accountsync')->onCustomerSaved($customer);
        } elseif ($adminId) {
            // Staff member without a storefront account: just add the learner
            // role. Creating a customer here would push its fresh password hash
            // onto their existing dashboard login (AccountSync sync).
            Mage::helper('mmd_accountsync')->_addLearnerRole($adminId, false);
        } else {
            list($first, $last) = $this->splitName($name);
            // loadByEmail() on a miss wipes the model data (website_id too),
            // so set scope explicitly — the site's one store view.
            $store   = Mage::app()->getDefaultStoreView();
            $storeId = (int) $store->getId();
            $customer->setWebsiteId((int) $store->getWebsiteId())
                ->setFirstname($first)
                ->setLastname($last)
                ->setEmail($email)
                ->setStoreId($storeId)
                ->setGroupId((int) Mage::getStoreConfig(Mage_Customer_Model_Group::XML_PATH_DEFAULT_ID, $storeId))
                ->setPassword(Mage::helper('core')->getRandomString(24))
                ->save(); // customer_save_after -> AccountSync creates the learner dashboard account
        }

        $added = $write->query(
            "INSERT IGNORE INTO `" . $res->getTableName('course_run_enrolments') . "`
                (product_id, run_id, learner_email, learner_name) VALUES (?, ?, ?, ?)",
            array((int) $run['product_id'], (int) $run['run_id'], $email, $name)
        )->rowCount() > 0;
        Mage::helper('mmd_rolemanager/handover')->noteIndependentMembership($run['run_id'], $email);
        return $added;
    }

    /** Load the storefront customer for this (single-store) site by email. */
    public function loadCustomerByEmail($email)
    {
        try {
            $websiteId = 1;
            foreach (Mage::app()->getWebsites() as $w) {
                $websiteId = (int) $w->getId();
                break;
            }
            $customer = Mage::getModel('customer/customer')->setWebsiteId($websiteId);
            $customer->loadByEmail($email);
            return $customer;
        } catch (Exception $e) {
            return null;
        }
    }

    /** "Jane Tan Mei Ling" -> ['Jane', 'Tan Mei Ling']; one word -> [word, '-']. */
    public function splitName($name)
    {
        $parts = explode(' ', $name, 2);
        return array($parts[0], isset($parts[1]) && $parts[1] !== '' ? $parts[1] : '-');
    }
}
