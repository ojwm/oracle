-- Define a test table
CREATE TABLE incentive
  (policy_number          VARCHAR2(6),
   renewal_effective_date DATE,
   type                   VARCHAR2(50),
   value                  VARCHAR2(100))
/
--
-- Define an object to contain data items to match the table
CREATE TYPE incentive_rec AS OBJECT
  (type  VARCHAR2(50),
   value VARCHAR2(100))
/
--
-- Define a table type to hold objects
CREATE TYPE incentive_tab AS TABLE OF incentive_rec
/
--
-- Example code to populate table from table of objects
DECLARE
   -- dummy policy number and renewal date
   v_policy_number          incentive.policy_number%TYPE := '1234';
   v_renewal_effective_date incentive.renewal_effective_date%TYPE := TRUNC(SYSDATE);
   -- instantiate the collection
   v_incentive_tab          incentive_tab := incentive_tab();
BEGIN
   -- initialise collection elements
   v_incentive_tab.EXTEND(2);
   -- set element values
   v_incentive_tab(1) := incentive_rec('A','1');
   v_incentive_tab(2) := incentive_rec('B','2');
   -- insert collection contents into table
   FORALL i IN v_incentive_tab.FIRST..v_incentive_tab.LAST
   INSERT INTO incentive
     (policy_number,
      renewal_effective_date,
      type,
      value)
   VALUES
     (v_policy_number,
      v_renewal_effective_date,
      v_incentive_tab(i).type,
      v_incentive_tab(i).value);
END;
/
--
-- View contents of the table
SELECT *
FROM   incentive
/
--
-- Drop the table type
DROP TYPE incentive_tab
/
--
-- Drop the object type
DROP TYPE incentive_rec
/
--
-- Drop the table
DROP TABLE incentive PURGE
/