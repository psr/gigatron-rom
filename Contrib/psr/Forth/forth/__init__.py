"""Native code Forth implementation for the Gigatron"""

from asm import C, adda, align, label, nop, pc, st

from . import (
    _arithmetic,
    _docol_exit,
    _literal,
    _memory,
    _next,
    _stackmanipulation,
)
from ._next import move_ip


def emit_entry_page(vticks, vreturn):
    """Emit the data for NEXT and some other core routines

    The first page does not have the 'restart-or-quit' trampoline at 0x00
    So we can't put any Forth word in here.
    """
    while pc() & 255 < 255:
        nop()
    assert _next.INTERPRETER_ENTER_PAGE == pc() >> 8
    label("FORTH_ENTER")
    C("You are now entering... Forth")
    adda(_next.INBOUND_TICK_CORRECTION)
    # --- Page boundary ---
    align(0x100, 0x100)
    st([vticks])
    _next.next1(vticks)
    _next.next1_reenter(vticks)
    _next.next2(vticks)
    _next.exit(vticks, vreturn)
    _docol_exit.do_docol_rom()
    _docol_exit.do_docol_ram()


def _start_page():
    align(0x100, 0x100)
    _next.restart_or_quit()


# TODO: find a neater way of packing these things
def emit_kernel_words():
    #### Page
    _start_page()
    # Core stuff
    _next.next3_rom_head()
    _next.next3_ram_rom()
    _next.next3_ram_ram()
    _docol_exit.do_restore_mode()
    _docol_exit.restore_mode()
    _docol_exit.exit()
    _docol_exit.docol_ram_ram()
    _memory.char_at()
    _memory.char_set()
    _arithmetic.increment()
    _arithmetic.decrement()
    _arithmetic.zero_equal()
    _literal.lit_rom_mode()
    _literal.char_lit_rom_mode()
    ####
    _start_page()
    # Stack manipulation words
    _stackmanipulation.drop()
    _stackmanipulation.drop_two()
    _stackmanipulation.swap()
    _stackmanipulation.dup()
    _stackmanipulation.over()
    _stackmanipulation.rot()
    _stackmanipulation.two_swap()
    # No-op thread used for testing DOCOL and EXIT
    # This can probably be removed later
    label("forth.NOP")
    _docol_exit.make_thread()
    from . import _compiler

    _compiler.compile_file("core.f")


__all__ = ["move_ip", "emit_core_words", "emit_entry_page"]
