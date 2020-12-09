"""Implementation of various shift words"""


from asm import (
    AC,
    C,
    X,
    Xpp,
    Y,
    adda,
    anda,
    beq,
    bgt,
    bne,
    bra,
    fillers,
    hi,
    jmp,
    label,
    ld,
    lo,
    nop,
    ora,
    pc,
    st,
    suba,
    xora,
)

from ._utilities import NEXT, REENTER, add_cost_of_next
from .variables import (
    W_lo,
    data_stack_page,
    data_stack_pointer,
    tmp0,
    tmp1,
    tmp2,
    tmp3,
    tmp4,
    tmp5,
    tmp6,
)


def two_times():
    """Implements a left-shift by one which is used for two words

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


###
# LSHIFT, RSHIFT (and /2)
###


# These ended up being very complicated, and they've been broken
# int several chunks.

# The following functions and variables are used by LSHIFT, RSHIFT and /2
# The functions get placed by shifts() below.

# tmp0 is used for temporary storage
amount, transfer_amount = tmp1, tmp2  # TODO: Might be better negated!
low_byte_temp = high_byte_temp = tmp3
continuation = tmp4  # Where to return from helper routines
mask, set_bits = tmp5, tmp6  # set by right_shift_by_n


def _shift_entry(
    *, offset_to_amount_eq_8, offset_to_amount_gt_8, offset_to_amount_lt_8
):
    # Structurally left and right shift are very similar,
    # and we can share a lot of code.
    # There are five major cases for each (n is the shift amount):
    # n == 0     : We don't do anything but adjust stack height.
    # 0 < n < 8  : The most complicated case - we need to shift both
    #              bytes and also transfer bits from one to the other
    # n == 8     : Quite simple, one byte takes its value from the other
    #              which becomes zero
    # 8 < n < 16 : Shift one byte, and store into the other.
    #              Store zero in first byte.
    # 16 <= n    : Result is zero (technically we could ignore this).
    #
    # These have very different costs!
    # The entry point for both LSHIFT and RSHIFT call a single routine.
    # It loads the shift amount, and works out which of the cases we're
    # in. n == 0, and n > 16 are both handled immediately, followed by
    # NEXT.
    # For the other three cases, we dispatch to different routines by
    # adjusting W and calling REENTER.
    # The code is structured so that the we need to apply to W is the
    # same whether we're doing a left or right shift.

    label("forth.core.shift.entry")
    ld([data_stack_pointer], X)  # 1
    ld([data_stack_pointer])
    adda(2)
    st([data_stack_pointer])
    # Load amount:
    ld([Y, X])  # 5 Load low-byte of amount
    st([Y, Xpp])
    st([amount])
    ora([Y, X])
    beq("forth.core.shift.entry.amount-zero")  # 9
    # Numbers greater than 16 must have bit 4 or higher set.
    # AND with 0xf0 will reveal high bits set.
    ld(0xF0)  # 10 Test for 16s place or higher being set in low byte
    anda([amount])
    ora([Y, X])  # Or any bit in high byte
    bne("forth.core.shift.entry.amount-gte16")  # 13
    # We want different values depending on which path we're going to follow
    # the n < 8 case wants -(n) and -(8 - n) = n - 8.
    # The n > 8 case wants -(n - 8) = 8 - n
    # The n = 8 case needs nothing.
    # Because the < 8 case has two variables, give it the "default" path
    # TODO: I feel very deeply that there must be a nicer way of doing this
    # TODO: Probably something todo with XOR.
    ld([amount])
    suba(8)
    bgt("forth.core.shift.entry.amount-gt8")  # 16
    beq("forth.core.shift.entry.amount-eq8")  # 17
    st([transfer_amount])  # 18  # For the n < 8 case
    ld(0)  # 19
    suba([amount])  # 20
    st([amount])  # 21
    ld(offset_to_amount_lt_8)  # 22
    label(".adjust_W")
    adda([W_lo])  # 23
    st([W_lo])  # 24
    REENTER(24 + 3)

    label("forth.core.shift.entry.amount-eq8")
    nop()  # 19
    nop()  # 20
    bra(lo(".adjust_W"))  # 21
    ld(offset_to_amount_eq_8)  # 22

    label("forth.core.shift.entry.amount-gt8")
    ld(8)  # 18
    suba([amount])  # 19
    st([amount])  # 20
    bra(".adjust_W")  # 21
    ld(offset_to_amount_gt_8)  # 22

    label("forth.core.shift.entry.amount-zero")
    NEXT(10 + 3)
    label("forth.core.shift.entry.amount-gte16")
    st([Y, Xpp])  # 15
    ld(0)
    st([Y, Xpp])
    st([Y, Xpp])
    NEXT(18 + 3)


cost_of_shift_entry = 3 + 24


def _left_shift_by_n():
    """Fixed cost routine to do a left-shift by 1-7 places

    Shift amount is passed in NEGATED in ac, value is loaded from [Y, X]
    Control is returned to address in continuation
    """
    label("left-shift-by-n")
    # Because we do n shift operations, with 0 < n < 8
    # we need to balance it with 7 - n nops - so that we always do
    # 7 ops in total
    adda(lo(".end-of-left-shifts"))  # 1
    st([tmp0])  # Where we jump in the left-shifts
    suba(lo(".end-of-left-shifts") - 7)
    xora(0xFF)  # ac = -(shift-amount) + 7; Negate it.
    adda(lo(".end-of-nops") + 1)  # 5;  +1 is to finish two's complement
    bra(AC)  # 6
    ld([tmp0])  # 7 ; Shift by 1
    nop()  # Shift by 2
    nop()  # Shift by 3
    nop()  # Shift by 4
    nop()  # Shift by 5
    nop()  # Shift by 6
    label(".end-of-nops")
    bra(AC)  # 8;
    ld([Y, X])  # 9
    adda(AC)  # Shift by 7
    adda(AC)  # Shift by 6
    adda(AC)  # Shift by 5
    adda(AC)  # Shift by 4
    adda(AC)  # Shift by 3
    adda(AC)  # Shift by 2
    bra([continuation])  # 10 # Shift by 1
    label(".end-of-left-shifts")
    adda(AC)  # (counted as one of the 7)


cost_of_left_shift_by_n = 17


def _right_shift_by_n(vtmp):
    """
    Fixed cost routine to do a right-shift by 1-7 places

    Shift amount is passed in NEGATED in ac, value is loaded from [y, x].
    Control is returned to address in continuation.
    In the case of a right-shift by between 1 and 7 places, this needs to
    be called twice. in which case we can jump to right-shift-by-n.second-time
    with mask in ac.
    """
    label("right-shift-by-n")
    st([tmp0])  # 1
    adda(".end-of-set_bits_table")
    bra(AC)  # 3
    bra(lo(".end-of-set_bits_table"))  # 4
    ld(0b0011_1111)  # Shift by 7
    ld(0b0001_1111)  # Shift by 6
    ld(0b0000_1111)  # Shift by 5
    ld(0b0000_0111)  # Shift by 4
    ld(0b0000_0011)  # Shift by 3
    ld(0b0000_0001)  # Shift by 2
    ld(0b0000_0000)  # Shift by 1
    label(".end-of-set_bits_table")
    st([set_bits])  # 6
    # Take the opportunity to set vTmp
    ld(lo("forth.right-shift-return-point"))
    st([vtmp])
    ld([tmp0])
    adda(".end-of-mask-table")
    bra(AC)  # 11
    bra(lo(".end-of-mask-table"))  # 12
    ld(0b1000_0000)  # Shift by 7
    ld(0b1100_0000)  # Shift by 6
    ld(0b1110_0000)  # Shift by 5
    ld(0b1111_0000)  # Shift by 4
    ld(0b1111_1000)  # Shift by 3
    ld(0b1111_1100)  # Shift by 2
    ld(0b1111_1110)  # Shift by 1
    label(".end-of-mask-table")
    st([mask])  # 14
    label("right-shift-by-n.second-time")
    anda([Y, X])  # 15, 1
    ora([set_bits])
    ld(hi("shiftTable"), Y)
    jmp(Y, AC)  # 18, 4
    bra(0xFF)  # 19, 5
    # In lookup table we have
    # ld # 20, 6
    # bra [vTmp] # 21, 7
    # nop # 22, 8
    # ld $thisPage, Y # 23, 9
    # jmp Y, [sysArgs + 4] # 24, 10
    # ld $0, y  # 25, 11


cost_of_right_shift_by_n = 25
cost_of_right_shift_by_n__second_time = 11


def _lshift():
    """LSHIFT (x1 u -- x2)"""
    label("forth.core.LSHIFT")
    adda(-add_cost_of_next(cost_of_shift_entry) / 2)  # 1
    bra("forth.core.shift.entry")
    ld(data_stack_page, Y)  # 3


def _lshift__amount_eq_8():
    """LSHIFT (x1 u -- x2)

    Special case where u = 8
    """
    label("forth.core.LSHIFT.n==8")
    adda(-add_cost_of_next(cost_of_lshift__amount_eq_8) / 2)  # 1
    ld(data_stack_page, Y)
    ld([data_stack_pointer], X)
    ld([Y, X])
    st([tmp0])  # 5
    ld(0)
    st([Y, Xpp])
    ld([tmp0])
    st([Y, X])  # 9
    NEXT(cost_of_lshift__amount_eq_8)


cost_of_lshift__amount_eq_8 = 9


def _lshift__amount_gt_8():
    """LSHIFT (x1 u -- x2)

    Special case where u > 8
    """
    label("forth.core.LSHIFT.n>8")
    adda(-add_cost_of_next(cost_of_lshift__amount_gt_8) / 2)  # 1
    ld(data_stack_page, Y)
    ld([data_stack_pointer], X)
    ld(lo("forth.core.LSHIFT.n>8.continuation"))
    st([continuation])  # 5
    bra("left-shift-by-n")  # 6
    ld([amount])  # 7
    label("forth.core.LSHIFT.n>8.continuation")
    st([Y, Xpp])  # 1
    st([Y, Xpp])  # 2
    ld([data_stack_pointer], X)  # 3
    ld(0)  # 4
    st([Y, Xpp])  # 5
    NEXT(cost_of_lshift__amount_gt_8)


cost_of_lshift__amount_gt_8 = 7 + 5 + cost_of_left_shift_by_n


def _lshift__amount_lt_8():
    """LSHIFT (x1 u -- x2)

    Special case where u < 8
    """
    label("forth.core.LSHIFT.n<8")
    adda(-add_cost_of_next(cost_of_lshift__amount_lt_8) / 2)  # 1
    ld(data_stack_page, Y)
    ld([data_stack_pointer], X)
    ld(lo("forth.core.LSHIFT.n<8.continuation1"))
    st([continuation])  # 5
    bra("right-shift-by-n")
    ld([transfer_amount])
    label("forth.core.LSHIFT.n<8.continuation1")
    st([high_byte_temp])
    ld(lo("forth.core.LSHIFT.n<8.continuation2"))
    st([continuation])  # 10
    bra("left-shift-by-n")
    ld([amount])
    label("forth.core.LSHIFT.n<8.continuation2")
    st([Y, Xpp])
    ld(lo("forth.core.LSHIFT.n<8.continuation3"))
    st([continuation])  # 15
    bra("left-shift-by-n")
    ld([amount])
    label("forth.core.LSHIFT.n<8.continuation3")
    ora([high_byte_temp])
    st([Y, X])  # 19
    NEXT(cost_of_lshift__amount_lt_8)


cost_of_lshift__amount_lt_8 = (
    19 + 2 * cost_of_left_shift_by_n + cost_of_right_shift_by_n
)


def _rshift():
    """RSHIFT (x1 u -- x2)"""
    label("forth.core.RSHIFT")
    adda(-add_cost_of_next(cost_of_shift_entry) / 2)  # 1
    bra("forth.core.shift.entry")
    ld(data_stack_page, Y)  # 3


def _rshift__amount_eq_8():
    # Offset to n==8 case = 3
    label("forth.core.RSHIFT.n==8")
    adda(-add_cost_of_next(cost_of_rshift__amount_eq_8) / 2)  # 1
    ld(data_stack_page, Y)
    ld([data_stack_pointer], X)
    st([Y, Xpp])  # Blat low byte
    ld([Y, X])  # 5
    ld([data_stack_pointer], X)
    st([Y, Xpp])
    ld(0)
    st([Y, X])  # 9
    NEXT(cost_of_rshift__amount_eq_8)


cost_of_rshift__amount_eq_8 = 9


def _rshift__amount_gt_8():
    # offset to n > 8 case
    label("forth.core.RSHIFT.n>8")
    adda(-add_cost_of_next(cost_of_rshift__amount_gt_8) / 2)  # 1
    ld(data_stack_page, Y)
    ld([data_stack_pointer], X)
    ld(lo("forth.core.RSHIFT.n>8.continuation"))
    st([continuation])  # 5
    bra("right-shift-by-n")
    ld([amount])
    label("forth.core.RSHIFT.n>8.continuation")
    st([Y, Xpp])
    st([Y, Xpp])
    ld([data_stack_pointer], X)  # 10
    ld(0)
    st([Y, X])  # 12
    NEXT(cost_of_rshift__amount_gt_8)


cost_of_rshift__amount_gt_8 = 12 + cost_of_right_shift_by_n


def _rshift__amount_lt_8():
    label("forth.core.RSHIFT.n<8")
    adda(-add_cost_of_next(cost_of_rshift__amount_lt_8) / 2)  # 1
    ld(data_stack_page, Y)
    ld([data_stack_pointer], X)
    ld(lo("forth.core.RSHIFT.n<8.continuation1"))
    st([continuation])  # 5
    bra("right-shift-by-n")
    ld([amount])
    label("forth.core.RSHIFT.n<8.continuation1")
    st([Y, Xpp])
    ld(lo("forth.core.RSHIFT.n<8.continuation2"))
    st([continuation])  # 10
    bra("left-shift-by-n")
    ld([transfer_amount])
    label("forth.core.RSHIFT.n<8.continuation2")
    ld([data_stack_pointer], X)
    ora([Y, X])
    st([Y, Xpp])  # 15
    ld(lo("forth.core.RSHIFT.n<8.continuation3"))
    st([continuation])
    bra("right-shift-by-n.second-time")
    ld([mask])
    label("forth.core.RSHIFT.n<8.continuation3")
    st([Y, X])  # 20
    NEXT(cost_of_rshift__amount_lt_8)


cost_of_rshift__amount_lt_8 = (
    20
    + cost_of_left_shift_by_n
    + cost_of_right_shift_by_n
    + cost_of_right_shift_by_n__second_time
)


def shift(vtmp):
    """Place all of the code required for LSHIFT and RSHIFT"""
    # The layout of the various types of LSHIFT and RSHIFT needs
    # to be equivalent in both cases. The RSHIFT code is shorter
    # so it's easier to enforce this if LSHIFT is first.
    offset_start = pc()
    _lshift()
    offset_of_shift_by_8 = pc() - offset_start
    _lshift__amount_eq_8()
    offset_of_shift_by_gt_8 = pc() - offset_start
    _lshift__amount_gt_8()
    offset_of_shift_by_lt_8 = pc() - offset_start
    _lshift__amount_lt_8()

    rshift_offset_start = pc()
    _rshift()
    assert pc() - rshift_offset_start <= offset_of_shift_by_8
    fillers(until=(rshift_offset_start + offset_of_shift_by_8) & 255)
    _rshift__amount_eq_8()
    assert pc() - rshift_offset_start <= offset_of_shift_by_gt_8
    fillers(until=(rshift_offset_start + offset_of_shift_by_gt_8) & 255)
    _rshift__amount_gt_8()
    assert pc() - rshift_offset_start <= offset_of_shift_by_lt_8
    fillers(until=(rshift_offset_start + offset_of_shift_by_lt_8) & 255)
    _rshift__amount_lt_8()
    _shift_entry(
        offset_to_amount_eq_8=offset_of_shift_by_8,
        offset_to_amount_gt_8=offset_of_shift_by_gt_8,
        offset_to_amount_lt_8=offset_of_shift_by_lt_8,
    )
    _left_shift_by_n()
    _right_shift_by_n(vtmp)
