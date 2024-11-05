DECLARE
   --
   -- Define a record type to hold table information
   TYPE rt_table_info IS RECORD
     (name   VARCHAR2(30),
      column VARCHAR2(30));
   v_table_info rt_table_info;
   --
   -- Define a table type to hold records of table information
   TYPE t_tables IS TABLE OF rt_table_info INDEX BY BINARY_INTEGER;
   v_tables t_tables;
--
BEGIN
   --
   -- Add table name and column name to the table info record 
   v_table_info.name   := 'TABLE1';
   v_table_info.column := 'COLUMN1';
   --
   -- Add the record to the table
   v_tables(1) := v_table_info;
   --
   v_table_info.name   := 'TABLE2';
   v_table_info.column := 'COLUMN2';
   v_tables(2) := v_table_info;
   --
   v_table_info.name   := 'TABLE3';
   v_table_info.column := 'COLUMN3';
   v_tables(3) := v_table_info;
   --
   v_table_info.name   := 'TABLE4';
   v_table_info.column := 'COLUMN4';
   v_tables(4) := v_table_info;
   --
   -- Loop round the records and do stuff
   FOR i IN v_tables.FIRST..v_tables.LAST LOOP
      --
      dbms_output.put_line(v_tables(i).name||'.'||v_tables(i).column);
   --
   END LOOP;
--
END;
/