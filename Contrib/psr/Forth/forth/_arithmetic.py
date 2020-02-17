"""Words for performing arithmetic"""

from asm import (
    C,
    X,
    Xpp,
    Y,
    adda,
    anda,
    beq,
    bne,
    bra,
    label,
    ld,
    lo,
    ora,
    pc,
    st,
    suba,
    wait,
    xora,
)

from ._utilities import NEXT, add_cost_of_next
from .variables import (
    data_stack_page,
    data_stack_pointer,
    tmp0,
    tmp1,
    tmp2,
    tmp3,
)


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


def zero_equal():
    """Logical not ( x -- flag )

    flag is true if and only if x is equal to zero.
    """
    label("forth.core.0=")
    adda(-add_cost_of_next(cost_of_zero_equal) / 2)  # 1
    ld([data_stack_pointer], X)
    ld([X])
    bne(".not-zero1")
    ld(data_stack_page, Y)  # 5

    st([Y, Xpp])  # 6
    C("Low byte is zero - advance to high-byte")
    ld([Y, X])
    bne(".not-zero2")
    ld([data_stack_pointer], X)  # 9

    bra(".write")  # 10
    C("Both bytes are 0 - replace with true flag")
    ld(0xFF)  # 11

    label(".not-zero1")
    wait(9 - 5)  # 6, 7, 8, 9
    label(".not-zero2")
    bra(".write")  # 10
    ld(0x00)  # 11
    C("One or both bytes are not zero - replace with false flag")

    label(".write")
    st([Y, Xpp])  # 12
    C("Overwrite both bytes")
    st([Y, Xpp])  # 13
    NEXT(cost_of_zero_equal)


cost_of_zero_equal = 13


def bitwise():
    """Common implementation for all of the bitwise operators
    """
    for name, target in [("AND", ".and"), ("OR", ".or"), ("XOR", ".xor")]:
        label(f"forth.core.{name}")
        adda(-add_cost_of_next(cost_of_binary_bitwise) / 2)  # 1
        bra(".copy-first-value")  # 2
        ld(lo(target))  # 3

    label(".copy-first-value")
    st([tmp0])  # 4
    adda(1)  # 5
    st([tmp1])
    ld(data_stack_page, Y)
    ld([data_stack_pointer], X)
    ld(2)
    adda([data_stack_pointer])  # 10
    st([data_stack_pointer])  # 11
    for tmp in [tmp2, tmp3]:
        ld([Y, X])
        st([tmp])
        st([Y, Xpp])  # 17 = 11 + 2 * 3
    ld([Y, X])
    bra([tmp0])
    bra(pc() + 1)  # 20
    # 21
    st([Y, Xpp])  # 22
    ld([Y, X])
    bra([tmp1])  # 24
    bra(".bitwise-done")  # 25
    # 26
    for l, op in [(".and", anda), (".or", ora), (".xor", xora)]:
        label(l)
        op([tmp2])
        op([tmp3])
    label(".bitwise-done")
    st([Y, X])  # 27
    NEXT(cost_of_binary_bitwise)


cost_of_binary_bitwise = 27


def invert():
    label("forth.core.INVERT")
    adda(-add_cost_of_next(cost_of_invert) / 2)  # 1
    ld(data_stack_page, Y)
    ld([data_stack_pointer], X)
    ld([Y, X])
    xora(0xFF)  # 5
    st([Y, Xpp])
    ld([Y, X])
    xora(0xFF)
    st([Y, X])  # 9
    NEXT(cost_of_invert)


cost_of_invert = 9
