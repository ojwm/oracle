DECLARE
   --
   v_program_id VARCHAR2(30) := 'omtrace_test';
   --
   PROCEDURE trace (p_message IN VARCHAR2) IS
   --
   BEGIN
      --
      omtrace.put_line(v_program_id, p_message);
   --
   END trace;
--
BEGIN
   --
   dbms_output.put_line('Clearing old trace messages');
   --
   omtrace.clear_trace(v_program_id);
   --
   dbms_output.put_line('About to test trace');
   --
   trace('The');
   trace('quick');
   trace('brown');
   trace('fox');
   --
   dbms_output.put_line('Finished sending trace messages');
   dbms_output.put_line('Displaying trace messages:');
   --
   omtrace.read_trace(v_program_id);
   --
   dbms_output.put_line('End of trace test');
--
EXCEPTION
   --
   WHEN others THEN
      --
      dbms_output.put_line('Error: '||SQLERRM);
--
END;