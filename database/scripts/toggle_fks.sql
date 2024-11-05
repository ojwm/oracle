SET SERVEROUTPUT ON;
--
DECLARE
   --
   CURSOR c_fk IS
      --
      SELECT c.owner,
             c.table_name,
             c.constraint_name
      FROM   user_constraints c
      WHERE  c.constraint_type = 'R';
   --
   -- *** Swap these two lines ***
   v_enable_disable VARCHAR2(7) := 'DISABLE';
   --v_enable_disable VARCHAR2(7) := 'ENABLE';
--
BEGIN
   --
   FOR l_c_fk IN c_fk LOOP
      --
      IF v_enable_disable = 'DISABLE' THEN
         --
         EXECUTE IMMEDIATE 'ALTER TABLE '||l_c_fk.owner||'.'||l_c_fk.table_name||
                           ' DISABLE CONSTRAINT '||l_c_fk.constraint_name;
         --
         dbms_output.put_line('Disabled: '||l_c_fk.owner||'.'||l_c_fk.table_name||'.'||l_c_fk.constraint_name);
      --
      ELSE
         --
         EXECUTE IMMEDIATE 'ALTER TABLE '||l_c_fk.owner||'.'||l_c_fk.table_name||
                           ' ENABLE CONSTRAINT '||l_c_fk.constraint_name;
         --
         dbms_output.put_line('Enabled: '||l_c_fk.owner||'.'||l_c_fk.table_name||'.'||l_c_fk.constraint_name);
      --
      END IF;
   --
   END LOOP;
--
EXCEPTION
   --
   WHEN others THEN
      --
      dbms_output.put_line('Problem: '||SQLERRM);
--
END;
/