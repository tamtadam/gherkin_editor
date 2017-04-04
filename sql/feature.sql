DROP TABLE Feature;

CREATE TABLE Feature (
  FeatureID  int(10)      unsigned         NOT NULL AUTO_INCREMENT,
  Title      varchar(100)                  NOT NULL,
  Locked     tinyint(1)   unsigned DEFAULT 0,
  LastModified TIMESTAMP           DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (FeatureID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;