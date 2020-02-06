""""Test for memory access words"""
from hypothesis import assume, given
from hypothesis.strategies import integers

from forth import variables
from gtemu import RAM
from strategies import addresses, characters, data_stack_depths
from utilities import do_test_word


@given(
    data_stack_depth=data_stack_depths(with_room_for_values=1),
    address=addresses,
    data=characters,
)
def test_char_at(emulator, data_stack, data_stack_depth, address, data):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    RAM[address] = data
    data_stack.push_word(address)
    # Act
    do_test_word(emulator, "forth.core.C@")
    # Assert
    assert data == data_stack.pop_i16()
    assert data_stack_depth == len(data_stack)


@given(
    data_stack_depth=data_stack_depths(with_room_for_values=2),
    address=addresses,
    data=characters,
)
def test_char_set(emulator, data_stack, data_stack_depth, address, data):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(data)
    data_stack.push_word(address)
    # Act
    do_test_word(emulator, "forth.core.C!")
    # Assert
    assert data_stack_depth == len(data_stack)
    assert RAM[address] == data
