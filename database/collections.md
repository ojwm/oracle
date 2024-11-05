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
    --
    TYPE t_header_list IS TABLE OF t_header INDEX BY BINARY_INTEGER;
    --
    FUNCTION get_headers(
        p_header_list IN t_header_list DEFAULT NEW t_header_list()
    ) RETURN CLOB;
END http_test_pkg;
/

CREATE OR REPLACE PACKAGE BODY http_test_pkg AS
    FUNCTION get_headers(
        p_header_list IN t_header_list DEFAULT NEW t_header_list()
    ) RETURN CLOB IS
        v_crlf CONSTANT CHAR(2) := CHR(13)||CHR(10);
        v_header_text CLOB;
    BEGIN
        IF p_header_list.COUNT > 0 THEN
            FOR i IN p_header_list.FIRST..p_header_list.LAST LOOP
                v_header_text := v_header_text
                    ||'Name : '||p_header_list(i).name||v_crlf
                    ||'Value: '||p_header_list(i).value||v_crlf;
            END LOOP;
        END IF;
        RETURN v_header_text;
    END get_headers;
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
    dbms_output.put_line(http_test_pkg.get_headers(p_header_list => v_header_list));
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
