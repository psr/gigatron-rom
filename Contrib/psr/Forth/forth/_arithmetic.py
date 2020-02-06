"""Words for performing arithmetic"""

from asm import X, Xpp, Y, adda, beq, bne, label, ld, lo, st, suba

from ._utilities import NEXT, add_cost_of_next
from .variables import data_stack_page, data_stack_pointer


def increment():
    "Add one to the top of the stack (n -- n)"
    label("forth.core.1+")
    adda(-add_cost_of_next(cost_of_increment) / 2)  # 1
    ld(data_stack_page, Y)
    ld([data_stack_pointer], X)
    ld([Y, X])
    adda(1)  # 5
    bne(lo(".done"))  # 6
    st([Y, Xpp])  # 7

    ld([Y, X])  # 8
    adda(1)
    st([Y, X])
    NEXT(cost_of_increment__two_words_written)

    label(".done")
    NEXT(cost_of_increment__one_word_written)


cost_of_increment__one_word_written = 7
cost_of_increment__two_words_written = 10
cost_of_increment = max(
    cost_of_increment__one_word_written, cost_of_increment__two_words_written
)


def decrement():
    "Subtract one from the top of the stack (n -- n)"
    label("forth.core.1-")
    adda(-add_cost_of_next(cost_of_decrement) / 2)  # 1
    ld(data_stack_page, Y)
    ld([data_stack_pointer], X)
    ld([Y, X])
    beq(lo(".low-byte-was-zero"))  # 5
    suba(1)  # 6
    st([Y, X])  # 7
    NEXT(cost_of_decrement__one_word_written)

    label(".low-byte-was-zero")
    st([Y, Xpp])  # 7
    ld([Y, X])
    suba(1)
    st([Y, X])  # 10
    NEXT(cost_of_decrement__two_words_written)


cost_of_decrement__one_word_written = 7
cost_of_decrement__two_words_written = 10
cost_of_decrement = max(
    cost_of_decrement__one_word_written, cost_of_decrement__two_words_written
)
