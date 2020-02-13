"""Tests for kernel words brought in from core.f"""
from hypothesis import given

from asm import symbol
from strategies import data_stack_depths, numbers
from utilities import do_test_word, get_IP, get_W, set_IP, set_W


@given(
    data_stack_depth=data_stack_depths(with_room_for_values=2), tos=numbers, nos=numbers
)
def test_nip(emulator, data_stack, return_stack, data_stack_depth, tos, nos):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(nos)
    data_stack.push_word(tos)
    set_IP(0x4282)
    set_W(symbol("forth.core.ext.NIP") + 4)
    # Act
    do_test_word(emulator, get_W())
    while get_IP() != 0x4282:
        do_test_word(emulator, "forth.next3.rom-mode")

    # Assert
    assert tos == data_stack.pop_i16()
    assert data_stack_depth == len(data_stack)
