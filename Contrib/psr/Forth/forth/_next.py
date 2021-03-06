from asm import (
    AC,
    C,
    X,
    Xpp,
    Y,
    adda,
    beq,
    bgt,
    ble,
    blt,
    bne,
    bra,
    hi,
    jmp,
    label,
    ld,
    lo,
    nop,
    pc,
    st,
    suba,
)

from ._utilities import REENTER, add_cost_of_reenter, cost_of_reenter
from .variables import (
    IP_hi,
    IP_lo,
    W,
    W_hi,
    W_lo,
    maxTicks,
    mode,
    tmp0,
    tmp1,
)

INTERPRETER_ENTER_PAGE = 0x12
INBOUND_TICK_CORRECTION = maxTicks * 2


def next1(vTicks):
    """Routine to make continue or abort decisions, and dispatch to the next word"""
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
    label("forth.restart-or-quit")
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
    label("forth.next2")
    label("forth.next2.odd")
    nop()
    label("forth.next2.even")
    # On entry AC holds the negative of the number of ticks taken by the just executed instruction
    # To have entered the instruction we must have also had a successful test,
    suba((cost_of_successful_test + cost_of_next2_success) / 2)  # 1
    adda([vTicks])  # 2
    st([vTicks])  # 3; If we exit successfully we'll be ready for next1
    ld([mode])  # 4
    st([W_lo])  # 5
    ld(hi("forth.next3"))  # 6  # TODO
    st([W_hi])  # 7
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
    label("forth.next1.reenter")
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
    suba(cost_of_failed_test / 2)  # 5
    blt(lo("forth.exit.from-next1-reenter"))  # 6
    vticks_error = cost_of_next1_reenter_success - cost_of_next1_reenter_failure
    ld((vticks_error / 2))  # 7  ; load vTicks wrongness into A
    bra(lo("forth.next1"))  # 8
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


def next3_rom_head():
    """Start the process of next3"""
    label("forth.next3")
    label("forth.next3.rom-mode")
    adda(-(cost_of_next3_rom // 2))  # 1
    ld(-(cost_of_next3_rom // 2))  # 2
    st([tmp0])  # 3
    ld(W, X)  # 4
    ld(3)  # We're going to shift the IP by 3
    ld([IP_hi], Y)  # 6
    nop()  # 7
    jmp(Y, [IP_lo])  # 8
    ld(0x00, Y)  # 9


cost_of_move_ip = 5
cost_of_next3_rom = 9 + 3 + cost_of_move_ip


# Three instructions in the word


def move_ip():
    """Page-Zero code to move the IP by the amount contained in AC

    This routine is used by the ROM mode next3, and also by literal, branch and zero_branch.
    As these routines all have different lengths, it uses a variable (tmp0) to tell it what length to return

    It always jumps to forth.next1.reenter.odd, and it has an odd length itself code calling it must have an even length
    """
    assert pc() >> 8 == 0
    label("forth.move-ip")
    adda([IP_lo])  # 1
    st([IP_lo])  # 2
    ld(hi("forth.next1.reenter"), Y)  # 3
    C("REENTER")
    jmp(Y, lo("forth.next1.reenter.odd"))  # 4
    ld([tmp0])  # 5


assert cost_of_move_ip == 5


def next3_ram_rom():
    """NEXT3 to use when in RAM->ROM mode"""
    label("forth.next3.ram-rom-mode")
    adda(-(cost_of_next3_ram_rom / 2))  # 1
    ld([IP_hi], Y)  # 2
    C("W <- [IP]")
    ld([IP_lo], X)  # 3
    ld([Y, X])  # 4
    st([W_lo])  # 5
    ld([IP_lo])  # 6
    adda(1)  # 7
    ld(AC, X)  # 8
    ld([Y, X])  # 9
    # Increment IP
    st([W_hi])  # 10
    C("IP <- IP + 2")
    ld([IP_lo])  # 11
    adda(2)  # 12
    beq(pc() + 5)  # 13
    st([IP_lo])  # 14
    REENTER(14)
    label(".page-boundary")
    ld([IP_hi])  # 15
    adda(1)  # 16
    st([IP_hi])  # 17
    REENTER(17)


cost_of_next3_ram_rom__no_page_cross = 14 + cost_of_reenter
cost_of_next3_ram_rom__page_crossed = 17 + cost_of_reenter
cost_of_next3_ram_rom = max(
    cost_of_next3_ram_rom__no_page_cross, cost_of_next3_ram_rom__page_crossed
)


def next3_ram_ram():
    label("forth.next3.ram-ram-mode")
    adda(-add_cost_of_reenter(cost_of_next3_ram_ram) // 2)  # 1

    # Copy low byte to zero-page
    ld([IP_hi], Y)
    C("[tmp] <- [IP]")
    ld([IP_lo], X)
    ld([Y, X])
    st([Y, Xpp])  # 5; Advance X
    st([tmp0])
    # High byte to zero-page
    ld([Y, X])
    st([tmp1])

    # Update W
    ld(AC, Y)
    C("[W] <- [tmp]")
    ld([tmp0], X)  # 10
    ld([Y, X])
    st([W_lo])
    st([Y, Xpp])  # Advance X
    ld([Y, X])
    st([W_hi])  # 15

    # Increment IP
    ld([IP_lo])
    C("IP <- IP + 2")
    adda(2)
    bne(pc() + 8)  # 18
    st([IP_lo])  # 19

    ld([IP_hi])  # 20
    adda(1)
    st([IP_hi])

    REENTER(cost_of_next3_ram_ram__page_crossed)

    label(".not-page-boundary")
    REENTER(cost_of_next3_ram_ram__no_page_cross)


cost_of_next3_ram_ram__no_page_cross = 19
cost_of_next3_ram_ram__page_crossed = 22
cost_of_next3_ram_ram = max(
    cost_of_next3_ram_ram__no_page_cross, cost_of_next3_ram_ram__page_crossed
)


def _switch_to_rom_rom():
    ld(hi("forth.next3.rom-mode"))
    st([mode])


def _switch_to_ram_rom():
    ld(hi("forth.next3.ram-rom-mode"))
    st([mode])


def _switch_to_ram_ram():
    ld(hi("forth.next3.ram-rom-mode"))
    st([mode])
