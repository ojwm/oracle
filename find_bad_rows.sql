create or replace procedure find_bad_rows is
nrows number;
badrows number;
begin
 dbms_output.put_line('1');
 badrows:=0;
 nrows:=0;
 dbms_output.put_line('2');
 for i in (select /*+ index (tab1.S_ACT_EMP_U2_X) */ rowid, EMP_ID, ACT_TODO_PLNEND_DT, ACT_EVT_STAT_CD from S_ACT_EMP tab1) loop
  begin
   insert into good_rows select 
   EMP_ID, ACT_TODO_PLNEND_DT, ACT_EVT_STAT_CD
   from S_ACT_EMP g where g.rowid=i.rowid;

   --if (mod(nrows,10000)=0) then commit; end if;

  exception when others then
   badrows:=badrows+1;
   insert into bad_rows values (i.rowid);
   --commit;
  end;
  nrows:=nrows+1;
 end loop;
 dbms_output.put_line('3');
 dbms_output.put_line('Total rows: '||to_char(nrows)||' Bad rows: '||to_char(badrows));
end find_bad_rows;