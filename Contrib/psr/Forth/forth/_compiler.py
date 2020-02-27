"""Compile Forth files into ROM"""
import copy
import functools
import json
import pathlib
import re
from itertools import count

import asm
from asm import X, Xpp, Y
from asm import _symbols as asm_symbols

from . import _start_page, variables
from ._docol_exit import docol_rom_only
from .bootstrapforth import (
    Dictionary,
    DictionaryFlags,
    Interpreter,
    State,
    python_forth_dictionary,
)

# BEGIN MASSIVE HACK
#
# As the cross-compiler processes definitions it calls asm.py
# functions to emit Gigatron instructions.
#
# However we have a rule that threads are not allowed to cross page-
# boundaries, not least because each page that holds (the start of) a Forth
# word must start with the restart-or-quit trampoline.
#
# When the cross-compiler encounters a colon definition, it doesn't know
# how long it will end up being in terms of instructions emitted, and so
# whether it will end up crossing the page. Instead we recognise when we
# have gone too far - and then undo what we have already done.
#
# asm.py doesn't currently offer much support for this (although it might
# be helpful to move some of this machinery in there), and so in the code
# that follows we monkey about with its internal state, in a thoroughly
# unhygenic way.
#
# The net result is that instead of calling the asm.py functions directly,
# we call wrapped versions, which are capable of undoing, and then redoing
# their effect.


# State
_asm_state = None  # Captured state from asm.py
_assembler_call_buffer = []  # [(asm.py function, *args, **kwargs)] for replay
_current_label = None  # Label of the definition we're in


def _capture_asm_state():
    """Grab the internal state of the asm module, and store in _asm_state"""
    global _asm_state
    asm_variables = [
        "_romSize",
        "_maxRomSize",
        "_zpSize",
        "_symbols",
        "_refsL",
        "_refsH",
        "_labels",
        "_comments",
        "_rom0",
        "_rom1",
        "_linenos",
        "_errors",
        "_lineno",
    ]
    _asm_state = {
        variable: copy.copy(getattr(asm, variable)) for variable in asm_variables
    }


def _restore_asm_state():
    """Restore the asm module to however it was"""
    global _asm_state

    for variable, old_value in _asm_state.items():
        setattr(asm, variable, old_value)
    _asm_state = None


def _restart_definition():
    """Restart the current definition on a fresh page

    Restores the asm module internal state to what it was before the start
    of the definition, start a new page, and replay the buffer.
    """
    _restore_asm_state()
    _start_page()

    asm.label(_current_label)
    docol_rom_only()

    for function, args, kwargs in _assembler_call_buffer:
        # If the operation was PC relative, we need to pass it the current pc
        try:
            (arg,) = args
            if callable(arg):
                args = (arg(asm.pc()),)
        except ValueError:
            pass
        function(*args, **kwargs)
    _assembler_call_buffer[:] = []  # Clear
    # Restart capturing
    _capture_asm_state()


def _start_definiton(label):
    """Mark the start of a definition"""
    global _current_label
    _assembler_call_buffer[:] = []  # Clear anything in the buffer
    _current_label = label
    _capture_asm_state()
    asm.label(label)
    docol_rom_only()


def _end_definition():
    """Mark the end of a successful definition"""
    global _asm_state
    _assembler_call_buffer[:] = []  # Clear anything in the buffer
    _asm_state = None  # Forget the captured state


def _wrap_asm_function(function):
    """Given an asm module function, decorate it so that it is replayable

    Returns the wrapped function. Beyond the normal arguments, wrapped
    functions have the capability to take a one argument callable as parameter.
    This will be called with the next address (asm.pc()) as argument, and the
    result passed to the underlying function. However these functions should
    not themselves use wrapped functions - or else they will get called twice
    on replay.

    When wrapped functions are called, they check the current address.
    If it is not a page boundary, they immediately emit the appropriate
    instruction, but also record themselves and their arguments into a list.

    If the call is on a page boundary, they call _restart_definition() before
    calling the underlying definition
    """

    @functools.wraps(function)
    def wrapper(*args, **kwargs):
        if asm.pc() & 0xFF < 0xFF:
            # We haven't run out of space yet - Let's keep going!
            # Record this call for future playback
            _assembler_call_buffer.append((function, args, kwargs))
        else:
            # Oh no - this thread definition crosses a page boundary
            # Restore the asm.py state to what it was before the start
            # of the definition, start a new page, and replay the buffer
            _restart_definition()
        # Now do the operation we were asked to.
        # If the operation is PC relative, we need to pass it the current pc
        try:
            (arg,) = args
            if callable(arg):
                args = (arg(asm.pc()),)
        except ValueError:
            pass
        return function(*args, **kwargs)

    return wrapper


C = _wrap_asm_function(asm.C)
bra = _wrap_asm_function(asm.bra)
hi = _wrap_asm_function(asm.hi)
jmp = _wrap_asm_function(asm.jmp)
label = _wrap_asm_function(asm.label)
ld = _wrap_asm_function(asm.ld)
lo = _wrap_asm_function(asm.lo)
st = _wrap_asm_function(asm.st)


# END MASSIVE HACK.
# BEGIN CODE THAT IS MERELY UGLY AND ILL-CONSIDERED.


_THIS_DIR = pathlib.Path(__file__).parent

with open(_THIS_DIR / "Forth Standard Words.json") as f:
    _ALL_STANDARD_WORDS = json.load(f)


def _is_standard_word(name):
    return name in _ALL_STANDARD_WORDS


def _get_label(name):
    standard_def = _ALL_STANDARD_WORDS.get(name, {})
    word_list = standard_def.get("Word List", "INTERNAL")
    name_parts = ["forth"]
    name_parts.extend(word_list.lower().split())
    name_parts.append(name)
    return ".".join(name_parts)


# Dictionary of words defined in Gigatron Forth

gigatron_forth_dictionary = Dictionary()
ram_dictionary = {}  # Put words that need to be usable from RAM in here.

_standard_word_lists = {word["Word List"] for word in _ALL_STANDARD_WORDS.values()}
_known_prefixes = {
    ".".join(["forth"] + word_list.lower().split() + [])
    for word_list in _standard_word_lists
}
_known_prefixes |= {"forth.internal.", "forth.internal.rom-mode."}
has_standard_prefix_re = re.compile(
    "^" + "|".join(re.escape(prefix) for prefix in _known_prefixes)
)
for symbol, address in asm_symbols.items():
    if has_standard_prefix_re.match(symbol):
        name_parts = symbol.split(".")
        if not name_parts[-2]:
            name = "." + name_parts[-1]
        else:
            name = name_parts[-1]
        gigatron_forth_dictionary.define(name, symbol)
        if _is_standard_word(name):
            ram_dictionary[name] = (symbol,)


# Interpreter dictionary, Contains Gigatron specific definitions of various immediate words, on top of python forth words

# Start with the standard dictionary

interpreter_dictionary = copy.copy(python_forth_dictionary)

# Replace COMPILE, and LITERAL - Our interpreter loop needs to use these definitions


@interpreter_dictionary.word("COMPILE,")
def _compile_comma(state):
    """Compile a word"""
    word_label = state.data_stack.pop()
    st(lo(word_label), [Y, Xpp])
    C(f"-> {word_label}")
    jmp(Y, "forth.move-ip")
    st(hi(word_label), [Y, Xpp])


@interpreter_dictionary.word(immediate=True)
def LITERAL(state):
    value = state.data_stack.pop()
    value_fits_in_byte = 0 <= value < 256
    lit_word = (
        "forth.internal.LIT" if not value_fits_in_byte else "forth.internal.C-LIT"
    )
    # Encode lit_word
    st(lo(lit_word), [Y, Xpp])
    C(f"-> {lit_word}")
    jmp(Y, "forth.move-ip")
    st(hi(lit_word), [Y, Xpp])
    # Encode value
    st(value & 0xFF, [Y, Xpp])
    C(f"{value}")
    if not value_fits_in_byte:
        st(value >> 8, [Y, Xpp])
    ld(variables.W, X)
    C("X <- W")


# Recompile QUIT into the interpreter_dictionary
with open(pathlib.Path(__file__).parent / "bootstrapforth" / "bootstrap.f") as f:
    interpreter = Interpreter(interpreter_dictionary, f)
    interpreter.run(python_forth_dictionary["QUIT"].execution_token)
    quit = interpreter_dictionary["QUIT"].execution_token

# Recompile some compiling words into the interpreter_dictionary
with open(pathlib.Path(__file__).parent / "ticks_and_postpone.f") as f:
    interpreter = Interpreter(
        python_forth_dictionary, f, target_dictionary=interpreter_dictionary
    )
    interpreter.run(python_forth_dictionary["QUIT"].execution_token)


_labels = (".thread_label#" + str(i) for i in count())


@interpreter_dictionary.word(">MARK")
def forward_mark(state):
    """Compile the source of a forward branch"""
    target_label = next(_labels)
    state.data_stack.append(target_label)
    bra(target_label)
    # Complicated because the expression needs to work twice!
    # What we want to calculate is the relative movement to the target label
    # If this code was definitely going to end up where pc() says it will,
    # we could say
    #    ld(lo(target_label) - pc() + 4)
    # At runtime ld gets a parameter of -pc() + 3, as lo() evaluates to 0.
    # When the label gets resolved later, the address gets added on.
    # However the call might get used twice, with pc() no longer equal to what we thought.
    #
    # The function wrapper above supports using a function of a single argument
    # which will be called with pc as parameter, so we can do roughly the same thing.
    # We have to use the unwrapped version of lo()
    ld(lambda pc: asm.lo(target_label) - pc + 4)


@interpreter_dictionary.word(">RESOLVE")
def forward_resolve(state):
    """Mark the target of a forward branch"""
    target_label = state.data_stack.pop()
    label(target_label)


@interpreter_dictionary.word("<MARK")
def backward_mark(state):
    """Mark the destination for a backward branch"""
    target_label = next(_labels)
    state.data_stack.append(target_label)
    label(target_label)


@interpreter_dictionary.word("<RESOLVE")
def backward_resolve(state):
    """Compile the tharget for a backward branch"""
    target_label = state.data_stack.pop()
    state.data_stack.append(target_label)
    bra(target_label)
    ld(lambda pc: asm.lo(target_label) - pc + 4)


# Compile the definitions of various compiling words.
# Use Gigatron dictionary as the first search dictionary (so that it can find e.g. EXIT),
# but put definitions in the interpreter_dictionary
with open(pathlib.Path(__file__).parent / "control.f") as f:
    interpreter = Interpreter(
        interpreter_dictionary,
        f,
        target_dictionary=interpreter_dictionary,
        search_dictionaries=[gigatron_forth_dictionary, interpreter_dictionary],
    )
    interpreter.run(python_forth_dictionary["QUIT"].execution_token)


@interpreter_dictionary.word(":")
def _colon(state):
    """Start a colon definition"""
    _end_definition()  # If we were already in one
    state.interpreter_dictionary["WORD"].execution_token(state)
    name = state.data_stack.pop()
    state.state = State.Compiling
    word_label = _get_label(name)

    # Emit a prefix, and store (word_label, address) in dictionary
    _start_definiton(word_label)
    if _is_standard_word(name):
        # This is a standard word, and needs to be available to the user.
        # Add an entry to the dictionary that we will eventually copy into RAM.
        # The eventual address will be the label of the word + 4
        ram_dictionary[name] = ("forth.DOCOL", (word_label, 4))
    state.target_dictionary.define(name, word_label, flags=DictionaryFlags.Hidden)


def compile_file(path):
    with open(pathlib.Path(__file__).parent / path) as f:
        interpreter = Interpreter(
            interpreter_dictionary, f, target_dictionary=gigatron_forth_dictionary
        )
        interpreter.run(quit)
        _end_definition()
