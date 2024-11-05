-- Search all current sessions for bad selects run today
SELECT s.username,
       s.sid,
       s.serial#,
       s.logon_time,
       s.status,
       p.hash_value,
       p.object_name,
       p.operation,
       p.options,
       p.child_number
FROM   (SELECT s2.username,
               s2.sid,
               s2.serial#,
               s2.status,
               s2.sql_hash_value,
               s2.logon_time
        FROM   v$session s2
        WHERE  trunc(s2.logon_time)  = trunc(SYSDATE)
        AND    s2.username          IS NOT NULL) s,
       v$sql_plan p
WHERE  p.hash_value    = s.sql_hash_value 
AND    p.options    LIKE '%FULL%'
AND    p.options      != 'FULL'
ORDER BY s.status,
         s.username