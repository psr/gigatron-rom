# -*- coding: utf-8 -*-
"""Tests for the Forth NEXT implementation"""

from __future__ import (
    absolute_import,
    division,
    print_function,
    unicode_literals,
)

import struct

from hypothesis import (
    assume,
    given,
)
from hypothesis.strategies import (
    integers,
    shared,
)
import pytest

import asm
import dev
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

WORD_START = dev.start_of_forth_word_space

W = slice(forth.variables.W_lo, forth.variables.W_hi + 1)
IP = slice(forth.variables.IP_lo, forth.variables.IP_hi + 1)


def _set_ram(slice, bytes):
    RAM[slice] = bytes


def _set_u8(addr, byte):
    assert 0 <= byte < 256
    _set_ram(addr, byte)


def _set_i8(addr, byte):
    assert -128 <= byte < 128
    _set_ram(addr, byte & 0xFF)


def _set_u16(slice, value):
    assert 0 <= value < (1 << 16)
    _set_ram(slice, bytearray(struct.pack("<H", value)))


def _set_i16(slice, value):
    assert -(1 << 15) <= value < (1 << 15)
    _set_ram(slice, bytearray(struct.pack("<h", value)))


def _get_ram(slice):
    return bytearray(RAM[slice])


def _get_i8(addr):
    return struct.unpack("b", _get_ram(slice(addr, addr + 1)))[0]


def _get_u16(slice):
    return struct.unpack("<H", _get_ram(slice))[0]


def set_W(value):
    _set_u16(W, value)


def get_W():
    return _get_u16(W)


def set_mode(value):
    _set_u8(forth.variables.mode, value)


def set_vticks(value):
    _set_i8(dev.vTicks, value)


def get_vticks():
    return _get_i8(dev.vTicks)


def set_IP(value):
    _set_u16(IP, value)


def get_IP():
    return _get_u16(IP)


## Setup for next1 tests

vticks_next1 = shared(
    integers(min_value=forth.cost_of_failed_test + 1 // 2, max_value=127)
)
cost_of_word_success = vticks_next1.flatmap(
    lambda ticks: integers(
        min_value=0, max_value=(ticks - (forth.cost_of_failfast + 1) // 2)
    )
)
cost_of_word_failure = vticks_next1.flatmap(
    lambda ticks: integers(
        min_value=(ticks - (forth.cost_of_failfast + 1) // 2), max_value=127
    )
)


@given(vticks=vticks_next1, word_cost=cost_of_word_success)
def test_next1_successful_test(emulator, vticks, word_cost):
    """A successful test should result in us being in the right place"""
    # Arrange
    emulator.next_instruction = "forth.next1"
    emulator.AC = 20  # Time remaining is 20 ticks - 40 cycles
    set_W(WORD_START)
    ROM[WORD_START] = [0xA0, word_cost]
    # Act
    emulator.run_for(forth.cost_of_successful_test)
    # Assert
    assert emulator.next_instruction == WORD_START


@given(vticks=vticks_next1, word_cost=cost_of_word_failure)
def test_next1_unsuccessful_test(emulator, vticks, word_cost):
    "A failed test should result in us being in the right place"
    # Arrange
    emulator.next_instruction = "forth.next1"
    emulator.AC = 20  # Time remaining is 20 ticks - 40 cycles
    set_W(WORD_START)
    ROM[WORD_START] = [0xA0, word_cost]  # suba $14 - worst case runtime is twenty ticks
    # Act
    emulator.run_for(forth.cost_of_failed_next1)
    # Assert
    assert emulator.next_instruction == asm.symbol("forth.exit.from-failed-test")


##
# Setup for the Next2 tests.

minimum_vticks_for_successful_next2 = (
    forth.cost_of_successful_test
    + forth.cost_of_next2_success
    + forth.cost_of_failed_test
) / 2
maximum_vticks_for_successful_next2 = 127

minimum_vticks_for_failed_next2 = (
    forth.cost_of_successful_test + forth.cost_of_failfast_next2
) / 2
maximum_vticks_for_failed_next2 = 127

# Hypothesis strategies to generate vticks values consistent with passing and failing next2

vticks_next2_success = shared(
    integers(
        min_value=minimum_vticks_for_successful_next2,
        max_value=maximum_vticks_for_successful_next2,
    )
)
vticks_next2_failure = shared(
    integers(
        min_value=minimum_vticks_for_failed_next2,
        max_value=maximum_vticks_for_failed_next2,
    )
)

# Given a the value held in vticks, what is the upper and lower bound of the number of cycles a word can have
# if next2 is to succeed or fail

minimum_word_cycles_for_sucessful_next2 = 0
maximum_word_cycles_for_sucessful_next2 = lambda vticks: (
    vticks * 2
    - forth.cost_of_successful_test
    - forth.cost_of_next2_success
    - forth.cost_of_failed_test
)

minimum_word_cycles_for_failed_next2 = (
    lambda vticks: maximum_word_cycles_for_sucessful_next2(vticks) + 1
)
maximum_word_cycles_for_failed_next2 = lambda vticks: (
    vticks * 2 - forth.cost_of_successful_test - forth.cost_of_failfast_next2
)

# Hypothesis strategies to generate elapsed cycles consistent with passing and failing next2 and vticks

word_cycles_next2_success = vticks_next2_success.flatmap(
    lambda vticks: integers(
        min_value=minimum_word_cycles_for_sucessful_next2,
        max_value=maximum_word_cycles_for_sucessful_next2(vticks),
    )
)
word_cycles_next2_failure = vticks_next2_failure.flatmap(
    lambda vticks: integers(
        min_value=minimum_word_cycles_for_failed_next2(vticks),
        max_value=maximum_word_cycles_for_failed_next2(vticks),
    )
)


@given(vticks=vticks_next2_success, cycles_executed_in_word=word_cycles_next2_success)
def test_next2_success(emulator, vticks, cycles_executed_in_word):
    # Arrange
    ticks_returned = -(
        (cycles_executed_in_word + 1) // 2  # Round up to a whole number of ticks
    )  # We round up on entry to next2
    entry_point = (
        "forth.next2.even" if even(cycles_executed_in_word) else "forth.next2.odd"
    )
    emulator.next_instruction = entry_point
    expected_cycles = forth.cost_of_next2_success
    if not even(cycles_executed_in_word):
        expected_cycles += 1
    emulator.AC = ticks_returned & 0xFF
    set_mode(asm.symbol("forth.next3.rom-mode") & 0xFF)
    set_vticks(vticks)
    # Act
    cycles_taken_by_next2 = emulator.run_to("forth.next1")
    # Assert
    assert get_W() == asm.symbol("forth.next3.rom-mode")
    assert cycles_taken_by_next2 == expected_cycles
    assert get_vticks() == emulator.AC
    assert get_vticks() * 2 >= forth.cost_of_failed_test
    assert get_vticks() * 2 == (
        vticks * 2
        - forth.cost_of_successful_test
        - cycles_executed_in_word
        - cycles_taken_by_next2
    )


@given(vticks=vticks_next2_failure, cycles_executed_in_word=word_cycles_next2_failure)
def test_next2_failure(emulator, vticks, cycles_executed_in_word):
    # Arrange
    ticks_returned = -(
        (cycles_executed_in_word + 1) // 2  # Round up to a whole number of ticks
    )  # We round up on entry to next2
    entry_point = (
        "forth.next2.even" if even(cycles_executed_in_word) else "forth.next2.odd"
    )
    emulator.next_instruction = entry_point
    expected_cycles = forth.cost_of_next2_failure
    if not even(cycles_executed_in_word):
        expected_cycles += 1
    emulator.AC = ticks_returned & 0xFF
    set_mode(asm.symbol("forth.next3.rom-mode") & 0xFF)
    set_vticks(vticks)
    # Act
    cycles_taken_by_next2 = emulator.run_to("forth.exit.from-next2")
    # Assert
    assert get_W() == asm.symbol("forth.next3.rom-mode")
    assert cycles_taken_by_next2 == expected_cycles
    assert (emulator.AC + get_vticks()) * 2 == (
        vticks * 2
        - forth.cost_of_successful_test
        - cycles_executed_in_word
        - cycles_taken_by_next2
    )


##
# Setup for the Next1_reenter tests

# For next1_reenter to succeed, vticks + AC needs to be >= cost_of_successful_test + next1_reenter_success + cost_of_failed_test

vticks_next1_reenter_success = shared(
    integers(
        min_value=(
            forth.cost_of_successful_test
            + forth.cost_of_next1_reenter_success
            + forth.cost_of_failed_test
        )
        // 2,
        max_value=127,
    )
)
minimum_word_cycles_for_sucessful_next1_reenter = 0
maximum_word_cycles_for_sucessful_next1_reenter = lambda vticks: (
    vticks * 2
    - forth.cost_of_successful_test
    - forth.cost_of_next1_reenter_success
    - forth.cost_of_failed_test
    + 1  # To account for the fact that we can round down
)
word_cycles_next1_reenter_success = vticks_next1_reenter_success.flatmap(
    lambda vticks: integers(
        min_value=minimum_word_cycles_for_sucessful_next1_reenter,
        max_value=maximum_word_cycles_for_sucessful_next1_reenter(vticks),
    )
)


@given(
    vticks=vticks_next1_reenter_success,
    cycles_executed_in_word=word_cycles_next1_reenter_success,
)
def test_next1_reenter_success(emulator, vticks, cycles_executed_in_word):
    # Arrange
    # Round down to a whole number of ticks
    ticks_returned = -((cycles_executed_in_word) // 2)
    entry_point = (
        "forth.next1.reenter.even"
        if even(cycles_executed_in_word)
        else "forth.next1.reenter.odd"
    )
    emulator.next_instruction = entry_point
    expected_cycles = forth.cost_of_next1_reenter_success
    if not even(cycles_executed_in_word):
        expected_cycles -= 1  # Skip NOP
    emulator.AC = ticks_returned & 0xFF
    set_vticks(vticks)
    # Act
    cycles_taken_by_next1 = emulator.run_to("forth.next1")
    # Assert
    assert cycles_taken_by_next1 == expected_cycles
    assert get_vticks() == emulator.AC
    assert get_vticks() * 2 >= forth.cost_of_failed_test
    assert get_vticks() * 2 == (
        vticks * 2
        - forth.cost_of_successful_test
        - cycles_executed_in_word
        - cycles_taken_by_next1
    )


vticks_next1_reenter_failure = shared(
    integers(
        min_value=(forth.cost_of_successful_test + forth.cost_of_failfast_next1_reenter)
        // 2,
        max_value=127,
    )
)
minimum_word_cycles_for_failed_next1_reenter = lambda vticks: (
    maximum_word_cycles_for_sucessful_next1_reenter(vticks) + 1
)
maximum_word_cycles_for_failed_next1_reenter = lambda vticks: (
    vticks * 2 - forth.cost_of_successful_test - forth.cost_of_failfast_next1_reenter
)
word_cycles_next1_reenter_failure = vticks_next1_reenter_failure.flatmap(
    lambda vticks: integers(
        min_value=minimum_word_cycles_for_failed_next1_reenter(vticks),
        max_value=maximum_word_cycles_for_failed_next1_reenter(vticks),
    )
)


def sext(num):
    """Sign extend 8-bit integer"""
    num |= (-1 & ~0xFF) if (num & 0x80) else 0
    return num


@given(
    vticks=vticks_next1_reenter_failure,
    cycles_executed_in_word=word_cycles_next1_reenter_failure,
)
def test_next1_reenter_failure(emulator, vticks, cycles_executed_in_word):
    # Arrange
    # Round down to a whole number of ticks
    ticks_returned = -((cycles_executed_in_word) // 2)
    entry_point = (
        "forth.next1.reenter.even"
        if even(cycles_executed_in_word)
        else "forth.next1.reenter.odd"
    )
    emulator.next_instruction = entry_point
    expected_cycles = forth.cost_of_next1_reenter_failure
    if not even(cycles_executed_in_word):
        expected_cycles -= 1  # Skip NOP
    emulator.AC = ticks_returned & 0xFF
    set_vticks(vticks)
    # Act
    cycles_taken_by_next1 = emulator.run_to("forth.exit.from-next1-reenter")
    # Assert
    assert cycles_taken_by_next1 == expected_cycles
    assert (sext(emulator.AC) + get_vticks()) == (
        vticks * 2
        - forth.cost_of_successful_test
        - cycles_executed_in_word
        - cycles_taken_by_next1
    ) / 2
    assert sext(emulator.AC) + get_vticks() >= forth.cost_of_exit_from_next1_reenter / 2


def negate(value):
    return -sext(value)


def _get_max_tick_cost_of_word(emulator, address):
    emulator.next_instruction = asm.symbol(address) or address
    emulator.AC = 0
    emulator.run_for(1)
    return negate(emulator.AC)


## Test for Next3_rom
def test_next3_rom(emulator):
    worst_case_ticks = _get_max_tick_cost_of_word(emulator, "forth.next3.rom-mode")
    emulator.next_instruction = "forth.next3.rom-mode"
    set_IP(WORD_START)
    ROM[WORD_START : WORD_START + 3] = [
        b"\xdc\x42",  # st $42,[y, x++]
        [0xE0, asm.symbol("forth.next3.rom-mode-tail")],  # jmp [y,]
        b"\xdc\x82",  # $82,[y, x++]
    ]

    cycles_taken = emulator.run_to("forth.next1.reenter")

    assert get_W() == 0x8242
    assert negate(emulator.AC) * 2 == cycles_taken <= worst_case_ticks * 2


## Hypothesis strategy to generate valid IP values.
# We're assuming that all of our addresses are two-byte
# aligned - at least for now. The range is from 0x100 to
# 0x7fff, but generate integers over half that range and multiply by two.
valid_ips = integers(min_value=0x100 / 2, max_value=(1 << 15) / 2 - 4).map(
    lambda i: i * 2
)


@given(ip=valid_ips)
def test_next3_ram_rom(emulator, ip):
    # Arrange
    will_cross_page = not ((ip + 2) & 0xFF)
    expected_cycles = (
        forth.cost_of_next3_ram_rom__page_crossed
        if will_cross_page
        else forth.cost_of_next3_ram_rom__no_page_cross
    )
    if even(expected_cycles):
        # We enter at the even point, but we're counting to the odd entry-point
        expected_cycles += 1
    worst_case_ticks = _get_max_tick_cost_of_word(emulator, "forth.next3.ram-rom-mode")
    emulator.next_instruction = "forth.next3.ram-rom-mode"
    set_IP(ip)
    RAM[ip : ip + 2] = bytearray(struct.pack("<H", WORD_START))
    # Act
    actual_cycles = emulator.run_to("forth.next1.reenter.odd")
    # Assert
    assert get_W() == WORD_START
    assert get_IP() == ip + 2
    assert actual_cycles == expected_cycles
    # -1 because we're counting to the odd entry_point
    assert worst_case_ticks >= actual_cycles // 2
    assert -sext(emulator.AC) == actual_cycles // 2


@given(ip=valid_ips, target=valid_ips)
def test_next3_ram_ram(emulator, ip, target):
    # Arrange
    # Address IP and target address can't intersect
    assume(not set(xrange(target, target + 2)) & set(xrange(ip, ip + 2)))
    will_cross_page = not ((ip + 2) & 0xFF)
    expected_cycles = (
        forth.cost_of_next3_ram_ram__page_crossed
        if will_cross_page
        else forth.cost_of_next3_ram_ram__no_page_cross
    )
    if even(expected_cycles):
        # We enter at the even point, but we're counting to the odd entry-point
        expected_cycles += 1
    worst_case_ticks = _get_max_tick_cost_of_word(emulator, "forth.next3.ram-ram-mode")
    emulator.next_instruction = "forth.next3.ram-ram-mode"
    RAM[target : target + 2] = bytearray(struct.pack("<H", WORD_START))
    set_IP(ip)
    RAM[ip : ip + 2] = bytearray(struct.pack("<H", target))
    # Act
    actual_cycles = emulator.run_to("forth.next1.reenter.odd")
    # Assert
    # Actual cycles is +1 because we're timing to odd entrypoint
    assert get_W() == WORD_START
    assert get_IP() == ip + 2
    assert actual_cycles == expected_cycles
    assert worst_case_ticks >= actual_cycles // 2
    assert -sext(emulator.AC) == actual_cycles // 2
