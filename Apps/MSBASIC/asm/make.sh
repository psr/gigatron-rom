if [ ! -d tmp ]; then
	mkdir tmp
fi

for i in cbmbasic1 cbmbasic2 kbdbasic osi kb9 applesoft microtan aim65 sym1 gigatron; do

echo $i
ca65 -D $i msbasic.s -o tmp/$i.o -l tmp/$i.lst &&
ld65 -C $i.cfg tmp/$i.o -o tmp/$i.bin -Ln tmp/$i.lbl

done

# Create Gigatron ../include.gcl file
(
# COLD_START and STOP addresses
awk '
 BEGIN          {printf"{ Generated by: cd asm && ./make.sh }\n"}
 /\.COLD_START$/{printf"_COLD_START=$%4s\n",$2}
 /\.STOP$/      {printf"_STOP=$%4s\n",$2}
 /\.LIST$/      {printf"_LIST=$%4s\n",$2}
 /\.DIMFLG$/    {printf"_TMPZP=$%4s\n",$2}
 /\.INPUTFLG$/  {printf"_INPUTFLG=$%4s\n",$2}
' tmp/gigatron.lbl

# Hex dump
od -v -A n -t x1 tmp/gigatron.bin |
 fmt -1 |
  awk -v A=536 '
   BEGIN {printf"\n*=$%x\n",A}
   NF>0 {
    if(A%16==0)print""
    if(A%256==0)printf"\n*=$%x\n",A
    printf " #$%-2s",$1
    A++}
   END          {print}
  '
) > ../include.gcl
