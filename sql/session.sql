CREATE TABLE sessions (
  id        char(32) NOT NULL,
  a_session text     NOT NULL,
  expire    datetime NOT NULL,
  pid       int(11)  NOT NULL,
  UNIQUE KEY id (id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;