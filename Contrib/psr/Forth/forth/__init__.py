# -*- coding: utf-8 -*-
from __future__ import (
    absolute_import,
    division,
    print_function,
    unicode_literals,
)

from asm import *
from .variables import (
    maxTicks,
    mode,
    W_hi,
    W_lo,
)

INTERPRETER_ENTER_PAGE = 0x12
INBOUND_TICK_CORRECTION = maxTicks * 2


def next1(vTicks):
    """Routine to make continue or abort decisions, and dispatch to the next word
    """
    # Invariant - on entry the vTicks variable and the accumulator both hold
    # an accurate number of cycles until we must be back in the display loop,
    # starting from the first instruction of this routine.
    # This value will always be greater than the cost of failing continue/abort test. This is true
    # whenever we return here from another word, and true when we first enter from the
    # display loop.
    label("forth.next1")
    C(
        "Timing point: [vTicks] == AC == accurate number of ticks until we need to be back"
    )
    suba((cost_of_successful_test + cost_of_failfast) / 2)  # 1
    ld([W_hi], Y)  # 2
    jmp(Y, [W_lo])  # 3
    bra("forth.restart-or-quit")  # 4


# 5 happens in start of thread


def restart_or_quit():
    assert pc() & 0xFF == 0, "restart_or_quit must be placed at the start of a page"
    label("forth.restart_or_quit")
    bra([W_lo])  # 6
    ble(pc() + 1)  # 7
    # 8 happens in start of thread again
    label(".quit")
    ld(hi("forth.exit"), Y)  # 9
    C("jmp forth.exit.from-failed-test")
    jmp(Y, lo("forth.exit.from-failed-test"))  # 10
    # 11, overlap with whatever comes next - hopefully not a branch or jump!


cost_of_successful_test = 7
cost_of_failed_next1 = 11


def next2(vTicks):
    label("forth.next2.odd")
    nop()
    label("forth.next2.even")
    # On entry AC holds the negative of the number of ticks taken by the just executed instruction
    # To have entered the instruction we must have also had a successful test,
    suba((cost_of_successful_test + cost_of_next2_success) / 2)  # 1
    adda([vTicks])  # 2
    st([vTicks])  # 3; If we exit successfully we'll be ready for next1
    ld([mode])  # 4
    st([W_hi])  # 5
    ld(0x82)  # 6  # TODO
    st([W_lo])  # 7
    ld([vTicks])  # 8
    suba((cost_of_failed_test) / 2)  # 9
    blt(lo("forth.exit.from-next2"))  # 10
    tick_correction = cost_of_next2_success - cost_of_next2_failure
    ld(tick_correction / 2)  # 11; Restore
    bra(lo("forth.next1"))  # 12
    ld([vTicks])  # 13


cost_of_next2_failure = 11
cost_of_next2_success = 13


def next1_reenter(vTicks):
    label(
        "forth.next1.reenter.even"
    )  # When a word took an even number of cycles, enter here
    nop()  # 1
    label(
        "forth.next1.reenter.odd"
    )  # Inbound code should round down ticks, because counting is from .even
    suba((cost_of_successful_test + cost_of_next1_reenter_success) / 2)  # 2
    adda([vTicks])  # 3
    st([vTicks])  # 4; If we exit successfully we'll be ready for next1
    suba(cost_of_failed_test)  # 5
    ble("forth.exit.from-next1-reenter")  # 6
    vticks_error = cost_of_next1_reenter_success - cost_of_next1_reenter_failure
    ld(-(vticks_error / 2))  # 7  ; load vTicks wrongness into A
    bra("forth.next1")  # 8
    ld([vTicks])  # 9


cost_of_next1_reenter_success = 9
cost_of_next1_reenter_failure = 7


def exit(vTicks, vReturn):
    label("forth.exit")  # Counting down
    label("forth.exit.from-failed-test")
    ld(-(cost_of_failed_next1 + 1) / 2)  # 7
    label("forth.exit.from-next1-reenter")
    label("forth.exit.from-next2")
    adda([vTicks])  # 6
    ld(hi("vBlankStart"), Y)  # 5
    bgt(pc() & 0xFF)  # 4
    suba(1)  # 3
    jmp(Y, [vReturn])  # 2
    nop()  # 1


cost_of_exit_from_failed_test = 7
cost_of_exit_from_next1_reenter = 6
cost_of_exit_from_next2 = 6


cost_of_failfast_next2 = cost_of_next2_failure + cost_of_exit_from_next2
cost_of_failfast_next1_reenter = (
    cost_of_next1_reenter_failure + cost_of_exit_from_next1_reenter
)
cost_of_failfast = max(cost_of_failfast_next2, cost_of_failfast_next1_reenter)

cost_of_failed_test = cost_of_failed_next1 + cost_of_exit_from_failed_test
