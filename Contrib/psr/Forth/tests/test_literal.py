"""Tests for literals"""
from hypothesis import given

import asm
import dev
from forth.variables import W
from gtemu import ROM
from strategies import characters, data_stack_depths, numbers
from utilities import do_test_word, get_IP, get_W, set_IP

WORD_START = dev.start_of_forth_word_space


@given(data=numbers, data_stack_depth=data_stack_depths(with_room_for_values=1))
def test_rom_mode_literal(emulator, data_stack, data_stack_depth, data):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    set_IP(WORD_START)
    ROM[WORD_START : WORD_START + 6] = [
        # Encoding for data
        [0xDC, data & 0xFF],
        [0xDC, data >> 8 & 0xFF],
        [0x10, W],  # ld $00,x
        # Encoding for next word
        b"\xdc\x42",  # st $42,[y, x++]
        [0xE0, asm.symbol("forth.move-ip")],  # jmp [y,]
        b"\xdc\x82",  # $82,[y, x++]
    ]
    # Act
    do_test_word(emulator, "forth.internal.LIT", continue_on_reenter=False)
    # Assert
    assert data == data_stack.pop_i16()
    assert data_stack_depth == len(data_stack)
    assert WORD_START + 6 == get_IP()
    assert 0x8242 == get_W()


@given(data=characters, data_stack_depth=data_stack_depths(with_room_for_values=1))
def test_rom_mode_char_literal(emulator, data_stack, data_stack_depth, data):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    set_IP(WORD_START)
    ROM[WORD_START : WORD_START + 5] = [
        # Encoding for data
        [0xDC, data & 0xFF],
        [0x10, W],  # ld $00,x
        # Encoding for next word
        b"\xdc\x42",  # st $42,[y, x++]
        [0xE0, asm.symbol("forth.move-ip")],  # jmp [y,]
        b"\xdc\x82",  # $82,[y, x++]
    ]
    # Act
    do_test_word(emulator, "forth.internal.C-LIT", continue_on_reenter=False)
    # Assert
    assert data == data_stack.pop_i16()
    assert data_stack_depth == len(data_stack)
    assert WORD_START + 5 == get_IP()
    assert 0x8242 == get_W()
