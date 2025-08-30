# Pipelined Functions

## Create database types

```sql
CREATE OR REPLACE TYPE department_record AS OBJECT (
    department_id INTEGER
    , name VARCHAR2(20)
);
/

CREATE OR REPLACE TYPE department_table AS TABLE OF department_record;
/

CREATE OR REPLACE TYPE employee_record AS OBJECT (
    employee_id INTEGER
    , department_id INTEGER
    , name VARCHAR2(20)
);
/

CREATE OR REPLACE TYPE employee_table AS TABLE OF employee_record;
/
```

## Create functions

```sql
CREATE OR REPLACE FUNCTION get_departments RETURN department_table PIPELINED AS
BEGIN
    FOR i IN (
        SELECT 1 department_id, 'HR' name FROM dual UNION
        SELECT 2 department_id, 'Sales' name FROM dual UNION
        SELECT 3 department_id, 'Support' name FROM dual UNION
        SELECT 4 department_id, 'Research' name FROM dual
    ) LOOP
        PIPE ROW(department_record(i.department_id, i.name));
    END LOOP;
    RETURN;
END;
/

CREATE OR REPLACE FUNCTION get_employees RETURN employee_table PIPELINED AS
BEGIN
    FOR i IN (
        SELECT 1 employee_id, 1 department_id, 'Jane' name FROM dual UNION
        SELECT 2 employee_id, 2 department_id, 'John' name FROM dual UNION
        SELECT 3 employee_id, 3 department_id, 'James' name FROM dual UNION
        SELECT 4 employee_id, 4 department_id, 'Janice' name FROM dual
    ) LOOP
        PIPE ROW(employee_record(i.employee_id, i.department_id, i.name));
    END LOOP;
    RETURN;
END;
/
```

## Query the functions

```sql
SQL> SELECT e.name
  2      , d.name department_name
  3  FROM get_departments() d
  4  JOIN get_employees() e ON e.department_id = d.department_id;

NAME      DEPARTMENT_NAME    
_________ __________________ 
Jane      HR                 
John      Sales              
James     Support            
Janice    Research
```

## Clean up

```sql
DROP FUNCTION get_employees;
DROP FUNCTION get_departments;
DROP TYPE employee_table;
DROP TYPE department_table;
DROP TYPE employee_record;
DROP TYPE department_record;
```
