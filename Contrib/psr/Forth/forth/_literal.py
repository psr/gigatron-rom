"""Implementation of Literals"""
from asm import *

from ._next import cost_of_move_ip
from .variables import IP_hi, IP_lo, data_stack_pointer, tmp0

# ROM mode literals are encoded in a ROM mode thread using the following encoding:

# On entry Y holds 0, and X holds the stack pointer, AC holds 6
# st $ll,[y,x++]
# st $hh,[y,x++]
# ld $W,x

# This causes the two bytes to be written to the stack (the stack pointer has already been decremented). Execution then
# runs into the following instructions, which write to W and call forth.move-ip (our standard encoding for words in a thread).
# In other words literals incorporate the effect of next3-rom-mode.
# For single byte values (0-255) we write the high byte in the word, not in the thread, for density.


def lit_rom_mode():
    """LIT - word that reads a number encoded in the thread, and pushes it to the stack"""
    label("forth.internal.LIT")
    adda(-(cost_of_lit_rom_mode // 2))

    ld(-(cost_of_lit_rom_mode // 2))
    C("Store cost")
    st([tmp0])

    ld([data_stack_pointer])
    C("Decrement Data stack pointer")
    suba(2)  # 5
    ld(AC, X)
    st([data_stack_pointer])

    ld([IP_hi], Y)
    C("Jump to the code in the thread")
    ld(6)
    C("We're going to shift the IP by 6")
    nop()  # 10, to meet requirement of move-ip that we must use an even number of cycles
    jmp(Y, [IP_lo])
    ld(0x00, Y)  # 12


cost_of_lit_rom_mode = 12 + 6 + cost_of_move_ip


def char_lit_rom_mode():
    """C-LIT - word that reads a byte encoded in the thread, and pushes it to the stack"""
    label("forth.internal.C-LIT")
    adda(-(cost_of_char_lit_rom_mode // 2))

    ld(-(cost_of_char_lit_rom_mode // 2))
    C("Store cost")
    st([tmp0])

    ld([data_stack_pointer])
    C("Decrement Data stack pointer and store high byte of 0")
    suba(1)  # 5
    ld(AC, X)
    ld(0)
    st([X])
    ld([data_stack_pointer])
    suba(2)  # 10
    ld(AC, X)
    st([data_stack_pointer])

    ld([IP_hi], Y)
    C("Jump to the code in the thread")
    ld(5)
    C("We're going to shift the IP by 5")
    nop()  # 15, to meet requirement of move-ip that we must use an even number of cycles
    jmp(Y, [IP_lo])
    ld(0x00, Y)  # 17


cost_of_char_lit_rom_mode = 17 + 5 + cost_of_move_ip
