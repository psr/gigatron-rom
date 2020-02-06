from hypothesis import assume, example, given
from hypothesis.strategies import integers

from forth import variables
from gtemu import RAM
from strategies import data_stack_depths, numbers
from utilities import do_test_word


@given(
    data_stack_depth=data_stack_depths(with_room_for_values=1), data=numbers,
)
@example(data_stack_depth=0, data=(1 << 15) - 1)
def test_increment(emulator, data_stack, data_stack_depth, data):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(data)
    # Act
    do_test_word(emulator, "forth.core.1+")
    # Assert
    assert (data + 1) & 0xFFFF == data_stack.pop_i16() & 0xFFFF
    assert data_stack_depth == len(data_stack)


@given(
    data_stack_depth=data_stack_depths(with_room_for_values=1), data=numbers,
)
@example(data_stack_depth=0, data=-(1 << 15))
def test_decrement(emulator, data_stack, data_stack_depth, data):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(data)
    # Act
    do_test_word(emulator, "forth.core.1-")
    # Assert
    assert (data - 1) & 0xFFFF == data_stack.pop_i16() & 0xFFFF
    assert data_stack_depth == len(data_stack)
