: NIP ( x1 x2 -- x2 )
    SWAP DROP ;

: 0<> ( x -- flag )
    0= 0= ;

: ?DUP ( x -- 0 | x x )
    DUP IF DUP THEN ;

: CELL+ ( a-addr1 -- a-addr2 ) 2 + ;

: NEGATE ( n1 -- n2 )
    INVERT 1+ ;

: - ( n1 | u1  n2 | u2 -- n3 | u3 )
    NEGATE + ;

: = ( x1 x2 -- flag )
    XOR 0= ;

: 0< ( n -- flag )
    [ BASE @ HEX ] 8000 [ BASE SWAP ! ] AND 0<> ;

: 0> ( n -- flag )
    0 SWAP - 0< ;

\ Taken from the eForth implementation - This confused me!
: U< ( u1 u2 -- flag )  2DUP XOR 0< IF SWAP DROP 0< EXIT THEN - 0< ;
:  < ( n1 n2 -- flag )  2DUP XOR 0< IF      DROP 0< EXIT THEN - 0< ;

:  > ( n1 n2 -- flag )  SWAP < ;
: U> ( u1 u2 -- flag )  SWAP U< ;

: ABS ( n -- u )
    DUP 0< IF NEGATE THEN ;
