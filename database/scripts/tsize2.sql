set serveroutput on size 1000000
variable table_name varchar2(50)
variable number_of_rows number
ACCEPT table_name PROMPT 'Please Enter Table Name (Ensure table exists): '
ACCEPT number_of_rows PROMPT 'Please Enter the number of rows expected : '

declare

   cursor c_get_info (c_table in varchar2) IS
      SELECT data_type,
             data_length,
             data_precision,
             column_name
      FROM   user_tab_columns
      WHERE  table_name = UPPER(c_table);

   cursor c_get_indx (c_table in varchar2) is
      select distinct(index_name) index_name
      from   all_ind_columns
      where  table_name = UPPER(c_table);

   cursor c_get_cols (c_index in varchar2,
                      c_table in varchar2) is
      select a.column_name    column_name,
             u.data_type      data_type,
             u.data_length    data_length,
             u.data_precision data_precision
      from   all_ind_columns a,
             user_tab_columns u
      where  a.index_name = c_index
      and    a.table_name = upper(c_table)
      and    a.table_name = u.table_name
      and    a.column_name = u.column_name;

   v_table_name    varchar2(50) := '&table_name';
   v_tmp           varchar2(50);
   v_rows          number       := &number_of_rows;
   v_no_rows       number; 
   v_row_length    number;
   v_break_it      varchar2(1);
   v_no_db_blocks  number;
   v_space_reqd    number;
   v_next_ext      number;
   v_space_MB      number;
   v_next_MB       number;
   v_average_len   number;
   v_count_rows    number;
   v_temp_name     varchar2(50);
   v_curs          integer;
   v_who_cares     number;
   ctrl_run_prog   varchar2(1000);
   exit_proc       exception;
   v_indx_name     varchar2(50);
   v_no_ind_blocks number;
   v_no_leaves     number;

begin

   v_row_length := 0;

   begin

      v_curs := dbms_sql.open_cursor;

      ctrl_run_prog := 'select count(*) from '||v_table_name;

      dbms_sql.parse(v_curs, ctrl_run_prog, dbms_sql.native);

      dbms_sql.define_column(v_curs, 1, v_count_rows);
 
      v_who_cares := dbms_sql.execute(v_curs);

      LOOP
 
         IF dbms_sql.fetch_rows(v_curs) = 0 THEN
            exit;
         end if;
 
         dbms_sql.column_value(v_curs, 1, v_count_rows);
 
      end loop;
 
      dbms_sql.close_cursor(v_curs);

      exception

         when others then

            dbms_output.put_line('Bugger '||sqlerrm||' '||sqlcode);
            raise exit_proc;

      end;

dbms_output.put_line('*******************************************************');
dbms_output.put_line('Running Extent Calculation for '||v_table_name);
dbms_output.put_line('with '||v_rows||' Rows...');
dbms_output.put_line('*******************************************************');
dbms_output.put_line('');

   FOR l_c_get_info in c_get_info (v_table_name) LOOP

      IF l_c_get_info.data_type = 'VARCHAR2' then

         IF v_count_rows > 0 THEN

            begin

               v_curs := dbms_sql.open_cursor;

               ctrl_run_prog := 'select sum(length(ltrim(nvl('||
                                l_c_get_info.column_name||
                                ',0)))) from '||v_table_name;

               v_average_len := 0;

               dbms_sql.parse(v_curs, ctrl_run_prog, dbms_sql.native);

               dbms_sql.define_column(v_curs, 1, v_average_len);

               v_who_cares := dbms_sql.execute(v_curs);

               LOOP

                  IF dbms_sql.fetch_rows(v_curs) = 0 THEN
                     exit;
                  end if;

                  dbms_sql.column_value(v_curs, 1, v_average_len);

               end loop;

               dbms_sql.close_cursor(v_curs);

            exception

               when others then

                  dbms_output.put_line('Bugger : '||sqlerrm||' '||sqlcode);
                  raise exit_proc;

            end;

            v_average_len := ceil(v_average_len / v_count_rows);

            v_row_length  := v_row_length + v_average_len + 3;

         else

            v_row_length := v_row_length + l_c_get_info.data_length + 3;

         end if;

      ELSIF l_c_get_info.data_type = 'NUMBER' then

         IF v_count_rows > 0 THEN

            begin
 
               v_curs := dbms_sql.open_cursor;
 
               ctrl_run_prog := 'select ceil(sum(length(nvl('||
                                l_c_get_info.column_name||',0))))'||
                                ' from '||v_table_name;

               v_average_len := 0;
 
               dbms_sql.parse(v_curs, ctrl_run_prog, dbms_sql.native);
 
               dbms_sql.define_column(v_curs, 1, v_average_len);
 
               v_who_cares := dbms_sql.execute(v_curs);
 
               LOOP
 
                  IF dbms_sql.fetch_rows(v_curs) = 0 THEN
                     exit;
                  end if;
 
                  dbms_sql.column_value(v_curs, 1, v_average_len);
 
               end loop;
 
               dbms_sql.close_cursor(v_curs);
 
            exception
 
               when others then
 
                  dbms_output.put_line('Bugger : '||sqlerrm||' '||sqlcode);
                  raise exit_proc;
 
            end;

            v_average_len := v_average_len / v_count_rows;
            v_row_length := v_row_length + (ceil(v_average_len / 2) + 1);

         else

            v_row_length := v_row_length + (
                            ceil(nvl(l_c_get_info.data_precision,
                                     l_c_get_info.data_length) / 2) + 1);

         end if;

      ELSIF l_c_get_info.data_type = 'DATE' then

         v_row_length := v_row_length + 8;

      ELSIF l_c_get_info.data_type = 'ROWID' then

         v_row_length := v_row_length + 7;

      ELSIF l_c_get_info.data_type = 'CHAR' then

         IF v_count_rows > 0 THEN

            begin
 
               v_curs := dbms_sql.open_cursor;
 
               ctrl_run_prog := 'select ceil(sum(length(nvl('||
                                l_c_get_info.column_name||',0))))'||
                                ' from '||v_table_name;
 
               v_average_len := 0;
 
               dbms_sql.parse(v_curs, ctrl_run_prog, dbms_sql.native);
 
               dbms_sql.define_column(v_curs, 1, v_average_len);
 
               v_who_cares := dbms_sql.execute(v_curs);
 
               LOOP
 
                  IF dbms_sql.fetch_rows(v_curs) = 0 THEN
                     exit;
                  end if;
 
                  dbms_sql.column_value(v_curs, 1, v_average_len);
 
               end loop;
 
               dbms_sql.close_cursor(v_curs);
 
            exception
 
               when others then
 
                  dbms_output.put_line('Bugger : '||sqlerrm||' '||sqlcode);
                  raise exit_proc;
 
            end;
 
            v_average_len := v_average_len / v_count_rows;
            v_row_length := v_row_length + v_average_len + 1;

         else

            v_row_length := v_row_length + l_c_get_info.data_length + 1;

         end if;

      ELSIF l_c_get_info.data_type = 'LONG' then

         IF v_count_rows > 0 THEN

            begin
 
               v_curs := dbms_sql.open_cursor;
 
               ctrl_run_prog := 'select ceil(sum(length(nvl('||
                                l_c_get_info.column_name||',0))))'||
                                ' from '||v_table_name;
 
               v_average_len := 0;
 
               dbms_sql.parse(v_curs, ctrl_run_prog, dbms_sql.native);
 
               dbms_sql.define_column(v_curs, 1, v_average_len);
 
               v_who_cares := dbms_sql.execute(v_curs);
 
               LOOP
 
                  IF dbms_sql.fetch_rows(v_curs) = 0 THEN
                     exit;
                  end if;
 
                  dbms_sql.column_value(v_curs, 1, v_average_len);
 
               end loop;
 
               dbms_sql.close_cursor(v_curs);
 
            exception
 
               when others then
 
                  dbms_output.put_line('Bugger : '||sqlerrm||' '||sqlcode);
                  raise exit_proc;
 
            end;
 
            v_average_len := v_average_len / v_count_rows;
            v_row_length := v_row_length + v_average_len + 3;

         else

            v_row_length := v_row_length + l_c_get_info.data_length + 3;

         end if;

      ELSE

         dbms_output.put_line('UNKNOWN datatype '||l_c_get_info.data_type||
                              ' please contact blah blah blah...');

         select 'Y'
         into   v_break_it
         from   dual
         where  1=0;

      end if;

   END LOOP;

   v_row_length   := v_row_length + 5; --ADD 5 FOR FIXED OVERHEAD

   v_no_rows      := floor(3610/v_row_length);
   v_no_db_blocks := ceil(v_rows/v_no_rows);
   v_space_reqd   := v_no_db_blocks * 4;
   v_space_reqd   := v_space_reqd * 1.1;
   v_next_ext     := v_space_reqd * 0.25;
   v_space_MB     := ceil(v_space_reqd / 1024);
   v_next_MB      := ceil(v_next_ext / 1024);

   IF v_space_reqd < 8 THEN
      v_space_reqd := 8;
   END IF;

   IF v_next_ext < 4 THEN
      v_next_ext := 4;
   END IF;

   dbms_output.put_line('');
   dbms_output.put_line('****************************************************');
   dbms_output.put_line('Initial Storage is '||ceil(v_space_reqd)||' K or '||
                        v_space_MB||' MB.');
   dbms_output.put_line('Next Extent is '||ceil(v_next_ext)||' K or '||
                        v_next_MB||' MB.');
   dbms_output.put_line('****************************************************');

   FOR l_c_get_indx IN c_get_indx (v_table_name) LOOP

      v_indx_name  := l_c_get_indx.index_name;
      v_row_length := 0;

      FOR l_c_get_cols in c_get_cols (v_indx_name, v_table_name) LOOP

         begin

            IF l_c_get_cols.data_type = 'VARCHAR2' then

               IF v_count_rows > 0 THEN

                  begin
 
                     v_curs := dbms_sql.open_cursor;
 
                     ctrl_run_prog := 'select sum(length(ltrim(nvl('||
                                      l_c_get_cols.column_name||
                                      ',0)))) from '||v_table_name;
 
                     v_average_len := 0;
 
                     dbms_sql.parse(v_curs, ctrl_run_prog, dbms_sql.native);
 
                     dbms_sql.define_column(v_curs, 1, v_average_len);
 
                     v_who_cares := dbms_sql.execute(v_curs);
 
                     LOOP
 
                        IF dbms_sql.fetch_rows(v_curs) = 0 THEN
                           exit;
                        end if;
 
                        dbms_sql.column_value(v_curs, 1, v_average_len);
 
                     end loop;
 
                     dbms_sql.close_cursor(v_curs);
 
                  exception
 
                     when others then
 
                       dbms_output.put_line('Bugger : '||sqlerrm||' '||sqlcode);
                        raise exit_proc;
 
                  end;

                  v_average_len := ceil(v_average_len / v_count_rows);

                  v_row_length  := v_row_length + v_average_len + 3;
 
               else

                  v_row_length := v_row_length + l_c_get_cols.data_length + 3;
 
               end if;
 
            ELSIF l_c_get_cols.data_type = 'NUMBER' then

               IF v_count_rows > 0 THEN

                  begin
 
                     v_curs := dbms_sql.open_cursor;
 
                     ctrl_run_prog := 'select ceil(sum(length(nvl('||
                                      l_c_get_cols.column_name||',0))))'||
                                      ' from '||v_table_name;
 
                     v_average_len := 0;
 
                     dbms_sql.parse(v_curs, ctrl_run_prog, dbms_sql.native);
 
                     dbms_sql.define_column(v_curs, 1, v_average_len);
 
                     v_who_cares := dbms_sql.execute(v_curs);
  
                     LOOP
 
                        IF dbms_sql.fetch_rows(v_curs) = 0 THEN
                           exit;
                        end if;
 
                        dbms_sql.column_value(v_curs, 1, v_average_len);
 
                     end loop;
 
                     dbms_sql.close_cursor(v_curs);
 
                  exception
 
                     when others then
 
                       dbms_output.put_line('Bugger : '||sqlerrm||' '||sqlcode);
                        raise exit_proc;
 
                  end;
 
                  v_average_len := v_average_len / v_count_rows;
                  v_row_length := v_row_length + (ceil(v_average_len / 2) + 1);
 
               else
 
                  v_row_length := v_row_length + (
                                  ceil(nvl(l_c_get_cols.data_precision,
                                           l_c_get_cols.data_length / 2)) + 1);
 
               end if;
 
            ELSIF l_c_get_cols.data_type = 'DATE' then

               v_row_length := v_row_length + 8;
 
            ELSIF l_c_get_cols.data_type = 'ROWID' then

               v_row_length := v_row_length + 7;
 
            ELSIF l_c_get_cols.data_type = 'CHAR' then

               IF v_count_rows > 0 THEN

                  begin
 
                     v_curs := dbms_sql.open_cursor;
 
                     ctrl_run_prog := 'select ceil(sum(length(nvl('||
                                      l_c_get_cols.column_name||',0))))'||
                                      ' from '||v_table_name;
 
                     v_average_len := 0;
 
                     dbms_sql.parse(v_curs, ctrl_run_prog, dbms_sql.native);
 
                     dbms_sql.define_column(v_curs, 1, v_average_len);
 
                     v_who_cares := dbms_sql.execute(v_curs);
 
                     LOOP
 
                        IF dbms_sql.fetch_rows(v_curs) = 0 THEN
                           exit;
                        end if;
 
                        dbms_sql.column_value(v_curs, 1, v_average_len);
 
                     end loop;
 
                     dbms_sql.close_cursor(v_curs);
 
                  exception
 
                     when others then
 
                       dbms_output.put_line('Bugger : '||sqlerrm||' '||sqlcode);
                        raise exit_proc;
 
                  end;
 
                  v_average_len := v_average_len / v_count_rows;
                  v_row_length := v_row_length + v_average_len + 1;
 
               else
 
                  v_row_length := v_row_length + l_c_get_cols.data_length + 1;
 
               end if;
 
            ELSIF l_c_get_cols.data_type = 'LONG' then

               IF v_count_rows > 0 THEN

                  begin
 
                     v_curs := dbms_sql.open_cursor;
 
                     ctrl_run_prog := 'select ceil(sum(length(nvl('||
                                      l_c_get_cols.column_name||',0))))'||
                                      ' from '||v_table_name;
 
                     v_average_len := 0;
 
                     dbms_sql.parse(v_curs, ctrl_run_prog, dbms_sql.native);
 
                     dbms_sql.define_column(v_curs, 1, v_average_len);
 
                     v_who_cares := dbms_sql.execute(v_curs);
 
                     LOOP
 
                        IF dbms_sql.fetch_rows(v_curs) = 0 THEN
                           exit;
                        end if;
 
                        dbms_sql.column_value(v_curs, 1, v_average_len);
  
                     end loop;
 
                     dbms_sql.close_cursor(v_curs);
 
                  exception
 
                     when others then
 
                       dbms_output.put_line('Bugger : '||sqlerrm||' '||sqlcode);
                        raise exit_proc;
 
                  end;
 
                  v_average_len := v_average_len / v_count_rows;
                  v_row_length := v_row_length + v_average_len + 3;
 
               else
 
                  v_row_length := v_row_length + l_c_get_cols.data_length + 3;
 
               end if;
 
            ELSE
 
              dbms_output.put_line('UNKNOWN datatype '||l_c_get_cols.data_type||
                                    ' please contact blah blah blah...');
 
               select 'Y'
               into   v_break_it
               from   dual
               where  1=0;
 
            end if;

         exception

            when others then 
               dbms_output.put_line('Poo : '||sqlerrm||' '||sqlcode);
               raise exit_proc;
 
         end;

      end loop;

      v_row_length    := v_row_length + 7; --ADD 7 FOR FIXED OVERHEAD.
      v_no_ind_blocks := floor(3540 / v_row_length);
      v_no_leaves     := ceil (v_rows/v_no_ind_blocks) * 1.1;
      v_space_reqd    := ceil((v_no_leaves * 4) * 1.5);
      v_next_ext      := ceil(v_space_reqd * 0.25);
      v_space_MB      := ceil(v_space_reqd / 1024);
      v_next_MB       := ceil(v_next_ext   / 1024);

      dbms_output.put_line('');
      dbms_output.put_line('*************************************************');
      dbms_output.put_line('STORAGE FOR INDEX '||l_c_get_indx.index_name);
      dbms_output.put_line('*************************************************');
      dbms_output.put_line('Storage initial '||v_space_reqd||'k or '||
                           v_space_MB||'MB.');
      dbms_output.put_line('Next extent '||v_next_ext||'k or '||v_next_MB||
                           'MB.');
      dbms_output.put_line('*************************************************');

      v_row_length := 0;

   end loop;

exception

when exit_proc then
   null;

when others then

   dbms_output.put_line('Bugger '||sqlerrm||' '||sqlcode);

end;
/
