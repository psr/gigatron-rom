from hypothesis.strategies import integers

from forth import variables

max_data_stack_size = variables.data_stack_empty - variables.data_stack_full


def data_stack_depths(*, with_room_for_values=0):
    return integers(
        min_value=0,
        max_value=min(
            max_data_stack_size - with_room_for_values * 2, max_data_stack_size
        ),
    )


# Arbitrary memory addresses, which avoid the zero-page
addresses = integers(min_value=0x100, max_value=(1 << 15) - 1)

# Arbitary one-byte values
characters = integers(min_value=0, max_value=0xFF)

# Arbitary numbers within the range of a 16 bit signed integer
numbers = integers(min_value=-(1 << 15), max_value=(1 << 15) - 1)

# Arbitrary numbers within the range of a 16 bit unsigned integer
unsigned_numbers = integers(min_value=0, max_value=(1 << 16) - 1)
