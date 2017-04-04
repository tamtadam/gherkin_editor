DROP TABLE IF EXISTS Scenario;

CREATE TABLE Scenario (
  ScenarioID  int(10) unsigned NOT NULL AUTO_INCREMENT,
  Title varchar(500) NOT NULL,
  Locked      tinyint(1) DEFAULT 0,
  LastModified TIMESTAMP           DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ScenarioID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;