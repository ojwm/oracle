-- Check the dba_advisor_findings table and shrink any tables that
-- have been recommended for shrinking
DECLARE
   --
   CURSOR c_tables IS
      --
      SELECT DISTINCT substr(message,instr(message,' ',1,6)+1,instr(message,' ',1,7)-instr(message,' ',1,6)-1) table_name
      FROM   dba_advisor_findings
      WHERE  message LIKE 'Enable row movement of the table%and perform shrink,%'
      ORDER BY 1;
--
BEGIN
   --
   FOR l_c_tables IN c_tables LOOP
      --
      BEGIN
         --
         dbms_output.put_line('Shrinking: '||l_c_tables.table_name);
         --
         EXECUTE IMMEDIATE 'ALTER TABLE '||l_c_tables.table_name||' ENABLE ROW MOVEMENT';

         EXECUTE IMMEDIATE 'ALTER TABLE '||l_c_tables.table_name||' SHRINK SPACE';

         EXECUTE IMMEDIATE 'ALTER TABLE '||l_c_tables.table_name||' DISABLE ROW MOVEMENT';
         --
         dbms_output.put_line('Shrinking: '||l_c_tables.table_name||' done');
      --
      EXCEPTION
         --
         WHEN others THEN
            --
            dbms_output.put_line(SQLERRM);
            --
            EXECUTE IMMEDIATE 'ALTER TABLE '||l_c_tables.table_name||' DISABLE ROW MOVEMENT';
      --
      END;
   --
   END LOOP;
--
END;
/