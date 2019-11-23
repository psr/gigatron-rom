# -*- coding: utf-8 -*-
"""Helpers for generating the right code"""
from __future__ import (
    absolute_import,
    division,
    print_function,
    unicode_literals,
)

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
    ld(-cost / 2)  # 3


NEXT = next
cost_of_next = 3


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


__all__ = ["next", "NEXT", "reenter", "REENTER"]
