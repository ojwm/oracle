------------------------------------------------------------------------------
-- Build a solution to hold parent child relationships and queries to:
-- 1) Return all child details when given a parent name.
-- 2) Return parent details for a specific set of children.
--    I.e. If a set of 2 children is provided, return the parents having
--    only those 2 children.
------------------------------------------------------------------------------
--
-- Create a table to hold parent details
CREATE TABLE parent
  (id   INTEGER,
   name VARCHAR2(30));
--
-- Create a table to hold child details
CREATE TABLE child
  (id   INTEGER,
   name VARCHAR2(30),
   dob  DATE);
--
-- Create a table to relate children to parents
CREATE TABLE parent_child
  (parent_id INTEGER,
   child_id  INTEGER);
--
-- Create some parent data
INSERT INTO parent (id,name) VALUES (1,'Jane');
INSERT INTO parent (id,name) VALUES (2,'Anne');
INSERT INTO parent (id,name) VALUES (3,'Laura');
INSERT INTO parent (id,name) VALUES (4,'Mark');
INSERT INTO parent (id,name) VALUES (5,'John');
INSERT INTO parent (id,name) VALUES (6,'Adam');
--
-- Create some child data
INSERT INTO child (id,name,dob) VALUES (1,'Thomas','12-FEB-2010');
INSERT INTO child (id,name,dob) VALUES (2,'Louise','26-AUG-2005');
INSERT INTO child (id,name,dob) VALUES (3,'Hannah','05-JUN-1998');
INSERT INTO child (id,name,dob) VALUES (4,'Louise','03-NOV-1993');
INSERT INTO child (id,name,dob) VALUES (5,'Hannah','30-APR-2007');
INSERT INTO child (id,name,dob) VALUES (6,'Louise','31-MAR-2003');
--
-- Create some parent to child relation data
INSERT INTO parent_child (parent_id,child_id) VALUES (1,1);
INSERT INTO parent_child (parent_id,child_id) VALUES (1,2);
INSERT INTO parent_child (parent_id,child_id) VALUES (2,3);
INSERT INTO parent_child (parent_id,child_id) VALUES (2,4);
INSERT INTO parent_child (parent_id,child_id) VALUES (3,5);
INSERT INTO parent_child (parent_id,child_id) VALUES (3,6);
INSERT INTO parent_child (parent_id,child_id) VALUES (4,1);
INSERT INTO parent_child (parent_id,child_id) VALUES (4,2);
INSERT INTO parent_child (parent_id,child_id) VALUES (5,3);
INSERT INTO parent_child (parent_id,child_id) VALUES (5,4);
INSERT INTO parent_child (parent_id,child_id) VALUES (6,5);
INSERT INTO parent_child (parent_id,child_id) VALUES (6,6);
--
-- Create a view to show parent and child relations
CREATE OR REPLACE FORCE VIEW parent_children AS
   SELECT p.name parent_name,
          c.name child_name,
          c.dob  child_dob
   FROM   parent p,
          child c,
          parent_child pc
   WHERE  pc.parent_id = p.id
   AND    pc.child_id  = c.id;
--
-- 1) Return all child details when given a parent name
SELECT child_name,
       child_dob
FROM   parent_children
WHERE  parent_name = 'Jane';
--
-- 2) Return parent details for a specific set of children
-- This query uses relational division
-- Execution steps:
-- 1. Define a table called CHILDREN to search for a parent with
-- 2. Select rows from PARENT_CHILDREN where rows match the details in CHILDREN
-- 3.1. Group by the parent and apply two having clauses:
-- 3.2. The distinct count of child names for each parent must equal the count
--      of CHILDREN.
-- 3.3. The distinct count of child names for each parent must equal the count
--      of all that parent's children.
WITH children AS
  (SELECT 'Hannah' name, TO_DATE('05-JUN-1998','DD-MON-RRRR') dob FROM dual UNION ALL
   SELECT 'Louise' name, TO_DATE('03-NOV-1993','DD-MON-RRRR') dob FROM dual)
SELECT pc1.parent_name
FROM   parent_children pc1
WHERE  (pc1.child_name, pc1.child_dob) IN (SELECT name, dob 
                                           FROM   children)
GROUP BY pc1.parent_name
HAVING COUNT(DISTINCT pc1.child_name) = (SELECT COUNT(*)
                                         FROM children)
AND    COUNT(DISTINCT pc1.child_name) = (SELECT COUNT(*)
                                         FROM   parent_children pc2
                                         WHERE  pc2.parent_name = pc1.parent_name);
--
-- Create a type and table for child details
CREATE TYPE child_rec AS OBJECT
  (name VARCHAR2(30),
   dob  DATE);
--
CREATE TYPE child_tab AS TABLE OF child_rec;
--
-- Create a type and table for parent details
CREATE TYPE parent_rec AS OBJECT
  (name VARCHAR2(30));
--
CREATE TYPE parent_tab AS TABLE OF parent_rec;
--
-- Create a package as an interface to the data
CREATE OR REPLACE PACKAGE family_api AS
   --
   -- Get all children related to the supplied parent.
   -- Return plan codes in a table.
   --
   -- Example usage:
   -- SELECT *
   -- FROM TABLE (family_api.get_children('Jane'));
   FUNCTION get_children
     (p_parent_name IN parent_children.parent_name%TYPE)
   RETURN child_tab;
   --
   -- Get all parents that have exactly the children supplied.
   -- Return parents in a table.
   --
   -- Example usage:
--    SELECT *
--    FROM   TABLE (fuse_api.get_children
--                    (child_tab
--                       (child_rec('Hannah', TO_DATE('05-JUN-1998','DD-MON-RRRR'))),
--                        child_rec('Louise', TO_DATE('03-NOV-1993','DD-MON-RRRR'))));
   FUNCTION get_parents
     (p_children IN child_tab)
   RETURN parent_tab;
--
END family_api;
/
--
CREATE OR REPLACE PACKAGE BODY family_api AS
   --
   -- Get all children related to the supplied parent.
   -- Return plan codes in a table.
   --
   -- Example usage:
   -- SELECT *
   -- FROM TABLE (family_api.get_children('Jane'));
   FUNCTION get_children (p_parent_name IN parent_children.parent_name%TYPE)
   RETURN child_tab IS
      --
      CURSOR c_children (cp_parent_name IN parent_children.parent_name%TYPE) IS
         --
         SELECT child_rec(child_name,child_dob)
         FROM   parent_children
         WHERE  parent_name = cp_parent_name;
      --
      v_child_tab child_tab;
   --
   BEGIN
      --
      OPEN c_children (p_parent_name);
      FETCH c_children BULK COLLECT INTO v_child_tab;
      CLOSE c_children;
      --
      RETURN v_child_tab;
   --
   END get_children;
   --
   -- Get all parents that have exactly the children supplied.
   -- Return parents in a table.
   --
   -- Example usage:
   -- SELECT *
   -- FROM   TABLE (family_api.get_parents
   --                 (child_tab
   --                    (child_rec('Hannah', TO_DATE('05-JUN-1998','DD-MON-RRRR')),
   --                     child_rec('Louise', TO_DATE('03-NOV-1993','DD-MON-RRRR')))));
   FUNCTION get_parents
     (p_children IN child_tab)
   RETURN parent_tab IS
      --
      CURSOR c_parents (cp_children IN child_tab) IS
         --
         WITH children AS
           (SELECT name, dob
            FROM   TABLE (cp_children))
         SELECT parent_rec(pc1.parent_name)
         FROM   parent_children pc1
         WHERE  (pc1.child_name, pc1.child_dob) IN (SELECT name, dob 
                                                    FROM   children)
         GROUP BY pc1.parent_name
         HAVING COUNT(DISTINCT pc1.child_name) = (SELECT COUNT(*)
                                                  FROM children)
         AND    COUNT(DISTINCT pc1.child_name) = (SELECT COUNT(*)
                                                  FROM   parent_children pc2
                                                  WHERE  pc2.parent_name = pc1.parent_name);
      --
      v_parent_tab parent_tab;
   --
   BEGIN
      --
      OPEN c_parents (p_children);
      FETCH c_parents BULK COLLECT INTO v_parent_tab;
      CLOSE c_parents;
      --
      RETURN v_parent_tab;
   --
   END get_parents;
--
END family_api;
/
--
-- Test the package with a specific parent
SELECT *
FROM TABLE (family_api.get_children('Jane'));
--
-- Test the package with specific children
SELECT *
FROM   TABLE (family_api.get_parents
                (child_tab
                   (child_rec('Hannah', TO_DATE('05-JUN-1998','DD-MON-RRRR')),
                    child_rec('Louise', TO_DATE('03-NOV-1993','DD-MON-RRRR')))));
--
-- Drop objects
DROP PACKAGE family_api;
DROP TYPE parent_tab;
DROP TYPE parent_rec;
DROP TYPE child_tab;
DROP TYPE child_rec;
DROP VIEW parent_children;
DROP TABLE parent PURGE;
DROP TABLE child PURGE;
DROP TABLE parent_child PURGE;