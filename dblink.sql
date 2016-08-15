-- How to create a DB link without an entry in tnsname.ora
CREATE PUBLIC DATABASE LINK "XE_GROT"
 CONNECT TO CATLINR1
 IDENTIFIED BY letmein
 USING '(DESCRIPTION=
  (ADDRESS=
   (PROTOCOL=TCP)
   (HOST=10.196.130.90)
   (PORT=1521))
  (CONNECT_DATA=
    (SID=XE)))';
 
 select * from catlinr1.policy@XE_GROT
 
 drop public DATABASE LINK "XE_GROT"