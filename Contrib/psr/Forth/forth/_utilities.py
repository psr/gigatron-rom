"""Helpers for generating the right code"""

from itertools import groupby
from operator import itemgetter

from asm import (
    AC,
    C,
    Y,
    X,
    Xpp,
    adda,
    hi,
    jmp,
    ld,
    lo,
    st,
)

from . import variables


def next(cycles_so_far):
    """Jump to the next instruction"""
    cost = cycles_so_far + cost_of_next
    if cost % 2 == 0:
        target = "forth.next2.even"
    else:
        target = "forth.next2.odd"
        cost += 1  # We're gaining a nop
    ld(hi("forth.next2"), Y)  # 1
    C("NEXT")
    jmp(Y, lo(target))  # 2
    ld(-(cost / 2))  # 3


NEXT = next
cost_of_next = 3


def add_cost_of_next(cycles_before):
    cost = cycles_before + cost_of_next
    if cost % 2 != 0:
        cost += 1
    return cost


"add_cost_of_reenter"


def reenter(cycles_so_far):
    """Dispatch to the word in W"""
    cost = cycles_so_far + cost_of_reenter
    if cost % 2 == 0:
        target = "forth.next1.reenter.even"
    else:
        target = "forth.next1.reenter.odd"
        cost -= 1  # We're skipping a nop
    ld(hi("forth.next1.reenter"), Y)  # 1
    C("REENTER")
    jmp(Y, lo(target))  # 2
    ld(-cost / 2)  # 3


REENTER = reenter
cost_of_reenter = 3


def add_cost_of_reenter(cycles_before):
    cost = cycles_before + cost_of_reenter
    if cost % 2 != 0:
        cost -= 1
    return cost


_PUSH, _POP, _DROP, _PEEK, _REPLACE = "PUSH", "POP", "DROP", "PEEK", "REPLACE"


class _GigatronStack(object):
    def __init__(self, sp_addr, page):
        self._sp_addr = sp_addr
        self._page = page
        self._operations = None
        self._sp_error = 0

    def __enter__(self):
        assert self._operations is None
        self._operations = []
        self._sp_error = 0
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if (exc_type, exc_val, exc_val) != (None, None, None):
            return False
        operations = self._operations
        self._operations = None
        _do_operations(self._page, self._sp_addr, operations)

    def push_from(self, addr):
        """Decrement stack pointer, and copy a zero-page variable to TOS"""
        self._operations.append((_PUSH, addr))

    def pop_to(self, addr):
        """Copy the TOS to a zero-page variable, and increment the stack pointer"""
        self._operations.append((_POP, addr))

    def peek_to(self, addr):
        """Copy the TOS to a zero-page address, without moving the stack pointer"""
        self._operations.append((_PEEK, addr))

    def drop(self):
        """Increment the stack pointer"""
        self._operations.append((_DROP,))


def _do_operations(stack_page, stack_pointer_address, operations):
    if not operations:
        return

    if stack_page != 0x00:
        ld(stack_page, Y)
        page_in_y = True
    else:
        page_in_y = False

    # In some cases operations will leave the stack pointer in the X register, and that might be useful to know.
    stack_pointer_in_x = False
    # We try to coalesce as many writes to the stack pointer as possible.
    # This variable is the amount to adjust the stack by
    stack_adjustment = 0
    # Do we need to update the stack pointer variable? We don't do it unless we need to
    useful_to_save_stack_pointer = False
    # Buffer of instructions (mostly asm function calls) to emit once we've worked out the appropriate stack adjustment
    # We emit instructions in order, and we want to update the stack pointer when we load it, to avoid loading it twice
    # So until we have worked out the stack adjustment, we can't emit anything.
    _buffer = [_buffered_load_to_x]

    def flush_buffer():
        for op, args in _buffer:
            op(*args)
        del _buffer[:]  # Empty buffer

    def buffer(f, args):
        _buffer.append((f, args))

    def _buffered_load_to_x():
        nonlocal stack_adjustment
        if stack_adjustment:
            ld([stack_pointer_address])
            adda(stack_adjustment)
            if useful_to_save_stack_pointer:
                st([stack_pointer_address], X)
                stack_adjustment = 0
            else:
                ld(AC, X)
        else:
            ld([stack_pointer_address], X)
    
    def load_stack_pointer_to_x():
        nonlocal stack_pointer_in_x, stack_adjustment
        if stack_pointer_in_x:
            return
#        tmp, stack_adjustment = stack_adjustment, 0
        flush_buffer()    
#        stack_adjustment = tmp
        # Now buffer code to load the SP to X
        buffer(_buffered_load_to_x, ())
        stack_pointer_in_x = True

    def do_pop(address):
        """Emit instructions that pop from the stack to zero-page addresses"""
        nonlocal stack_pointer_in_x, page_in_y, stack_adjustment
        load_stack_pointer_to_x()
        if page_in_y:
            buffer(ld, ([Y, X],))
        else:
            assert stack_page == 0x00
            buffer(ld, ([X],))
        buffer(st, ([address],))
        stack_pointer_in_x = False
        stack_adjustment += 1

    def do_drop():
        nonlocal stack_adjustment
        stack_adjustment += 1

    def do_pushes(addresses):
        """Emit instructions that push from zero-page to the stack"""
        nonlocal stack_adjustment, page_in_y, stack_pointer_in_x
        stack_adjustment -= len(addresses)
        load_stack_pointer_to_x()
        if len(addresses) == 1:
            (address,) = addresses
            buffer(ld, ([address],))
            if page_in_y:
                buffer(st, ([Y, X],))
            else:
                assert stack_page == 0x00
                buffer(st, ([X],))
            stack_pointer_in_x = True
        else:
            if not page_in_y:
                buffer(ld, (stack_page, Y))
                page_in_y = True
            for address in reversed(addresses):
                # Fill the stack from low addresses to high with the values
                # popped, in reverse order, so that the last value pushed
                # is a the lowest address
                buffer(ld, ([address],))
                buffer(st, ([Y, Xpp],))
            stack_pointer_in_x = False

    def do_peek(address):
        load_stack_pointer_to_x()
        if page_in_y:
            buffer(ld, ([Y, X],))
        else:
            assert stack_page == 0x00
            buffer(ld, ([X],))
        buffer(st, ([address],))
        stack_pointer_in_x = True

    grouped_ops = groupby(operations, itemgetter(0))
    # grouped ops is an iterable of (op, iterable(args)) pairs
    # - Runs of pushes, pops, drops etc. This makes it easy to coalesce stack adjustments
    # and make good use of the [y, x++] addressing mode, because we know if we're
    # dealing with one or many.

    for op, group in grouped_ops:
        if op == _POP:
            for _, address in group:
                do_pop(address)
        elif op == _PUSH:
            addresses = [a for _, a in group]
            do_pushes(addresses)
        elif op == _DROP:
            for (_,) in group:
                do_drop()
        elif op == _PEEK:
            for _, address in group:
                do_peek(address)
        else:
            raise RuntimeError(f"Unknown operation {op}")

    useful_to_save_stack_pointer = True
    flush_buffer()

    # In the case of drop, we might have set a stack_adjustment
    # without ever buffering code that can update the variable
    if stack_adjustment:
        ld([stack_pointer_address])
        adda(stack_adjustment)
        st([stack_pointer_address])


return_stack = _GigatronStack(
    variables.return_stack_pointer, variables.return_stack_page
)
data_stack = _GigatronStack(variables.data_stack_pointer, variables.data_stack_page)


__all__ = [
    "next",
    "NEXT",
    "reenter",
    "REENTER",
    "add_cost_of_reenter",
    "add_cost_of_next",
]
