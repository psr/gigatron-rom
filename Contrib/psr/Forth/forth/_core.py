from __future__ import (
    absolute_import,
    division,
    print_function,
    unicode_literals,
)

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


__all__ = ["drop", "drop_two", "swap"]
