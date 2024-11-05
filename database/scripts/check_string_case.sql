SELECT CASE WHEN (t.upper > 0 AND t.lower > 0) THEN 'Mixed'
            WHEN (t.upper = 0 AND t.lower > 0) THEN 'Lower'
            WHEN (t.upper > 0 AND t.lower = 0) THEN 'Upper'
            ELSE 'Blank' END "CASE"
FROM   (SELECT nvl(length(regexp_replace(translate('oliver mitchell', 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
                                                                      'LLLLLLLLLLLLLLLLLLLLLLLLLLUUUUUUUUUUUUUUUUUUUUUUUUUU'),
                                         '[^U]')),0) "UPPER",
               nvl(length(regexp_replace(translate('oliver mitchell', 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
                                                                      'LLLLLLLLLLLLLLLLLLLLLLLLLLUUUUUUUUUUUUUUUUUUUUUUUUUU'),
                                         '[^L]')),0) "LOWER"
        FROM   dual) t
/