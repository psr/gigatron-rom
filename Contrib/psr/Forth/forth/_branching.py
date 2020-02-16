"""Implementations of kernel words related to branching
"""
from asm import C, X, Xpp, Y, adda, bne, bra, jmp, label, ld, nop, st

from ._next import cost_of_move_ip
from .variables import (
    IP_hi,
    IP_lo,
    W,
    data_stack_page,
    data_stack_pointer,
    tmp0,
)

# ROM mode branches are encoded in a ROM mode thread using the following encoding:

# On entry Y holds 0, and X holds the address of W. AC is undefined
# bra $aa
# ld $bb
# Where aa is absolute address to branch to, and bb is the relative movement that this represents.

# The bra causes us to load the address of the following word into the W register (the encoding of the target instruction).
# The ld causes the eventual jump to forth.move-ip to result in the correct update to IP.
# In other words branches incorporate the effect of next3-rom-mode.


def branch_rom_mode():
    """Unconditional Branch ( -- )"""
    label("forth.internal.BRANCH-rom-mode")
    adda(-cost_of_branch_rom_mode // 2)  # 1

    ld(-(cost_of_branch_rom_mode // 2))
    C("Store cost")
    st([tmp0])

    ld(W, X)
    C("X <- W")

    ld([IP_hi], Y)  # 5
    C("Jump to the code in the thread")
    jmp(Y, [IP_lo])
    ld(0x00, Y)  # 7


cost_of_branch_rom_mode = 7 + 2 + 3 + cost_of_move_ip
assert (
    cost_of_branch_rom_mode % 2 != 0
), "cost must be odd due to the requirements of move_ip"


def question_branch_rom_mode():
    """Conditional Branch (flag -- )

    Branches when the flag at the top of the stack is zero

    Naming is per the Forth '83 standard.
    """
    label("forth.internal.?BRANCH-rom-mode")
    adda(-cost_of_question_branch_rom_mode // 2)  # 1

    ld([data_stack_pointer], X)
    ld([data_stack_pointer])
    adda(2)
    st([data_stack_pointer])  # 5
    ld([X])
    bne(".?BRANCH.not-zero1")
    ld(-(cost_of_question_branch_rom_mode__first_byte_nonzero // 2))  # 8

    ld(data_stack_page, Y)  # 9
    st([Y, Xpp])
    ld([Y, X])
    bne(".?BRANCH.not-zero2")
    ld(-(cost_of_question_branch_rom_mode__second_byte_nonzero // 2))  # 13

    ld(-(cost_of_question_branch_rom_mode__both_bytes_zero // 2))  # 14
    C("Store cost")
    st([tmp0])  # 15

    label(".enter-thread")
    ld(W, X)  # 16, 20
    C("X <- W")
    ld([IP_hi], Y)
    C("Jump to the code in the thread")
    jmp(Y, [IP_lo])
    ld(0x00, Y)  # 19, 23

    label(".?BRANCH.not-zero1")
    nop()
    label(".?BRANCH.not-zero2")
    st([tmp0])  # 10, 14
    C("Store cost")
    ld(2)  # 11, 15
    ("IP <- IP + 2")
    adda([IP_lo])
    st([IP_lo])
    bra(".enter-thread")
    ld(3)  # 15, 19
    C("IP will move a further 3")


cost_of_question_branch_rom_mode__first_byte_nonzero = 19 + 3 + cost_of_move_ip
cost_of_question_branch_rom_mode__second_byte_nonzero = 23 + 3 + cost_of_move_ip
cost_of_question_branch_rom_mode__both_bytes_zero = 19 + 2 + 3 + cost_of_move_ip
assert all(
    cost % 2 != 0
    for cost in [
        cost_of_question_branch_rom_mode__first_byte_nonzero,
        cost_of_question_branch_rom_mode__second_byte_nonzero,
        cost_of_question_branch_rom_mode__both_bytes_zero,
    ]
), "cost must be odd due to the requirements of move-ip"
cost_of_question_branch_rom_mode = max(
    cost_of_question_branch_rom_mode__first_byte_nonzero,
    cost_of_question_branch_rom_mode__second_byte_nonzero,
    cost_of_question_branch_rom_mode__both_bytes_zero,
)
