DROP table IF EXISTS template;

CREATE TABLE template (
  TemplatetID  int(10) unsigned NOT NULL PRIMARY KEY AUTO_INCREMENT,
  Title varchar(500) NOT NULL,
  LastModified TIMESTAMP           DEFAULT CURRENT_TIMESTAMP,
) ENGINE=InnoDB DEFAULT CHARSET=utf8;