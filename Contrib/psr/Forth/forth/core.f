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

