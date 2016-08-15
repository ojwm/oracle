SELECT *
FROM (SELECT ename,
             deptno,
             COUNT(*) OVER (PARTITION BY NULL) FULL_ROW_COUNT
      FROM   emp
      WHERE  deptno = 1)
WHERE rownum < 6;