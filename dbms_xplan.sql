SELECT plan_table_output
FROM   TABLE(dbms_xplan.display_cursor('af8439wt24yfm',0,'TYPICAL'));