# -*- coding: utf-8 -*-
"""Tests for the Forth NEXT implementation"""

from __future__ import (
    absolute_import,
    division,
    print_function,
    unicode_literals,
)

import struct

import pytest

import asm
from gtemu import ROM, RAM
import forth


##
# Odd and odd is even, even and even is even. Even and odd is odd.
# ================================================================
# Tests relating to whether the number of cycles on a given path
# is even or odd.


def even(n):
    return n % 2 == 0


parity_must_match = {
    "cost_of_successful_test": {
        "cost_of_next2_success",
        "cost_of_next1_reenter_success",
        "cost_of_failfast_next2",
        "cost_of_failfast_next1_reenter",
    },
    "cost_of_failed_next1": {"cost_of_exit_from_failed_test",},
}


_parity_match_cases = [
    pytest.param(
        getattr(forth, from_), getattr(forth, to), id="{} to {}".format(from_, to)
    )
    for from_, tos in parity_must_match.viewitems()
    for to in tos
]


@pytest.mark.parametrize("from_,to", _parity_match_cases)
def test_parity_matches(from_, to):
    """There are various paths through NEXT where we need a + b to be a multiple of 2,
    where a and b are the lengths of various peices of code. This is because they need
    to be convertable to a number of ticks.

    These tests validate that those requirements are met.
    """
    assert even(from_) is even(to)


parity_depends = {
    ("cost_of_next2_failure", "cost_of_exit_from_next2"),
    ("cost_of_next1_reenter_failure", "cost_of_exit_from_next1_reenter",),
}

_parity_match_cases = [
    pytest.param(
        getattr(forth, from_),
        getattr(forth, to),
        getattr(forth, "cost_of_next2_success"),
        id="{} to {} must match cost_of_next2_success".format(from_, to),
    )
    for from_, to in parity_depends
]


@pytest.mark.parametrize("from_,to,must_match", _parity_match_cases)
def test_parity_depends(from_, to, must_match):
    """The failfast paths are themselves made of two parts,
    and they may need to differ or agree in parity depending
    on whether the successful test case is even or odd"""
    assert (
        even(from_) is even(to) if even(must_match) else (even(from_) is not even(to))
    )


##
# Run various processes in the emulator

WORD_START = 0x1404  # TODO - this is based on the disassembly, and will change

W = slice(forth.variables.W_lo, forth.variables.W_hi + 1)


def set_W(value):
    assert 0 <= value < (1 << 16)
    RAM[W] = bytearray(struct.pack("<H", value))


def test_next1_successful_test(emulator):
    """A successful test should result in us being in the right place"""
    # Arrange
    emulator.next_instruction = "forth.next1"
    emulator.AC = 20  # Time remaining is 20 ticks - 40 cycles
    set_W(WORD_START)
    ROM[WORD_START] = b"\xa0\x02"  # suba $02 - worst case runtime is two ticks
    # Act
    emulator.run_for(forth.cost_of_successful_test)
    # Assert
    assert emulator.next_instruction == WORD_START


def test_next1_unsuccessful_test(emulator):
    # Arrange
    emulator.next_instruction = "forth.next1"
    emulator.AC = 20  # Time remaining is 20 ticks - 40 cycles
    set_W(WORD_START)
    ROM[WORD_START] = b"\xa0\x14"  # suba $14 - worst case runtime is twenty ticks
    # Act
    emulator.run_for(forth.cost_of_failed_next1)
    # Assert
    assert emulator.next_instruction == asm.symbol("forth.exit.from-failed-test")
