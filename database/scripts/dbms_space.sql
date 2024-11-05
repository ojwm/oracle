DECLARE
   --
   CURSOR c_columns (p_owner IN dba_tab_cols.owner%TYPE,
                     p_table IN dba_tab_cols.table_name%TYPE) IS
      --
      SELECT table_name,
             column_name,
             data_type,
             data_length
      FROM   dba_tab_cols
      WHERE  owner      = p_owner
      AND    table_name = p_table
      ORDER BY table_name,
               column_id;
   --
   v_owner           VARCHAR2(30);
   v_table           VARCHAR2(30);
   v_rows            NUMBER;
   v_count           NUMBER := 0;
   v_sql             VARCHAR2(4000);
   v_type            sys.create_table_cost_columns;
   v_used_bytes      NUMBER(10);
   v_allocated_bytes NUMBER(10);
--
BEGIN
   --
   v_owner := 'MITCHO2';
   v_table := 'CUSTOMER';
   v_rows  := 300000;
   --
   v_sql := ':1 := sys.create_table_cost_columns
(';
   --
   FOR c IN c_columns(v_owner, v_table) LOOP
      --
      IF v_count != 0 THEN
         --
         v_sql := v_sql||',
';
      --
      END IF;
      --
      IF c.data_type LIKE 'TIMESTAMP%' THEN
         --
         v_sql := v_sql||
                  'sys.create_table_cost_colinfo(''TIMESTAMP'','||
                  substr(c.data_type, 11, length(c.data_type)-11)||')';
      --
      ELSE
         --
         v_sql := v_sql||
                  'sys.create_table_cost_colinfo('''||
                  c.data_type||''','||
                  c.data_length||')';
      --
      END IF;
      --
      v_count := v_count+1;
   --
   END LOOP;
   --
   v_sql := v_sql||');';
   --
   --dbms_output.put_line(v_sql);
   --
   EXECUTE IMMEDIATE ('BEGIN '||v_sql||' END;')
   USING OUT v_type;
   --
   dbms_space.create_table_cost('SYSTEM',
                                v_type,
                                v_rows,
                                7,
                                v_used_bytes,
                                v_allocated_bytes);
   --
   dbms_output.put_line('Table: '||v_table);
   dbms_output.put_line('Used Bytes: ' || to_char(v_used_bytes));
   dbms_output.put_line('Allocated Bytes: ' || to_char(v_allocated_bytes));
--
END;