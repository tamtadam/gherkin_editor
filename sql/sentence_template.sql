DROP table IF EXISTS SentenceTemplate;

CREATE TABLE SentenceTemplate (
  SentenceTemplateID  int(10) unsigned NOT NULL AUTO_INCREMENT,
  SentenceTemplate varchar(500) NOT NULL,
  LastModified TIMESTAMP           DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (SentenceTemplateID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;