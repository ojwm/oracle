-- Use GROUP BY ROLLUP to create a "totals" row
CREATE TABLE total_test
  (id   VARCHAR2(1),
   num1 INTEGER,
   num2 INTEGER);
--
INSERT INTO total_test VALUES ('a',10,100);
INSERT INTO total_test VALUES ('b',20,200);
INSERT INTO total_test VALUES ('c',30,300);
--
SELECT NVL(id,'TOTAL') id,
       SUM(num1) num1,
       SUM(num2) num2
FROM   total_test
GROUP BY ROLLUP(id);
--
DROP TABLE total_test;
PURGE TABLE total_test;