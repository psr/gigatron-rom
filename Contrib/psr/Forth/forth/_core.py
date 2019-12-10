from asm import *

from ._utilities import (
    NEXT,
    add_cost_of_next,
)
from .variables import (
    data_stack_pointer,
    tmp0,
    tmp1,
    tmp2,
    tmp3,
    tmp4,
    tmp5,
    tmp6,
    tmp7,
)


def make_drop(name, size):
    def drop():
        label("forth.core." + name)
        adda(-add_cost_of_next(cost_of_drop) / 2)
        ld([data_stack_pointer])
        adda(size)
        st([data_stack_pointer])
        NEXT(cost_of_drop)

    return drop


cost_of_drop = 4


drop = make_drop("DROP", 2)
drop_two = make_drop("2DROP", 4)


def swap():
    label("forth.core.SWAP")
    adda(-add_cost_of_next(cost_of_swap) / 2)
    C("Copy top 4 bytes of stack to tmp")
    ld([data_stack_pointer], X)
    ld([X])
    st([tmp0])  # 4
    # TODO: should this loop be in the assembly, or is unrolled better?
    for i, location in enumerate([tmp1, tmp2, tmp3], start=1):
        ld([data_stack_pointer])
        adda(i)
        ld(AC, X)
        ld([X])
        st([location])  # 5
    ld(0x00, Y)
    C("Copy back to stack in order")
    ld([data_stack_pointer], X)  # 2
    for location in [tmp2, tmp3, tmp0, tmp1]:
        ld([location])
        st([Y, Xpp])  # 2
    NEXT(cost_of_swap)


cost_of_swap = 4 + 3 * 5 + 2 + 4 * 2


def dup():
    label("forth.core.DUP")
    adda(-add_cost_of_next(cost_of_dup) / 2)
    ld([data_stack_pointer], X)
    ld([X])
    st([tmp0])
    ld([data_stack_pointer])  # 5
    adda(1, X)
    ld([X])
    st([tmp1])
    ld(0, Y)
    ld([data_stack_pointer])  # 10
    suba(2)
    st([data_stack_pointer], X)
    ld([tmp0])
    st([Y, Xpp])
    ld([tmp1])  # 15
    st([Y, X])  # 16
    NEXT(cost_of_dup)


cost_of_dup = 16


def over():
    label("forth.core.OVER")
    adda(-add_cost_of_next(cost_of_over) / 2)
    ld([data_stack_pointer])
    adda(2, X)
    ld([X])
    st([tmp0])  # 5
    ld([data_stack_pointer])
    adda(3, X)
    ld([X])
    st([tmp1])
    ld(0, Y)  # 10
    ld([data_stack_pointer])
    suba(2)
    st([data_stack_pointer], X)
    ld([tmp0])
    st([Y, Xpp])  # 15
    ld([tmp1])
    st([Y, X])  # 17
    NEXT(cost_of_over)


cost_of_over = 17


def rot():
    label("forth.core.ROT")
    adda(-add_cost_of_next(cost_of_rot) / 2)
    ld(0, Y)  # 2
    # copy 3OS -> tmp{0,1}
    for offset, dest in enumerate([tmp0, tmp1], start=4):
        ld([data_stack_pointer])
        adda(offset, X)
        ld([X])
        st([dest])
    # Shift Everything down, Filling with tmp{0,1}
    ld([data_stack_pointer], X)  # 11 = 2 + 2 * 4 + 1
    for to, from_ in zip([tmp2, tmp0, tmp1, tmp2], [tmp0, tmp1, tmp2, tmp0]):
        ld([X])
        st([to])
        ld([from_])
        st([Y, Xpp])
    for src in [tmp1, tmp2]:  # 27 = 11 + 16
        ld([src])
        st([Y, Xpp])
    NEXT(31)


cost_of_rot = 31  # 31 = 27 + 2 * 2


def two_swap():
    label("forth.core.2SWAP")
    adda(-add_cost_of_next(cost_of_2swap) / 2)
    ld(0, Y)
    ld([data_stack_pointer])
    adda(4, X)  # 4
    for copy_to in [tmp0, tmp1, tmp2]:
        ld([X])
        st([Y, Xpp])  # Increment X
        st([copy_to])
    ld([X])  # 14 = 4 + 3 * 3 + 1
    st([tmp3])
    ld([data_stack_pointer], X)  #  16
    for copy_from, copy_to in zip([tmp0, tmp1, tmp2, tmp3], [tmp4, tmp0, tmp1, tmp2]):
        ld([X])
        st([copy_to])
        ld([copy_from])
        st([Y, Xpp])
    for copy_from in [tmp4, tmp0, tmp1, tmp2]:
        ld([copy_from])
        st([Y, Xpp])
    NEXT(cost_of_2swap)


cost_of_2swap = 40  # 16 + 4 * 4 + 4 * 2

__all__ = ["drop", "drop_two", "swap", "dup", "over", "rot", "two_swap"]
