CREATE OR REPLACE PACKAGE qotw IS
   --
   PROCEDURE add_quote (p_who   IN qotw_storage.who%TYPE,
                        p_quote IN qotw_storage.quote%TYPE);
   --
   PROCEDURE get_quotes_by (p_who   IN qotw_storage.who%TYPE,
                            p_start IN qotw_storage.timestamp%TYPE DEFAULT NULL,
                            p_end   IN qotw_storage.timestamp%TYPE DEFAULT NULL);
   --
   PROCEDURE get_quotes_to_vote;
   --
   PROCEDURE get_winners;
   --
   PROCEDURE submit_vote (p_quote_id IN qotw_storage.quote_id%TYPE);
--
END omtrace;