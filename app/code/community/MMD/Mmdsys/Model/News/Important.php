<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_Model_News_Important extends MMD_Mmdsys_Model_News_Recent
{
    /**
     * @var string 
     */
    protected $_cacheKey = 'MMD_AITSYS_NEWS_IMPORTANT';
    
    /**
     * @var string 
     */
    protected $_method = 'getNewsNotification';
    
    /**
     * @var string 
     */
    protected $_type = 'important';
    
    /**
     * @return MMD_Mmdsys_Model_News_Recent
     */
    public function saveData()
    {
        $feedData = array();
        foreach ($this->_news as $item) {
            if ($item['title'] || $item['content']) {
                $feedData[] = array(
                    'severity'    => isset($item['severity']) ? $item['severity'] : Mage_AdminNotification_Model_Inbox::SEVERITY_MINOR,
                    'date_added'  => isset($item['pubDate'])  ? $item['pubDate']  : date('Y-m-d H:i:s'),
                    'title'       => isset($item['title'])    ? $item['title']    : '',
                    'description' => isset($item['content'])  ? $item['content']  : '',
                    'url'         => (isset($item['link']) && $item['link']) ? $item['link'] : 'http://mmd.com/#'.strtolower(preg_replace('/\W+/','_',$item['title']))
                );
            }
        }
        
        if ($feedData) {
            Mage::getModel('adminnotification/inbox')->parse(array_reverse($feedData));
        }
        return parent::saveData();
    }
}