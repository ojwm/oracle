# APEX JSON Web Token (JWT)

<https://docs.oracle.com/en/database/oracle/apex/24.1/aeapi/APEX_JWT.html>.

```sql
CREATE OR REPLACE PACKAGE jwt_pkg AS
    FUNCTION get_jwt (p_header IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION get_jwt_formatted (p_header IN VARCHAR2) RETURN VARCHAR2;
END jwt_pkg;

CREATE OR REPLACE PACKAGE BODY jwt_pkg AS
    FUNCTION get_jwt (p_header IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        -- Get JWT from HTTP header
        RETURN owa_util.get_cgi_env(param_name => p_header);
    END get_jwt;
    --
    FUNCTION get_jwt_formatted (p_header IN VARCHAR2) RETURN VARCHAR2 IS
        FUNCTION get_json_formatted (p_clob IN CLOB) RETURN CLOB IS
            v_blob BLOB;
            v_clob CLOB;
            --
            FUNCTION get_blob_from_clob (p_clob IN CLOB) RETURN BLOB IS
                v_blob BLOB;
                v_dest_offset INTEGER := 1;
                v_src_offset INTEGER := 1;
                v_blob_csid CONSTANT NUMBER := 0;
                v_lang_context INTEGER := 0;
                v_warning INTEGER := 0;
            BEGIN
                dbms_lob.createTemporary(
                    lob_loc => v_blob
                    , cache => TRUE
                );
                --
                dbms_lob.convertToBlob(
                    dest_lob => v_blob
                    , src_clob => p_clob
                    , amount => LENGTH(p_clob)
                    , dest_offset => v_dest_offset
                    , src_offset => v_src_offset
                    , blob_csid => v_blob_csid
                    , lang_context => v_lang_context
                    , warning => v_warning
                );
                --
                RETURN v_blob;
            END get_blob_from_clob;
        BEGIN
            v_blob := get_blob_from_clob (p_clob => p_clob);
            -- JSON_SERIALIZE is not available in PL/SQL context
            SELECT JSON_SERIALIZE(v_blob RETURNING CLOB PRETTY)
            INTO v_clob
            FROM dual;
            --
            RETURN v_clob;
        END get_json_formatted;
    BEGIN
        RETURN get_json_formatted(
            p_clob => JSON_OBJECT_T.parse(
                apex_jwt.decode(
                    p_value => get_jwt (p_header => p_header)
                ).payload
            ).stringify()
        )
    END get_jwt_formatted;
END jwt_pkg;
```
