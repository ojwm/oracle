# APEX Application Availability

<https://docs.oracle.com/en/database/oracle/apex/24.1/aeapi/APEX_APPLICATION_ADMIN.SET_APPLICATION_STATUS-Procedure.html>.

## Disable an application

```sql
BEGIN
    apex_application_admin.set_application_status(
        p_application_id => 100
        , p_application_status => apex_application_admin.c_app_unavailable_show_plsql
        , p_plsql_code => 'htp.p(''<h1>Application Unavailable</h1><p>&APP_NAME. is unavailable, due to planned maintenance.</p>'')'
    );
    COMMIT;
END;
/
```

## Enable an application

```sql
BEGIN
    apex_application_admin.set_application_status(
        p_application_id => 100
        , p_application_status => apex_application_admin.c_app_available
    );
    COMMIT;
END;
/
```
