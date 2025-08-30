# APEX ORDS Gateway Allow List

After an ORDS upgrade, `/ords/apex` may return a HTTP 404 status with the following error.

```text
ORDS-22001: The procedure named apex could not be accessed, it may not be declared, or the user executing this request may not have been granted execute privilege on the procedure, or a function specified by security.requestValidationFunction configuration property has prevented access. Check the spelling of the procedure, check that the execute privilege has been granted to the caller and check the configured security.requestValidationFunction function. If using the PL/SQL Gateway Procedure Allow List, check that the procedure has been allowed via ords_admin.add_plsql_gateway_procedure.
```

This can be resolved by synchronising the ORDS gateway allow list.

```sql
BEGIN
    apex_listener.wwv_flow_listener.sync_ords_gateway_allow_list;
END;
/
```

After execution, check that there are rows present for the installed version of APEX.

```sql
SELECT *
FROM dba_plsql_gateway_allow_list;
```
