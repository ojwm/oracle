-- Declare a DB collection type to hold integers.
CREATE TYPE tab_integers IS
   TABLE OF INTEGER;
--
DECLARE
   --
   -- Build a simple list of integers from 1 to cp_max.
   CURSOR c_integers (cp_max IN PLS_INTEGER) IS
      --
      SELECT rownum
      FROM   all_objects
      WHERE  rownum <= cp_max;
   --
   -- Check whether an integer exists in the given collection of integers.
   -- This demonstrates using a collection in a subquery.
   CURSOR c_check (cp_integer IN INTEGER,
                   cp_range   IN tab_integers) IS
      --
      SELECT 'Y'
      FROM   dual
      WHERE  cp_integer IN (SELECT COLUMN_VALUE
                            FROM   TABLE(cp_range));
   --
   v_range   VARCHAR2(100);
   v_integer INTEGER;
   v_result  VARCHAR2(1);
   --
   -- Create a collection to hold integers.
   arr_integers tab_integers;
--
BEGIN
   --
   -- Create a collection of integers.
   OPEN c_integers (10);
   FETCH c_integers BULK COLLECT INTO arr_integers;
   CLOSE c_integers;
   --
   -- Convert the collection of integers into a comma separated list.
   FOR i IN arr_integers.FIRST..arr_integers.LAST LOOP
      --
      v_range := v_range||','||arr_integers(i);
   --
   END LOOP;
   --
   -- Remove extra commas.
   v_range := TRIM(BOTH ',' FROM v_range);
   --
   -- Check whether an integer exists in the collection.
   v_integer := 5;
   v_result  := NULL;
   --
   OPEN c_check (v_integer, arr_integers);
   FETCH c_check INTO v_result;
   CLOSE c_check;
   --
   -- Print the result.
   dbms_output.put_line(v_integer||' is '||
                        CASE WHEN v_result IS NULL THEN 'not '
                             ELSE ''
                        END||
                        'in the range ('||v_range||')');
   --
   -- Check whether an integer exists in the collection.
   v_integer := 15;
   v_result  := NULL;
   --
   OPEN c_check (v_integer, arr_integers);
   FETCH c_check INTO v_result;
   CLOSE c_check;
   --
   -- Print the result.
   dbms_output.put_line(v_integer||' is '||
                        CASE WHEN v_result IS NULL THEN 'not '
                             ELSE ''
                        END||
                        'in the range ('||v_range||')');
--
END;
/
--
-- Drop the DB collection.
DROP TYPE tab_integers;