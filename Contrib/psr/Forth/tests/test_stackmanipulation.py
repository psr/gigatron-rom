"""Tests for core words"""
from hypothesis import given
from hypothesis.strategies import integers, lists

from forth import variables
from utilities import do_test_word

max_data_stack_size = (variables.data_stack_empty - variables.data_stack_full) // 2


@given(
    initial_stack=lists(
        integers(min_value=0, max_value=(1 << 16) - 1),
        min_size=1,
        max_size=max_data_stack_size,
    )
)
def test_drop(emulator, data_stack, initial_stack):
    # Arrange
    for value in reversed(initial_stack):
        data_stack.push_word(value)
    # Act
    do_test_word(emulator, "forth.core.DROP")
    # Assert
    expected_stack = initial_stack[1:]
    actual_stack = [data_stack.pop_u16() for _ in range(len(data_stack) // 2)]
    assert actual_stack == expected_stack


@given(
    initial_stack=lists(
        integers(min_value=0, max_value=(1 << 16) - 1),
        min_size=2,
        max_size=max_data_stack_size,
    )
)
def test_2drop(emulator, data_stack, initial_stack):
    # Arrange
    for value in reversed(initial_stack):
        data_stack.push_word(value)
    # Act
    do_test_word(emulator, "forth.core.2DROP")
    # Assert
    expected_stack = initial_stack[2:]
    actual_stack = [data_stack.pop_u16() for _ in range(len(data_stack) // 2)]
    assert actual_stack == expected_stack


@given(
    initial_stack=lists(
        integers(min_value=0, max_value=(1 << 16) - 1),
        min_size=2,
        max_size=max_data_stack_size,
    )
)
def test_swap(emulator, data_stack, initial_stack):
    for value in reversed(initial_stack):
        data_stack.push_word(value)
    # Act
    do_test_word(emulator, "forth.core.SWAP")
    # Assert
    expected_stack = list(reversed(initial_stack[:2])) + initial_stack[2:]
    actual_stack = [data_stack.pop_u16() for _ in range(len(data_stack) // 2)]
    assert actual_stack == expected_stack


@given(
    initial_stack=lists(
        integers(min_value=0, max_value=(1 << 16) - 1),
        min_size=1,
        max_size=max_data_stack_size - 1,
    )
)
def test_dup(emulator, data_stack, initial_stack):
    # Arrange
    for value in reversed(initial_stack):
        data_stack.push_word(value)
    # Act
    do_test_word(emulator, "forth.core.DUP")
    # Assert
    expected_stack = [initial_stack[0]] + initial_stack
    actual_stack = [data_stack.pop_u16() for _ in range(len(data_stack) // 2)]
    assert actual_stack == expected_stack


@given(
    initial_stack=lists(
        integers(min_value=0, max_value=(1 << 16) - 1),
        min_size=2,
        max_size=max_data_stack_size - 1,
    )
)
def test_two_dup(emulator, data_stack, initial_stack):
    # Arrange
    for value in reversed(initial_stack):
        data_stack.push_word(value)
    # Act
    do_test_word(emulator, "forth.core.2DUP")
    # Assert
    expected_stack = [initial_stack[0], initial_stack[1]] + initial_stack
    actual_stack = [data_stack.pop_u16() for _ in range(len(data_stack) // 2)]
    assert actual_stack == expected_stack


@given(
    initial_stack=lists(
        integers(min_value=0, max_value=(1 << 16) - 1),
        min_size=2,
        max_size=max_data_stack_size - 1,
    )
)
def test_over(emulator, data_stack, initial_stack):
    # Arrange
    for value in reversed(initial_stack):
        data_stack.push_word(value)
    # Act
    do_test_word(emulator, "forth.core.OVER")
    # Assert
    expected_stack = [initial_stack[1]] + initial_stack
    actual_stack = [data_stack.pop_u16() for _ in range(len(data_stack) // 2)]
    assert actual_stack == expected_stack


@given(
    initial_stack=lists(
        integers(min_value=0, max_value=(1 << 16) - 1),
        min_size=3,
        max_size=max_data_stack_size,
    )
)
def test_rot(emulator, data_stack, initial_stack):
    # Arrange
    for value in reversed(initial_stack):
        data_stack.push_word(value)
    # Act
    do_test_word(emulator, "forth.core.ROT")
    # Assert
    x3, x2, x1, *rest = initial_stack
    expected_stack = [x1, x3, x2] + rest
    actual_stack = [data_stack.pop_u16() for _ in range(len(data_stack) // 2)]
    assert actual_stack == expected_stack


@given(
    initial_stack=lists(
        integers(min_value=0, max_value=(1 << 16) - 1),
        min_size=4,
        max_size=max_data_stack_size,
    )
)
def test_2swap(emulator, data_stack, initial_stack):
    # Arrange
    for value in reversed(initial_stack):
        data_stack.push_word(value)
    # Act
    do_test_word(emulator, "forth.core.2SWAP")
    # Assert
    x4, x3, x2, x1, *rest = initial_stack
    expected_stack = [x2, x1, x4, x3] + rest
    actual_stack = [data_stack.pop_u16() for _ in range(len(data_stack) // 2)]
    assert actual_stack == expected_stack
