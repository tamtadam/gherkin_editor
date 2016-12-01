CREATE TABLE Scenario (
  ScenarioID  int(10) unsigned NOT NULL AUTO_INCREMENT,
  Description varchar(500) NOT NULL,
  Locked      tinyint(1) DEFAULT NULL,
  PRIMARY KEY (ScenarioID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;