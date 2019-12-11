"""Implementations of DOCOL and EXIT"""
from asm import *

from ._utilities import NEXT, add_cost_of_next, REENTER, add_cost_of_reenter
from .variables import *


def _push_ip_to_return_stack():
    ld([return_stack_pointer])
    adda(2)
    st([return_stack_pointer], X)
    ld([IP_lo])
    st([Y, Xpp])
    ld([IP_hi])
    st([Y, X])


cost_to_push_ip_to_returnstack = 7


def _copy_W_to_IP(*, increment_by):
    ld([W_hi])
    st([IP_hi])
    ld([W_lo])
    adda(increment_by)
    st([IP_lo])


cost_of_copy_W_to_IP = 5


def do_docol_rom():
    label("forth.DO-DOCOL-ROM")
    _push_ip_to_return_stack()
    _copy_W_to_IP(increment_by=4)
    NEXT(cost_of_docol_rom)


def do_docol_ram():
    label("forth.DO-DOCOL-RAM")
    # Upon exit from this thread, we need to restore the mode
    # So the return stack needs to look like:
    # TOP-> [restore_mode, mode, old_IP + 2]
    ld([return_stack_pointer])  # 1
    adda(-2)
    st([return_stack_pointer], X)
    st(hi("forth.RESTORE-MODE"), [Y, Xpp])
    st(lo("forth.RESTORE-MODE"), [Y, Xpp])
    ld([mode])
    st([Y, Xpp])
    ld([IP_lo])
    adda(2)
    st([Y, Xpp])
    bne(pc() + 4)
    ld([IP_hi])  # 12
    adda(1)
    st([Y, Xpp])  # 14
    NEXT(4 + 14)
    st([Y, Xpp])  # 13
    NEXT(4 + 13)


cost_of_docol_ram = 4 + 14


def docol_rom_only():
    """Code that should be inlined in each word that is only accessible in ROM mode"""
    suba(-add_cost_of_next(cost_of_docol_rom) / 2)
    ld(hi("forth.DO-DOCOL-ROM"), Y)
    jmp(Y, "forth.DO-DOCOL-ROM")
    ld(return_stack_page, Y)  # 4


cost_of_docol_rom = 4 + cost_to_push_ip_to_returnstack + cost_of_copy_W_to_IP


def docol():
    "Code that should be inlined at the start of each core word"
    suba(-add_cost_of_next(cost_of_docol_ram) / 2)
    ld(hi("forth.DO-DOCOL-ROM"), Y)
    jmp(Y, "forth.DO-DOCOL-ROM")
    ld(return_stack_page, Y)  # 4
    docol_rom_only()  # 4 + 4


def do_restore_mode():
    label("forth.DO-RESTORE-MODE")
    adda(-add_cost_of_reenter(cost_of_do_restore_mode) / 2)
    ld(return_stack_page, Y)
    ld([return_stack_pointer], X)
    ld([return_stack_pointer])
    adda(1)
    st([return_stack_pointer])
    ld([Y, X])
    st([mode])
    ld(0, Y)
    ld([IP_lo], X)
    st(lo("forth.EXIT"), [Y, Xpp])
    st(hi("forth.EXIT"), [Y, Xpp])  # 12
    REENTER(cost_of_do_restore_mode)


cost_of_do_restore_mode = 12


def restore_mode():
    label("forth.RESTORE-MODE")
    # Hand compiled thread with no exit
    st(hi("forth.DO-RESTORE-MODE"), [Y, Xpp])
    jmp(Y, "forth.next3.rom-mode-tail")
    st(lo("forth.DO-RESTORE-MODE"), [Y, Xpp])


def exit():
    """Word to exit from a thread
    """
    label("forth.EXIT")
    adda(-add_cost_of_next(cost_of_exit) / 2)
    ld(return_stack_page, Y)
    ld([return_stack_pointer], X)
    ld([Y, X])
    st([IP_lo])
    ld([return_stack_pointer])
    adda(1, X)
    adda(2)
    st([return_stack_pointer])
    ld([Y, X])
    st([IP_hi])  # 11
    NEXT(cost_of_exit)


cost_of_exit = 11
