: NIP ( x1 x2 -- x2 )
    SWAP DROP ;

: 0<> ( x -- flag )
    0= 0= ;

: ?DUP ( x -- 0 | x x )
    DUP IF DUP THEN ;

: CELL+ ( a-addr1 -- a-addr2 ) 2 + ;

: - ( n1 | u1 n2 | u2 -- n3 | u3 )
    INVERT 1+ + ;

: = ( x1 x2 -- flag )
    XOR 0=
;
