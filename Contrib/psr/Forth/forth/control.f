\ Definitions of various compiling words.

: IF
    POSTPONE ?BRANCH >MARK
; IMMEDIATE

: ELSE
    POSTPONE BRANCH >MARK SWAP >RESOLVE
; IMMEDIATE

: THEN
    >RESOLVE
; IMMEDIATE

\ This definition needs to be the last as it assumes that future
\ definitions use the cross compiling :
: ;
    POSTPONE [
    POSTPONE EXIT
    HIDDEN
; IMMEDIATE
