CREATE OR REPLACE PACKAGE BODY qotw IS
------------------------------------------------------------------------------
-- qotw package.
-- Suite of tools to allow us to record quotes of the week and weekly winners
-- in a table (qotw_storage).
------------------------------------------------------------------------------
-- Change History
------------------------------------------------------------------------------
-- Version     1
-- Date        04-SEP-2008
-- Comments    Initial release
------------------------------------------------------------------------------
   --
   -- trace procedure.
   PROCEDURE trace (p_message IN omtrace_out.message%TYPE) IS
   --
   BEGIN
      --
      omtrace.put_line('qotw', p_message);
   --
   END trace;
   --
   -- next_quote_id function.
   -- Returns the next available quote_id from the current period of quotes
   -- that have not been voted on.
   FUNCTION next_quote_id
      RETURN qotw_storage.quote_id%TYPE IS
      --
      v_quote_id qotw_storage.quote_id%TYPE;
   --
   BEGIN
      --
      SELECT MAX(quote_id)+1
      INTO   v_quote_id
      FROM   qotw_storage
      WHERE  voted_on != 'Y';
      --
      IF v_quote_id IS NULL THEN
         --
         v_quote_id := 1;
      --
      END IF;
      --
      RETURN v_quote_id;
   --
   EXCEPTION
      --
      WHEN others THEN
         --
         trace('next_quote_id error: '||SQLERRM);
   --
   END next_quote_id;
   
   -- add_quote procedure.
   -- Add a quote to the system.
   PROCEDURE add_quote (p_who   IN qotw_storage.who%TYPE,
                        p_quote IN qotw_storage.quote%TYPE) IS
   --
   BEGIN
      --
      INSERT INTO qotw_storage
        (quote_id,
         who,
         quote,
         voted_on,
         voters,
         winner,
         timestamp)
      VALUES
        (next_quote_id,
         initcap(p_who),
         p_quote,
         'N',
         t_voters(NULL),
         NULL,
         trunc(SYSDATE));
      --
      COMMIT;
   --
   EXCEPTION
      --
      WHEN others THEN
         --
         trace('add_quote error: '||SQLERRM);
   --
   END add_quote;
   --
   -- get_quotes_by procedure
   -- Gets quotes by the specified person in the specified date range.
   -- If no dates are specified then all quotes by that person are returned. 
   PROCEDURE get_quotes_by
     (p_who   IN qotw_storage.who%TYPE,
      p_start IN qotw_storage.timestamp%TYPE DEFAULT NULL,
      p_end   IN qotw_storage.timestamp%TYPE DEFAULT NULL) IS
      --
      -- c_quotes_by cursor.
      CURSOR c_quotes_by (p_who   IN qotw_storage.who%TYPE,
                          p_start IN qotw_storage.timestamp%TYPE,
                          p_end   IN qotw_storage.timestamp%TYPE) IS
         --
         SELECT trunc(timestamp) timestamp,
                quote
         FROM   qotw_storage
         WHERE  who             = initcap(p_who)
         AND    timestamp BETWEEN p_start AND p_end
         ORDER BY timestamp DESC;
   --
   BEGIN
      --
      dbms_output.put_line('Quotes by: '||initcap(p_who));
      dbms_output.put_line('Date'||CHR(9)||'Quote');
      --
      FOR c IN c_quotes_by
                 (p_who,
                  NVL(p_start, to_date('01-JAN-1900','DD-MON-YYYY')),
                  NVL(p_end, to_date('31-DEC-3000','DD-MON-YYYY'))) LOOP
         --
         dbms_output.put_line(c.timestamp||CHR(9)||quote);
      --
      END LOOP;
   --
   END get_quotes_by;
   --
   -- get_quotes_to_vote procedure
   PROCEDURE get_quotes_to_vote IS
      --
      -- c_quotes cursor.
      -- Selects all quotes that have not been voted on.
      CURSOR c_quotes IS
         --
         SELECT quote_id,
                trunc(timestamp) timestamp,
                quote
         FROM   qotw_storage
         WHERE  voted_on != 'Y'
         ORDER BY quote_id ASC;
   --
   BEGIN
      --
      dbms_output.put_line('Quotes to vote on');
      dbms_output.put_line('ID'||CHR(9)||'Date'||CHR(9)||'Quote');
      --
      FOR c IN c_quotes LOOP
         --
         dbms_output.put_line(c.quote_id||CHR(9)||c.timestamp||CHR(9)||c.quote);
      --
      END LOOP;
   --
   EXCEPTION
      --
      WHEN others THEN
         --
         trace('get_quotes_to_vote error: '||SQLERRM);
   --
   END get_quotes_to_vote;
   --
   -- get_winners procedure
   PROCEDURE get_winners IS
      --
      -- c_winners cursor.
      CURSOR c_winners IS
         --
         SELECT trunc(timestamp) timestamp,
                who,
                quote
         FROM   qotw_storage
         WHERE  winner                    IS NOT NULL
         AND    winner                    != 'QOTY'
         AND    to_char(timestamp,'YYYY')  = to_char(SYSDATE,'YYYY')
         ORDER BY timestamp ASC;
      --
      v_qoty VARCHAR2(4000);
   --
   BEGIN
      --
      SELECT trunc(timestamp)||CHR(9)||who||CHR(9)||quote
      INTO   v_qoty
      FROM   qotw_storage
      WHERE  winner                    = 'QOTY'
      AND    to_char(timestamp,'YYYY') = to_char(SYSDATE,'YYYY');
      --
      dbms_output.put_line('Quote of the Year'||to_char(SYSDATE,'YYYY'));
      --
      dbms_output.put_line(v_qoty);
      dbms_output.put_line('');
      --
      dbms_output.put_line('Winning quotes of '||to_char(SYSDATE,'YYYY'));
      dbms_output.put_line('Date'||CHR(9)||'By'||CHR(9)||CHR(9)||'Quote');
      --
      FOR c IN c_winners LOOP
         --
         dbms_output.put_line(c.timestamp||CHR(9)||c.who||CHR(9)||c.quote);
      --
      END LOOP;
   --
   EXCEPTION
      --
      WHEN others THEN
         --
         trace('get_winners error: '||SQLERRM);
   --
   END get_winners;
   --
   -- submit_vote procedure
   PROCEDURE submit_vote (p_quote_id IN qotw_storage.quote_id%TYPE) IS
   --
   BEGIN
      --
      NULL;
   --
   END submit_vote;
--
END qotw;