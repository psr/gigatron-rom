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
    W,
    W_hi,
    W_lo,
    IP,
    IP_lo,
    IP_hi,
)

INTERPRETER_ENTER_PAGE = 0x12
INBOUND_TICK_CORRECTION = maxTicks * 2


def next1_enter(vTicks):
    """Duplicates next1, to avoid an extra jump"""
    label("forth.enter")
    adda(INBOUND_TICK_CORRECTION - cost_of_return + (cost_of_successful_test / 2))
    st([vTicks])
    _next1_test()


def _next1_test():
    """Macro to make continue or abort decisions, and dispatch to the next word
    """
    suba(cost_of_next2_failure / 2)  # 1
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
cost_of_failed_test = 11 + 2


def next2(vTicks):
    """
    Dispatch to the appropriate Next3 as quickly as possible - if there is time.
    If not, store next3 as the next word to execute.

    This routine takes a half number of ticks when it succeeds, but skips the
    initial subtract instruction of Next3.

    On Entry: vTicks + AC == number of ticks until we need to be in return
    On Exit: vTicks == number of ticks until we need to be in return
    """
    label("forth.next2.odd")
    nop()  # 4
    label("forth.next2")  # We start counting here
    label("forth.next2.even")
    adda([vTicks])  # 1
    suba(
        (cost_of_next2_success + maximum_cost_of_next3 + cost_of_next1_reenter_failure)
        / 2
    )
    blt(lo("forth.next2.fail"))  # 3
    adda((maximum_cost_of_next3 - 1 + cost_of_next1_reenter_failure) / 2)  # 4
    ld([mode], Y)  # 5
    jmp(Y, [lo("forth.next3.fast-entry")])  # 6
    st([vTicks])  # 7
    # else
    label("forth.next2.fail")
    adda((cost_of_next2_failure - cost_of_next2_success) / 2)  # 5
    st([vTicks])  # 6
    ld([mode])  # 7
    st([W_hi])  # 8
    ld(lo("forth.next3"))  # 9
    st([W_lo])  # 10
    bra(lo("forth.exit.countdown-ticks"))  # 11
    ld([vTicks])  # 12


cost_of_next2_success = 7
cost_of_next2_failure = 12


def next1_reenter(vTicks):
    """
    Update vTicks and dispatch to the instruction in W - if there is time.
    If not, exit.

    There is time iff we can end this routine, and test the next instruction and fail.

    This routine takes whole number of ticks when it succeeds or fails.

    On Entry: vTicks + AC == number of ticks until we need to be in return
    On Exit: vTicks == number of ticks until we need to be in return.

    We consider exiting this routine as being the point where the word in W starts executing.
    """
    # Inbound code should round down ticks, because
    label("forth.next1.reenter.odd")
    nop()
    label("forth.next1.reenter")  # We start counting here
    label("forth.next1.reenter.even")
    adda([vTicks])  # 1
    suba(
        (
            cost_of_next1_reenter_success
            + cost_of_failed_test
            + cost_of_exit_from_failed_test
        )
        / 2
    )  # 2
    blt(lo("forth.exit.countdown-ticks"))  # 3
    adda(
        (
            cost_of_next1_reenter_success
            - cost_of_next1_reenter_failure
            + cost_of_failed_test
            + cost_of_exit_from_failed_test
        )
        / 2
    )  # 4
    suba(
        cost_of_next1_reenter_success
        - cost_of_next1_reenter_failure
        + cost_of_successful_test
    )  # 5
    st([vTicks])  # 6
    _next1_test()  # Only counted as cost_of_successful_test


cost_of_next1_reenter_failure = 4
cost_of_next1_reenter_success = 6


def exit(vTicks, vReturn):
    label("forth.exit")  # Counting down
    label("forth.exit.from-failed-test")
    ld((-cost_of_successful_test + cost_of_failed_test + 2) / 2)  # 7
    label("forth.exit.from-failfast")
    adda([vTicks])  # 6
    label("forth.exit.countdown-ticks")
    bgt(pc() & 0xFF)  # 5
    suba(1)  # 4
    ld(hi("vBlankStart"), Y)  # 3
    jmp(Y, [vReturn])  # 2
    nop()  # 1


cost_of_exit_from_failed_test = 7
cost_of_exit_from_failfast = 5
cost_of_exit_from_next2 = 6
cost_of_return = 5


def next3_rom_head():
    """Start the process of next3"""
    label("forth.next3")
    label("forth.next3.rom-mode")
    adda(-14 / 2)  # 1
    label("forth.next3.fast-entry")
    ld(W, X)  # 2
    ld([IP_hi], Y)  # 3
    jmp(Y, [W_lo])  # 4
    ld(0x00, Y)  # 5


# Three instructions in the word


def next3_rom_tail():
    """Page-Zero code to finish next3"""
    assert pc() >> 8 == 0
    label("forth.next3.rom-mode-tail")
    ld([IP_lo])  # 9
    adda(3)  # 10
    st([IP_lo])  # 11
    ld(hi("forth.next1.reenter"), Y)  # 12
    jmp(Y, lo("forth.next1.reenter.even"))  # 13
    ld(-(cost_of_next3_rom / 2))  # 14


cost_of_next3_rom = 14

maximum_cost_of_next3 = max((cost_of_next3_rom,))
