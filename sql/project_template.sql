DROP table IF EXISTS project_template;

CREATE TABLE project_template (
  Project_templateID  int(10) unsigned NOT NULL AUTO_INCREMENT,
  ProjectID int(10) NOT NULL,
  SentenceTemplateID int(10) NOT NULL,
  PRIMARY KEY (Project_templateID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;