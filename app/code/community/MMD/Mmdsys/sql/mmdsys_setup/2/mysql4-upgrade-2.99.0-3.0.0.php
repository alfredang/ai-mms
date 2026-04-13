<?php
/* @var $this MMD_Mmdsys_Model_Mysql4_Setup */
$this->startSetup();
$this->run("
    
    DROP TABLE IF EXISTS `{$this->getTable('mmdsys_performer')}`;
    DROP TABLE IF EXISTS `{$this->getTable('mmdsys_notification')}`;
    
");
$this->endSetup();