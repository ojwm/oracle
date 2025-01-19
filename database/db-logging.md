# Database Logging

## SQLcl & SQL*Plus

Use `SPOOL` to log script output to a file.

```sql
-- Substitution variable 1 is the base file name
-- This column will hold the full file name
COLUMN log_file new_value log_file NOPRINT
-- This date format will be appended to the file name
DEFINE date_format = 'YYYY-MM-DD_HH24-MI-SS'

-- Combine the database name with the system timestamp and remove any special characters
-- The CONCAT character '.' is used to terminate the substitution variable
SELECT TRANSLATE(
        '&1._'||SYS_CONTEXT('USERENV', 'DB_UNIQUE_NAME')||'_'||TO_CHAR(SYSTIMESTAMP, '&date_format')||'.log'
        , '<>:"/\|?*'
        , '_________'
    ) log_file
FROM dual;

-- Spool output to the file
SPOOL &log_file

-- Do stuff
SELECT 'Hello World!'
FROM dual;
```
