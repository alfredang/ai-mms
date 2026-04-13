<?php

/* @var $this MMD_Mmdsys_Model_Mysql4_Setup */
$this->startSetup();

$this->run("CREATE TABLE IF NOT EXISTS {$this->getTable('mmdsys_news')} (
    `entity_id` INT(10) UNSIGNED NOT NULL auto_increment ,
    `date_added` DATETIME NOT NULL ,
    `title` VARCHAR(255) NOT NULL ,
    `description` MEDIUMTEXT NOT NULL ,
    `type` ENUM('news','important') NOT NULL default 'news',
    PRIMARY KEY ( `entity_id` ) ,
    KEY `date` ( `date_added` )
) ENGINE=MyISAM DEFAULT CHARSET=utf8;");

$this->endSetup();