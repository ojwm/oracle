DROP TABLE secret_santa;
--
CREATE TABLE secret_santa (name  VARCHAR2(50),
                           email VARCHAR2(100),
                           used  VARCHAR2(1),
CONSTRAINT secret_santa_pk PRIMARY KEY (name),
CONSTRAINT secret_santa_uk UNIQUE (email));
--
INSERT INTO secret_santa VALUES ('Aimee Norman', 'aimee.norman@aviva.co.uk', 'N');
INSERT INTO secret_santa VALUES ('Alice Rainer-Guy', 'alice.rainer-guy@aviva.co.uk', 'N');
INSERT INTO secret_santa VALUES ('Audra Savory', 'audra.savory@aviva.co.uk', 'N');
INSERT INTO secret_santa VALUES ('Beki Pearson', 'beki.pearson@aviva.co.uk', 'N');
INSERT INTO secret_santa VALUES ('Claire Hopkin', 'claire.hopkin@aviva.co.uk', 'N');
INSERT INTO secret_santa VALUES ('David Richards', 'david.richards@aviva.co.uk', 'N');
INSERT INTO secret_santa VALUES ('Ewa Wielochowski', 'ewa.wielochowska@aviva.co.uk', 'N');
INSERT INTO secret_santa VALUES ('Graham Kesley', 'graham.p.kesley@aviva.co.uk', 'N');
INSERT INTO secret_santa VALUES ('Ian Balson', 'ian.balson@aviva.co.uk', 'N');
INSERT INTO secret_santa VALUES ('Ian Hunter', 'ian.hunter2@aviva.co.uk', 'N');
INSERT INTO secret_santa VALUES ('James Roberts', 'james.roberts2@aviva.co.uk', 'N');
INSERT INTO secret_santa VALUES ('Mark Budd', 'mark.budd@aviva.co.uk', 'N');
INSERT INTO secret_santa VALUES ('Mike Holloway', 'mike.holloway@aviva.co.uk', 'N');
INSERT INTO secret_santa VALUES ('Neil Rawlings', 'neil.rawlings@aviva.co.uk', 'N');
INSERT INTO secret_santa VALUES ('Oliver Mitchell', 'oliver.j.mitchell@aviva.co.uk', 'N');
INSERT INTO secret_santa VALUES ('Paul Briggs', 'paul.m.briggs@aviva.co.uk', 'N');
INSERT INTO secret_santa VALUES ('Sean Stanley-Adams', 'sean.stanley-adams@aviva.co.uk', 'N');
INSERT INTO secret_santa VALUES ('Shane Challis', 'shane.challis@aviva.co.uk', 'N');
--
COMMIT;
--
DECLARE
   --
   v_receiver VARCHAR2(50);
   v_email    CLOB;
   v_check    CLOB;
   v_referee  VARCHAR2(50) := 'shane.challis@aviva.co.uk';
--
BEGIN
   --
   UPDATE secret_santa
   SET    used = 'N';
   --
   FOR i IN (SELECT name, email
             FROM   secret_santa
             ORDER BY name) LOOP
      --
      SELECT name
      INTO   v_receiver
      FROM   (SELECT name
              FROM   secret_santa
              WHERE  name != i.name
              AND    used  = 'N'
              ORDER BY dbms_random.value)
      WHERE  rownum = 1;
      --
      UPDATE secret_santa
      SET    used = 'Y'
      WHERE  name = v_receiver;
      --
      v_check := v_check||chr(12)||i.name||','||v_receiver;
      --
      v_email := i.name||', your Secret Santa is... '||v_receiver||'!'||chr(12)||chr(12)||
                 'Your budget is around 5 pounds. Please give something that you would be happy to receive yourself and/or is suitably amusing!'||chr(12)||chr(12)||
                 'Please remember to put a gift tag on your present, so they don''t get mixed up, and put them in Mike Holloway''s office before 20th December.'||chr(12)||chr(12)||
                 'Happy shopping!';
      --
      pkg_email.send_mail
        (p_sender       => 'noreply@oracle',
         p_recipient    => i.email,
         p_cc           => NULL,
         p_importance   => 'High',
         p_subject      => 'Staff Panel Secret Santa draw!',
         p_message_body => v_email);
   --
   END LOOP;
   --
   pkg_email.send_mail
     (p_sender       => 'noreply@oracle',
      p_recipient    => v_referee,
      p_cc           => NULL,
      p_importance   => 'High',
      p_subject      => 'Staff Panel Secret Santa draw check',
      p_message_body => v_check);
   --
   COMMIT;
--
END;
/