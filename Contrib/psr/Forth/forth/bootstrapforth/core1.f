\ Definitions for core words common to both the bootstrap Forth and the
\ Gigatron Forth.

\ When compiling the bootstrap Forth the next file to load is bootstrap.f

\ When compiling the Gigatron Forth the next file to load is gigatron.f

\ Can only use features supported by the bootstrap compiler and words
\ defined in both Python and Gigatron asm.



: 0<> 0= 0= ;
: 0< 0 < ;
: 0> 0 > ;
: ?DUP DUP 0<> IF DUP THEN ;
: NIP SWAP DROP ;


: [ STATE 0 ! ; IMMEDIATE
: ] STATE 1 ! ;

: HEX BASE 16 ! ;
: DECIMAL BASE 10 ! ;

: ABORT
    ." Aborted!"
    BYE
;

: ' WORD FIND DROP ;  \ TODO Error handling

