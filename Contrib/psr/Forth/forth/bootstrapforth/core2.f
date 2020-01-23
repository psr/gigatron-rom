: ; [ WORD EXIT FIND DROP COMPILE,
      WORD [ FIND DROP COMPILE,
      IMMEDIATE
      HIDDEN
;


: \
    >IN SOURCE NIP !
; IMMEDIATE

\ The previous definition handles backslash comments


\ TODO: Handle word not found
: [']
    WORD FIND DROP LITERAL
; IMMEDIATE



