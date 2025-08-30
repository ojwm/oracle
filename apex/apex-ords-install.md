# APEX ORDS Install

## `dbms_random`

The `apex_public_user` requires the `EXECUTE` privilege on `dbms_random`. Prior to Oracle Database 11.2.0.2, there was a `PUBLIC EXECUTE` privilege for `dbms_random` but the current guidance is to explicitly grant the privilege to the necessary user: <https://docs.oracle.com/cd/E11882_01/readmes.112/e41331/chapter11202.htm#sthref494>.

## Amazon Relational Database Service (RDS)

See [Configuring Oracle Rest Data Services (ORDS)](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.Oracle.Options.APEX.ORDSConf.html) for instructions on configuring ORDS to work with APEX in Amazon RDS.
