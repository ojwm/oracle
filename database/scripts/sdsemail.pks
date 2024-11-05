CREATE OR REPLACE PACKAGE sdsemail
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

    SUBTYPE connection IS UTL_SMTP.connection;

    invalid_argument              EXCEPTION;
    invalid_priority              EXCEPTION;

    PRAGMA EXCEPTION_INIT(invalid_argument, -29261);
    PRAGMA EXCEPTION_INIT(invalid_priority, -44101);

    c_log_off            CONSTANT INTEGER := 0;
    c_log_dbms_output    CONSTANT INTEGER := 1;
    c_log_rolling_buffer CONSTANT INTEGER := 2;
    c_log_client_info    CONSTANT INTEGER := 4;
    c_default_verbose    CONSTANT BOOLEAN := FALSE;

    PROCEDURE set_log_options(p_log_options IN INTEGER);

    FUNCTION get_log_options
        RETURN INTEGER;

    PROCEDURE clear_log;

    FUNCTION get_log_text
        RETURN VARCHAR2;

    PROCEDURE set_verbose(p_verbose IN BOOLEAN);

    FUNCTION get_verbose
        RETURN BOOLEAN;

    PROCEDURE write_to_log(v_text IN VARCHAR2, p_verbose IN BOOLEAN DEFAULT FALSE);

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
    );

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
    );

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
    );

    PROCEDURE set_mime_boundary(p_boundary IN VARCHAR2);

    FUNCTION get_mime_boundary
        RETURN VARCHAR2;

    FUNCTION multipart_mime_type
        RETURN VARCHAR2;

    PROCEDURE attach_text(
        p_connection   IN OUT NOCOPY connection,
        p_data         IN            VARCHAR2,
        p_mime_type    IN            VARCHAR2 DEFAULT 'text/plain;charset=us-ascii',
        p_inline       IN            BOOLEAN DEFAULT TRUE,
        p_filename     IN            VARCHAR2 DEFAULT NULL,
        p_last         IN            BOOLEAN DEFAULT FALSE
    );

    PROCEDURE attach_clob(
        p_connection   IN OUT NOCOPY connection,
        p_data         IN OUT NOCOPY CLOB,
        p_mime_type    IN            VARCHAR2 DEFAULT 'text/plain;charset=us-ascii',
        p_inline       IN            BOOLEAN DEFAULT TRUE,
        p_filename     IN            VARCHAR2 DEFAULT NULL,
        p_last         IN            BOOLEAN DEFAULT FALSE
    );

    PROCEDURE attach_raw(
        p_connection   IN OUT NOCOPY connection,
        p_data         IN            RAW,
        p_mime_type    IN            VARCHAR2 DEFAULT 'application/octet-stream',
        p_inline       IN            BOOLEAN DEFAULT TRUE,
        p_filename     IN            VARCHAR2 DEFAULT NULL,
        p_last         IN            BOOLEAN DEFAULT FALSE
    );

    PROCEDURE attach_blob(
        p_connection   IN OUT NOCOPY connection,
        p_data         IN OUT NOCOPY BLOB,
        p_mime_type    IN            VARCHAR2 DEFAULT 'application/octet-stream',
        p_inline       IN            BOOLEAN DEFAULT TRUE,
        p_filename     IN            VARCHAR2 DEFAULT NULL,
        p_last         IN            BOOLEAN DEFAULT FALSE
    );

    PROCEDURE begin_mime_block(
        p_connection     IN OUT NOCOPY connection,
        p_mime_type      IN            VARCHAR2 DEFAULT 'text/plain;charset=us-ascii',
        p_inline         IN            BOOLEAN DEFAULT TRUE,
        p_filename       IN            VARCHAR2 DEFAULT NULL,
        p_transfer_enc   IN            VARCHAR2 DEFAULT NULL
    );

    PROCEDURE end_mime_block(
        p_connection   IN OUT NOCOPY connection,
        p_last         IN            BOOLEAN DEFAULT FALSE
    );
END sdsemail;