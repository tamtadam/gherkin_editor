CREATE TABLE IF NOT EXISTS partner (
  partner_id int(11)      NOT NULL           AUTO_INCREMENT,
  username   varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  password   varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  szul_datum datetime                        DEFAULT NULL,
  name       varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  email      varchar(255) CHARACTER SET utf8 COLLATE utf8_hungarian_ci DEFAULT NULL,
  activated  tinyint(1)   NOT NULL DEFAULT '0',
  PRIMARY KEY (partner_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;