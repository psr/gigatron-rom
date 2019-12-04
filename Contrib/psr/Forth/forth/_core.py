from asm import *

from ._utilities import (
    NEXT,
    add_cost_of_next,
    data_stack,
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
        with data_stack as ds:
            for _ in range(size):
                ds.drop()
        NEXT(cost_of_drop)

    return drop


cost_of_drop = 4


drop = make_drop("DROP", 2)
drop_two = make_drop("2DROP", 4)


def swap():
    label("forth.core.SWAP")
    adda(-add_cost_of_next(cost_of_swap) / 2)
    (a_lo, a_hi), (b_lo, b_hi) = (tmp0, tmp1), (tmp2, tmp3)
    with data_stack as ds:
        # C("Copy top 4 bytes of stack to tmp")
        for location in [a_lo, a_hi, b_lo, b_hi]:
            ds.pop_to(location)
        # C("Copy back to stack in order")
        for location in reversed([b_lo, b_hi, a_lo, a_hi]):
            ds.push_from(location)
    NEXT(cost_of_swap)


cost_of_swap = 4 + 3 * 5 + 2 + 4 * 2


__all__ = ["drop", "drop_two", "swap"]
