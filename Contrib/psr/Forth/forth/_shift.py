"""Implementation of various shift words"""


from asm import AC, C, X, Xpp, Y, adda, anda, label, ld, st

from ._utilities import NEXT, add_cost_of_next
from .variables import data_stack_page, data_stack_pointer, tmp0


def two_times():
    """Implements a left-shift by one which is used for both

    2* ( x1 -- x2 )
    CELLS ( n1 -- n2 )
    """
    label("forth.core.2*")
    label("forth.core.CELLS")
    adda(-add_cost_of_next(cost_of_two_times) / 2)  # 1
    ld(data_stack_page, Y)
    ld([data_stack_pointer], X)
    C("Load low-byte")
    ld([X])
    anda(0b1000_0000, X)  # 5
    C("Calculate bit to shift in to the high-byte")
    ld([X])
    st([tmp0])
    ld([data_stack_pointer], X)
    C("Reload and left-shift")
    ld([X])
    adda(AC)  # 10
    st([Y, Xpp])
    ld([Y, X])
    C("Load high byte and left-shift")
    adda(AC)
    adda([tmp0])
    st([Y, X])  # 15
    NEXT(cost_of_two_times)


cost_of_two_times = 15
