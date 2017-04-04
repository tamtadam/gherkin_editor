DROP table IF EXISTS Project;

CREATE TABLE Project (
  ProjectID  int(10) unsigned NOT NULL AUTO_INCREMENT,
  Title varchar(500) NOT NULL,
  LastModified TIMESTAMP           DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ProjectID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;