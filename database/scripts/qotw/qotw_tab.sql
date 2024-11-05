CREATE OR REPLACE TYPE t_voters AS TABLE OF VARCHAR2(30);
--
DROP TABLE qotw_storage;
--
------------------------------------------------------------------------------
-- qotw_storage table.
-- Table to hold quotes of the week.
-- Manipulate by using the qotw package.
------------------------------------------------------------------------------
CREATE TABLE qotw_storage (quote_id  NUMBER,
                           who       VARCHAR2(30),
                           quote     VARCHAR2(4000),
                           voted_on  VARCHAR2(1),
                           voters    t_voters,
                           winner    VARCHAR2(14),
                           timestamp DATE)
   NESTED TABLE voters STORE AS qotw_voters;
--
-- Create a public synonym for qotw_storage.
DROP PUBLIC SYNONYM qotw_storage;
--
CREATE PUBLIC SYNONYM qotw_storage FOR qotw_storage;
--
DROP TABLE qotw_users;
--
------------------------------------------------------------------------------
-- qotw_users table.
-- Table to hold users of quote of the week.
-- Manipulate by using the qotw package.
------------------------------------------------------------------------------
CREATE TABLE qotw_users (name VARCHAR2(30));
--
ALTER TABLE qotw_users
ADD CONSTRAINT qotw_users_pk PRIMARY KEY (name);
--
-- Create a public synonym for qotw_users.
DROP PUBLIC SYNONYM qotw_users;
--
CREATE PUBLIC SYNONYM qotw_users FOR qotw_users;