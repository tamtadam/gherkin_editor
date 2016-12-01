CREATE TABLE FeatureScenario (
  FeatureScenarioID int(10) unsigned NOT NULL AUTO_INCREMENT,
  ScenarioID        int(10) unsigned NOT NULL,
  Position          int(10) unsigned NOT NULL,
  FeatureID         int(10) unsigned NOT NULL,
  PRIMARY KEY (FeatureScenarioID),
  KEY ScenarioID (ScenarioID),
  KEY Position (Position),
  KEY FeatureID (FeatureID),
  CONSTRAINT fk_FeatureScenario_1 FOREIGN KEY (FeatureID) REFERENCES Feature (FeatureID) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_FeatureScenario_2 FOREIGN KEY (ScenarioID) REFERENCES Scenario (ScenarioID) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;