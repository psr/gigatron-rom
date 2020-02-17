\ Immediate definitions for various important compiling words.

\ When imported as part of the Python Forth bootstrap process
\ these definitions have immediate effect, and are used to define each other.

\ However when imported when bringing up the Gigatron cross compiler the interpreter
\ dictionary is the Python Forth dictionary - containining the Python Forth definition of COMPILE,
\ but the cross compiler dictionary (containing the cross-compiling definition of COMPILE,) is used
\ when in compilation mode.  There are cases when we need each of these.

\ This word compiles an immediate word - Immediate words are located in the interpreter dictionary,
\ and need to use the COMPILE, from the interpreter dictionary

: [COMPILE]
    ' [ ' COMPILE, COMPILE,
; IMMEDIATE

: [']
    ' [COMPILE] LITERAL
; IMMEDIATE


: POSTPONE
    WORD FIND ?DUP IF ( found )
        1 = IF ( Immediate )
            \ Append interpreter mode COMPILE, to definition.
            [ ' COMPILE, COMPILE, ]
        ELSE ( Non-immediate )
            [COMPILE] LITERAL
            \ The COMPILE, we need to run is the Gigatron version
            \ This finds it and embeds it in the definition of POSTPONE as a literal
            ['] COMPILE,
            \ This compiles the Python version into the definition of POSTPONE.
            \ At run time this will compile the literal into the current definition
            [ ' COMPILE, COMPILE, ]
        THEN
    ELSE ( not found TODO )
    THEN
; IMMEDIATE
