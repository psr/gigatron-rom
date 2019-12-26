"""Words for manipulating memory"""
from asm import *

from ._utilities import NEXT, add_cost_of_next
from .variables import data_stack_page, data_stack_pointer, tmp0, tmp1


def char_at():
    label("forth.core.C@")
    adda(-add_cost_of_next(cost_of_char_at) / 2)  # 1
    ld(data_stack_page, Y)
    ld([data_stack_pointer], X)
    ld([Y, X])
    st([tmp0])  # 5
    st([Y, Xpp])
    ld([Y, X])
    ld(AC, Y)
    ld([tmp0], X)
    ld([Y, X])  # 10
    ld(data_stack_page, Y)
    ld([data_stack_pointer], X)
    st([Y, Xpp])
    ld(0)
    st([Y, X])  # 15
    NEXT(cost_of_char_at)


cost_of_char_at = 15
