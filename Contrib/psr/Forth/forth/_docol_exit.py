"""Implementations of DOCOL and EXIT"""
from asm import *

from ._utilities import (
    NEXT,
    REENTER,
    add_cost_of_next,
    add_cost_of_reenter,
)
from .variables import *


def _push_ip_to_return_stack():
    ld([return_stack_pointer])
    C("Y holds the page of the return stack")
    C("Push [IP] to Return stack")
    suba(2)
    st([return_stack_pointer], X)
    ld([IP_lo])
    st([Y, Xpp])
    ld([IP_hi])
    st([Y, X])


cost_of_push_ip_to_return_stack = 7


def _copy_W_to_IP(*, increment_by):
    ld([W_hi])
    C(f"Copy [W] to [IP], incrementing it by {increment_by}")
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
    # TOP-> [restore_mode, mode, IP]
    ld([return_stack_pointer])  # 1
    suba(5)
    st([return_stack_pointer], X)
    st(lo("forth.RESTORE-MODE"), [Y, Xpp])
    st(hi("forth.RESTORE-MODE"), [Y, Xpp])  # 5
    ld([mode])
    st([Y, Xpp])
    ld([IP_lo])
    st([Y, Xpp])
    ld([IP_hi])  # 10
    st([Y, X])
    ld(lo("forth.next3.rom-mode"))
    st([mode])  # 13
    _copy_W_to_IP(increment_by=8)
    NEXT(cost_of_docol_ram)


cost_of_docol_ram = 4 + 13 + cost_of_copy_W_to_IP


def docol_rom_only():
    """Code that should be inlined in each word that is only accessible in ROM mode"""
    adda(-add_cost_of_next(cost_of_docol_rom) / 2)
    ld(hi("forth.DO-DOCOL-ROM"), Y)
    jmp(Y, "forth.DO-DOCOL-ROM")
    ld(return_stack_page, Y)  # 4


cost_of_docol_rom = 4 + cost_of_push_ip_to_return_stack + cost_of_copy_W_to_IP


def docol():
    "Code that should be inlined at the start of each core word"
    adda(-add_cost_of_next(cost_of_docol_ram) / 2)
    ld(hi("forth.DO-DOCOL-RAM"), Y)
    jmp(Y, "forth.DO-DOCOL-RAM")
    ld(return_stack_page, Y)  # 4
    docol_rom_only()  # 4 + 4


def docol_ram_ram():
    """Word that implements DOCOL for a thread in RAM"""
    label("forth.DOCOL")
    adda(-add_cost_of_next(cost_of_docol_ram_ram) / 2)  # 1
    ld(return_stack_page, Y)
    _push_ip_to_return_stack()
    # The Next3 for ram-ram mode leaves the thread address in tmp0, tmp1
    # We need to increment it by two, and store in IP
    ld([tmp0])
    adda(2)
    st([IP_lo])  # 5
    beq(lo(".page-boundary#docol"))  # Page boundary test
    ld([tmp1])  # 7
    st([IP_hi])  # 8
    NEXT(cost_of_docol_ram_ram__page_not_crossed)
    label(".page-boundary#docol")
    adda(1)  # 8
    st([IP_hi])  # 9
    NEXT(cost_of_docol_ram_ram__page_crossed)


cost_of_docol_ram_ram__page_not_crossed = 8 + cost_of_push_ip_to_return_stack
cost_of_docol_ram_ram__page_crossed = 9 + cost_of_push_ip_to_return_stack
cost_of_docol_ram_ram = max(
    cost_of_docol_ram_ram__page_crossed, cost_of_docol_ram_ram__page_not_crossed
)


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
    ld(W, X)
    st(lo("forth.EXIT"), [Y, Xpp])
    st(hi("forth.EXIT"), [Y, Xpp])  # 12
    REENTER(cost_of_do_restore_mode)


cost_of_do_restore_mode = 12


def restore_mode():
    label("forth.RESTORE-MODE")
    # Hand compiled thread with no exit
    st(lo("forth.DO-RESTORE-MODE"), [Y, Xpp])
    jmp(Y, "forth.next3.rom-mode-tail")
    st(hi("forth.DO-RESTORE-MODE"), [Y, Xpp])


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


def make_thread(*words):
    """Build a thread from a sequence of words (using their asm symbols)"""
    docol()
    for word in words:
        st(lo(word), [Y, Xpp])
        jmp(Y, "forth.next3.rom-mode-tail")
        st(hi(word), [Y, Xpp])
    st(lo("forth.EXIT"), [Y, Xpp])
    jmp(Y, "forth.next3.rom-mode-tail")
    st(hi("forth.EXIT"), [Y, Xpp])
