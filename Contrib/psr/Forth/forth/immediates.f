\ Immediate definitions.

\ When imported as part of the Python Forth bootstrap process
\ these definitions have immediate effect, but when used in the
\ Gigatron ROM bringup they do not effect one another, as the
\ compiled definitions end up in the target dictionary
\ but immediate definitions are found in the runtime dictionary

: POSTPONE
    WORD FIND DROP
    [ WORD COMPILE, FIND DROP COMPILE, ]
; IMMEDIATE

: [']
    WORD FIND DROP POSTPONE LITERAL
; IMMEDIATE

: ;
    POSTPONE [
    ['] EXIT COMPILE,
    HIDDEN
; IMMEDIATE
