# Administration Services

Administration Services can be disabled for an APEX instance.

```sql
DECLARE
    v_enable CONSTANT BOOLEAN := FALSE;
    v_enable_flag CONSTANT BOOLEAN := CASE WHEN v_enable THEN 'Y' ELSE 'N' END;
BEGIN
    apex_instance_admin.set_parameter('DISABLE_ADMIN_LOGIN', v_enable_flag);
    apex_instance_admin.set_parameter('DISABLE_WORKSPACE_LOGIN', v_enable_flag);
    COMMIT;
END;
/
```
