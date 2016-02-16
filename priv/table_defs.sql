DROP DATABASE IF EXISTS `upup`;
CREATE DATABASE `upup`;
USE upup;



DROP TABLE IF EXISTS `accounts`;
CREATE TABLE `accounts` (
	`uid` bigint unsigned NOT NULL,
	`token` varchar(255) NOT NULL,
	`country` varchar(255) NOT NULL,
	`stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY `uid` (`uid`),
	KEY `country` ( `country` ),
	KEY `stamp` (`stamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `tasks`;
CREATE TABLE `tasks` (
	`id` bigint unsigned NOT NULL AUTO_INCREMENT,
	`uid` bigint unsigned NOT NULL,
	`task_name` varchar(255) NOT NULL,
	`ttl` bigint unsigned NOT NULL, # updates ttl , seconds
	`stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY `id` (`id`),
	KEY `uid` (`uid`),
	KEY `task_name` (`task_name`),
	KEY `ttl` (`ttl`),
	UNIQUE KEY `full` (`uid`,`task_name`),
	KEY `stamp` (`stamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `items`;
CREATE TABLE `items` (
	`id` bigint unsigned NOT NULL AUTO_INCREMENT,
	`link` varchar(255) NOT NULL,
	`task_id` bigint unsigned NOT NULL,
	`caption` varchar(1023) NOT NULL,
	`stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY `id` (`id`),
	KEY `link` (`link`),
	KEY `task_id` (`task_id`),
	UNIQUE KEY `full` (`link`,`task_id`),
	KEY `stamp` (`stamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `albums`;
CREATE TABLE `albums` (
	`id` bigint unsigned NOT NULL AUTO_INCREMENT,
	`gid` bigint unsigned NOT NULL,
	`aid` bigint unsigned NOT NULL,
	`task_id` bigint unsigned NOT NULL,
	`album_name` varchar(255) NOT NULL,
	`upload_result` BLOB NOT NULL,
	`stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY `id` (`id`),
	KEY `gid` (`gid`),
	KEY `aid` (`aid`),
	KEY `task_id` (`task_id`),
	UNIQUE KEY `full` (`gid`,`aid`,`task_id`),
	KEY `stamp` (`stamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
