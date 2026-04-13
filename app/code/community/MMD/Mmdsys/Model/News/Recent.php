<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_Model_News_Recent extends MMD_Mmdsys_Abstract_Model
{
    const CACHE_LIVE_TIME = 86400;

    /**
     * @var array
     */
    protected $_news = array();
    
    /**
     * @var string
     */
    protected $_cacheKey = 'MMD_AITSYS_NEWS';
    
    /**
     * @var string
     */
    protected $_method = 'getNews';

    /**
     * @var string
     */
    protected $_type = 'news';
    
    /**
     * @return MMD_Mmdsys_Model_Mysql4_News
     */
    protected function _getNewsResource()
    {
        return Mage::getResourceSingleton('mmdsys/news');
    }
    
    /**
     * @return MMD_Mmdsys_Model_Mysql4_News_Collection
     */
    protected function _getNewsCollection()
    {
        return Mage::getResourceModel('mmdsys/news_collection')->addTypeFilter($this->_type);
    }
    
    /**
     * @return MMD_Mmdsys_Model_News_Recent
     */
    public function loadData()
    {
        try {
            $latest = $this->_getNewsResource()->getLatest($this->_type);
        } catch (Exception $exc) {
            Mage::logException($exc);
            return $this;
        }
        
        if (!$latest->isOld()) {
            foreach ($this->_getNewsCollection() as $model) {
                $this->addNews(array(
                    'title' => $model->getTitle(),
                    'content' => $model->getDescription()
                ));
            }
            return $this;
        }
        
        try {
            $this->tool()->testMsg('Load news from service');
            $service = $this->tool()->platform()->getService()->setMethodPrefix('aitnewsad');
            if ($service->getServiceUrl()) {
                $this->tool()->testMsg('Get news data from: ' . $service->getServiceUrl());
                $service->connect();
                if ($news = $service->{$this->_method}()) {
                    $this->tool()->testMsg($news);
                    foreach ($news as $item) {
                        $this->addNews($item);
                    }
                }
                $service->disconnect();
                $this->saveData();
            } else {
                $this->tool()->testMsg('Service URL is empty: News download skipped.');
            }
        } catch (Exception $exc) {
            Mage::logException($exc);
            $this->tool()->testMsg($exc);
        }

        $this->tool()->testMsg("Loaded news:");
        $this->tool()->testMsg($this->_news);
        return $this;
    }
    
    /**
     * @return MMD_Mmdsys_Model_News_Recent
     */
    public function saveData()
    {
        $this->_getNewsResource()->clear($this->_type);
        if (!$this->_news) {
            Mage::getModel('mmdsys/news')->setData(array(
                'date_added'  => date('Y-m-d H:i:s'),
                'title'       => '',
                'description' => '',
                'type'        => $this->_type
            ))->save();
        } else {
            foreach ($this->_news as $item) {
                Mage::getModel('mmdsys/news')->setData(array(
                    'date_added'  => date('Y-m-d H:i:s'),
                    'title'       => $item['title'],
                    'description' => $item['content'],
                    'type'        => $this->_type
                ))->save();
            }
        }
        return $this;
    }
    
    /**
     * @param array $item
     * @return MMD_Mmdsys_Model_News_Recent
     */
    public function addNews( $item )
    {
        if ($item && !empty($item['content'])) {
            $this->_news[] = $item;
        }
        return $this;
    }
    
    public function getNews()
    {
        return $this->_news;
    }
}