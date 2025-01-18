-- Run this on Dev
SELECT *
FROM   (-- Dev
        SELECT name sid,
               privilege,
               grantee
        FROM   v$database,
               dba_sys_privs
        UNION
        SELECT name sid,
               granted_role privilege,
               grantee
        FROM   v$database,
               dba_role_privs
        -- UAT
        UNION
        SELECT name sid,
               privilege,
               grantee
        FROM   v$database@UAT_DBLINK,
               dba_sys_privs@UAT_DBLINK
        UNION
        SELECT name sid,
               granted_role privilege,
               grantee
        FROM   v$database@UAT_DBLINK,
               dba_role_privs@UAT_DBLINK
        -- PP
        UNION
        SELECT name sid,
               privilege,
               grantee
        FROM   v$database@PP_DBLINK.WORLD,
               dba_sys_privs@PP_DBLINK.WORLD
        UNION
        SELECT name sid,
               granted_role privilege,
               grantee
        FROM   v$database@PP_DBLINK.WORLD,
               dba_role_privs@PP_DBLINK.WORLD
        -- Prod
        UNION
        SELECT name sid,
               privilege,
               grantee
        FROM   v$database@PROD_DBLINK.WORLD,
               dba_sys_privs@PROD_DBLINK.WORLD
        UNION
        SELECT name sid,
               granted_role privilege,
               grantee
        FROM   v$database@PROD_DBLINK.WORLD,
               dba_role_privs@PROD_DBLINK.WORLD)
PIVOT  (MIN('Y')
FOR     grantee IN ('USER1' AS "USER1",
                    'USER2' AS "USER2",
                    'USER3' AS "USER3"))
WHERE  privilege = 'DBA' -- Put list of roles and privileges here
ORDER BY privilege,
         CASE sid
            WHEN 'DEV_SID'  THEN 1
            WHEN 'UAT_SID'  THEN 2
            WHEN 'PP_SID'   THEN 3
            WHEN 'PROD_SID' THEN 4
         END
/