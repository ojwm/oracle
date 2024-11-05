select *
from   sa.inc_prior
/

-- open incidents assigned to a queue
SELECT i.incident_ref,
       se.inc_serious_sc severity,
       p.inc_prior_sc priority,
       i.callback_rmk  short_desc,
       i.inc_resolve_due resolution_due,
       CASE WHEN i.inc_resolve_due >= SYSDATE THEN 'OK' ELSE 'PASSED' END sla,
       u.assyst_usr_n
FROM   sa.incident i,
       sa.serv_dept s,
       sa.assyst_usr u,
       sa.inc_serious se,
       sa.inc_prior p
WHERE  i.ass_svd_id      = s.serv_dept_id
AND    u.assyst_usr_id   = i.ass_usr_id
AND    se.inc_serious_id = i.inc_serious_id
AND    p.inc_prior_id    = i.inc_prior_id
AND    s.serv_dept_sc    = '&serv_dept_sc'
AND    i.event_type      = 'i'
AND    i.inc_status      = 'o'
/

-- incidents and service requests resolved in last x days
SELECT i.incident_ref,
       c.inc_cat_sc      category,
       i.callback_rmk    short_desc,
       i.date_logged,
       i.inc_resolve_due resolution_due,
       u.assyst_usr_sc   assigned_user,
       t.act_type_sc     action,
       a.date_actioned,
       a.act_usr_sc      racfid
FROM   sa.act_reg a,
       sa.act_type t,
       sa.assyst_usr u,
       sa.assyst_usr u2,
       sa.serv_dept s,
       sa.incident i,
       sa.inc_cat c
WHERE  a.incident_id    = i.incident_id
AND    t.act_type_id    = a.act_type_id
AND    a.assyst_usr_id  = u.assyst_usr_id
AND    u.serv_dept_id   = s.serv_dept_id
AND    s.serv_dept_sc   = '&serv_dept_sc'
AND    t.act_type_sc    = 'RESOLVED'
--AND    a.date_actioned >= trunc(SYSDATE)-5 -- x days
AND    a.date_actioned  BETWEEN trunc(add_months(SYSDATE,-1),'MM') AND trunc(last_day(add_months(SYSDATE,-1)),'DD')+1
--AND    a.date_actioned BETWEEN '01-FEB-2014' AND '28-FEB-2014'
AND    a.act_reg_id     = (SELECT MAX(a2.act_reg_id)
                           FROM   sa.act_reg a2
                           WHERE  a2.incident_id = a.incident_id
                           AND    a2.act_type_id = a.act_type_id)
AND    i.event_type     = 'i'
AND    i.inc_status    IN ('c','p')
AND    u2.assyst_usr_id = i.ass_usr_id
AND    c.inc_cat_id     = i.inc_cat_id
ORDER BY a.date_actioned
/

-- Resolved incidents
SELECT period "Month",
       NVL(SUM(DECODE(racfid,'MITCHO2',num)),0) "Oli",
       NVL(SUM(DECODE(racfid,'RASTOA1',num)),0) "Anshi",
       NVL(SUM(DECODE(racfid,'RANED',num)),0) "Devendra",
       NVL(SUM(DECODE(racfid,'KUMAM13',num)),0) "Manoj",
       NVL(SUM(DECODE(racfid,'KUMAS38',num)),0) "Sathish",
       NVL(SUM(DECODE(racfid,'PADALAS',num)),0) "Shiva"
FROM   (SELECT TO_CHAR(a.date_actioned,'YYYY-MM') period,
               a.act_usr_sc racfid,
               COUNT(*) num
        FROM   sa.act_reg a,
               sa.act_type t,
               sa.assyst_usr u,
               sa.incident i
        WHERE  a.incident_id    = i.incident_id
        AND    t.act_type_id    = a.act_type_id
        AND    a.assyst_usr_id  = u.assyst_usr_id
        AND    u.assyst_usr_sc IN ('MITCHO2','RASTOA1','RANED','KUMAM13','KUMAS38','PADALAS')
        AND    t.act_type_sc    = 'RESOLVED'
--        AND    a.date_actioned >= '01-JAN-2014'
        AND    a.date_actioned  BETWEEN TRUNC(SYSDATE,'YYYY') AND TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE,-1)),'DD')+1
        AND    a.act_reg_id     = (SELECT MAX(a2.act_reg_id)
                                   FROM   sa.act_reg a2
                                   WHERE  a2.incident_id = a.incident_id
                                   AND    a2.act_type_id = a.act_type_id)
        AND    i.event_type     = 'i'
        AND    i.inc_status    IN ('c','p')
        GROUP BY TO_CHAR(a.date_actioned,'YYYY-MM'),
                 a.act_usr_sc)
GROUP BY period
ORDER BY period
/

-- Closed changes
SELECT period "Month",
       NVL(SUM(DECODE(racfid,'MITCHO2',num)),0) "Oli",
       NVL(SUM(DECODE(racfid,'RASTOA1',num)),0) "Anshi",
       NVL(SUM(DECODE(racfid,'RANED',num)),0) "Devendra",
       NVL(SUM(DECODE(racfid,'KUMAM13',num)),0) "Manoj",
       NVL(SUM(DECODE(racfid,'KUMAS38',num)),0) "Sathish",
       NVL(SUM(DECODE(racfid,'PADALAS',num)),0) "Shiva"
FROM   (SELECT TO_CHAR(a.date_actioned,'YYYY-MM') period,
               a.act_usr_sc racfid,
               COUNT(*) num
        FROM   sa.act_reg a,
               sa.act_type t,
               sa.assyst_usr u,
               sa.incident i
        WHERE  a.incident_id    = i.incident_id
        AND    t.act_type_id    = a.act_type_id
        AND    a.assyst_usr_id  = u.assyst_usr_id
        AND    u.assyst_usr_sc IN ('MITCHO2','RASTOA1','RANED','KUMAM13','KUMAS38','PADALAS')
        AND    t.act_type_sc    = 'CLOSURE'
--        AND    a.date_actioned >= '01-JAN-2014'
        AND    a.date_actioned  BETWEEN TRUNC(SYSDATE,'YYYY') AND TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE,-1)),'DD')+1
        AND    a.act_reg_id     = (SELECT MAX(a2.act_reg_id)
                                   FROM   sa.act_reg a2
                                   WHERE  a2.incident_id = a.incident_id
                                   AND    a2.act_type_id = a.act_type_id)
        AND    i.event_type     = 'c'
        AND    i.inc_status     = 'c'
        GROUP BY TO_CHAR(a.date_actioned,'YYYY-MM'),
                 a.act_usr_sc)
GROUP BY period
ORDER BY period
/

-- Resolved incidents, grouped by category
SELECT category                                 "Category",
       NVL(SUM(DECODE(period,'2014-01',num)),0) "Jan",
       NVL(SUM(DECODE(period,'2014-02',num)),0) "Feb",
       NVL(SUM(DECODE(period,'2014-03',num)),0) "Mar",
       NVL(SUM(DECODE(period,'2014-04',num)),0) "Apr",
       NVL(SUM(DECODE(period,'2014-05',num)),0) "May",
       NVL(SUM(DECODE(period,'2014-06',num)),0) "Jun",
       NVL(SUM(DECODE(period,'2014-07',num)),0) "Jul",
       NVL(SUM(DECODE(period,'2014-08',num)),0) "Aug",
       NVL(SUM(DECODE(period,'2014-09',num)),0) "Sep",
       NVL(SUM(DECODE(period,'2014-10',num)),0) "Oct",
       NVL(SUM(DECODE(period,'2014-11',num)),0) "Nov",
       NVL(SUM(DECODE(period,'2014-12',num)),0) "Dec"
FROM   (SELECT c.inc_cat_sc                       category,
               TO_CHAR(a.date_actioned,'YYYY-MM') period,
               COUNT(*)                           num
        FROM   sa.inc_cat c,
               sa.act_reg a,
               sa.act_type t,
               sa.assyst_usr u,
               sa.incident i
        WHERE  c.inc_cat_id     = i.inc_cat_id
        AND    a.incident_id    = i.incident_id
        AND    t.act_type_id    = a.act_type_id
        AND    a.assyst_usr_id  = u.assyst_usr_id
        AND    u.assyst_usr_sc IN ('MITCHO2','RASTOA1','RANED','KUMAM13','KUMAS38','PADALAS')
        AND    t.act_type_sc    = 'RESOLVED'
        AND    a.date_actioned >= '01-JAN-2014'
--        AND    a.date_actioned  BETWEEN TRUNC(SYSDATE,'YYYY') AND TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE,-1)),'DD')+1
        AND    a.act_reg_id     = (SELECT MAX(a2.act_reg_id)
                                   FROM   sa.act_reg a2
                                   WHERE  a2.incident_id = a.incident_id
                                   AND    a2.act_type_id = a.act_type_id)
        AND    i.event_type     = 'i'
        AND    i.inc_status    IN ('c','p')
        GROUP BY TO_CHAR(a.date_actioned,'YYYY-MM'),
                 c.inc_cat_sc)
GROUP BY category
ORDER BY category
/

-- Data incomplete
SELECT i.incident_ref,
       i.callback_rmk               short_desc,
       to_char(trunc(i.date_logged),
               'DD-MON-YYYY')       date_logged,
       s.serv_dept_sc               logging_team,
       u2.assyst_usr_sc             logging_user,
       t.act_type_sc                action,
       u1.assyst_usr_sc             action_user,
       a.act_rmk                    action_remark
FROM   sa.act_reg a,
       sa.act_type t,
       sa.assyst_usr u1,
       sa.assyst_usr u2,
       sa.serv_dept s,
       sa.incident i
WHERE  a.incident_id    = i.incident_id
AND    t.act_type_id    = a.act_type_id
AND    a.assyst_usr_id  = u1.assyst_usr_id
AND    u2.assyst_usr_id = i.assyst_usr_id
AND    s.serv_dept_id   = u2.serv_dept_id
AND    u1.assyst_usr_sc IN ('MITCHO2','RASTOA1','RANED','KUMAM13','KUMAS38')
AND    s.serv_dept_sc   = 'UKITS SERV DESK'
AND    t.act_type_sc    = 'DATA INCOMPLETE'
AND    a.date_actioned >= trunc(SYSDATE,'YYYY')
AND    i.event_type     = 'i'
ORDER BY i.incident_ref
/

-- Incidents assigned to queue by another queue
SELECT a.incident_id
FROM   sa.act_reg a,
       sa.incident i
WHERE  a.incident_id  = i.incident_id
AND    i.event_type   = 'i'
AND    i.date_logged >= TRUNC(SYSDATE,'YYYY')
AND    a.ass_svd_sc   = 'UKHE DB SUPP'
AND    a.act_svd_sc   = 'UKITS SERV DESK'
--AND    i.incident_ref = 12918956
GROUP BY a.incident_id
/

-- Incidents assigned to queue and not subsequently deemed incorrectly assigned
SELECT i.incident_ref,
       MIN(TRUNC(a.date_actioned))
FROM   sa.act_reg a,
       sa.incident i,
       sa.inc_data d
WHERE  a.incident_id  = i.incident_id
AND    d.incident_id  = i.incident_id
AND    i.date_logged >= TRUNC(SYSDATE,'YYYY')
AND    a.ass_svd_sc   = '&serv_dept_sc'
AND    d.event_type   = 'i'
--AND    i.incident_ref = 13157294
AND NOT EXISTS (SELECT 'Y'
                FROM   sa.act_reg a2,
                       sa.act_type t,
                       sa.assyst_usr u,
                       sa.serv_dept s
                WHERE  a2.incident_id   = i.incident_id
                AND    t.act_type_id    = a2.act_type_id
                AND    t.act_type_sc    = 'INCOR ASSIGN'
                AND    a2.assyst_usr_id = u.assyst_usr_id
                AND    u.serv_dept_id   = s.serv_dept_id
                AND    s.serv_dept_sc   = '&serv_dept_sc')
GROUP BY i.incident_ref
ORDER BY 1,2
/

-- Incidents related to an item
SELECT inc.incident_ref,
       TRUNC(inc.date_logged) date_logged
FROM   sa.incident inc,
       sa.item itm
WHERE  inc.event_type = 'i'
AND    itm.item_id    = inc.item_id
AND    (itm.item_sc = 'SVC GROUP RISK QUOTE' OR
        itm.item_sc = 'ADMINISTRATOR (UKHE)  [PRD]')
/

-- Incidents related to an item, grouped by date logged
SELECT TRUNC(inc.date_logged) date_logged,
       COUNT(*)
FROM   sa.incident inc,
       sa.item itm
WHERE  inc.event_type = 'i'
AND    itm.item_id    = inc.item_id
AND    (itm.item_sc = 'SVC GROUP RISK QUOTE' OR
        itm.item_sc = 'ADMINISTRATOR (UKHE)  [PRD]')
GROUP BY TRUNC(inc.date_logged)
ORDER BY TRUNC(inc.date_logged)
/

-- Incidents related to an item, grouped by quarter logged
SELECT TO_CHAR(TRUNC(d.adate,'Q'),'YYYY')||' '||
       CASE TO_CHAR(TRUNC(d.adate,'Q'),'DD-MM')
          WHEN '01-01' THEN 'Q1'
          WHEN '01-04' THEN 'Q2'
          WHEN '01-07' THEN 'Q3'
          WHEN '01-10' THEN 'Q4' END quarter,
       COUNT(*)
FROM   (SELECT inc.incident_ref,
               TRUNC(inc.date_logged) date_logged
        FROM   sa.incident inc,
               sa.item itm
        WHERE  inc.event_type = 'i'
        AND    itm.item_id    = inc.item_id
        AND    (itm.item_sc = 'SVC GROUP RISK QUOTE' OR
                itm.item_sc = 'ADMINISTRATOR (UKHE)  [PRD]')) i,
       (SELECT TO_DATE('01-MAR-2012','DD-MON-YYYY')+rownum-1 adate
        FROM   all_objects
        WHERE  rownum <= SYSDATE-TO_DATE('01-MAR-2012','DD-MON-YYYY')+1) d
WHERE  i.date_logged(+) = d.adate
GROUP BY TRUNC(d.adate,'Q')
ORDER BY quarter
/

-- Incidents related to an item, handled by a queue, grouped by quarter logged
SELECT TO_CHAR(TRUNC(d.adate,'Q'),'YYYY')||' '||
       CASE TO_CHAR(TRUNC(d.adate,'Q'),'DD-MM')
          WHEN '01-01' THEN 'Q1'
          WHEN '01-04' THEN 'Q2'
          WHEN '01-07' THEN 'Q3'
          WHEN '01-10' THEN 'Q4' END quarter,
       COUNT(i.incident_ref)
FROM   (SELECT inc.incident_ref,
               TRUNC(inc.date_logged) date_logged
        FROM   sa.incident inc,
               sa.item itm
        WHERE  inc.event_type = 'i'
        AND    itm.item_id    = inc.item_id
        AND    (itm.item_sc = 'SVC GROUP RISK QUOTE' OR
                itm.item_sc = 'ADMINISTRATOR (UKHE)  [PRD]')
        AND EXISTS (SELECT 'Y'
                    FROM   sa.act_reg a,
                           sa.assyst_usr u,
                           sa.serv_dept s
                    WHERE  a.incident_id   = inc.incident_id
                    AND    a.assyst_usr_id = u.assyst_usr_id
                    AND    u.serv_dept_id  = s.serv_dept_id
                    AND    s.serv_dept_sc  = 'UKHE DB SUPP')) i,
       (SELECT TO_DATE('01-MAR-2012','DD-MON-YYYY')+rownum-1 adate
        FROM   all_objects
        WHERE  rownum <= SYSDATE-TO_DATE('01-MAR-2012','DD-MON-YYYY')+1) d
WHERE  i.date_logged(+) = d.adate
GROUP BY TRUNC(d.adate,'Q')
ORDER BY quarter
/

-- incidents assigned to a queue, without particular actions
SELECT i.incident_ref,
       i.callback_rmk,
       i.date_logged,
       i.last_action_date
FROM   sa.serv_dept s,
       sa.incident i
WHERE  i.ass_svd_id   = s.serv_dept_id
AND    s.serv_dept_sc = 'UKHE DB SUPP'
AND    i.event_type   = 'i'
AND    i.inc_status   = 'o'
AND NOT EXISTS (SELECT 'Y'
                FROM   sa.act_reg a,
                       sa.act_type t
                WHERE  a.incident_id  = i.incident_id
                AND    t.act_type_id  = a.act_type_id
                AND    t.act_type_sc IN ('ATTACHED JIRA','VERIFIED JIRA'))
/

-- incidents assigned to a queue, with presence of particular actions
SELECT i.incident_ref,
       i.callback_rmk,
       i.date_logged,
       i.last_action_date,
       (SELECT MAX('Y')
        FROM   sa.act_reg aaj,
               sa.act_type taj
        WHERE  aaj.incident_id = i.incident_id
        AND    taj.act_type_id = aaj.act_type_id
        AND    taj.act_type_sc = 'ATTACHED JIRA') attached_jira,
       (SELECT MAX('Y')
        FROM   sa.act_reg avj,
               sa.act_type tvj
        WHERE  avj.incident_id = i.incident_id
        AND    tvj.act_type_id = avj.act_type_id
        AND    tvj.act_type_sc = 'VERIFIED JIRA') verified_jira
FROM   sa.serv_dept s,
       sa.incident i
WHERE  i.ass_svd_id   = s.serv_dept_id
AND    s.serv_dept_sc = 'UKHE DB SUPP'
AND    i.event_type   = 'i'
AND    i.inc_status   = 'o'
/