""""Test for memory access words"""
from hypothesis import assume, given
from hypothesis.strategies import integers

from forth import variables
from gtemu import RAM
from utilities import do_test_word

max_data_stack_size = variables.data_stack_empty - variables.data_stack_full


def data_stack_depths(*, with_room_for_values=0):
    return integers(
        min_value=0,
        max_value=min(
            max_data_stack_size - with_room_for_values * 2, max_data_stack_size
        ),
    )


@given(
    data_stack_depth=data_stack_depths(with_room_for_values=1),
    address=integers(min_value=0x100, max_value=(1 << 15) - 1),
    data=integers(min_value=0, max_value=0xFF),
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
