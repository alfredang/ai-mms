<?php
/**
 * MMD
 *
 * NOTICE OF LICENSE
 *
 * This source file is subject to the MMD EULA that is bundled with
 * this package in the file LICENSE.txt.
 * It is also available through the world-wide-web at this URL:
 * http://www.magemobiledesign.com/LICENSE-1.0.html
 *
 * DISCLAIMER
 *
 * Do not edit or add to this file if you wish to upgrade the extension
 * to newer versions in the future. If you wish to customize the extension
 * for your needs please refer to http://www.magemobiledesign.com/ for more information
 *
 * @category   MMD
 * @package    MMD_CustomOptions
 * @copyright  Copyright (c) 2012 MMD (http://www.magemobiledesign.com/)
 * @license    http://www.magemobiledesign.com/LICENSE-1.0.html
 */

/**
 * Advanced Product Options extension
 *
 * @category   MMD
 * @package    MMD_CustomOptions
 * @author     MMD Dev Team
 */

class MMD_CustomOptions_Model_Mysql4_Product_Indexer_Price_Default extends MMD_CustomOptions_Model_Mysql4_Product_Indexer_Price_Default_Abstract 
{
    protected function _applyCustomOption() {
        if (!Mage::helper('customoptions')->isEnabled() || version_compare(Mage::getVersion(), '1.4.0', '<') || (string)Mage::getConfig()->getModuleConfig('Innoexts_AdvancedPricing')->active == 'true') return parent::_applyCustomOption();
        
        if (version_compare(Mage::getVersion(), '1.6.0', '<') || (version_compare(Mage::getVersion(), '1.10.0', '>=') && version_compare(Mage::getVersion(), '1.11.0', '<'))) {
            return $this->_applyCustomOption1510();
        }
        
        if (version_compare(Mage::getVersion(), '1.7.0', '<') || (version_compare(Mage::getVersion(), '1.11.0', '>=') && version_compare(Mage::getVersion(), '1.12.0', '<'))) {
            return $this->_applyCustomOption1620();
        }
        
        // m1700>=
        return $this->_applyCustomOption1700();
    }
    
    protected function _excludeProductsWithAbsolutePrice($select) {
        $select->join(array('p' => $this->getTable('catalog/product')),
                'i.entity_id = p.entity_id AND p.absolute_price = 0',
                array());
        return $select;
    }
    
    
    protected function _applyCustomOption1700() {
        $write      = $this->_getWriteAdapter();
        $coaTable   = $this->_getCustomOptionAggregateTable();
        $copTable   = $this->_getCustomOptionPriceTable();

        $this->_prepareCustomOptionAggregateTable();
        $this->_prepareCustomOptionPriceTable();

        $select = $write->select()
            ->from(
                array('i' => $this->_getDefaultFinalPriceTable()),
                array('entity_id', 'customer_group_id', 'website_id'))
            ->join(
                array('cw' => $this->getTable('core/website')),
                'cw.website_id = i.website_id',
                array())
            ->join(
                array('csg' => $this->getTable('core/store_group')),
                'csg.group_id = cw.default_group_id',
                array())
            ->join(
                array('cs' => $this->getTable('core/store')),
                'cs.store_id = csg.default_store_id',
                array())
            ->join(
                array('o' => $this->getTable('catalog/product_option')),
                'o.product_id = i.entity_id',
                array('option_id'))
            ->join(
                array('ot' => $this->getTable('catalog/product_option_type_value')),
                'ot.option_id = o.option_id',
                array())
            ->join(
                array('otpd' => $this->getTable('catalog/product_option_type_price')),
                'otpd.option_type_id = ot.option_type_id AND otpd.store_id = 0',
                array())
            ->joinLeft(
                array('otps' => $this->getTable('catalog/product_option_type_price')),
                'otps.option_type_id = otpd.option_type_id AND otpd.store_id = cs.store_id',
                array())
            ->group(array('i.entity_id', 'i.customer_group_id', 'i.website_id', 'o.option_id'));

        $optPriceType   = $write->getCheckSql('otps.option_type_price_id > 0', 'otps.price_type', 'otpd.price_type');
        $optPriceValue  = $write->getCheckSql('otps.option_type_price_id > 0', 'otps.price', 'otpd.price');
        $minPriceRound  = new Zend_Db_Expr("ROUND(i.price * ({$optPriceValue} / 100), 4)");
        $minPriceExpr   = $write->getCheckSql("{$optPriceType} = 'fixed'", $optPriceValue, $minPriceRound);
        $minPriceMin    = new Zend_Db_Expr("MIN({$minPriceExpr})");
        $minPrice       = $write->getCheckSql("MIN(o.is_require) = 1", $minPriceMin, '0');

        $tierPriceRound = new Zend_Db_Expr("ROUND(i.base_tier * ({$optPriceValue} / 100), 4)");
        $tierPriceExpr  = $write->getCheckSql("{$optPriceType} = 'fixed'", $optPriceValue, $tierPriceRound);
        $tierPriceMin   = new Zend_Db_Expr("MIN($tierPriceExpr)");
        $tierPriceValue = $write->getCheckSql("MIN(o.is_require) > 0", $tierPriceMin, 0);
        $tierPrice      = $write->getCheckSql("MIN(i.base_tier) IS NOT NULL", $tierPriceValue, "NULL");

        $groupPriceRound = new Zend_Db_Expr("ROUND(i.base_group_price * ({$optPriceValue} / 100), 4)");
        $groupPriceExpr  = $write->getCheckSql("{$optPriceType} = 'fixed'", $optPriceValue, $groupPriceRound);
        $groupPriceMin   = new Zend_Db_Expr("MIN($groupPriceExpr)");
        $groupPriceValue = $write->getCheckSql("MIN(o.is_require) > 0", $groupPriceMin, 0);
        $groupPrice      = $write->getCheckSql("MIN(i.base_group_price) IS NOT NULL", $groupPriceValue, "NULL");

        $maxPriceRound  = new Zend_Db_Expr("ROUND(i.price * ({$optPriceValue} / 100), 4)");
        $maxPriceExpr   = $write->getCheckSql("{$optPriceType} = 'fixed'", $optPriceValue, $maxPriceRound);
        $maxPrice       = $write->getCheckSql("(MIN(o.type)='radio' OR MIN(o.type)='drop_down')",
            "MAX($maxPriceExpr)", "SUM($maxPriceExpr)");

        $select->columns(array(
            'min_price'   => $minPrice,
            'max_price'   => $maxPrice,
            'tier_price'  => $tierPrice,
            'group_price' => $groupPrice,
        ));

        $query = $select->insertFromSelect($coaTable);
        $write->query($query);

        $select = $write->select()
            ->from(
                array('i' => $this->_getDefaultFinalPriceTable()),
                array('entity_id', 'customer_group_id', 'website_id'))
            ->join(
                array('cw' => $this->getTable('core/website')),
                'cw.website_id = i.website_id',
                array())
            ->join(
                array('csg' => $this->getTable('core/store_group')),
                'csg.group_id = cw.default_group_id',
                array())
            ->join(
                array('cs' => $this->getTable('core/store')),
                'cs.store_id = csg.default_store_id',
                array())
            ->join(
                array('o' => $this->getTable('catalog/product_option')),
                'o.product_id = i.entity_id',
                array('option_id'))
            ->join(
                array('opd' => $this->getTable('catalog/product_option_price')),
                'opd.option_id = o.option_id AND opd.store_id = 0',
                array())
            ->joinLeft(
                array('ops' => $this->getTable('catalog/product_option_price')),
                'ops.option_id = opd.option_id AND ops.store_id = cs.store_id',
                array());

        $optPriceType   = $write->getCheckSql('ops.option_price_id > 0', 'ops.price_type', 'opd.price_type');
        $optPriceValue  = $write->getCheckSql('ops.option_price_id > 0', 'ops.price', 'opd.price');

        $minPriceRound  = new Zend_Db_Expr("ROUND(i.price * ({$optPriceValue} / 100), 4)");
        $priceExpr      = $write->getCheckSql("{$optPriceType} = 'fixed'", $optPriceValue, $minPriceRound);
        $minPrice       = $write->getCheckSql("{$priceExpr} > 0 AND o.is_require > 1", $priceExpr, 0);

        $maxPrice       = $priceExpr;

        $tierPriceRound = new Zend_Db_Expr("ROUND(i.base_tier * ({$optPriceValue} / 100), 4)");
        $tierPriceExpr  = $write->getCheckSql("{$optPriceType} = 'fixed'", $optPriceValue, $tierPriceRound);
        $tierPriceValue = $write->getCheckSql("{$tierPriceExpr} > 0 AND o.is_require > 0", $tierPriceExpr, 0);
        $tierPrice      = $write->getCheckSql("i.base_tier IS NOT NULL", $tierPriceValue, "NULL");

        $groupPriceRound = new Zend_Db_Expr("ROUND(i.base_group_price * ({$optPriceValue} / 100), 4)");
        $groupPriceExpr  = $write->getCheckSql("{$optPriceType} = 'fixed'", $optPriceValue, $groupPriceRound);
        $groupPriceValue = $write->getCheckSql("{$groupPriceExpr} > 0 AND o.is_require > 0", $groupPriceExpr, 0);
        $groupPrice      = $write->getCheckSql("i.base_group_price IS NOT NULL", $groupPriceValue, "NULL");

        $select->columns(array(
            'min_price'   => $minPrice,
            'max_price'   => $maxPrice,
            'tier_price'  => $tierPrice,
            'group_price' => $groupPrice,
        ));

        $query = $select->insertFromSelect($coaTable);
        $write->query($query);

        $select = $write->select()
            ->from(
                array($coaTable),
                array(
                    'entity_id',
                    'customer_group_id',
                    'website_id',
                    'min_price'     => 'SUM(min_price)',
                    'max_price'     => 'SUM(max_price)',
                    'tier_price'    => 'SUM(tier_price)',
                    'group_price'   => 'SUM(group_price)',
                ))
            ->group(array('entity_id', 'customer_group_id', 'website_id'));
        $query = $select->insertFromSelect($copTable);
        $write->query($query);

        $table  = array('i' => $this->_getDefaultFinalPriceTable());
        $select = $write->select()
            ->join(
                array('io' => $copTable),
                'i.entity_id = io.entity_id AND i.customer_group_id = io.customer_group_id'
                    .' AND i.website_id = io.website_id',
                array());
        
        // begin customization *****
        $select = $this->_excludeProductsWithAbsolutePrice($select);
        // end customization *****
        
        $select->columns(array(
            'min_price'   => new Zend_Db_Expr('i.min_price + io.min_price'),
            'max_price'   => new Zend_Db_Expr('i.max_price + io.max_price'),
            'tier_price'  => $write->getCheckSql('i.tier_price IS NOT NULL', 'i.tier_price + io.tier_price', 'NULL'),
            'group_price' => $write->getCheckSql(
                'i.group_price IS NOT NULL',
                'i.group_price + io.group_price', 'NULL'
            ),
        ));
        $query = $select->crossUpdateFromSelect($table);
        $write->query($query);

        $write->delete($coaTable);
        $write->delete($copTable);

        return $this;
    }
  
    protected function _applyCustomOption1620() {
        $write      = $this->_getWriteAdapter();
        $coaTable   = $this->_getCustomOptionAggregateTable();
        $copTable   = $this->_getCustomOptionPriceTable();

        $this->_prepareCustomOptionAggregateTable();
        $this->_prepareCustomOptionPriceTable();

        $select = $write->select()
            ->from(
                array('i' => $this->_getDefaultFinalPriceTable()),
                array('entity_id', 'customer_group_id', 'website_id'))
            ->join(
                array('cw' => $this->getTable('core/website')),
                'cw.website_id = i.website_id',
                array())
            ->join(
                array('csg' => $this->getTable('core/store_group')),
                'csg.group_id = cw.default_group_id',
                array())
            ->join(
                array('cs' => $this->getTable('core/store')),
                'cs.store_id = csg.default_store_id',
                array())
            ->join(
                array('o' => $this->getTable('catalog/product_option')),
                'o.product_id = i.entity_id',
                array('option_id'))
            ->join(
                array('ot' => $this->getTable('catalog/product_option_type_value')),
                'ot.option_id = o.option_id',
                array())
            ->join(
                array('otpd' => $this->getTable('catalog/product_option_type_price')),
                'otpd.option_type_id = ot.option_type_id AND otpd.store_id = 0',
                array())
            ->joinLeft(
                array('otps' => $this->getTable('catalog/product_option_type_price')),
                'otps.option_type_id = otpd.option_type_id AND otpd.store_id = cs.store_id',
                array())
            ->group(array('i.entity_id', 'i.customer_group_id', 'i.website_id', 'o.option_id'));

        $optPriceType   = $write->getCheckSql('otps.option_type_price_id > 0', 'otps.price_type', 'otpd.price_type');
        $optPriceValue  = $write->getCheckSql('otps.option_type_price_id > 0', 'otps.price', 'otpd.price');
        $minPriceRound  = new Zend_Db_Expr("ROUND(i.price * ({$optPriceValue} / 100), 4)");
        $minPriceExpr   = $write->getCheckSql("{$optPriceType} = 'fixed'", $optPriceValue, $minPriceRound);
        $minPriceMin    = new Zend_Db_Expr("MIN({$minPriceExpr})");
        $minPrice       = $write->getCheckSql("MIN(o.is_require) = 1", $minPriceMin, '0');

        $tierPriceRound = new Zend_Db_Expr("ROUND(i.base_tier * ({$optPriceValue} / 100), 4)");
        $tierPriceExpr  = $write->getCheckSql("{$optPriceType} = 'fixed'", $optPriceValue, $tierPriceRound);
        $tierPriceMin   = new Zend_Db_Expr("MIN($tierPriceExpr)");
        $tierPriceValue = $write->getCheckSql("MIN(o.is_require) > 0", $tierPriceMin, 0);
        $tierPrice      = $write->getCheckSql("MIN(i.base_tier) IS NOT NULL", $tierPriceValue, "NULL");

        $maxPriceRound  = new Zend_Db_Expr("ROUND(i.price * ({$optPriceValue} / 100), 4)");
        $maxPriceExpr   = $write->getCheckSql("{$optPriceType} = 'fixed'", $optPriceValue, $maxPriceRound);
        //$tierPriceMin   = new Zend_Db_Expr("MIN($tierPriceExpr)");
        $maxPrice       = $write->getCheckSql("(MIN(o.type)='radio' OR MIN(o.type)='drop_down')",
            "MAX($maxPriceExpr)", "SUM($maxPriceExpr)");

        $select->columns(array(
            'min_price'  => $minPrice,
            'max_price'  => $maxPrice,
            'tier_price' => $tierPrice
        ));

        $query = $select->insertFromSelect($coaTable);
        $write->query($query);

        $select = $write->select()
            ->from(
                array('i' => $this->_getDefaultFinalPriceTable()),
                array('entity_id', 'customer_group_id', 'website_id'))
            ->join(
                array('cw' => $this->getTable('core/website')),
                'cw.website_id = i.website_id',
                array())
            ->join(
                array('csg' => $this->getTable('core/store_group')),
                'csg.group_id = cw.default_group_id',
                array())
            ->join(
                array('cs' => $this->getTable('core/store')),
                'cs.store_id = csg.default_store_id',
                array())
            ->join(
                array('o' => $this->getTable('catalog/product_option')),
                'o.product_id = i.entity_id',
                array('option_id'))
            ->join(
                array('opd' => $this->getTable('catalog/product_option_price')),
                'opd.option_id = o.option_id AND opd.store_id = 0',
                array())
            ->joinLeft(
                array('ops' => $this->getTable('catalog/product_option_price')),
                'ops.option_id = opd.option_id AND ops.store_id = cs.store_id',
                array());

        $optPriceType   = $write->getCheckSql('ops.option_price_id > 0', 'ops.price_type', 'opd.price_type');
        $optPriceValue  = $write->getCheckSql('ops.option_price_id > 0', 'ops.price', 'opd.price');

        $minPriceRound  = new Zend_Db_Expr("ROUND(i.price * ({$optPriceValue} / 100), 4)");
        $priceExpr      = $write->getCheckSql("{$optPriceType} = 'fixed'", $optPriceValue, $minPriceRound);
        $minPrice       = $write->getCheckSql("{$priceExpr} > 0 AND o.is_require > 1", $priceExpr, 0);

        $maxPrice       = $priceExpr;

        $tierPriceRound = new Zend_Db_Expr("ROUND(i.base_tier * ({$optPriceValue} / 100), 4)");
        $tierPriceExpr  = $write->getCheckSql("{$optPriceType} = 'fixed'", $optPriceValue, $tierPriceRound);
        $tierPriceValue = $write->getCheckSql("{$tierPriceExpr} > 0 AND o.is_require > 0", $tierPriceExpr, 0);
        $tierPrice      = $write->getCheckSql("i.base_tier IS NOT NULL", $tierPriceValue, "NULL");

        $select->columns(array(
            'min_price'  => $minPrice,
            'max_price'  => $maxPrice,
            'tier_price' => $tierPrice
        ));

        $query = $select->insertFromSelect($coaTable);
        $write->query($query);

        $select = $write->select()
            ->from(
                array($coaTable),
                array(
                    'entity_id',
                    'customer_group_id',
                    'website_id',
                    'min_price'     => 'SUM(min_price)',
                    'max_price'     => 'SUM(max_price)',
                    'tier_price'    => 'SUM(tier_price)',
                ))
            ->group(array('entity_id', 'customer_group_id', 'website_id'));
        $query = $select->insertFromSelect($copTable);
        $write->query($query);

        $table  = array('i' => $this->_getDefaultFinalPriceTable());
        $select = $write->select()
            ->join(
                array('io' => $copTable),
                'i.entity_id = io.entity_id AND i.customer_group_id = io.customer_group_id'
                    .' AND i.website_id = io.website_id',
                array());
        
        // begin customization *****
        $select = $this->_excludeProductsWithAbsolutePrice($select);
        // end customization *****
        
        $select->columns(array(
            'min_price'  => new Zend_Db_Expr('i.min_price + io.min_price'),
            'max_price'  => new Zend_Db_Expr('i.max_price + io.max_price'),
            'tier_price' => $write->getCheckSql('i.tier_price IS NOT NULL', 'i.tier_price + io.tier_price', 'NULL'),
        ));
        $query = $select->crossUpdateFromSelect($table);
        $write->query($query);

        if ($this->useIdxTable() && (version_compare(Mage::getVersion(), '1.6.1', '<') || version_compare(Mage::getVersion(), '1.6.1', '=') && $this->_allowTableChanges)) {
            $write->truncateTable($coaTable);
            $write->truncateTable($copTable);
        } else {
            //version_compare(Mage::getVersion(), '1.6.2', '=')
            $write->delete($coaTable);
            $write->delete($copTable);
        }

        return $this;
    }
    
    
    
    protected function _applyCustomOption1510() {
        $write      = $this->_getWriteAdapter();
        $coaTable   = $this->_getCustomOptionAggregateTable();
        $copTable   = $this->_getCustomOptionPriceTable();

        $this->_prepareCustomOptionAggregateTable();
        $this->_prepareCustomOptionPriceTable();

        $select = $write->select()
            ->from(
                array('i' => $this->_getDefaultFinalPriceTable()),
                array('entity_id', 'customer_group_id', 'website_id'))
            ->join(
                array('cw' => $this->getTable('core/website')),
                'cw.website_id = i.website_id',
                array())
            ->join(
                array('csg' => $this->getTable('core/store_group')),
                'csg.group_id = cw.default_group_id',
                array())
            ->join(
                array('cs' => $this->getTable('core/store')),
                'cs.store_id = csg.default_store_id',
                array())
            ->join(
                array('o' => $this->getTable('catalog/product_option')),
                'o.product_id = i.entity_id',
                array('option_id'))
            ->join(
                array('ot' => $this->getTable('catalog/product_option_type_value')),
                'ot.option_id = o.option_id',
                array())
            ->join(
                array('otpd' => $this->getTable('catalog/product_option_type_price')),
                'otpd.option_type_id = ot.option_type_id AND otpd.store_id = 0',
                array())
            ->joinLeft(
                array('otps' => $this->getTable('catalog/product_option_type_price')),
                'otps.option_type_id = otpd.option_type_id AND otpd.store_id = cs.store_id',
                array())
            ->group(array('i.entity_id', 'i.customer_group_id', 'i.website_id', 'o.option_id'));

        $minPrice = new Zend_Db_Expr("IF(o.is_require, MIN(IF(IF(otps.option_type_price_id>0, otps.price_type, "
            . "otpd.price_type)='fixed', IF(otps.option_type_price_id>0, otps.price, otpd.price), "
            . "ROUND(i.price * (IF(otps.option_type_price_id>0, otps.price, otpd.price) / 100), 4))), 0)");
        $tierPrice = new Zend_Db_Expr("IF(i.base_tier IS NOT NULL, IF(o.is_require, "
            . "MIN(IF(IF(otps.option_type_price_id>0, otps.price_type, otpd.price_type)='fixed', "
            . "IF(otps.option_type_price_id>0, otps.price, otpd.price), "
            . "ROUND(i.base_tier * (IF(otps.option_type_price_id>0, otps.price, otpd.price) / 100), 4))), 0), NULL)");
        $maxPrice = new Zend_Db_Expr("IF((o.type='radio' OR o.type='drop_down'), "
            . "MAX(IF(IF(otps.option_type_price_id>0, otps.price_type, otpd.price_type)='fixed', "
            . "IF(otps.option_type_price_id>0, otps.price, otpd.price), "
            . "ROUND(i.price * (IF(otps.option_type_price_id>0, otps.price, otpd.price) / 100), 4))), "
            . "SUM(IF(IF(otps.option_type_price_id>0, otps.price_type, otpd.price_type)='fixed', "
            . "IF(otps.option_type_price_id>0, otps.price, otpd.price), "
            . "ROUND(i.price * (IF(otps.option_type_price_id>0, otps.price, otpd.price) / 100), 4))))");

        $select->columns(array(
            'min_price'  => $minPrice,
            'max_price'  => $maxPrice,
            'tier_price' => $tierPrice
        ));

        $query = $select->insertFromSelect($coaTable);
        
        
        
        $write->query($query);

        $select = $write->select()
            ->from(
                array('i' => $this->_getDefaultFinalPriceTable()),
                array('entity_id', 'customer_group_id', 'website_id'))
            ->join(
                array('cw' => $this->getTable('core/website')),
                'cw.website_id = i.website_id',
                array())
            ->join(
                array('csg' => $this->getTable('core/store_group')),
                'csg.group_id = cw.default_group_id',
                array())
            ->join(
                array('cs' => $this->getTable('core/store')),
                'cs.store_id = csg.default_store_id',
                array())
            ->join(
                array('o' => $this->getTable('catalog/product_option')),
                'o.product_id = i.entity_id',
                array('option_id'))
            ->join(
                array('opd' => $this->getTable('catalog/product_option_price')),
                'opd.option_id = o.option_id AND opd.store_id = 0',
                array())
            ->joinLeft(
                array('ops' => $this->getTable('catalog/product_option_price')),
                'ops.option_id = opd.option_id AND ops.store_id = cs.store_id',
                array());

        $minPrice = new Zend_Db_Expr("IF((@price:=IF(IF(ops.option_price_id>0, ops.price_type, opd.price_type)='fixed',"
            . " IF(ops.option_price_id>0, ops.price, opd.price), ROUND(i.price * (IF(ops.option_price_id>0, "
            . "ops.price, opd.price) / 100), 4))) AND o.is_require, @price,0)");
        $maxPrice = new Zend_Db_Expr("@price");
        $tierPrice = new Zend_Db_Expr("IF(i.base_tier IS NOT NULL, IF((@tier_price:=IF(IF(ops.option_price_id>0, "
            . "ops.price_type, opd.price_type)='fixed', IF(ops.option_price_id>0, ops.price, opd.price), "
            . "ROUND(i.base_tier * (IF(ops.option_price_id>0, ops.price, opd.price) / 100), 4))) AND o.is_require, "
            . "@tier_price, 0), NULL)");

        $select->columns(array(
            'min_price'  => $minPrice,
            'max_price'  => $maxPrice,
            'tier_price' => $tierPrice
        ));

        $query = $select->insertFromSelect($coaTable);
        
        $write->query($query);

        $select = $write->select()
            ->from(
                array($coaTable),
                array(
                    'entity_id',
                    'customer_group_id',
                    'website_id',
                    'min_price'     => 'SUM(min_price)',
                    'max_price'     => 'SUM(max_price)',
                    'tier_price'    => 'SUM(tier_price)',
                ))
            ->group(array('entity_id', 'customer_group_id', 'website_id'));
        $query = $select->insertFromSelect($copTable);
        
        $write->query($query);

        $table  = array('i' => $this->_getDefaultFinalPriceTable());
        $select = $write->select()
            ->join(
                array('io' => $copTable),
                'i.entity_id = io.entity_id AND i.customer_group_id = io.customer_group_id'
                    .' AND i.website_id = io.website_id',
                array());
        
        // begin customization *****
        $select = $this->_excludeProductsWithAbsolutePrice($select);
        // end customization *****
        
        $select->columns(array(
            'min_price'  => new Zend_Db_Expr('i.min_price + io.min_price'),
            'max_price'  => new Zend_Db_Expr('i.max_price + io.max_price'),
            'tier_price' => new Zend_Db_Expr('IF(i.tier_price IS NOT NULL, i.tier_price + io.tier_price, NULL)'),
        ));
        $query = $select->crossUpdateFromSelect($table);
        
        $write->query($query);

        if (version_compare(Mage::getVersion(), '1.4.2', '<') || $this->useIdxTable()) {
            $write->truncate($coaTable);
            $write->truncate($copTable);
        }
        else {
            $write->delete($coaTable);
            $write->delete($copTable);
        }

        return $this;
    }
    
}
