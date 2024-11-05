DECLARE
   --
   v_ddl             VARCHAR2(4000);
   v_used_bytes      NUMBER(10);
   v_allocated_bytes NUMBER(10);
--
BEGIN
   --
   v_ddl := 'CREATE INDEX quotation_customer_idx ON quotation (customer_id)';
   --
   dbms_space.create_index_cost(v_ddl, v_used_bytes, v_allocated_bytes);
   --
   dbms_output.put_line('Used Bytes: ' || to_char(v_used_bytes));
   dbms_output.put_line('Allocated Bytes: ' || to_char(v_allocated_bytes));
--
END;