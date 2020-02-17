import operator

from hypothesis import example, given

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


@given(
    data_stack_depth=data_stack_depths(with_room_for_values=1), data=numbers,
)
@example(data_stack_depth=0, data=-(1 << 15))
def test_zero_equal(emulator, data_stack, data_stack_depth, data):
    # Arrange
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(data)
    # Act
    do_test_word(emulator, "forth.core.0=")
    # Assert
    assert (data == 0) == data_stack.pop_flag()
    assert data_stack_depth == len(data_stack)


def make_binary_bitwise_operator_test(name, operator):
    """Factory for binary operator tests"""

    @given(
        data_stack_depth=data_stack_depths(with_room_for_values=2),
        tos=numbers,
        nos=numbers,
    )
    def test(emulator, data_stack, data_stack_depth, tos, nos):
        # Arrange
        data_stack.set_depth_in_bytes(data_stack_depth)
        data_stack.push_word(nos)
        data_stack.push_word(tos)
        # Act
        do_test_word(emulator, f"forth.core.{name}")
        # Assert
        expected = operator(tos, nos)
        assert expected == data_stack.pop_i16()
        assert data_stack_depth == len(data_stack)

    return test


test_xor = make_binary_bitwise_operator_test("XOR", operator.xor)
test_or = make_binary_bitwise_operator_test("OR", operator.or_)
test_and = make_binary_bitwise_operator_test("AND", operator.and_)
