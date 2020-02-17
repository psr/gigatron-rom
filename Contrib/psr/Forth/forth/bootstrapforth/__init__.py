"""Yet another tiny Forth written in Python

This is intended to be used at ROM assembly time to bootstrap Gigatron forth

This doesn't implement the full Forth language, notably it doesn't have any notion of memory - it's purely a stack machine.
Also it uses 0 for False and 1 for True (or the Python True and False values).

Values on the stack are Python values, there's no cell-size limits.

The threading model is... uuhhh... DTC? STC? Threads are lists of objects called ExecutionTokens. Each Execution token includes a
reference to a Python function and optionally parameters. The ExecutionToken class could easily be a tuple, but I wanted a better repr.

An outer dispatch loop calls the moral equivalent of ```for fn, *args in current_thread: fn(state, *args)``` until we're finished.

Implementation of kernel words is in _kernel.py. Everything else is in various .f files in this directory.

There is a minimal compiler in _compiler.py which is used to process the first two Forth files.

Running this package with python3 -m bootstrapforth brings up an interactive interpreter
"""

import copy
import pathlib

from ._compiler import bootstrap_compiler
from ._dictionary import Dictionary
from ._dictionary import Flags as DictionaryFlags
from ._kernel import dictionary as kernel_dictionary
from ._runtime import Interpreter, State

# To bootstrap our Python Forth, we process the following files with the bootstrap compiler
_BOOTSTRAP_BRINGUP_SEQUENCE = ["core1.f", "bootstrap.f"]

# Adds definitions to the runtime that were provided by the compiler before
_POST_BOOTSTRAP_SEQUENCE = ["core0.f", "../ticks_and_postpone.f", "../control.f"]

# To load a more complete environment we start over again with the following sequence of files

_PYTHON_FORTH_BRINGUP_SEQUENCE = [
    "core1.f",
    "core0.f",
    "../ticks_and_postpone.f",
    "../control.f",
    "bootstrap.f",  # TODO: a more complete environment!
]


_FORTH_ROOT = pathlib.Path(__file__).parent


def _get_forth_file(name):
    return open(_FORTH_ROOT / name, "r")


bootstrap_dictionary = copy.copy(kernel_dictionary)
for file in _BOOTSTRAP_BRINGUP_SEQUENCE:
    with _get_forth_file(file) as f:
        bootstrap_compiler(f, bootstrap_dictionary)

# bootstrap_dictionary now includes a runable QUIT
# which we can run to bring up a new interpreter. However it lacks
# some words such as ['] ; \ ( which are were handled by the compiler before.
# core0.f contains these definitions.

for file in _POST_BOOTSTRAP_SEQUENCE:
    with _get_forth_file(file) as f:
        interpreter = Interpreter(bootstrap_dictionary, f)
        interpreter.run(bootstrap_dictionary["QUIT"].execution_token)


# Just for good measure, lets use the bootstrap interpreter to compile itself
# into a new dictionary.  This proves that we can do this.

python_forth_dictionary = copy.copy(kernel_dictionary)
for file in _PYTHON_FORTH_BRINGUP_SEQUENCE:
    with _get_forth_file(file) as f:
        interpreter = Interpreter(bootstrap_dictionary, f, python_forth_dictionary)
        interpreter.run(bootstrap_dictionary["QUIT"].execution_token)

__all__ = [
    "python_forth_dictionary",
    "Interpreter",
    "State",
    "Dictionary",
    "DictionaryFlags",
]
