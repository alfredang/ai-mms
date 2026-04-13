<?php

/* @var $this MMD_Mmdsys_Model_Mysql4_Setup */

$this->startSetup();

$this->run("CREATE TABLE IF NOT EXISTS {$this->getTable('mmdsys_notification')} (
	`entity_id` INT(10) UNSIGNED NOT NULL auto_increment ,
	`assigned` VARCHAR(64) NOT NULL , 
    `severity` TINYINT(3) UNSIGNED NOT NULL ,
    `date_added` DATETIME NOT NULL ,
    `title` VARCHAR(255) NOT NULL ,
    `description` MEDIUMTEXT NOT NULL ,
    `url` VARCHAR(255) NOT NULL ,
    `type` VARCHAR(16) NOT NULL ,
    `source` VARCHAR(255) NOT NULL ,
    `viewed` TINYINT(3) UNSIGNED NOT NULL default 0,
    PRIMARY KEY ( `entity_id` ) ,
    KEY `date` ( `date_added` ) ,
    KEY `assigned` ( `assigned` )
) ENGINE=MyISAM DEFAULT CHARSET=utf8;");

$this->endSetup();