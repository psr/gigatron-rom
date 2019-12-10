"""Native code Forth implementation for the Gigatron"""

from ._next import (
    INBOUND_TICK_CORRECTION,
    INTERPRETER_ENTER_PAGE,
    exit,
    next1,
    next1_reenter,
    next2,
    next3_rom_head,
    next3_rom_tail,
    next3_ram_ram,
    next3_ram_rom,
    restart_or_quit,
)

from ._core import *


def emit_core_words():
    drop()
    drop_two()
    swap()
    dup()
    over()
    rot()
    two_swap()
