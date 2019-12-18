"""Tests for DOCOL, EXIT and company"""

import asm
from forth import variables
from hypothesis import given
from hypothesis.strategies import integers, just, lists, one_of
from utilities import (
    do_test_word,
    get_IP,
    get_mode,
    get_W,
    set_IP,
    set_mode,
    set_W,
)

max_return_stack_size = (
    variables.return_stack_empty - variables.return_stack_full
) // 2

# Address for RAM mode
nop_start = asm.symbol("forth.NOP")
# Address for ROM mode
nop_start_rom = nop_start + 4
end_of_docol = nop_start + 8

ram_modes = one_of(
    just(asm.symbol("forth.next3.ram-rom-mode") & 0xFF),
    just(asm.symbol("forth.next3.ram-ram-mode") & 0xFF),
)


@given(
    ip=integers(min_value=2, max_value=(1 << 15) - 2), mode=ram_modes,
)
def test_docol_ram(emulator, return_stack, ip, mode):
    """Test the docol implementation for RAM mode
    
    On entry:
    IP holds the RAM address after the one we've just come from
    W holds the address of our NOP instruction
    mode holds the mode

    On exit:
    IP holds the first address of the thread
    mode holds the address of NEXT3-ROM-Mode
    The return stack holds: 
        Top: The address of restore-mode (little-endian)
        2:   The previous mode
        3:   The old ip (little endian)
    """
    # Arrange
    set_IP(ip)
    set_mode(mode)
    set_W(asm.symbol("forth.NOP"))
    # Act
    do_test_word(emulator, "forth.NOP")
    # Assert
    assert end_of_docol == get_IP()
    assert asm.symbol("forth.next3.rom-mode") & 0xFF == get_mode()
    assert [asm.symbol("forth.RESTORE-MODE"), mode, ip] == [
        return_stack.pop_u16(),
        return_stack.pop_u8(),
        return_stack.pop_u16(),
    ]


@given(ip=integers(min_value=2, max_value=(1 << 15) - 2))
def test_docol_rom(emulator, return_stack, ip):
    """Test the docol implementation for RAM mode
    
    On entry:
    IP holds the ROM address after the one we've just come from
    W holds the address of our NOP instruction
    mode holds ROM mode

    On exit:
    IP holds the first address of the thread
    mode holds the address of NEXT3-ROM-Mode
    The return stack holds the old ip (little endian)
    """
    # Arrange
    set_IP(ip)
    set_mode(asm.symbol("forth.next3.rom-mode") & 0xFF)
    set_W(nop_start_rom)
    # Act
    do_test_word(emulator, nop_start_rom)
    # Assert
    assert end_of_docol == get_IP()
    assert asm.symbol("forth.next3.rom-mode") & 0xFF == get_mode()
    assert [ip] == [return_stack.pop_u16()]


@given(return_address=integers(min_value=2, max_value=(1 << 15) - 2))
def test_exit(emulator, return_stack, return_address):
    # Arrange
    return_stack.push_word(return_address)
    # Act
    do_test_word(emulator, "forth.EXIT")
    # Assert
    assert return_address == get_IP()
    assert not len(return_stack)


@given(return_address=integers(min_value=2, max_value=(1 << 15) - 2), mode=ram_modes)
def test_exit_to_ram_mode(emulator, return_stack, return_address, mode):
    # Arrange
    return_stack.push_word(return_address)
    return_stack.push_byte(mode)
    return_stack.push_word(asm.symbol("forth.RESTORE-MODE"))
    # Act
    do_test_word(emulator, "forth.EXIT")
    # Exit should have left restore-mode in IP, so next should DTRT
    do_test_word(emulator, "forth.next3.rom-mode")
    # Assert
    assert mode == get_mode()
    assert return_address == get_IP()
    assert not len(return_stack)
