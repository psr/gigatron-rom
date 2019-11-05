# NEXT

The traditional Forth NEXT code will be split into three parts:

* *NEXT1*, which runs before each word, and includes the decision about whether to run the next word or jump to the video loop.
* *NEXT2*, which runs after each word. It updates the time remaining, selects the appropriate NEXT3, stores in in W, and then jumps to NEXT1.
* *NEXT3*, which is most like the traditional NEXT - Logically it copies the IP to W, and increments the IP before jumping to W (by jumping to NEXT1).

I'm going to have three versions of NEXT3, to handle three cases:
* The current thread is in RAM, and the next codeword is a RAM address
* The current thread is in RAM, but the next codeword is a ROM address
* The current thread is in ROM (and therefore the next codeword is a ROM addresses).
All three versions of NEXT3 would start at the same address, but in different pages, and a zero-page variable would hold the appropriate page for the current mode.
I will have a words to switch between the three states, which will be compiled into threads as appropriate.


## NEXT1

This routine starts with the time remaining in A.
It must execute the word who's address is in W, if there is time to do so.
The value in W is always a ROM address.

There are three paths through this:

1. (Success) We may decide to execute the next word - we must allow sufficient time to examinine it, run it, run NEXT2 and case 3 of this routine.
2. (Fail Test) We may examine the next word, but decide that we don't have time to complete it and jump back to the video loop. This case is off the critical path but must complete in less time than is allowed for case 1.
3. (Fail Fast) We may decide that there isn't time to complete case 1 or case 2, and so we return to the video loop.

### The Test

We will have a rule that each word must start with a single instruction to subtract the worst-case cost in ticks from A.
We will also have the following trampoline in each ROM page that holds a FORTH word:
```
quit-or-restart:
    bra [W-lo];   # Unconditionally restarts the word
    ble quit;     # But jump straight back out again if we're going to run out of time.
quit:
    ld hi(displayloop), Y
    jmp Y, lo(displayloop)
```

The test is then to load A with (time_remaining - (cost-of(success case of quit-or-restart = 1) + cost-of(NEXT2) + cost-of(Fail-fast case of NEXT1) + 2),
and then jumping to W, with a branch to quit-or-restart in the branch-delay slot. This will run the word if can make it back in time, and words only need to know
their own cost.

### Re-entry

Some words won't know their worst-case cost because they contain a loop (it's data dependant).
They can split themselves with internal entrypoints, update W-Lo, load the time taken so far, and re-enter NEXT1 at a known point.

## NEXT2

We will have a rule that each word finish by loading the time taken in ticks into A.
To this we need to add the cost-of(NEXT2) and cost-of(success case of quit-or-restart), and subtract from the previous time remaining.

NEXT2 will be the routine:
```
    adda (-)              # 1  Cost of NEXT2, plus cost of quit-or-restart
    adda [vTicks]         # 2
    st [vTicks]           # 3
    ld [mode];            # 4
    st [W-hi];            # 5
    ld NEXT3;             # 6
    st [W-lo];            # 7
    bra NEXT1;            # 8
    ld [vTicks]           # 9
```

## NEXT3

### For threads in ROM

The threads in Forth are traditional lists of the addresses of words (and other data), but we can only really store instructions in ROM.
So we need our threads to be lists of instructions. We can use the st $00 [y, x++] instructions to write data to arbitrary memory locations,
so we can combine that with the double-jump trick to copy to the W location. The page we want to write to needs to be in the Y register,
so we load that in the branch delay slot.
If it turns out that we don't care much about code-size, we can make this much faster by inlining code.

```
    adda (-42/2)        # 1
    ld W-Lo             # 2
    ld ac, x            # 3
    ld hi(return)       # 4
    st [return-hi]      # 5
    ld return           # 6
    st [return-lo]      # 7
    ld $02              # 8
top:
    st [loopcounter]    # 9, 25
    ld [IP-Hi], Y       # 10, 26
    ld [IP-Lo]          # 11, 27
    jmp Y, trampoline   # 12, 28
    ld $00, y           # 13, 29
return:
    st [IP-Lo]          # 20, 36
    ld [loopcounter]    # 21, 37
    suba $01            # 22, 38
    bgt top             # 23, 39
exit:
    ld hi(NEXT1), y     # 24, 40
    jmp y, NEXT1-reenter# 41
    ld (-42/2)          # 42

# In the thread page
    st $<CFA-Lo>, [y,x++] # 16
    st $<CFA-Hi>, [y,x++] # 32
...
trampoline:
    bra ac              # 14, 30
    bra $here           # 15, 31
here:
    ld [return-hi], y   # 17, 33
    jmp y, [return-lo]  # 18, 34
    adda $01            # 19, 35
```
The trampoline doesn't mess with the X or A register if they're set by other code, which might prove useful for LIT and other words.

As it will be common for both the quit-or-restart trampoline and this one to be present in the same page, and I don't intend to allow threads to cross pages
this leaves 256 - 5 - 4 = 247 instructions for the longest possible thread.


### NEXT3 for threads in RAM, but using Addresses in ROM.

This is the simplest case. Assumes that addresses are 2-byte aligned.
```
    adda -(16 / 2)          # 1
    ld [IP-hi]              # 2
    st [W-hi]               # 3
    ld [IP-lo]              # 4
    st [W-Lo]               # 5
    adda 2                  # 6
    beq page-boundary       # 7
    st [IP-Lo]              # 8
    ld (-12/2)              # 9
exit:
    ld hi(NEXT1), y         # 10, 14
    jmp y, NEXT1-reenter    # 11, 15
page-boundary:
    ld [IP-Hi]              # 12, 9, 16 - Overlap
    adda 1                  # 10
    st [IP-Hi]              # 11
    bra exit                # 12
    ld (-16/2)              # 13
```

### NEXT3 for threads in RAM, and using addresses in RAM.
```
    adda -(22 / 2)          # 1
    ld [IP-hi], y           # 2
    ld [IP-lo], x           # 3
    ld [x,y]                # 4
    st [W-Hi]               # 5
    ld [IP-lo]              # 6
    adda 1                  # 7
    st ac,x                 # 8
    ld [y, x]               # 9
    st [IP-lo]              # 10
    adda 2                  # 11
    beq page-boundary       # 12
    st [IP-Lo]              # 13
    ld (-18/2)              # 14
exit:
    ld hi(NEXT1), y         # 15, 19
    nop                     # 16, 20
    jmp y, NEXT1-reenter    # 17, 21
page-boundary:
    ld [IP-Hi]              # 18, 14, 22 - Overlap
    adda 1                  # 15
    st [IP-Hi]              # 16
    bra exit                # 17
    ld (-22/2)              # 18
```
