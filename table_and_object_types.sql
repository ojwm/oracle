SET FEEDBACK ON;
SET SERVEROUTPUT ON;
--
CREATE OR REPLACE TYPE test_object AS OBJECT (id   NUMBER,
                                              text VARCHAR2(30))
/
--
CREATE OR REPLACE TYPE test_table AS TABLE OF test_object;
/
--
DECLARE
   --
   v_object test_object;
   v_table  test_table;
   j        PLS_INTEGER;
--
BEGIN
   --
   -- Initialise the table
   v_table := test_table();
   --
   -- Write data to the table
   FOR i IN 1..3 LOOP
      --
      -- Initialise the object with data
      v_object := test_object(i, CASE i WHEN 1 THEN 'one' WHEN 2 THEN 'two' WHEN 3 THEN 'three' END);
      --
      -- Extend the space in the table object
      v_table.EXTEND;
      --
      -- Add the object to the table
      v_table(i) := v_object;
   --
   END LOOP;
   --
   dbms_output.put_line('Count: '||v_table.COUNT);
   --
   -- Read data from the table (method 1)
   dbms_output.put_line('Read method 1');
   --
   j := v_table.FIRST;
   --
   WHILE j IS NOT NULL LOOP
      --
      dbms_output.put_line(v_table(j).id||','||v_table(j).text);
      --
      j := v_table.NEXT(j);
   --
   END LOOP;
   --
   -- Read data from the table (method 2)
   dbms_output.put_line('Read method 2');
   --
   FOR k IN v_table.FIRST..v_table.LAST LOOP
      --
      dbms_output.put_line(v_table(k).id||','||v_table(k).text);
   --
   END LOOP;
   --
   -- Clear the table
   v_table.DELETE;
--
END;
/
--
DROP TYPE test_table
/
--
DROP TYPE test_object
/
--
PURGE RECYCLEBIN
/
--
SET SERVEROUTPUT OFF;