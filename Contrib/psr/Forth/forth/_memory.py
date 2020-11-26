"""Words for manipulating memory"""
from asm import AC, C, X, Xpp, Y, adda, label, ld, st

from ._utilities import NEXT, add_cost_of_next
from .variables import (
    data_stack_page,
    data_stack_pointer,
    tmp0,
    tmp1,
    tmp2,
    tmp3,
)


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
    """Write a character at an address ( char c-addr -- )"""
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


def at():
    label("forth.core.@")
    adda(-add_cost_of_next(cost_of_at) / 2)  # 1
    ld(data_stack_page, Y)
    ld([data_stack_pointer], X)
    ld([Y, X])
    st([tmp0])  # 5
    st([Y, Xpp])
    ld([Y, X])
    ld(AC, Y)
    ld([tmp0], X)
    ld([Y, X])  # 10
    st([tmp0])
    st([Y, Xpp])
    ld([Y, X])
    st([tmp1])
    ld(data_stack_page, Y)  # 15
    ld([data_stack_pointer], X)
    ld([tmp0])
    st([Y, Xpp])
    ld([tmp1])
    st([Y, X])  # 20
    NEXT(cost_of_at)


cost_of_at = 20


def set():
    """Write a call value at an aligned address ( x a-addr -- )"""
    label("forth.core.!")
    adda(-add_cost_of_next(cost_of_set) / 2)  # 1
    ld(data_stack_page, Y)
    C("Remove 4 bytes from stack (SP moves by 4)")
    ld([data_stack_pointer])
    ld(AC, X)
    adda(4)  # 5
    st([data_stack_pointer])  # 6
    address_low, address_high, data_low, data_high = tmp0, tmp1, tmp2, tmp3
    C("Copy stack data and low part of address to temporary")
    for dest in [address_low, address_high, data_low]:
        ld([Y, X])  # 1
        st([dest])
        st([Y, Xpp])  # 3
    ld([Y, X])  # 1
    st([data_high])
    C("Load address")
    ld([address_low], X)
    ld([address_high], Y)
    C("Write data")
    ld([data_low])  # 5
    st([Y, Xpp])
    ld([data_high])
    st([Y, X])  # 8
    NEXT(cost_of_set)


cost_of_set = 6 + 3 * 3 + 8
