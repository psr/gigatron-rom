: NIP ( x1 x2 -- x2 )
    SWAP DROP ;

: 0<> ( x -- flag )
    0= 0= ;

: ?DUP ( x -- 0 | x x )
    DUP IF DUP THEN ;
