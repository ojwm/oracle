DROP TABLE oli_test
/

CREATE TABLE oli_test (col NUMBER(1))
/

CREATE INDEX oli_test_index ON oli_test (col)
/

DECLARE
   --
   CURSOR c_indexes (p_table IN VARCHAR2) IS
      --
      SELECT i.index_name,
             i.table_owner
      FROM   user_indexes i
      WHERE  i.table_name = upper(p_table);
   --
   TYPE t_clob IS TABLE OF CLOB INDEX BY BINARY_INTEGER;
   v_indexes t_clob;
   v_count   NUMBER;
   v_table   VARCHAR2(30) := 'oli_test';
--
BEGIN
   --
   FOR l_c_indexes IN c_indexes (v_table) LOOP
      --
      dbms_output.put_line('Storing index');
      --
      v_indexes(nvl(v_indexes.LAST,0)+1) := dbms_metadata.get_ddl('INDEX',
                                                                  l_c_indexes.index_name,
                                                                  l_c_indexes.table_owner);
      --
      dbms_output.put_line('Index stored');
   --
   END LOOP;
   --
   EXECUTE IMMEDIATE 'DROP INDEX oli_test_index';
   --
   dbms_output.put_line('Index dropped');
   --
   SELECT COUNT(*)
   INTO   v_count
   FROM   user_indexes
   WHERE  table_name = upper(v_table);
   --
   dbms_output.put_line(v_table||' has '||v_count||' indexes');
   --
   FOR i IN v_indexes.FIRST .. v_indexes.LAST LOOP
      --
      EXECUTE IMMEDIATE to_char(v_indexes(i));
      --
      dbms_output.put_line('Index created');
   --
   END LOOP;
--
END;
/