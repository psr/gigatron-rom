"""Tests for kernel words brought in from core.f"""
from hypothesis import given
from hypothesis.strategies import just, one_of, shared

from asm import symbol
from strategies import (
    addresses,
    data_stack_depths,
    numbers,
    truth_values,
    unsigned_numbers,
)
from utilities import do_test_word, get_IP, get_W, set_IP, set_W


def _do_test_thread(emulator, label):
    set_IP(0x4282)
    set_W(symbol(label))
    do_test_word(emulator, get_W())
    while get_IP() != 0x4282:
        do_test_word(emulator, "forth.next3.rom-mode")


@given(
    data_stack_depth=data_stack_depths(with_room_for_values=2), tos=numbers, nos=numbers
)
def test_nip(emulator, data_stack, return_stack, data_stack_depth, tos, nos):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(nos)
    data_stack.push_word(tos)
    # Act
    _do_test_thread(emulator, "forth.core.ext.NIP")
    # Assert
    assert tos == data_stack.pop_i16()
    assert data_stack_depth == len(data_stack)


@given(data_stack_depth=data_stack_depths(with_room_for_values=2), number=numbers)
def test_zero_not_equal(emulator, data_stack, return_stack, data_stack_depth, number):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(number)
    # Act
    _do_test_thread(emulator, "forth.core.ext.0<>")
    # Assert
    assert (number != 0) == data_stack.pop_flag()
    assert data_stack_depth == len(data_stack)


@given(data_stack_depth=data_stack_depths(with_room_for_values=2), number=truth_values)
def test_question_dup(emulator, data_stack, return_stack, data_stack_depth, number):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(number)
    # Act
    _do_test_thread(emulator, "forth.core.?DUP")
    # Assert
    if number == 0:
        assert 0 == data_stack.pop_i16()
    else:
        assert number == data_stack.pop_i16()
        assert number == data_stack.pop_i16()
    assert data_stack_depth == len(data_stack)


@given(data_stack_depth=data_stack_depths(with_room_for_values=1), address=addresses)
def test_cell_plus(emulator, data_stack, data_stack_depth, address):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(address)
    # Act
    _do_test_thread(emulator, "forth.core.CELL+")
    # Assert
    (address + 2) & 0xFFFF == data_stack.pop_u16()
    assert data_stack_depth == len(data_stack)


@given(data_stack_depth=data_stack_depths(with_room_for_values=1), tos=numbers)
def test_negate(emulator, data_stack, data_stack_depth, tos):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(tos)
    # Act
    _do_test_thread(emulator, "forth.core.NEGATE")
    # Assert
    (-tos) & 0xFFFF == data_stack.pop_u16()
    assert data_stack_depth == len(data_stack)


@given(
    data_stack_depth=data_stack_depths(with_room_for_values=2), tos=numbers, nos=numbers
)
def test_minus(emulator, data_stack, data_stack_depth, tos, nos):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(nos)
    data_stack.push_word(tos)
    # Act
    _do_test_thread(emulator, "forth.core.-")
    # Assert
    (nos - tos) & 0xFFFF == data_stack.pop_u16()
    assert data_stack_depth == len(data_stack)


# Strategies that might generate equal values (if I understand correctly)
values = shared(numbers)
maybe_equal = values.flatmap(lambda value: one_of(just(value), numbers))


@given(
    data_stack_depth=data_stack_depths(with_room_for_values=2),
    tos=values,
    nos=maybe_equal,
)
def test_equals(emulator, data_stack, data_stack_depth, tos, nos):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(nos)
    data_stack.push_word(tos)
    # Act
    _do_test_thread(emulator, "forth.core.=")
    # Assert
    assert (tos == nos) == data_stack.pop_flag()
    assert data_stack_depth == len(data_stack)


@given(
    data_stack_depth=data_stack_depths(with_room_for_values=1), tos=numbers,
)
def test_zero_lessthan(emulator, data_stack, data_stack_depth, tos):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(tos)
    # Act
    _do_test_thread(emulator, "forth.core.0<")
    # Assert
    assert (tos < 0) == data_stack.pop_flag()
    assert data_stack_depth == len(data_stack)


@given(
    data_stack_depth=data_stack_depths(with_room_for_values=1), tos=numbers,
)
def test_zero_greaterthan(emulator, data_stack, data_stack_depth, tos):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(tos)
    # Act
    _do_test_thread(emulator, "forth.core.ext.0>")
    # Assert
    assert (tos > 0) == data_stack.pop_flag()
    assert data_stack_depth == len(data_stack)


# @given(
#     data_stack_depth=data_stack_depths(with_room_for_values=2),
#     tos=numbers,
#     nos=numbers,
# )
def test_lessthan(emulator, data_stack, data_stack_depth=0, tos=0, nos=0):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(nos)
    data_stack.push_word(tos)
    # Act
    _do_test_thread(emulator, "forth.core.<")
    # Assert
    assert (nos < tos) == data_stack.pop_flag()
    assert data_stack_depth == len(data_stack)


@given(
    data_stack_depth=data_stack_depths(with_room_for_values=2),
    tos=numbers,
    nos=numbers,
)
def test_greaterthan(emulator, data_stack, data_stack_depth, tos, nos):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(nos)
    data_stack.push_word(tos)
    # Act
    _do_test_thread(emulator, "forth.core.>")
    # Assert
    assert (nos > tos) == data_stack.pop_flag()
    assert data_stack_depth == len(data_stack)


@given(
    data_stack_depth=data_stack_depths(with_room_for_values=2),
    tos=unsigned_numbers,
    nos=unsigned_numbers,
)
def test_unsigned_lessthan(emulator, data_stack, data_stack_depth, tos, nos):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(nos)
    data_stack.push_word(tos)
    # Act
    _do_test_thread(emulator, "forth.core.U<")
    # Assert
    assert (nos < tos) == data_stack.pop_flag()
    assert data_stack_depth == len(data_stack)


@given(
    data_stack_depth=data_stack_depths(with_room_for_values=2),
    tos=unsigned_numbers,
    nos=unsigned_numbers,
)
def test_unsigned_greaterthan(emulator, data_stack, data_stack_depth, tos, nos):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(nos)
    data_stack.push_word(tos)
    # Act
    _do_test_thread(emulator, "forth.core.ext.U>")
    # Assert
    assert (nos > tos) == data_stack.pop_flag()
    assert data_stack_depth == len(data_stack)


@given(data_stack_depth=data_stack_depths(with_room_for_values=1), tos=numbers)
def test_abs(emulator, data_stack, data_stack_depth, tos):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(tos)
    # Act
    _do_test_thread(emulator, "forth.core.ABS")
    # Assert
    assert abs(tos) == data_stack.pop_u16()
    assert data_stack_depth == len(data_stack)
