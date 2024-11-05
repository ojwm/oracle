SELECT owner,
       segment_name,
       trim(to_char(round(bytes/1024/1024,2),'99999990.00')) "Size in MB",
       --trim(to_char(round(bytes/1024/1024/1024,2),'99999990.00')) "Size in GB",
       tablespace_name
FROM   dba_segments
WHERE  segment_type                    = 'TABLE'
AND    round(bytes/1024/1024,2)        > 128
AND    segment_name             NOT LIKE 'AUD\_%' ESCAPE '\'
ORDER BY round(bytes/1024/1024,2) DESC