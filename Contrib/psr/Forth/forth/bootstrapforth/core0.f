: ; [ WORD [ FIND DROP COMPILE,
      WORD HIDDEN FIND DROP COMPILE,
      WORD EXIT FIND DROP ] LITERAL
    [ WORD COMPILE, FIND DROP COMPILE,
      IMMEDIATE HIDDEN ]
; HIDDEN

: \ >IN SOURCE NIP ! ; IMMEDIATE

\ Now we can use backslash comments!
\ They last to the end of the line

: '(' [ CHAR ( ] LITERAL ;
: ')' [ CHAR ) ] LITERAL ;

: (
    1                     \ allowed nested parens by keeping track of depth
    BEGIN
        KEY               \ read next character
        DUP '(' = IF      \ open paren?
            DROP          \ drop the open paren
            1 +           \ depth increases
        ELSE ')' = IF     \ close paren?
            1 -           \ depth decreases
        THEN THEN
    DUP 0= UNTIL          \ continue until we reach matching close paren, depth 0
    DROP                  \ drop the depth counter
; IMMEDIATE
