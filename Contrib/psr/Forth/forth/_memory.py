"""Words for manipulating memory"""
from asm import AC, C, X, Xpp, Y, adda, label, ld, st

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


def char_set():
    """Write a character at an address ( char c-addr -- )
    """
    label("forth.core.C!")
    adda(-add_cost_of_next(cost_of_char_set) / 2)  # 1
    ld(data_stack_page, Y)
    C("Pop 2 byte address to temp (SP moves by 4)")
    ld([data_stack_pointer])
    ld(AC, X)
    adda(4)  # 5
    st([data_stack_pointer])  # 6
    for dest in [tmp0, tmp1]:
        ld([Y, X])
        st([dest])
        st([Y, Xpp])
    ld([Y, X])
    C("Load low-byte of char - top byte ignored")
    ld([tmp0], X)
    ld([tmp1], Y)
    st([Y, X])
    C("Write")
    NEXT(cost_of_char_set)


cost_of_char_set = 6 + 2 * 3 + 4
