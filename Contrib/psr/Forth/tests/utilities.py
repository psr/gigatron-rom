"""Utilities that should be useful in unit testing"""
import struct

import asm
import dev
from forth import variables
from gtemu import RAM, ROM


def even(num):
    "Return true if num is an even number"
    return num % 2 == 0


def sign_extend(num):
    """Sign extend 8-bit integer"""
    num |= (-1 & ~0xFF) if (num & 0x80) else 0
    return num


def negate_byte(value):
    """Returns an int from a signed-byte value"""
    return -sign_extend(value)


# RAM accessors
W = slice(variables.W_lo, variables.W_hi + 1)
IP = slice(variables.IP_lo, variables.IP_hi + 1)


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


def _get_u8(addr):
    return RAM[addr]


def _get_u16(slice):
    return struct.unpack("<H", _get_ram(slice))[0]


def set_W(value):
    _set_u16(W, value)


def get_W():
    return _get_u16(W)


def set_mode(value):
    _set_u8(variables.mode, value)


def get_mode():
    return _get_u8(variables.mode)


def set_vticks(value):
    _set_i8(dev.vTicks, value)


def get_vticks():
    return _get_i8(dev.vTicks)


def set_IP(value):
    _set_u16(IP, value)


def get_IP():
    return _get_u16(IP)


def _get_max_tick_cost_of_current_word(emulator):
    """Run one instruction to find out how long the current word should take"""
    emulator.AC = 0
    emulator.run_for(1)
    return negate_byte(emulator.AC)


def do_test_word(emulator, entrypoint=None, continue_on_reenter=True):
    """Execute a single Forth word, checking the timing related invariants

    If continue_on_reenter is True (the default),
    this will run the emulator until it returns to Next2.
    Otherwise it will return after the emulator returns to Next1-reenter,
    it will raise an assertion error if it returns to Next2.

    The starting instruction can be specified as a parameter,
    or set on the emulator object before the call.
    """
    reenter_odd = asm.symbol("forth.next1.reenter.odd")
    next2_even = asm.symbol("forth.next2.even")

    old_breakpoints = emulator.breakpoints
    # Break at the inner entrypoints of the two routines
    emulator.breakpoints = set([reenter_odd, next2_even])

    entrypoint = entrypoint or emulator.next_instruction

    def do_iteration():
        emulator.next_instruction = entrypoint
        worst_case_ticks = _get_max_tick_cost_of_current_word(emulator)
        emulator.next_instruction = entrypoint
        actual_cycles = emulator.run_for(worst_case_ticks * 2)
        if emulator.PC == reenter_odd:
            # We've jumped to next1-reenter.odd, but not yet loaded the instruction.
            # This is actually OK.
            actual_cycles += emulator.run_for(1)
        return actual_cycles

    def check_next1_reenter_constraints():
        assert not even(actual_cycles)  # We're at the odd entrypoint
        assert negate_byte(emulator.AC) * 2 == actual_cycles - 1

    actual_cycles = do_iteration()
    while continue_on_reenter and emulator.next_instruction == reenter_odd:
        check_next1_reenter_constraints()
        entrypoint = get_W()
        emulator.next_instruction = entrypoint
        actual_cycles = do_iteration()
    emulator.breakpoints = old_breakpoints

    if not continue_on_reenter:
        if emulator.next_instruction == reenter_odd:
            # Good, that's where we expected to be
            check_next1_reenter_constraints()
            return
        elif emulator.next_instruction == next2_even:
            raise AssertionError(
                "Expected see jump to reenter - but instead saw jump to next2"
            )

    if emulator.next_instruction == next2_even:
        assert even(actual_cycles)
        assert negate_byte(emulator.AC) * 2 == actual_cycles
        return

    raise AssertionError(
        "Did not hit Next2 or Reenter within the promised {} ticks".format(
            actual_cycles / 2
        )
    )
