from hypothesis.strategies import integers, one_of, sampled_from

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

# Arbitrary aligned memory addresses, which avoid the zero-page
aligned_addresses = integers(min_value=(0x100 / 2), max_value=(1 << 14) - 1).map(
    lambda n: n * 2
)

# Arbitary one-byte values
characters = integers(min_value=0, max_value=0xFF)

# Arbitary numbers within the range of a 16 bit signed integer
numbers = integers(min_value=-(1 << 15), max_value=(1 << 15) - 1)

# Arbitrary numbers within the range of a 16 bit unsigned integer
unsigned_numbers = integers(min_value=0, max_value=(1 << 16) - 1)

# False and True flag values
flags = sampled_from([0, -1])

# Basically numbers - Should shrink towards the flag values though.
truth_values = one_of(flags, numbers)
