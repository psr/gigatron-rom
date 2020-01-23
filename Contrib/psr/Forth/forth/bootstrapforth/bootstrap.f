\ A very simple Forth environment
\ This file is processed with the bootstrap compiler when bringing up
\ the Python Forth, so can only use features supported there.

\ Once these definitions are loaded, QUIT is executed, and we start back at core1.f
\ In order to get a Python Forth environment.


: INTERPRET
  BEGIN
    WORD DUP COUNT NIP 0<>
  WHILE
    FIND ?DUP IF                                     ( xt +-1 )
      STATE @ IF                                     ( xt +-1 )
        0> IF EXECUTE ELSE POSTPONE COMPILE, THEN   ( ??? )
      ELSE                                            ( xt +-1 )
        DROP EXECUTE                                       ( ??? )
      THEN
    ELSE                                              ( c-addr )
      STATE @ IF
        NUMBER POSTPONE LITERAL
      ELSE
        NUMBER
      THEN
    THEN
  REPEAT
  DROP
;

: QUIT
  POSTPONE [
  BEGIN
    REFILL
  WHILE
    INTERPRET
    STATE @ 0= IF ." OK" THEN
    CR
   REPEAT BYE
;