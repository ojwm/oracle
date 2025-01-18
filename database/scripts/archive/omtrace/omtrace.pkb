CREATE OR REPLACE PACKAGE BODY omtrace IS
------------------------------------------------------------------------------
-- omtrace package.
-- Suite of tools to allow developers to add trace messages to their code
-- and have the output stored in a table (omtrace_out), which is easy to
-- access/manipulate manually or by the provided procedures.
------------------------------------------------------------------------------
-- Change History
------------------------------------------------------------------------------
-- Version     1.0
-- Date        02-SEP-2008
-- Comments    Initial release
------------------------------------------------------------------------------
   --
   -- get_current_db_user function.
   -- Gets the current Oracle user.
   FUNCTION get_current_db_user
      RETURN VARCHAR2 IS
      --
      v_db_user VARCHAR2(100);
   --
   BEGIN
      --
      SELECT user
      INTO   v_db_user
      FROM   dual;
      --
      RETURN v_db_user;
   --
   EXCEPTION
      --
      WHEN others THEN
         --
         dbms_output.put_line('get_current_db_user error: ');
         dbms_output.put_line(SQLERRM); 
   --
   END get_current_db_user;
   --
   -- get_current_os_user function.
   -- Gets the current OS user.
   FUNCTION get_current_os_user
      RETURN VARCHAR2 IS
      --
      v_os_user VARCHAR2(100);
   --
   BEGIN
      --
      SELECT SYS_CONTEXT('USERENV','OS_USER')
      INTO   v_os_user
      FROM   dual;
      --
      RETURN v_os_user;
   --
   EXCEPTION
      --
      WHEN others THEN
         --
         dbms_output.put_line('get_current_os_user error: ');
         dbms_output.put_line(SQLERRM); 
   --
   END get_current_os_user;
   --
   -- next_line_id function.
   -- Gets the next available line ID for the given program and current user.
   -- Returns 1 if no trace messages exist.
   FUNCTION next_line_id (p_program IN omtrace_out.program_id%TYPE)
      RETURN omtrace_out.line_id%TYPE IS
      --
      v_next_line_id omtrace_out.line_id%TYPE;
   --
   BEGIN
      --
      SELECT NVL(MAX(o.line_id), 0) + 1
      INTO   v_next_line_id
      FROM   omtrace_out o
      WHERE  o.program_id = p_program
      AND    o.user_db    = get_current_db_user
      AND    o.user_os    = get_current_os_user;
      --
      RETURN v_next_line_id;
   --
   EXCEPTION
      --
      WHEN others THEN
         --
         dbms_output.put_line('omtrace.next_line_id error:');
         dbms_output.put_line(SQLERRM);
   --
   END next_line_id;
   --
   -- clear_lines procedure.
   -- Removes all trace messages for the given program and current user.
   PROCEDURE clear_trace (p_program IN omtrace_out.program_id%TYPE) IS
   --
   BEGIN
      --
      DELETE FROM omtrace_out o
      WHERE o.program_id = p_program
      AND   o.user_db    = get_current_db_user
      AND   o.user_os    = get_current_os_user;
   --
   EXCEPTION
      --
      WHEN others THEN
         --
         dbms_output.put_line('omtrace.clear_trace error:');
         dbms_output.put_line(SQLERRM);
   --
   END clear_trace;

   --
   -- put_line procedure.
   -- Adds a trace message to the omtrace table
   -- using the next available line ID.
   PROCEDURE put_line (p_program IN omtrace_out.program_id%TYPE,
                       p_message IN omtrace_out.message%TYPE) IS
   --
   BEGIN
      --
      INSERT INTO omtrace_out
        (program_id,
         line_id,
         user_db,
         user_os,
         message,
         timestamp)
      VALUES
        (p_program,
         next_line_id(p_program),
         get_current_db_user,
         get_current_os_user,
         p_message,
         SYSDATE);
      --
      COMMIT;
   --
   EXCEPTION
      --
      WHEN others THEN
         --
         dbms_output.put_line('omtrace.put_line error:');
         dbms_output.put_line(SQLERRM);
   --
   END put_line;
   --
   -- read_trace procedure.
   -- Outputs all lines from omtrace for the given program and given user.
   PROCEDURE read_trace
     (p_program IN omtrace_out.program_id%TYPE,
      p_db_user IN omtrace_out.user_db%TYPE DEFAULT NULL,
      p_os_user IN omtrace_out.user_os%TYPE DEFAULT NULL) IS
      --
      -- c_lines cursor.
      -- Select all lines for the given program and user in line order.
      CURSOR c_lines
        (p_program IN omtrace_out.program_id%TYPE,
         p_db_user IN omtrace_out.user_db%TYPE,
         p_os_user IN omtrace_out.user_os%TYPE) IS
         --
         SELECT o.timestamp,
                o.message
         FROM   omtrace_out o
         WHERE  o.program_id = p_program
         AND    o.user_db    = p_db_user
         AND    o.user_os    = p_os_user
         ORDER BY line_id ASC;
      --
      v_db_user omtrace_out.user_db%TYPE;
      v_os_user omtrace_out.user_os%TYPE;
   --
   BEGIN
      --
      -- If a DB user has not been specified then use the current DB user.
      IF p_db_user IS NULL THEN
         --
         v_db_user := get_current_db_user;
      --
      ELSE
         --
         v_db_user := p_db_user;
      --
      END IF;
      --
      -- If an OS user has not been specified then use the current OS user.
      IF p_os_user IS NULL THEN
         --
         v_os_user := get_current_os_user;
      --
      ELSE
         --
         v_os_user := p_os_user;
      --
      END IF;
      --
      FOR c IN c_lines(p_program, v_db_user, v_os_user) LOOP
         --
         dbms_output.put_line(p_program                         ||
                              ' - '                             ||
                              to_char(c.timestamp, 'HH24:MI:SS')||
                              ': '                              ||
                              c.message);
      --
      END LOOP;
   --
   EXCEPTION
      --
      WHEN no_data_found THEN
         --
         dbms_output.put_line('read_trace error: No trace messages found for '||
                              p_program);
      --
      WHEN others THEN
         --
         dbms_output.put_line('read_trace error: ');
         dbms_output.put_line(SQLERRM);
   --
   END read_trace;
--
END omtrace;