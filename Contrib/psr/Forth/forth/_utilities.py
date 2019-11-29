"""Helpers for generating the right code"""

from asm import (
    C,
    Y,
    hi,
    jmp,
    ld,
    lo,
)


def next(cycles_so_far):
    """Jump to the next instruction"""
    cost = cycles_so_far + cost_of_next
    if cost % 2 == 0:
        target = "forth.next2.even"
    else:
        target = "forth.next2.odd"
        cost += 1  # We're gaining a nop
    ld(hi("forth.next2"), Y)  # 1
    C("NEXT")
    jmp(Y, lo(target))  # 2
    ld(-(cost / 2))  # 3


NEXT = next
cost_of_next = 3


def add_cost_of_next(cycles_before):
    cost = cycles_before + cost_of_next
    if cost % 2 != 0:
        cost += 1
    return cost


"add_cost_of_reenter"


def reenter(cycles_so_far):
    """Dispatch to the word in W"""
    cost = cycles_so_far + cost_of_reenter
    if cost % 2 == 0:
        target = "forth.next1.reenter.even"
    else:
        target = "forth.next1.reenter.odd"
        cost -= 1  # We're skipping a nop
    ld(hi("forth.next1.reenter"), Y)  # 1
    C("REENTER")
    jmp(Y, lo(target))  # 2
    ld(-cost / 2)  # 3


REENTER = reenter
cost_of_reenter = 3


def add_cost_of_reenter(cycles_before):
    cost = cycles_before + cost_of_reenter
    if cost % 2 != 0:
        cost -= 1
    return cost


__all__ = [
    "next",
    "NEXT",
    "reenter",
    "REENTER",
    "add_cost_of_reenter",
    "add_cost_of_next",
]
