<?php

$installer = $this;

$installer->startSetup();

$installer->run("

-- DROP TABLE IF EXISTS {$this->getTable('courses_providers')};
CREATE TABLE {$this->getTable('courses_providers')} (
  `providers_id` int(11) unsigned NOT NULL auto_increment,
  `relation_id` int(11) unsigned NOT NULL,	
  `title` varchar(255) NOT NULL default '',
  `email` text NULL,
  `address` varchar(255) NULL,
  `tel` varchar(255) NULL,
  `website` varchar(255) NULL,
  `profile_image` varchar(255) NOT NULL default '',
  `status` smallint(6) NOT NULL default '0',
  `created_time` datetime NULL,
  `update_time` datetime NULL,
  PRIMARY KEY (`providers_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

    ");	

$installer->endSetup(); 