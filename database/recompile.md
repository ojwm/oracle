# Recompile

## Schema

```sql
DECLARE
    v_owner CONSTANT all_objects.owner%TYPE := '&schema_name';
    v_max_attempts CONSTANT INTEGER := 3;
    v_attempt INTEGER := 0;
    --
    FUNCTION has_invalid_objects (p_owner IN all_objects.owner%TYPE) RETURN BOOLEAN IS
    BEGIN
        FOR i IN (
            SELECT NULL
            FROM dual
            WHERE EXISTS (
                SELECT NULL
                FROM all_objects
                WHERE UPPER(owner) = UPPER(p_owner)
                AND UPPER(status) = 'INVALID'
            )
        ) LOOP
            RETURN TRUE;
        END LOOP;
        RETURN FALSE;
    END has_invalid_objects;
BEGIN
    WHILE v_attempt < v_max_attempts AND has_invalid_objects(p_owner => v_owner) LOOP
        v_attempt := v_attempt+1;
        dbms_utility.compile_schema(UPPER(v_owner), FALSE);
    END LOOP;
    --
    IF v_attempt >= v_max_attempts AND has_invalid_objects(p_owner => v_owner) THEN
        RAISE_APPLICATION_ERROR(-20001, 'Recompile failed for schema "'||v_owner||'"');
    END IF;
END;
/
```
