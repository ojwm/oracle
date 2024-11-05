# Collections

## See also

* <https://docs.oracle.com/en/database/oracle/oracle-database/23/lnpls/plsql-collections-and-records.html>.

## Associative arrays

* Also known as PL/SQL tables.
* Can be referenced like any other PL/SQL type.
* Cannot be referenced in SQL.

```sql
CREATE OR REPLACE PACKAGE http_test_pkg AS
    TYPE t_header IS RECORD (
        name VARCHAR2(40)
        , value VARCHAR2(32767)
    );
    TYPE t_header_list IS TABLE OF t_header INDEX BY BINARY_INTEGER;
END http_test_pkg;
/
```

```sql
SET SERVEROUTPUT ON
DECLARE
    v_header http_test_pkg.t_header;
    v_header_list http_test_pkg.t_header_list;
BEGIN
    v_header.name := 'Content-Type';
    v_header.value := 'application/json';
    --
    v_header_list(v_header_list.COUNT) := v_header;
    --
    FOR i IN v_header_list.FIRST..v_header_list.LAST LOOP
        dbms_output.put_line('Name : '||v_header_list(i).name);
        dbms_output.put_line('Value: '||v_header_list(i).value);
    END LOOP;
END;
/
```

```text
Name : Content-Type
Value: application/json

PL/SQL procedure successfully completed.
```

```sql
DROP PACKAGE http_test_pkg;
```
