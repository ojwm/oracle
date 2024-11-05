SELECT CASE i.event_type
          WHEN 'i' THEN 'Incident'
          WHEN 'p' THEN 'Problem'
       END                                                  rectype,
       CASE i.event_type
          WHEN 'i' THEN to_char(i.incident_ref)
          WHEN 'p' THEN upper(i.event_type)||i.incident_ref
       END                                                  ref,
       99999                                                cost_centre,
       s.serv_dept_sc                                       allocated,
       u.assyst_usr_n                                       assigned_user_name,
       sev.inc_serious_sc,
       pri.inc_prior_sc,
       i.date_logged,
       i.inc_close_date,
       round(i.inc_close_date-i.date_logged) days_ticket_took_to_close
FROM   sa.incident i,
       sa.serv_dept s,
       sa.assyst_usr u,
       sa.inc_serious sev,  
       sa.inc_prior pri
WHERE  i.ass_svd_id       = s.serv_dept_id      -- Join condition.
AND    u.assyst_usr_id    = i.ass_usr_id        -- Join condition.
AND    sev.inc_serious_id = i.inc_serious_id    -- Join condition.
AND    pri.inc_prior_id   = i.inc_prior_id      -- Join condition.
AND    (i.inc_status  != 'c' OR                 -- Must be not closed or closed in last month.
        (i.inc_status        = 'c' AND
         i.last_action_date >= '01-DEC-2011'))  -- last_action_date not indexed.
AND    i.event_type   IN ('i','p')              -- event_type not indexed.
AND    s.serv_dept_id  = 749
/

-- Unacknowledged records
SELECT s.serv_dept_sc allocated,
       CASE i.event_type
          WHEN 'i' THEN 'Incident'
          WHEN 'p' THEN 'Problem'
       END type,
       sev.inc_serious_sc severity,
       COUNT(*) count
FROM   sa.incident i,
       sa.serv_dept s,
       sa.inc_serious sev
WHERE  i.ass_svd_id        = s.serv_dept_id   -- Join condition.
AND    sev.inc_serious_id  = i.inc_serious_id -- Join condition.
AND    i.inc_status       != 'c'       -- Open records
AND    i.event_type       IN ('i','p') -- Incidents and problems
AND    i.svd_ack_reqd      = 'y'       -- Acknowledgement required
AND    s.serv_dept_id     IN (SELECT s2.serv_dept_id
                              FROM   sa.serv_dept s2
                              WHERE  s2.serv_dept_sc LIKE 'UKHE %') -- All UKHE Assyst queues
GROUP BY s.serv_dept_sc,
         CASE i.event_type
            WHEN 'i' THEN 'Incident'
            WHEN 'p' THEN 'Problem'
         END,
         sev.inc_serious_sc
ORDER BY allocated,
         type,
         severity
/

SELECT 'R'||i.incident_ref   ref,
       it.item_n             item,
       i.callback_rmk        short_desc,
       trunc(i.date_logged)  rasied_on,
       r.rproc_hdr_sc        process,
       i.rfc_scheduled_date  scheduled_for,
       i.rfc_end_date        required_by,
       s.serv_dept_sc        allocated,
       u.assyst_usr_n        assigned_user_name
FROM   sa.incident i,
       sa.item it,
       sa.serv_dept s,
       sa.assyst_usr u,
       sa.inc_data id,
       sa.rproc_hdr r
WHERE  i.ass_svd_id                = s.serv_dept_id
AND    u.assyst_usr_id             = i.ass_usr_id
AND    it.item_id                  = i.item_id
AND    id.incident_id              = i.incident_id
AND    r.rproc_hdr_id              = id.u_num1
AND    i.event_type                = 'c'
AND    i.inc_status                = 'o'
AND    trunc(i.rfc_scheduled_date) = trunc(SYSDATE)
--AND    i.incident_ref        = 774922
AND    s.serv_dept_sc           LIKE 'UKHE %'
ORDER BY i.rfc_scheduled_date
/

-- Shows latest task linked to a change
SELECT *
FROM   (SELECT ic.inc_cat_sc  category,
               s.serv_dept_sc allocated,
               u.assyst_usr_n assigned_user_name
        FROM   sa.incident i,
               sa.inc_cat ic,
               sa.link_inc li,
               sa.serv_dept s,
               sa.assyst_usr u
        WHERE  i.incident_id  = li.incident_id
        AND    ic.inc_cat_id  = i.inc_cat_id
        AND    li.link_grp_id = (SELECT li2.link_grp_id
                                 FROM   sa.link_inc li2,
                                        sa.incident i2
                                 WHERE  li2.incident_id = i2.incident_id
                                 AND    i2.incident_ref = 774922
                                 AND    i2.event_type   = 'c')
        AND   i.incident_ref      != 774922
        AND   i.event_type    NOT IN ('i','p','c')
        AND   i.ass_svd_id         = s.serv_dept_id
        AND   u.assyst_usr_id      = i.ass_usr_id
        ORDER BY i.incident_ref DESC)
WHERE rownum = 1
/

-- Incidents with data incomplete or incorrect assignment action by user associated with SVD
-- No index on act_type_id but separating the join with act_type from the rest
-- seems to be more efficient. Oracle 8 RBO quirk?
SELECT all_actions.incident_ref  "INCIDENT",
       all_actions.callback_rmk  "DESCRIPTION",
       t.act_type_sc             "ACTION",
       all_actions.date_actioned "DATE",
       all_actions.act_usr_sc    "USER",
       all_actions.remark
FROM   (SELECT i.incident_ref,
               i.callback_rmk,
               r.date_actioned,
               r.act_usr_sc,
               r.act_type_id,
               replace(r.act_rmk||r.act_rmk2||r.act_rmk3||r.act_rmk4,
                       chr(13)||chr(10),
                       ' ') "REMARK"
        FROM   sa.act_reg r,
               sa.serv_dept s,
               sa.incident i
        WHERE  r.incident_id    = i.incident_id
        AND    r.serv_dept_id   = s.serv_dept_id
        AND    i.event_type     = 'i'
        AND    s.serv_dept_sc   = 'UKHE DB SUPP'
        AND    r.date_actioned >= trunc(SYSDATE,'YYYY')) all_actions,
        sa.act_type t
WHERE  t.act_type_id  = all_actions.act_type_id
AND    t.act_type_sc IN ('DATA INCOMPLETE','INCOR ASSIGN')
ORDER BY t.act_type_sc,
         all_actions.incident_ref DESC,
         all_actions.date_actioned DESC
/

-- incidents that have been assigned to an SVD
-- even if they are no longer assigned to the SVD
WITH assignments AS
  (SELECT i.incident_ref,
          r.act_reg_id,
          r.act_rmk,
          r.date_actioned,
          r.act_svd_sc,
          r.act_usr_sc,
          r.ass_svd_sc
   FROM   sa.act_reg r,
          sa.act_type t,
          sa.incident i
   WHERE  i.incident_id  = r.incident_id
   AND    i.event_type   = 'i'
   AND    r.act_type_id    = t.act_type_id 
   AND    t.act_type_sc    = 'ASSIGN'
   AND    r.ass_svd_sc     = 'UKHE DB SUPP'
   AND    r.act_svd_sc    != 'UKHE DB SUPP'
   AND    r.date_actioned >= trunc(SYSDATE,'YYYY'))
SELECT a1.incident_ref,
       a1.act_rmk       remark,
       a1.date_actioned,
       a1.act_svd_sc    assigning_svd,
       a1.act_usr_sc    assigning_user,
       a1.ass_svd_sc    assigned_svd
FROM   assignments a1
WHERE  a1.act_reg_id = (SELECT MIN(a2.act_reg_id)
                        FROM   assignments a2
                        WHERE  a2.incident_ref = a1.incident_ref)
/
