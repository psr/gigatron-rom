from hypothesis import given
from hypothesis.strategies import integers

import asm
from forth import _shift, variables
from gtemu import RAM
from strategies import data_stack_depths, numbers, unsigned_numbers
from utilities import do_test_word, set_W


@given(data_stack_depth=data_stack_depths(with_room_for_values=1), tos=numbers)
def test_left_shift(emulator, data_stack, data_stack_depth, tos):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(tos)
    # Act
    do_test_word(emulator, "forth.core.2*")
    # Assert
    assert (tos << 1) & 0xFFFF == data_stack.pop_u16()
    assert data_stack_depth == len(data_stack)


@given(
    data_stack_depth=data_stack_depths(with_room_for_values=2),
    tos=unsigned_numbers,
    nos=numbers,
)
def test_lshift(emulator, data_stack, data_stack_depth, tos, nos):
    # Arrange
    emulator.zero_memory()
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(nos)
    data_stack.push_word(tos)
    set_W(asm.symbol("forth.core.LSHIFT"))
    # Act
    do_test_word(emulator, "forth.core.LSHIFT")
    # Assert
    assert (nos << tos) & 0xFFFF == data_stack.pop_u16()
    assert data_stack_depth == len(data_stack)


@given(
    data_stack_depth=data_stack_depths(with_room_for_values=2),
    tos=unsigned_numbers,
    nos=numbers,
)
def test_rshift(emulator, data_stack, data_stack_depth, tos, nos):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(nos)
    data_stack.push_word(tos)
    set_W(asm.symbol("forth.core.RSHIFT"))

    # Act
    do_test_word(emulator, "forth.core.RSHIFT")
    # Assert
    assert ((nos & 0xFFFF) >> tos) == data_stack.pop_u16()
    assert data_stack_depth == len(data_stack)


@given(
    value=integers(min_value=0x00, max_value=0xFF),
    shift_amount=integers(min_value=1, max_value=7),
)
def test_left_shift_by_n(emulator, value, shift_amount):
    """Test for the left-shift-by-n utility"""
    # Arrange
    RAM[variables.tmp4] = 0x1
    emulator.AC = -shift_amount & 0xFF
    RAM[0x42] = value
    emulator.Y = 0x00
    emulator.X = 0x42
    emulator.next_instruction = asm.symbol("left-shift-by-n")
    # Act
    emulator.run_for(_shift.cost_of_left_shift_by_n)
    # Assert
    assert emulator.AC == (value << shift_amount) & 0xFF
    assert emulator.next_instruction & 0xFF == 0x1


@given(
    value1=integers(min_value=0x00, max_value=0xFF),
    value2=integers(min_value=0x00, max_value=0xFF),
    shift_amount=integers(min_value=1, max_value=7),
)
def test_right_shift_by_n(emulator, value1, value2, shift_amount):
    """Test for the left-shift-by-n utility"""
    # Arrange
    RAM[variables.tmp4] = 0x1
    emulator.AC = -shift_amount & 0xFF
    RAM[0x42] = value1
    emulator.Y = 0x00
    emulator.X = 0x42
    emulator.next_instruction = asm.symbol("right-shift-by-n")
    # Act
    emulator.run_for(_shift.cost_of_right_shift_by_n)
    # Assert
    assert emulator.AC == (value1 >> shift_amount)
    assert emulator.next_instruction & 0xFF == 0x1
    # Arrange
    emulator.AC = RAM[variables.tmp5]
    RAM[0x42] = value2
    emulator.next_instruction = asm.symbol("right-shift-by-n.second-time")
    # Act
    emulator.run_for(_shift.cost_of_right_shift_by_n__second_time)
    # Assert
    assert emulator.AC == (value2 >> shift_amount)
    assert emulator.next_instruction & 0xFF == 0x1
