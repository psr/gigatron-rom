"""Words for performing arithmetic"""

from asm import (
    C,
    X,
    Xpp,
    Y,
    adda,
    anda,
    beq,
    bmi,
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
    """Common implementation for all of the bitwise operators"""
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
    for label_, op in [(".and", anda), (".or", ora), (".xor", xora)]:
        label(label_)
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


def add():
    # This is exactly the same algorithm as in the vCPU implementation, but with my own comments to explain it to myself.
    label("forth.core.+")
    label("forth.core.CHAR+")
    adda(-add_cost_of_next(cost_of_add) / 2)  # 1
    low, high = tmp0, tmp1
    ld(data_stack_page, Y)
    C("Load and move data stack pointer")
    ld([data_stack_pointer], X)
    ld([data_stack_pointer])
    adda(2)  # 5
    st([data_stack_pointer])  # 6

    # Copy TOS to low, high
    c = "Copy TOS to zero-page"
    for address in [low, high]:
        ld([Y, X])
        c = C(c)
        st([address])
        st([Y, Xpp])  # 12 = 6 + 2 * 3

    # Add low bytes
    ld([Y, X])
    C("Add low bytes")
    adda([low])
    st([Y, Xpp])  # 15
    bmi(".add.result-has-1-in-bit-7")
    suba([low])  # 17 Restore to low-byte of TOS

    # We previously had a result with a 0 in bit seven 0xxxxxxx
    # We can now use the operands to work out if there was
    # a carry out of bit seven.

    # The truth table is as follows

    #    | A[7] | B[7] | Carry-in || Result[7] | Carry-out
    # ---|------------------------------------------------
    #  0 |   0  |   0  |     0    ||     0     |     0
    #  1 |   0  |   0  |     1    ||     1     |     0
    #  2 |   0  |   1  |     0    ||     1     |     0
    #  3 |   0  |   1  |     1    ||     0     |     1
    #  4 |   1  |   0  |     0    ||     1     |     0
    #  5 |   1  |   0  |     1    ||     0     |     1
    #  6 |   1  |   1  |     0    ||     0     |     1
    #  7 |   1  |   1  |     1    ||     1     |     1

    # Given that there is zero in bit seven (cases 0, 3, 5 and 6)
    # There is not a carry (case 0) when both A[7] and B[7] are 0
    # There is if either or both are 1.
    # Bitwise OR of the two operands will place the carry in bit seven
    bra(".add.carry-bit-in-msb")  # 18
    ora([low])  # 19

    label(".add.result-has-1-in-bit-7")
    # Given that there is one in bit seven (cases 1, 2, 4 and 7)
    # There is not a carry (case 1, 2, 4) when either A[7] or B[7] are 0
    # There is only a carry (case 7) when both are one.
    # Bitwise AND of the two operands will place the carry in bit seven
    bra(".add.carry-bit-in-msb")  # 18
    anda([low])  # 19

    label(".add.carry-bit-in-msb")
    # vCPU moves uses anda $80, x to load 0x00 or 0x80 to X, and loads [X],
    # using constant values at 0x80 and 0x00, but we still need X for now,
    # So branching on the sign-bit works out just as cheap.
    bmi(".add.carry")
    ld([Y, X])  # 21
    bra(".add.finish")
    adda([high])  # 23
    label(".add.carry")
    adda(1)  # 22
    adda([high])  # 23
    label(".add.finish")
    st([Y, X])  # 24
    NEXT(cost_of_add)


cost_of_add = 24
