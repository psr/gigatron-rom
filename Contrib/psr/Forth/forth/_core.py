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
from .variables import data_stack_pointer


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


__all__ = ["drop", "drop_two"]
