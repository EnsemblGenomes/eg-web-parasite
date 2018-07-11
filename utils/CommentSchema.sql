CREATE TABLE `comment_meta` (
  `meta_id` int(11) NOT NULL AUTO_INCREMENT,
  `comment_uuid` varchar(50) NOT NULL UNIQUE,
  `user_id` int(11) NOT NULL,
  `gene_stable_id` varchar(100) NOT NULL,
  `species` varchar(100) NOT NULL,
  `isRemoved` tinyint(1) DEFAULT 0,
  `created_by` int(11) default NULL,
  `modified_by` int(11) default NULL,
  `created_at` datetime DEFAULT NULL,
  `modified_at` datetime DEFAULT NULL,
  PRIMARY KEY  (`meta_id`)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `comment_data` (
  `data_id` int(11) NOT NULL AUTO_INCREMENT,
  `meta_id` int(11) NOT NULL,
  `data` text,
  `created_by` int(11) default NULL,
  `modified_by` int(11) default NULL,
  `created_at` datetime DEFAULT NULL,
  `modified_at` datetime DEFAULT NULL,
  PRIMARY KEY  (`data_id`),
  FOREIGN KEY (`meta_id`) REFERENCES `comment_meta` (`meta_id`) 
)ENGINE=InnoDB DEFAULT CHARSET=latin1;
