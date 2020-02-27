"""Compile Forth files into ROM"""
import copy
import json
import pathlib
import re
from itertools import count

from asm import C, X, Xpp, Y
from asm import _symbols as asm_symbols
from asm import bra, hi, jmp, label, ld, lo, pc, st

from . import variables
from ._docol_exit import docol_rom_only
from .bootstrapforth import (
    Dictionary,
    DictionaryFlags,
    Interpreter,
    State,
    python_forth_dictionary,
)

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
    ld(lo(target_label) - pc() + 4)


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
    ld(lo(target_label) - pc() + 4)


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
    state.interpreter_dictionary["WORD"].execution_token(state)
    name = state.data_stack.pop()
    state.state = State.Compiling
    word_label = _get_label(name)

    # Emit a prefix, and store (word_label, address) in dictionary
    label(word_label)
    address = pc()
    docol_rom_only()
    if _is_standard_word(name):
        # This is a standard word, and needs to be available to the user.
        # Add an entry to the dictionary that we will eventually copy into RAM.
        ram_dictionary[name] = ("forth.DOCOL", address + 4)
    state.target_dictionary.define(name, word_label, flags=DictionaryFlags.Hidden)


def compile_file(path):
    with open(pathlib.Path(__file__).parent / path) as f:
        interpreter = Interpreter(
            interpreter_dictionary, f, target_dictionary=gigatron_forth_dictionary
        )
        interpreter.run(quit)
