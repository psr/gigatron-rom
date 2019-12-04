"""Utilities for generating optimised machine code for stack operations

The Gigatron instruction set doesn't have indexed addressing, making
stack operations relatively expensive - each time we need to access a
stack different memory location we must load the location into X.
Every time we want to move the stack pointer we must do some
arithmetic to find the new value, clobbering the accumulator.

We can save some instructions by being lazy about updating the stack pointer
in memory when we know that it will be updated again later, and we can also
make use of the st [y, x++] instructions when storing several bytes to the
stack.

This module provides a contextmanager and context object which provides a
byte-oriented stack api, and records the operations on the stack, which it
then analyses to try to emit the best instructions possible.

For example:

>>> with data_stack as ds:
...     ds.drop()
...     ds.drop()
...     ds.push_from([tmp1])
...     ds.push_from([tmp0])

looks like it should update the stack pointer in memory four times, but
hand-written code would not update it at all:

ld [sp], x
ld $00, y
ld [tmp0]
st [y, x++]
ld [tmp1]
st [y, x]

Note that some of the instructions are not emitted in the order that they
appear in the Python source. The purpose of this module is to enable this
sort of optimisation.

Whenever the stack pointer is used (for a read or write),
the X register must be loaded with the logical stack pointer and so at this
point we need to emit code to "do" the load, and we get the opportunity to
update the real stack pointer if it is productive to do so.

Our options are:

If the real stack pointer is correct, and it is not productive to update it:

ld [sp], x  # 1

If the real stack pointer is not correct, but it is not productive to update
it:

ld wrongness
adda [sp], x  # 2

If the real stack pointer is not correct, we need its current value now,
and will need it again in future

ld [sp]
adda wrongness
st [sp], x  # 3

The real stack pointer is correct, we need its current value now,
but a different value will be useful to us in the future:

ld [sp]
ld ac, x
adda future_wrongness
st [sp]  # 4

The real stack pointer is not correct, we need an adjusted value now,
and will need a different value in future.

ld [sp]
adda wrongness, x
adda future_wrongness
st [sp]  # 4


Finally there is a case that takes no code - when the previous operation left
the stack pointer in X - this could happen after peeking at the TOS for example

There are variations on some of these, where a given stack location will be
used again, but we don't want to clobber the stack pointer address (perhaps
the total effect of a series of operations is no change in the stack height).
In this case we can use a temporary zero-page location to store intermediate
stack positions - calling code must provide available temporary addresses.

This ends up looking like a mini-compiler, with features like dead-store elimination.
"""
# TODO: currently trying to interveave asm.py calls with these operations will
# result in strange code being emitted. In future we should explicitly check
# for this, and either disallow it, or better still, anaylyse the instructions
# and allow them under certain circumstances. This could be useful for
# operations like this:
#
# with data_stack as ds:
#     ds.pop_to(AC)
#     adda(AC)
#     ds.push(AC)
#
# Could emit
#
# ld [data_stack_pointer], x
# ld [x]
# adda ac
# st [x]
#
# Doubling the byte at the top of the stack. This requires the code to
# recognise that adda ac doesn't branch, and doesn't clobber X (or Y).


from collections import Counter
import dataclasses
import enum
from itertools import groupby, count
import functools
import typing
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


class _Stack_Operations:
    """Class providing stack methods"""
    def __init__(self):
        self._operations = []

    def push_from(self, addr):
        """Decrement stack pointer, and copy a zero-page variable to TOS"""
        self._operations.append(_PushZP(addr))

    def pop_to(self, addr):
        """Copy the TOS to a zero-page variable, and increment the stack pointer"""
        self._operations.append(_PopZP(addr))

    def peek_to(self, addr, offset=0):
        """Copy the TOS to a zero-page address, without moving the stack pointer"""
        assert offset <= 0
        self._operations.append(_PeekZP(addr, offset))

    def drop(self):
        """Increment the stack pointer"""
        self._operations.append(_Drop())


# This is more or less a nano-pass compiler - See the bottom of the file for definitions
# Passes
# 1.  Replace push and pop operations with stack sp movement and read and write stack operations
# 2.  Replace ZP operations with READ and WRITE and MACHINE_CODE operations
# 3.  Remove MOVE_STACK_POINTER operations and instead store each operation with its stack location
# 4.  Identify stores to stack locations that are subsequently read and introduce temporary variables to read instead
# 5.  Discard temps which are populated from zp variables - use the zp variable instead
# 6.  Remove dead stores - which will later be overwritten
# 7.  Group writes to consecutive stack locations, and replace with ordered MACHINECODE st [y, x++], place at end
# 8.  Count usages of different stack locations, and insert LOAD_STACK_LOCATION, COMPUTE_STACK_LOCATION, and where things are needed multiple times, insert WRITE_STACK_LOCATION
# 9.  Append a write stack pointer operation
# 10. Drop LOAD_STACK_LOCATION where value is already in X.
# 11. Pair LOAD_STACK_LOCATION and WRITE_STACK_LOCATION, rewrite COMPUTE_STACK_LOCATION if necessary (stack pointer rewritten)
# 12. Emit code

def _validate_op(op, language):
    assert op in language
    return op

class _Optimiser:
    def __init__(self):
        self._passes = []

    def pass_(self, input_language, output_language):
        """Decorator factory for optimiser passes"""
        def decorator(fn):

            @functools.wraps(fn)
            def wrapper(operations):
                # Just verify the operations are valid in and out
                input_ops = (_validate_op(op, input_language) for op in operations)
                output_ops = iter(fn(input_ops))
                try:
                    yield (op1 := _validate_op(next(output_ops), output_language))
                except StopIteration:
                    return
                for op2 in output_ops:
                    op2 = _validate_op(op2, output_language)
                    if op2.glue is not None:
                        assert op2.glue is op1
                    yield (op1 := op2)
            self._passes.append(wrapper)
            return wrapper

        return decorator

    def optimise(self, input_ops):
        chain = reduce(lambda f, chain: f(chain), self._passes, input_ops)
        yield from chain
_optimiser = _Optimiser




def replace_zp_ops(operations):
    for op in operations:
        if isinstance(op, ):
            yield (new_op := _ReadToAc())
            yield _MachineCode(
                glue=new_op,
                instructions=[(st, (op.address,))],
                touches_x=False,
                touches_y=False,
            )
        if isinstance(op, _WriteToZP):
            new_op = _MachineCode(
                instructions=[(ld, (op.address,))], touches_x=False, touches_y=False
            )
            yield new_op
            yield _WriteAc(glue=new_op)
        else:
            yield op


def replace_stack_move(operations):
    relative_stack_pointer = 0
    for op in operations:
        if isinstance(op, _MoveStackPointer):
            relative_stack_pointer += op.movement
        else:
            yield (relative_stack_pointer, op)

@_optimiser.pass_
def remove_dead_stores_and_introduce_temps(operations):
    locations_written = {}
    buffer = set()  # Preserves insertion order in modern Python
    temp_counter = count()
    replacements = {}
    for sp, op in operations:
        if isinstance(op, _WriteAc):
            if sp in locations_written:
                # Previous write was a dead-write
                previous_write = locations_written.pop(sp)
                buffer.remove((sp, previous_write))
                # If the previous write was glued to another operation, drop that too.
                if previous_write.glue is not None:
                    buffer.remove(previous_write.glue)
            locations_written[sp] = op
        elif isinstance(op, _ReadAc):
            if sp in locations_written:
                # Reading a value we've previously written
                previous_write = locations_written.pop(sp)
        buffer.append((sp, op))
    yield from buffer


# Base classes for Operations

@dataclasses.dataclass(frozen=True)
class _Operation:
    """Base class for all operations"""

    glue: typing.Optional['_Operation'] = None

@dataclasses.dataclass(frozen=True)
class _StackRead(_Operation):
    pass

@dataclasses.dataclass(frozen=True)
class _StackWrite(_Operation):
    pass

@dataclasses.dataclass(frozen=True)
class _ZPOperation(_Operation):
    address: int

@dataclasses.dataclass(frozen=True)
class _StackPointerMovement(_Operation):
    relative_movement: int

@dataclasses.dataclass(frozen=True)
class _WriteAc(_Operation): pass
@dataclasses.dataclass(frozen=True)
class _ReadAc(_Operation): pass


## Initial Language

class _PushZP(_StackWrite, _StackPointerMovement, _ZPOperation): pass
class _PopZP(_StackRead, _StackPointerMovement, _ZPOperation): pass
class _Drop(_StackPointerMovement): pass
class _PeekZP(_StackRead, _ZPOperation):
    offset: int