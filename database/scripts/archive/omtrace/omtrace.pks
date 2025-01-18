CREATE OR REPLACE PACKAGE omtrace IS
   --
   FUNCTION get_current_db_user
      RETURN VARCHAR2;
   --
   FUNCTION get_current_os_user
      RETURN VARCHAR2;
   --
   FUNCTION next_line_id (p_program IN omtrace_out.program_id%TYPE)
      RETURN omtrace_out.line_id%TYPE;
   --
   PROCEDURE clear_trace (p_program IN omtrace_out.program_id%TYPE);
   --
   PROCEDURE put_line (p_program IN omtrace_out.program_id%TYPE,
                       p_message IN omtrace_out.message%TYPE);
   --
   PROCEDURE read_trace (p_program IN omtrace_out.program_id%TYPE,
                         p_db_user IN omtrace_out.user_db%TYPE DEFAULT NULL,
                         p_os_user IN omtrace_out.user_os%TYPE DEFAULT NULL);
--
END omtrace;