"""Compile Forth files into ROM"""
import copy
import json
import pathlib

from asm import C, X, Xpp, Y
from asm import _symbols as asm_symbols
from asm import hi, jmp, label, ld, lo, pc, st

from . import variables
from ._docol_exit import docol, docol_rom_only
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


for symbol, address in asm_symbols.items():
    if symbol.startswith("forth.core"):
        name_parts = symbol.split(".")
        gigatron_forth_dictionary.define(name_parts[-1], symbol)


# Interpreter dictionary, Contains Gigatron specific definitions of various immediate words, on top of python forth words

# Start with the standard dictionary

interpreter_dictionary = copy.copy(python_forth_dictionary)

# Replace COMPILE, and LITERAL - Our interpreter loop needs to use these definitions


@interpreter_dictionary.word("COMPILE,")
def _compile_comma(state):
    """Compile a word"""
    xt = state.data_stack.pop()
    try:
        word_label, address = xt
    except ValueError:
        word_label = address = xt
    st(lo(address), [Y, Xpp])
    C(f"-> {word_label}")
    jmp(Y, "forth.move-ip")
    st(hi(address), [Y, Xpp])


@interpreter_dictionary.word()
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
    interpreter = Interpreter(
        python_forth_dictionary, f, compilation_dictionary=interpreter_dictionary
    )
    interpreter.run(python_forth_dictionary["QUIT"].execution_token)
    quit = interpreter_dictionary["QUIT"].execution_token

# Compile the definitions of various immediate words
with open(pathlib.Path(__file__).parent / "immediates.f") as f:
    interpreter_dictionary.define("EXIT", "forth.core.EXIT")
    interpreter = Interpreter(
        python_forth_dictionary, f, compilation_dictionary=interpreter_dictionary
    )
    interpreter.run(python_forth_dictionary["QUIT"].execution_token)


@interpreter_dictionary.word(":")
def _colon(state):
    """Start a colon definition"""
    state.dictionary["WORD"].execution_token(state)
    name = state.data_stack.pop()
    state.state = State.Compiling
    word_label = _get_label(name)

    # Emit a prefix, and store (word_label, address) in dictionary
    label(word_label)
    address = pc()
    if _is_standard_word(name):
        # We want this thread to be accessible from RAM mode
        docol()
        address += 4  # Always skip first four bytes - avoiding ram-mode entrypoint
    else:
        docol_rom_only()
    state.compilation_dictionary.define(
        name, (word_label, address), flags=DictionaryFlags.Hidden
    )


def compile_file(path):
    with open(pathlib.Path(__file__).parent / path) as f:
        interpreter = Interpreter(
            interpreter_dictionary, f, compilation_dictionary=gigatron_forth_dictionary
        )
        interpreter.run(quit)