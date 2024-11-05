SET ECHO ON
COLUMN db_name FORMAT a10
COLUMN param_name FORMAT a20
COLUMN param_value FORMAT a30

ALTER SESSION SET smtp_out_server = '&smtp_server_1'
/

SELECT SYS_CONTEXT('userenv','db_name') db_name,
       name param_name,
       value param_value
FROM   v$parameter
WHERE  name = 'smtp_out_server'
/

BEGIN
   system.nu_send_email (p_sender       => '&email_address',
                         p_recipient    => '&email_address',
                         p_cc           => NULL,
                         p_bcc          => NULL,
                         p_importance   => NULL,
                         p_subject      => 'Test '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:Mi:SS'),
                         p_message_body => '&smtp_server_1');
END;
/

ALTER SESSION SET smtp_out_server = '&smtp_server_2'
/

SELECT SYS_CONTEXT('userenv','db_name') db_name,
       name param_name,
       value param_value
FROM   v$parameter
WHERE  name = 'smtp_out_server'
/

BEGIN
   system.nu_send_email (p_sender       => '&email_address',
                         p_recipient    => '&email_address',
                         p_cc           => NULL,
                         p_bcc          => NULL,
                         p_importance   => NULL,
                         p_subject      => 'Test '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:Mi:SS'),
                         p_message_body => '&smtp_server_2');
END;
/

ALTER SESSION SET smtp_out_server = 'smtp_server_1'
/