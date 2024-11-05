-- Show all roles granted to a user or role
-- Use CONNECT BY to handle roles granted to roles
-- Put the specified grantee at the top of the ORDER BY list
SELECT r.grantee,
       r.granted_role
FROM   dba_role_privs r
START WITH r.grantee = '&&grantee'
CONNECT BY NOCYCLE (PRIOR r.granted_role) = r.grantee
ORDER BY CASE grantee WHEN '&&grantee' THEN '0' ELSE grantee END,
         r.granted_role
/

-- Show all system privileges granted to a user or role
-- Use CONNECT BY to handle roles granted to roles
-- Put the specified grantee at the top of the ORDER BY list
SELECT *
FROM   (SELECT s.grantee,
               s.privilege
        FROM   dba_sys_privs s,
               dba_role_privs r
        WHERE  s.grantee = r.granted_role
        START WITH r.grantee = '&&grantee'
        CONNECT BY NOCYCLE (PRIOR r.granted_role) = r.grantee
        UNION
        SELECT s.grantee,
               s.privilege
        FROM   dba_sys_privs s
        WHERE  s.grantee = '&&grantee'
        GROUP BY grantee,
                 privilege)
ORDER BY CASE grantee WHEN '&&grantee' THEN '0' ELSE grantee END,
         privilege
/

-- Show all table privileges granted to a user or role
-- Use CONNECT BY to handle roles granted to roles
-- *** THIS IS SLOW ***
SELECT t.grantee,
       t.owner,
       t.table_name,
       t.privilege
FROM   dba_tab_privs t,
       dba_role_privs r
WHERE  t.grantee = r.granted_role
START WITH r.grantee = '&&grantee'
CONNECT BY NOCYCLE (PRIOR r.granted_role) = r.grantee
GROUP BY t.grantee,
         t.owner,
         t.table_name,
         t.privilege
ORDER BY t.grantee,
         t.owner,
         t.table_name,
         t.privilege
/