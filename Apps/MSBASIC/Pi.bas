10 INPUT"HOW MANY DIGITS";N
20 T=TIME
30 L=INT(10*N/3)+1:DIM A(L)
40 Z$="000000":T$="999999"
50 FOR I=1TOL:A(I)=2:NEXT
60 M=0:P=0
70 FOR J=1TON:Q=0:K=2*L+1
80 FOR I=L TO 1 STEP -1
90 K=K-2:X=10*A(I)+Q*I
100 Q=INT(X/K):A(I)=X-Q*K
110 NEXT
120 Y=INT(Q/10):A(1)=Q-10*Y:Q=Y
130 IF Q=9 THEN M=M+1:GOTO170
140 IF Q>9 THEN PRINT CHR$(49+P);LEFT$(Z$,M);:GOTO170
150 PRINT CHR$(48+P);LEFT$(T$,M);
160 P=Q:M=0
170 NEXT
180 PRINT CHR$(48+P):PRINT (TIME-T)/59.98
