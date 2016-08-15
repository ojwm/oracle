create table bad_rows (row_id rowid);
set serveroutput on

declare
nrows number;
badrows number;
begin
 badrows:=0;
 nrows:=0;
 for i in (select /*+ index (tab1.oli_index) */ rowid, col1 from oli_test tab1) loop
  begin
   insert into good_rows select 
   col1
   from oli_test where rowid=i.rowid;

   if (mod(nrows,10000)=0) then commit; end if;

  exception when others then
   badrows:=badrows+1;
   insert into bad_rows values (i.rowid);
   commit;
  end;
  nrows:=nrows+1;
 end loop;
 dbms_output.put_line('Total rows: '||to_char(nrows)||' Bad rows: '||to_char(badrows));
end;
