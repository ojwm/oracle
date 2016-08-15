SELECT upper(substr('&&table',1,regexp_instr('&&table','[^a|e|i|o|u]', 3, 1, 0, 'i'))||'_'||
             substr('&&table', instr('&&table','_')+1, regexp_instr('&&table','[^a|e|i|o|u]', instr('&&table','_')+3, 1, 0, 'i')-instr('&&table','_'))) short_name
FROM   dual
/