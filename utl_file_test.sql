DECLARE
   --
   v_file      utl_file.file_type;
   v_data_file VARCHAR2(30);
--
BEGIN
   --
   dbms_output.put_line('1');
   --
   v_data_file := 'hello.txt';
   v_file      := utl_file.fopen('UTL_PATH', v_data_file, 'w');
   --
   dbms_output.put_line('2');
   --
   utl_file.put_line(v_file, 'Hello World!');
   --
   dbms_output.put_line('3');
   --
   utl_file.fclose(v_file);
   --
   dbms_output.put_line('4');
--
EXCEPTION
   --
   WHEN others THEN
      --
      dbms_output.put_line('Others: '||SQLERRM);
      --
      utl_file.fclose(v_file);
--
END;