from hypothesis import assume, given
from hypothesis.strategies import integers, shared

import asm
import dev
from gtemu import ROM
from strategies import data_stack_depths, truth_values
from utilities import do_test_word, get_IP, get_W, set_IP

WORD_START = dev.start_of_forth_word_space

address = shared(integers(min_value=WORD_START, max_value=(1 << 16) - 3))
target = address.flatmap(
    lambda address: integers(
        min_value=max(WORD_START, address & 0xFF00),
        max_value=min(address | 0xFF, (1 << 16) - 4),
    )
)


@given(address=address, target=target)
def test_branch_rom_mode(emulator, address, target):
    # Arrange
    # Jump target must not intersect with jump
    assume(not set(range(address, address + 2)) & set(range(target, target + 3)))
    # Jump address cannot be encoded right at the end of a page.
    # In practice this is not a problem, it's a two instruction encoding, and we
    # already have a requirement that threads can't cross pages.
    assume(address & 0xFF != 0xFF)
    set_IP(address)
    ip_movement = target - address + 3
    ROM[target : target + 3] = [
        b"\xdc\x42",  # st $42,[y, x++]
        [0xE0, asm.symbol("forth.move-ip")],  # jmp [y,]
        b"\xdc\x82",  # $82,[y, x++]
    ]
    ROM[address : address + 2] = [
        # Encoding for data
        [0xFC, target & 0xFF],  # bra target
        [0x00, ip_movement & 0xFF],  # ld ip_movement
    ]
    # Act
    do_test_word(emulator, "forth.internal.rom-mode.BRANCH", continue_on_reenter=False)
    # Assert
    assert (
        target + 3
    ) & 0xFF == get_IP() & 0xFF  # low-byte equality, because move-ip doesn't handle page crossings
    assert 0x8242 == get_W()


@given(
    address=address,
    target=target,
    tos=truth_values,
    data_stack_depth=data_stack_depths(with_room_for_values=1),
)
def test_question_branch_rom_mode(
    emulator, data_stack, address, target, data_stack_depth, tos
):
    # Arrange
    # Jump target must not intersect with jump
    assume(not set(range(address, address + 5)) & set(range(target, target + 3)))
    # We need to not be within the last five bytes of the page,
    # as there needs to be an instruction after us to run into if we don't branch.
    assume((address & 0xFF) + 5 <= 0xFF)
    data_stack.set_depth_in_bytes(data_stack_depth)
    data_stack.push_word(tos)
    set_IP(address)
    ip_movement = target - address + 3
    ROM[target : target + 3] = [
        b"\xdc\x00",  # st $00,[y, x++]
        [0xE0, asm.symbol("forth.move-ip")],  # jmp [y,]
        b"\xdc\x00",  # $00,[y, x++]
    ]
    ROM[address : address + 5] = [
        # Encoding for data
        [0xFC, target & 0xFF],  # bra target
        [0x00, ip_movement & 0xFF],  # ld ip_movement
        # Encoding for following word
        b"\xdc\xff",  # st $ff,[y, x++]
        [0xE0, asm.symbol("forth.move-ip")],  # jmp [y,]
        b"\xdc\xff",  # $ff,[y, x++]
    ]
    # Act
    do_test_word(emulator, "forth.internal.rom-mode.?BRANCH", continue_on_reenter=False)
    # Assert
    if not tos:
        # IP should point after target address
        assert (
            target + 3
        ) & 0xFF == get_IP() & 0xFF  # low-byte equality, because move-ip doesn't handle page crossings
        # Target instruction should be about to run
        assert 0x0000 == get_W()
    else:
        # We run into the encoding of the next instruction, so IP should point after it.
        assert (address + 5) & 0xFF == get_IP() & 0xFF
        # Next instruction should be about to run
        assert 0xFFFF == get_W()
