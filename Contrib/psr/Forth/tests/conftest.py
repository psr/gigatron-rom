import struct

import pytest

# This lines need to happen in (roughly) this order
from gtemu import RAM, Emulator  # isort:skip
from forth import variables  # isort:skip

pytest.register_assert_rewrite("utilities")
import utilities  # noqa: E402 isort:skip


@pytest.fixture(scope="module")
def emulator():
    emulator = Emulator()
    emulator.zero_memory()
    yield emulator
    print(emulator.state)


class _GigatronStack(object):
    """Test utilities for manipulating the stack of the gigatron

    Assumes the stack stays in a single page, grows downwards, and is addressed by a single byte
    """

    def __init__(self, sp_address, initial_sp, stack_top):
        self._sp_address = sp_address
        RAM[sp_address] = initial_sp & 0xFF
        self._empty_stack = initial_sp
        self._full_stack = stack_top
        if initial_sp & 0xFF == 0:
            self._stack_page = (initial_sp >> 8) - 1
        else:
            self._stack_page = initial_sp & 0xFF

    @property
    def stack_pointer(self):
        # Slightly complicated, because an empty datastack would be
        # 0x00 - meaning 0x0100 (decrement should give 0xff), not 0x0000,
        # but any other value would be in page 0
        sp = RAM[self._sp_address]
        if sp == self._empty_stack & 0xFF:
            return self._empty_stack
        else:
            return (self._stack_page << 8) | sp

    @stack_pointer.setter
    def stack_pointer(self, sp):
        RAM[self._sp_address] = sp & 0xFF

    def set_depth_in_bytes(self, depth):
        self.stack_pointer = self._empty_stack - depth

    def __len__(self):
        return self._empty_stack - self.stack_pointer

    def _push(self, bytes):
        """Push a list of bytes"""
        new_sp = self.stack_pointer - len(bytes)
        assert new_sp >= self._full_stack, "Stack Overflow"
        RAM[self._sp_address] = new_sp & 0xFF
        RAM[new_sp : new_sp + len(bytes)] = bytes

    def _pop(self, num_bytes):
        new_sp = self.stack_pointer + num_bytes
        assert new_sp <= self._empty_stack, "Stack Underflow"
        bytes = RAM[self.stack_pointer : new_sp]
        RAM[self._sp_address] = new_sp & 0xFF
        return bytearray(bytes)

    def push_byte(self, value):
        assert -128 <= value < 256
        self._push([value & 0xFF])

    def push_word(self, value):
        assert -(1 << 15) <= value < (1 << 16)
        self._push([value & 0xFF, (value >> 8) & 0xFF])

    def pop_byte(self):
        """Returns an int in the range 0-255

        Probably clearer to use pop_u8
        """
        (byte,) = self._pop(1)
        return byte

    def pop_word(self):
        """Returns a length-two bytearray in lo, hi order

        probably clearer to use pop_u16 etc.
        """
        return self._pop(2)

    def pop_u8(self):
        return self.pop_byte()

    def pop_i8(self):
        return utilities.sign_extend(self.pop_byte())

    def pop_u16(self):
        return struct.unpack("<H", self.pop_word())[0]

    def pop_i16(self):
        return struct.unpack("<h", self.pop_word())[0]

    def pop_flag(self):
        value = self.pop_u16()
        if value == 0xFFFF:
            return True
        elif value == 0x0000:
            return False
        else:
            raise AssertionError(f"Value {value:x} is not a valid flag value")

    def pop_char(self):
        value = self.pop_u16()
        return chr(value)


@pytest.fixture(scope="module")
def data_stack(emulator):
    """Gives easy access to the data stack"""
    # Emulator is unused, but ensures that we run after the memory is zeroed
    return _GigatronStack(
        variables.data_stack_pointer,
        variables.data_stack_empty,
        variables.data_stack_full,
    )


@pytest.fixture(scope="module")
def return_stack(emulator):
    """Gives easy access to the return stack"""
    # Emulator is unused, but ensures that we run after the memory is zeroed
    return _GigatronStack(
        variables.return_stack_pointer,
        variables.return_stack_empty,
        variables.return_stack_full,
    )
