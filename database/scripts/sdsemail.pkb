CREATE OR REPLACE PACKAGE BODY sdsemail
AS
    --                    .///.
    --                   (0 o)
    ---------------0000--(_)--0000---------------
    --
    --  Sean D. Stuber
    --  sean.stuber@gmail.com
    --
    --             oooO      Oooo
    --------------(   )-----(   )---------------
    --             \ (       ) /
    --              \_)     (_/

    c_base64_line         CONSTANT PLS_INTEGER := 57;
    c_crlf                         VARCHAR2(2) := UTL_TCP.crlf;
    /*
        If a default SMTP server is specified here it will be used when the user doesn't specify a server list to try
        instead of checking smtp_out_server and db_domain initialization parameters.

    */
    c_default_smtp_server CONSTANT VARCHAR2(100) := NULL;
    c_default_smtp_port   CONSTANT INTEGER := 25;

    g_boundary                     VARCHAR2(256);

    /* Logging/debugging options */
    g_log_options                  INTEGER := c_log_dbms_output;
    g_log_text                     VARCHAR2(32767) := NULL;
    g_verbose                      BOOLEAN := c_default_verbose;

    ---------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------*/

    -- write the text to each logging option that is currently enabled
    -- verbose comments will not be logged if verbose mode is off.
    PROCEDURE write_to_log(v_text IN VARCHAR2, p_verbose IN BOOLEAN DEFAULT FALSE)
    IS
    BEGIN
        -- If global verbose setting is ON (meaning log everything)
        -- or if this text is not verbose then log it.
        IF g_verbose OR NOT p_verbose
        THEN
            IF BITAND(g_log_options, c_log_dbms_output) > 0
            THEN
                DBMS_OUTPUT.put_line(v_text);
            END IF;

            IF BITAND(g_log_options, c_log_rolling_buffer) > 0
            THEN
                IF LENGTH(g_log_text) + LENGTH(c_crlf) + LENGTH(v_text) > 32767
                THEN
                    g_log_text := SUBSTR(g_log_text, INSTR(g_log_text, c_crlf, LENGTH(v_text) + 2));
                END IF;

                g_log_text := g_log_text || v_text || c_crlf;
            END IF;

            IF BITAND(g_log_options, c_log_client_info) > 0
            THEN
                DBMS_APPLICATION_INFO.set_client_info(v_text);
            END IF;
        END IF;
    END write_to_log;

    -- When verbose mode is TRUE then additional information will be written to the logs.
    -- If logging is turned off then verbose mode won't add anything.
    PROCEDURE set_verbose(p_verbose IN BOOLEAN)
    IS
    BEGIN
        g_verbose := NVL(p_verbose, c_default_verbose);

        IF p_verbose
        THEN
            write_to_log('Switching logging to verbose mode', TRUE);
        END IF;
    END set_verbose;

    -- Returns the current setting of verbose mode (true/false)
    FUNCTION get_verbose
        RETURN BOOLEAN
    IS
    BEGIN
        RETURN g_verbose;
    END get_verbose;

    -- Turn off logging (options=0) or turn on different options (see c_log_xxxxx constants)
    PROCEDURE set_log_options(p_log_options IN INTEGER)
    IS
    BEGIN
        -- options big mask must be between 0 and sum of all possible log options.
        IF p_log_options < 0
        OR p_log_options > c_log_dbms_output + c_log_rolling_buffer + c_log_client_info
        THEN
            raise_application_error(
                -20001,
                   'Invalid log options, must be between 0 and '
                || TO_CHAR(c_log_dbms_output + c_log_rolling_buffer + c_log_client_info),
                TRUE
            );
        END IF;

        g_log_options := p_log_options;
    END set_log_options;

    -- Return current logging options
    FUNCTION get_log_options
        RETURN INTEGER
    IS
    BEGIN
        RETURN g_log_options;
    END get_log_options;

    -- Clears (null) the logging buffers
    PROCEDURE clear_log
    IS
    BEGIN
        -- Clear the log buffer
        g_log_text := NULL;

        -- if logging to session client then clear that too
        IF BITAND(g_log_options, c_log_client_info) > 0
        THEN
            DBMS_APPLICATION_INFO.set_client_info(NULL);
        END IF;
    END clear_log;

    -- Return the current contents of the rolling log buffer
    FUNCTION get_log_text
        RETURN VARCHAR2
    IS
    BEGIN
        RETURN g_log_text;
    END get_log_text;

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------

    FUNCTION find_a_server(p_server_list IN VARCHAR2 DEFAULT NULL)
        RETURN connection
    IS
        v_servers    VARCHAR2(32767);
        v_start      INTEGER := 1;
        v_index      INTEGER;
        v_port_split INTEGER;
        v_host       VARCHAR2(32767);
        v_port       INTEGER;
        v_connected  BOOLEAN := FALSE;
        v_length     INTEGER;
        v_connection UTL_SMTP.connection;
        v_reply      UTL_SMTP.reply;
    BEGIN
        -- Enteries should be of the from
        --   host[:port][,host[:port]][,host[:port]][,host[:port]]...
        -- If the user didn't specify a list, and there is no default
        -- then use the UTL_MAIL parameters
        -- Use smtp_out_server if available or db_domain if not
        IF p_server_list IS NULL
        THEN
            IF c_default_smtp_server IS NULL
            THEN
                SELECT *
                  INTO v_servers
                  FROM (SELECT TRIM(VALUE)
                          FROM v$parameter
                         WHERE name IN ('smtp_out_server', 'db_domain') AND TRIM(VALUE) IS NOT NULL
                        ORDER BY name DESC)
                 WHERE ROWNUM = 1;
            ELSE
                v_servers := c_default_smtp_server || ':' || c_default_smtp_port;
            END IF;
        ELSE
            v_servers := p_server_list;
        END IF;

        v_length := LENGTH(v_servers);

        LOOP
            v_index := INSTR(v_servers, ',', v_start);

            IF v_index = 0
            THEN
                v_port_split := INSTR(v_servers, ':');

                IF v_port_split > 0
                THEN
                    v_host := SUBSTR(v_servers, 1, v_port_split - 1);
                    v_port := TO_NUMBER(SUBSTR(v_servers, v_port_split + 1));
                ELSE
                    v_host := TRIM(v_servers);
                    v_port := c_default_smtp_port;
                END IF;

                v_start := v_length + 1;
            ELSE
                v_host := SUBSTR(v_servers, v_start, v_index - v_start);
                v_port_split := INSTR(v_host, ':');

                IF v_port_split > 0
                THEN
                    v_port := TO_NUMBER(SUBSTR(v_host, v_port_split + 1));
                    v_host := SUBSTR(v_host, 1, v_port_split - 1);
                ELSE
                    v_port := c_default_smtp_port;
                END IF;

                v_start := v_index + 1;
            END IF;

            BEGIN
                write_to_log(
                    'find_a_server: trying - ' || v_connection.HOST || ':' || v_connection.port,
                    TRUE
                );
                v_connection := UTL_SMTP.open_connection(v_host, v_port);
                UTL_SMTP.helo(v_connection, v_host);
                v_connected := TRUE;
            EXCEPTION
                WHEN OTHERS
                THEN
                    write_to_log(
                        'find_a_server: failed - ' || v_connection.HOST || ':' || v_connection.port,
                        TRUE
                    );

                    -- If we've walked off the end of the server list
                    -- without getting connected then raise the last error
                    -- received from the attempt
                    -- otherwise, we'll try again with the next server/port
                    IF v_start > v_length
                    THEN
                        write_to_log('find_a_server: failed all hosts in server list', TRUE);
                        RAISE;
                    END IF;
            END;

            EXIT WHEN v_connected;
        END LOOP;

        write_to_log('find_a_server: ' || v_connection.HOST || ':' || v_connection.port);
        RETURN v_connection;
    END find_a_server;

    FUNCTION instr_enc(
        p_string      IN VARCHAR2,
        p_substring   IN VARCHAR2,
        p_start       IN INTEGER DEFAULT 1,
        p_occurence   IN INTEGER DEFAULT 1,
        p_enclosing   IN VARCHAR2 DEFAULT NULL,
        p_escape      IN VARCHAR2 DEFAULT '\'
    )
        RETURN INTEGER
    IS
        v_occur_cnt INTEGER := 0;
        v_sub_idx   INTEGER;
        v_sub_len   INTEGER := LENGTH(p_substring);
        v_enc_idx   INTEGER;
        v_enc_len   INTEGER := LENGTH(p_enclosing);
        v_esc_idx   INTEGER;
        v_esc_len   INTEGER := LENGTH(p_escape);
        v_index     INTEGER := p_start;
        v_enclosed  BOOLEAN := FALSE;
        v_max       INTEGER := LENGTH(p_string) + 1;

        FUNCTION first_found(a IN INTEGER, b IN INTEGER, c INTEGER)
            RETURN INTEGER
        IS
            v_result INTEGER;
        BEGIN
            v_result :=
                LEAST(NVL(NULLIF(a, 0), v_max), NVL(NULLIF(b, 0), v_max), NVL(NULLIF(c, 0), v_max));

            IF v_result = v_max
            THEN
                v_result := 0;
            END IF;

            RETURN v_result;
        END;
    BEGIN
        IF p_enclosing IS NULL
        THEN
            v_index :=
                INSTR(
                    p_string,
                    p_substring,
                    p_start,
                    p_occurence
                );
        ELSE
            LOOP
                v_sub_idx := INSTR(p_string, p_substring, v_index);
                v_enc_idx := INSTR(p_string, p_enclosing, v_index);
                v_esc_idx := INSTR(p_string, p_escape || p_enclosing, v_index);

                v_index := first_found(v_sub_idx, v_enc_idx, v_esc_idx);

                IF GREATEST(v_sub_idx, v_enc_idx, v_esc_idx) = 0
                THEN
                    NULL;
                ELSIF v_index = v_esc_idx -- escape character found
                THEN
                    v_index := v_index + v_esc_len + v_enc_len;
                ELSIF v_index = v_enc_idx -- enclosing character found
                THEN
                    v_enclosed := NOT v_enclosed;
                    v_index := v_index + v_enc_len;
                ELSE -- substring found
                    IF v_enclosed
                    THEN
                        v_index := v_index + v_sub_len;
                    ELSE -- not enclosed
                        v_occur_cnt := v_occur_cnt + 1;

                        IF v_occur_cnt < p_occurence
                        THEN
                            v_index := v_index + v_sub_len;
                        END IF;
                    END IF;
                END IF;

                EXIT WHEN v_index > LENGTH(p_string) OR v_index = 0 OR v_occur_cnt = p_occurence;
            END LOOP;
        END IF;

        RETURN v_index;
    END;

    FUNCTION extract_address(p_string IN VARCHAR2)
        RETURN VARCHAR2
    IS
        v_bracket_start INTEGER;
        v_bracket_end   INTEGER;
        v_result        VARCHAR2(32767) := TRIM(p_string);
    BEGIN
        v_bracket_start :=
            instr_enc(
                v_result,
                '<',
                1,
                1,
                '"'
            );

        IF v_bracket_start > 0
        THEN
            v_bracket_end :=
                instr_enc(
                    v_result,
                    '>',
                    v_bracket_start + 1,
                    1,
                    '"'
                );

            IF v_bracket_end > 0
            THEN
                v_result :=
                    SUBSTR(v_result, v_bracket_start + 1, v_bracket_end - v_bracket_start - 1);
            END IF;
        END IF;

        -- Take out any tab, line feed or carriage return characters
        -- that might have been used to visually format the strings
        RETURN TRIM(TRANSLATE(v_result, 'a' || CHR(9) || CHR(10) || CHR(13), 'a'));
    END extract_address;

    PROCEDURE parse_email_list(p_addresses IN VARCHAR2, p_list IN OUT NOCOPY DBMS_SQL.varchar2s)
    IS
        v_length      INTEGER := LENGTH(p_addresses);
        v_start       INTEGER := 1;
        v_delim_index INTEGER;
    BEGIN
        WHILE (v_start <= v_length)
        LOOP
            v_delim_index :=
                instr_enc(
                    p_addresses,
                    ',',
                    v_start,
                    1,
                    '"'
                );

            IF v_delim_index = 0
            THEN
                p_list(p_list.COUNT + 1) := extract_address(SUBSTR(p_addresses, v_start));
                v_start := v_length + 1;
            ELSE
                p_list(p_list.COUNT + 1) :=
                    extract_address(SUBSTR(p_addresses, v_start, v_delim_index - v_start));
                v_start := v_delim_index + 1;
            END IF;
        END LOOP;
    END parse_email_list;

    PROCEDURE begin_mime_block(
        p_connection     IN OUT NOCOPY connection,
        p_mime_type      IN            VARCHAR2 DEFAULT 'text/plain;charset=us-ascii',
        p_inline         IN            BOOLEAN DEFAULT TRUE,
        p_filename       IN            VARCHAR2 DEFAULT NULL,
        p_transfer_enc   IN            VARCHAR2 DEFAULT NULL
    )
    IS
    BEGIN
        UTL_SMTP.write_data(p_connection, '--' || g_boundary || c_crlf);
        UTL_SMTP.write_data(p_connection, 'Content-Type: ' || p_mime_type || c_crlf);

        IF (p_transfer_enc IS NOT NULL)
        THEN
            UTL_SMTP.write_data(
                p_connection,
                'Content-Transfer-Encoding: ' || p_transfer_enc || c_crlf
            );
        END IF;

        IF (p_filename IS NOT NULL)
        THEN
            IF (p_inline)
            THEN
                UTL_SMTP.write_data(
                    p_connection,
                    'Content-Disposition: inline; filename="' || p_filename || '"' || c_crlf
                );
            ELSE
                UTL_SMTP.write_data(
                    p_connection,
                    'Content-Disposition: attachment; filename="' || p_filename || '"' || c_crlf
                );
            END IF;
        END IF;

        UTL_SMTP.write_data(p_connection, c_crlf);
    END begin_mime_block;

    ------------------------------------------------------------------------
    PROCEDURE end_mime_block(
        p_connection   IN OUT NOCOPY connection,
        p_last         IN            BOOLEAN DEFAULT FALSE
    )
    IS
    BEGIN
        UTL_SMTP.write_data(p_connection, c_crlf);

        IF (p_last)
        THEN
            UTL_SMTP.write_data(p_connection, '--' || g_boundary || '--' || c_crlf);
        END IF;
    END end_mime_block;

    PROCEDURE write_clob(p_connection IN OUT NOCOPY connection, p_clob IN OUT NOCOPY CLOB)
    IS
        v_len   INTEGER;
        v_index INTEGER;
    BEGIN
        v_len := DBMS_LOB.getlength(p_clob);
        v_index := 1;

        write_to_log('Starting write_clob: ' || TO_CHAR(v_len) || ' characters', TRUE);

        WHILE v_index <= v_len
        LOOP
            UTL_SMTP.write_data(p_connection, DBMS_LOB.SUBSTR(p_clob, 32000, v_index));
            v_index := v_index + 32000;
        END LOOP;

        write_to_log('End write_clob: ' || TO_CHAR(v_len) || ' characters', TRUE);
    END write_clob;

    PROCEDURE write_blob(p_connection IN OUT NOCOPY connection, p_blob IN OUT NOCOPY BLOB)
    IS
        v_len   INTEGER;
        v_index INTEGER;
        v_chunk RAW(32767);
    BEGIN
        v_len := DBMS_LOB.getlength(p_blob);
        v_index := 1;

        write_to_log('Starting write_blob: ' || TO_CHAR(v_len) || ' bytes', TRUE);

        WHILE v_index <= v_len
        LOOP
            v_chunk := DBMS_LOB.SUBSTR(p_blob, c_base64_line, v_index);
            v_index := v_index + c_base64_line;

            UTL_SMTP.write_data(
                p_connection,
                UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(v_chunk))
            );
        END LOOP;

        write_to_log('End write_blob: ' || TO_CHAR(v_len) || ' bytes', TRUE);
    END write_blob;

    PROCEDURE send_all(
        p_sender          IN            VARCHAR2,
        p_recipients      IN            VARCHAR2,
        p_cc              IN            VARCHAR2,
        p_bcc             IN            VARCHAR2,
        p_subject         IN            VARCHAR2,
        p_message         IN OUT NOCOPY CLOB,
        p_mime_type       IN            VARCHAR2,
        p_priority        IN            PLS_INTEGER,
        p_clob            IN OUT NOCOPY CLOB,
        p_blob            IN OUT NOCOPY BLOB,
        p_att_inline      IN            BOOLEAN,
        p_att_mime_type   IN            VARCHAR2,
        p_att_filename    IN            VARCHAR2,
        p_replyto         IN            VARCHAR2,
        p_server_list     IN            VARCHAR2
    )
    IS
        v_connection   UTL_SMTP.connection;
        v_address_list DBMS_SQL.varchar2s;
        v_reply        UTL_SMTP.reply;
    BEGIN
        v_connection := find_a_server(p_server_list);

        v_reply := UTL_SMTP.mail(v_connection, extract_address(p_sender));
        write_to_log(
            'Mail(' || p_sender || '): ' || TO_CHAR(v_reply.code, 'fm009') || ' ' || v_reply.text
        );

        IF (p_recipients IS NOT NULL)
        THEN
            parse_email_list(p_recipients, v_address_list);
        END IF;

        IF (p_cc IS NOT NULL)
        THEN
            parse_email_list(p_cc, v_address_list);
        END IF;

        IF (p_bcc IS NOT NULL)
        THEN
            parse_email_list(p_bcc, v_address_list);
        END IF;

        IF v_address_list.COUNT > 0
        THEN
            FOR i IN 1 .. v_address_list.COUNT
            LOOP
                v_reply := UTL_SMTP.rcpt(v_connection, v_address_list(i));
                write_to_log(
                       'Rcpt('
                    || v_address_list(i)
                    || '): '
                    || TO_CHAR(v_reply.code, 'fm009')
                    || ' '
                    || v_reply.text
                );
            END LOOP;
        END IF;

        v_reply := UTL_SMTP.open_data(v_connection);
        write_to_log('Open Data: ' || TO_CHAR(v_reply.code, 'fm009') || ' ' || v_reply.text);

        IF (p_sender IS NOT NULL)
        THEN
            UTL_SMTP.write_data(v_connection, 'From: ' || p_sender || c_crlf);
        ELSE
            RAISE invalid_argument;
        END IF;

        IF (p_recipients IS NOT NULL)
        THEN
            UTL_SMTP.write_data(v_connection, 'To: ' || p_recipients || c_crlf);
        END IF;

        IF (p_cc IS NOT NULL)
        THEN
            UTL_SMTP.write_data(v_connection, 'CC: ' || p_cc || c_crlf);
        END IF;

        IF (p_replyto IS NOT NULL)
        THEN
            UTL_SMTP.write_data(v_connection, 'Reply-To: ' || extract_address(p_replyto) || c_crlf);
        END IF;

        UTL_SMTP.write_data(v_connection, 'Subject: ' || p_subject || c_crlf);

        IF p_priority BETWEEN 1 AND 5
        THEN
            UTL_SMTP.write_data(v_connection, 'X-Priority: ' || p_priority || c_crlf);
        ELSE
            RAISE invalid_priority;
        END IF;

        IF p_clob IS NOT NULL OR p_blob IS NOT NULL
        THEN
            UTL_SMTP.write_data(v_connection, 'MIME-Version: 1.0' || c_crlf);
            UTL_SMTP.write_data(v_connection, 'Content-Type: ' || multipart_mime_type || c_crlf);
            UTL_SMTP.write_data(v_connection, c_crlf);
            UTL_SMTP.write_data(
                v_connection,
                'This is a multi-part message in MIME format.' || c_crlf
            );

            IF p_message IS NOT NULL
            THEN
                attach_clob(
                    v_connection,
                    p_message,
                    p_mime_type,
                    TRUE,
                    NULL,
                    FALSE
                );
            END IF;

            IF p_clob IS NOT NULL
            THEN
                attach_clob(
                    v_connection,
                    p_clob,
                    p_att_mime_type,
                    p_att_inline,
                    p_att_filename,
                    TRUE
                );
            END IF;

            IF p_blob IS NOT NULL
            THEN
                attach_blob(
                    v_connection,
                    p_blob,
                    p_att_mime_type,
                    p_att_inline,
                    p_att_filename,
                    TRUE
                );
            END IF;
        ELSE
            IF p_mime_type IS NOT NULL
            THEN
                UTL_SMTP.write_data(v_connection, 'MIME-Version: 1.0' || c_crlf);
                UTL_SMTP.write_data(v_connection, 'Content-Type: ' || p_mime_type || c_crlf);
                UTL_SMTP.write_data(v_connection, c_crlf);
            END IF;

            IF p_message IS NOT NULL
            THEN
                write_clob(v_connection, p_message);
            END IF;
        END IF;

        v_reply := UTL_SMTP.close_data(v_connection);
        write_to_log('Close_Data:' || TO_CHAR(v_reply.code, 'fm009') || ' ' || v_reply.text);

        v_reply := UTL_SMTP.quit(v_connection);
        write_to_log('Quit: ' || TO_CHAR(v_reply.code, 'fm009') || ' ' || v_reply.text);
    EXCEPTION
        WHEN OTHERS
        THEN
            IF (v_connection.HOST IS NOT NULL)
            THEN
                UTL_SMTP.quit(v_connection);
            END IF;

            RAISE;
    END send_all;

    PROCEDURE send(
        p_sender        IN            VARCHAR2,
        p_recipients    IN            VARCHAR2,
        p_cc            IN            VARCHAR2 DEFAULT NULL,
        p_bcc           IN            VARCHAR2 DEFAULT NULL,
        p_subject       IN            VARCHAR2 DEFAULT NULL,
        p_message       IN OUT NOCOPY CLOB,
        p_mime_type     IN            VARCHAR2 DEFAULT 'text/plain;charset=us-ascii',
        p_priority      IN            PLS_INTEGER DEFAULT 3,
        p_replyto       IN            VARCHAR2 DEFAULT NULL,
        p_server_list   IN            VARCHAR2 DEFAULT NULL
    )
    IS
        v_dummyclob CLOB := NULL;
        v_dummyblob BLOB := NULL;
    BEGIN
        send_all(
            p_sender,
            p_recipients,
            p_cc,
            p_bcc,
            p_subject,
            p_message,
            p_mime_type,
            p_priority,
            v_dummyclob,
            v_dummyblob,
            NULL,
            NULL,
            NULL,
            NULL,
            p_server_list
        );
    END send;

    PROCEDURE send_attach_clob(
        p_sender          IN            VARCHAR2,
        p_recipients      IN            VARCHAR2,
        p_cc              IN            VARCHAR2 DEFAULT NULL,
        p_bcc             IN            VARCHAR2 DEFAULT NULL,
        p_subject         IN            VARCHAR2 DEFAULT NULL,
        p_message         IN OUT NOCOPY CLOB,
        p_mime_type       IN            VARCHAR2 DEFAULT 'text/plain;charset=us-ascii',
        p_priority        IN            PLS_INTEGER DEFAULT 3,
        p_attachment      IN OUT NOCOPY CLOB,
        p_att_inline      IN            BOOLEAN DEFAULT TRUE,
        p_att_mime_type   IN            VARCHAR2 DEFAULT 'text/plain;charset=us-ascii',
        p_att_filename    IN            VARCHAR2 DEFAULT NULL,
        p_replyto         IN            VARCHAR2 DEFAULT NULL,
        p_server_list     IN            VARCHAR2 DEFAULT NULL
    )
    IS
        v_dummy BLOB := NULL;
    BEGIN
        send_all(
            p_sender,
            p_recipients,
            p_cc,
            p_bcc,
            p_subject,
            p_message,
            p_mime_type,
            p_priority,
            p_attachment,
            v_dummy,
            p_att_inline,
            p_att_mime_type,
            p_att_filename,
            p_replyto,
            p_server_list
        );
    END send_attach_clob;

    PROCEDURE send_attach_blob(
        p_sender          IN            VARCHAR2,
        p_recipients      IN            VARCHAR2,
        p_cc              IN            VARCHAR2 DEFAULT NULL,
        p_bcc             IN            VARCHAR2 DEFAULT NULL,
        p_subject         IN            VARCHAR2 DEFAULT NULL,
        p_message         IN OUT NOCOPY CLOB,
        p_mime_type       IN            VARCHAR2 DEFAULT 'text/plain;charset=us-ascii',
        p_priority        IN            PLS_INTEGER DEFAULT 3,
        p_attachment      IN OUT NOCOPY BLOB,
        p_att_inline      IN            BOOLEAN DEFAULT TRUE,
        p_att_mime_type   IN            VARCHAR2 DEFAULT 'application/octet-stream',
        p_att_filename    IN            VARCHAR2 DEFAULT NULL,
        p_replyto         IN            VARCHAR2 DEFAULT NULL,
        p_server_list     IN            VARCHAR2 DEFAULT NULL
    )
    IS
        v_dummy CLOB := NULL;
    BEGIN
        send_all(
            p_sender,
            p_recipients,
            p_cc,
            p_bcc,
            p_subject,
            p_message,
            p_mime_type,
            p_priority,
            v_dummy,
            p_attachment,
            p_att_inline,
            p_att_mime_type,
            p_att_filename,
            p_replyto,
            p_server_list
        );
    END send_attach_blob;

    PROCEDURE set_mime_boundary(p_boundary IN VARCHAR2)
    IS
    BEGIN
        g_boundary := p_boundary;
    END;

    FUNCTION get_mime_boundary
        RETURN VARCHAR2
    IS
    BEGIN
        RETURN g_boundary;
    END;

    FUNCTION multipart_mime_type
        RETURN VARCHAR2
    IS
    BEGIN
        RETURN 'multipart/mixed; boundary="' || g_boundary || '"';
    END;

    PROCEDURE attach_text(
        p_connection   IN OUT NOCOPY connection,
        p_data         IN            VARCHAR2,
        p_mime_type    IN            VARCHAR2 DEFAULT 'text/plain;charset=us-ascii',
        p_inline       IN            BOOLEAN DEFAULT TRUE,
        p_filename     IN            VARCHAR2 DEFAULT NULL,
        p_last         IN            BOOLEAN DEFAULT FALSE
    )
    IS
    BEGIN
        begin_mime_block(
            p_connection,
            p_mime_type,
            p_inline,
            p_filename
        );
        UTL_SMTP.write_data(p_connection, p_data);
        end_mime_block(p_connection, p_last);
    END attach_text;

    PROCEDURE attach_clob(
        p_connection   IN OUT NOCOPY connection,
        p_data         IN OUT NOCOPY CLOB,
        p_mime_type    IN            VARCHAR2 DEFAULT 'text/plain;charset=us-ascii',
        p_inline       IN            BOOLEAN DEFAULT TRUE,
        p_filename     IN            VARCHAR2 DEFAULT NULL,
        p_last         IN            BOOLEAN DEFAULT FALSE
    )
    IS
    BEGIN
        begin_mime_block(
            p_connection,
            p_mime_type,
            p_inline,
            p_filename
        );

        write_clob(p_connection, p_data);

        end_mime_block(p_connection, p_last);
    END attach_clob;

    PROCEDURE attach_raw(
        p_connection   IN OUT NOCOPY connection,
        p_data         IN            RAW,
        p_mime_type    IN            VARCHAR2 DEFAULT 'application/octet-stream',
        p_inline       IN            BOOLEAN DEFAULT TRUE,
        p_filename     IN            VARCHAR2 DEFAULT NULL,
        p_last         IN            BOOLEAN DEFAULT FALSE
    )
    IS
    BEGIN
        begin_mime_block(
            p_connection,
            p_mime_type,
            p_inline,
            p_filename,
            'base64'
        );

        UTL_SMTP.write_raw_data(
            p_connection,
            UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(p_data))
        );

        end_mime_block(p_connection, p_last);
    END attach_raw;

    PROCEDURE attach_blob(
        p_connection   IN OUT NOCOPY connection,
        p_data         IN OUT NOCOPY BLOB,
        p_mime_type    IN            VARCHAR2 DEFAULT 'application/octet-stream',
        p_inline       IN            BOOLEAN DEFAULT TRUE,
        p_filename     IN            VARCHAR2 DEFAULT NULL,
        p_last         IN            BOOLEAN DEFAULT FALSE
    )
    IS
    BEGIN
        begin_mime_block(
            p_connection,
            p_mime_type,
            p_inline,
            p_filename,
            'base64'
        );

        write_blob(p_connection, p_data);

        end_mime_block(p_connection, p_last);
    END attach_blob;
BEGIN
    g_boundary := '--' || RAWTOHEX(SYS_GUID());
END sdsemail;