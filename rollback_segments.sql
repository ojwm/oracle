SELECT rn.Name "Rollback Segment", rs.RSSize/1024 "Size (KB)", rs.Gets "Gets",
       rs.waits "Waits", (rs.Waits/rs.Gets)*100 "% Waits",
       rs.Shrinks "# Shrinks", rs.Extends "# Extends"
FROM   sys.v_$rollName rn, sys.v_$rollStat rs
WHERE  rn.usn = rs.usn;