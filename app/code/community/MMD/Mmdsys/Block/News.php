<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_Block_News extends MMD_Mmdsys_Abstract_Adminhtml_Block
{
    /**
     * @var MMD_Mmdsys_Model_News_Recent
     */
    protected $_news;
    
    /**
     * @return MMD_Mmdsys_Model_News_Recent
     */
    public function getNews()
    {
        if (!$this->_news) {
            $this->_news = Mage::getModel('mmdsys/news_recent');
            $this->_news->loadData();
        }
        return $this->_news->getNews();
    }
}