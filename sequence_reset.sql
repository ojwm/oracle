------------------------------------------------------------------------------
-- Script to reset all sequences, for the current user, to their minimum
-- value (or as close as possible)
------------------------------------------------------------------------------
-- Revision history
--
-- Ver   Reference   Author      Description
-- ----  ----------  ----------  ---------------------------------------------
-- 1.0               MITCHO2     Initial version
------------------------------------------------------------------------------
DECLARE
   --
   -- c_sequences cursor
   -- Gets all sequences owned by the current user
   CURSOR c_sequences IS
      --
      SELECT sequence_name,
             min_value,
             last_number,
             increment_by,
             cache_size
      FROM   all_sequences
      WHERE  sequence_owner = USER
      ORDER BY sequence_name ASC;
   -- 
   v_val NUMBER;
--
BEGIN
   -- 
   FOR l_c_sequences IN c_sequences LOOP
      --
      v_val := NULL;
      --
      BEGIN
         --
         -- Get the nextval of the sequence
         EXECUTE IMMEDIATE 'SELECT '||l_c_sequences.sequence_name||
                           '.nextval FROM dual'
         INTO v_val;
         --
         -- Get the sequence back to the min_value by incrementing the sequence
         -- by min_value-1 minus the nextval
         -- The extra -1 is to keep the resulting sequence start number as low
         -- as possible
         EXECUTE IMMEDIATE 'ALTER SEQUENCE '||l_c_sequences.sequence_name||
                           ' INCREMENT BY '||
                           to_char(l_c_sequences.min_value-1-v_val)||
                           ' NOMINVALUE NOCACHE';
         --
         -- Get the nextval to apply the above change
         EXECUTE IMMEDIATE 'SELECT '||l_c_sequences.sequence_name||
                           '.nextval FROM dual'
         INTO v_val;
         --
         -- Return the increment to original increment
         EXECUTE IMMEDIATE 'ALTER SEQUENCE '||l_c_sequences.sequence_name||
                           ' INCREMENT BY '||l_c_sequences.increment_by;
         --
         -- Get the nextval to apply the above change
         EXECUTE IMMEDIATE 'SELECT '||l_c_sequences.sequence_name||
                           '.nextval FROM dual'
         INTO v_val;
         --
         -- Return the minvalue and cache to original values
         EXECUTE IMMEDIATE 'ALTER SEQUENCE '||l_c_sequences.sequence_name||
                           ' MINVALUE '||l_c_sequences.min_value||
                           CASE l_c_sequences.cache_size 
                           WHEN 0
                           THEN ' NOCACHE'
                           ELSE ' CACHE '||l_c_sequences.cache_size
                           END;
      --
      EXCEPTION
         --
         WHEN others THEN
            --
            dbms_output.put_line('Error with: '||l_c_sequences.sequence_name);
            dbms_output.put_line(SQLERRM);
      --
      END;
   --
   END LOOP;
--
END;
/