SET ECHO ON

DROP USER itss CASCADE;
DROP USER analyst CASCADE;

CREATE USER itss IDENTIFIED BY itss;
GRANT CONNECT TO itss;

CREATE USER analyst IDENTIFIED BY analyst;
ALTER USER analyst GRANT CONNECT THROUGH itss;
GRANT CONNECT TO analyst;

CREATE OR REPLACE PROCEDURE hello_world IS
BEGIN
   dbms_output.put_line('Hello World');
END hello_world;
/

GRANT EXECUTE ON hello_world TO analyst;

DROP PROCEDURE hello_world;
DROP USER itss CASCADE;
DROP USER analyst CASCADE;