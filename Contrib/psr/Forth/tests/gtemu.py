# -*- coding: utf-8 -*-
"""Wrapper for the gtemu emulator"""

from __future__ import (
    absolute_import,
    division,
    print_function,
    unicode_literals,
)
import itertools
import sys

import _gtemu

assert "asm" not in sys.modules, "gtemu needs to load before anything else touches asm"
import asm


def _make_state_field_accessors(name):
    """Return a descriptor that accesses the fields of the state

    Just because I don't yet know how to create CFFI structs, so I'm starting with a dict,
    and CFFI seems to do the conversion just fine.
    """

    def _getter(self):
        state = self._state
        state_is_dict = isinstance(state, dict)
        return state[name] if state_is_dict else getattr(state, name)

    def _setter(self, value):
        state = self._state
        if isinstance(state, dict):
            state[name] = value
        else:
            setattr(state, name, value)

    return property(
        _getter,
        _setter,
        doc="Get or set the current state of the " + name + " register",
    )


class _Emulator(object):
    def __init__(self):
        self._state = {}
        self._last_pc = None

    def _step(self):
        """Run a single step of the interpreter"""
        # Store the current PC, so that we can return it as next_instruction
        # This is needed because of the pipeline
        self._last_pc = self.PC
        self._state = _gtemu.lib.cpuCycle(self._state)

    globals().update(
        {
            field: _make_state_field_accessors(field)
            for field in ["PC", "IR", "D", "AC", "X", "Y", "OUT"]
        }
    )

    @property
    def next_instruction(self):
        return self._last_pc

    @next_instruction.setter
    def next_instruction(self, address):
        """Set program execution to proceed from `address`
        
        This sets the PC to address + 1, having loaded the instruction at address,
        as if we had just executed address - 1.
        """
        # To start from an address, we need to fill the pipeline with the instruction at address
        # and set PC to address + 1.
        address = asm.symbol(address) or address
        self.PC = address + 1
        self.IR = _gtemu.lib.ROM[address][0]
        self.D = _gtemu.lib.ROM[address][1]
        self._last_pc = address

    def run_for(self, instructions):
        """Run the emulator for a fixed number of cycles"""
        for _ in xrange(instructions):
            self._step()

    def run_to(self, address, max_instructions=1000):
        """Run the emulator until it is about to execute the instruction at `address`
        
        Due to the pipeline, this means that for the previous instruction PC was `address`,
        and therefore we have loaded the instruction.
        """
        address = asm.symbol(address) or address
        iterator = (
            xrange(max_instructions)
            if max_instructions is not None
            else itertools.count()
        )
        for _ in iterator:
            if self._last_pc == address:
                return
            self._step()
        raise ValueError("Did not hit address in %d instructions" % (max_instructions,))


emulator = _Emulator()


ROM = _gtemu.lib.ROM

# On load, populate the ROM from dev.py, and load the labels
# HACK!
# dev.py is not expecting to run as a module, and will naturally fail
# in multiple ways.

# We create a 'Reset' label, and stub out writeRomFiles() to prevent
# breakage.

asm.label("Reset")  # Creates it at 0x00


def _stub(*args, **kwargs):
    pass


_original_writeRomFiles = asm.writeRomFiles
asm.writeRomFiles = _stub
try:
    import dev
finally:
    asm.writeRomFiles = _original_writeRomFiles


def gen_rom_data():
    for opcode, operand in itertools.izip(asm._rom0, asm._rom1):
        yield opcode
        yield operand


rom_data = bytearray(gen_rom_data())
_gtemu.ffi.buffer(ROM)[0 : len(rom_data)] = rom_data


__all__ = ["emulator", "ROM"]
