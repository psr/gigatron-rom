"""Interactive Forth Environment"""
import copy
import pathlib
import sys

from ._compiler import bootstrap_compiler
from ._dictionary import Flags
from ._kernel import dictionary as kernel_dictionary
from ._runtime import Interpreter

# To bootstrap our Python Forth, we process the following files with the bootstrap compiler
_BOOTSTRAP_BRINGUP_SEQUENCE = ["core1.f", "bootstrap.f"]

# To load a more complete environment we start over again with the following sequence of files

_PYTHON_FORTH_BRINGUP_SEQUENCE = [
    "core1.f",
    "core0.f",
    "bootstrap.f",  # TODO: remove bootstrap.f and use core3.f
]

_GIGATRON_FORTH_BRINGUP_SEQUENCE = [
    "core1.f",  # TODO: The rest!
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

with _get_forth_file("core0.f") as f:
    interpreter = Interpreter(bootstrap_dictionary, f)
    # interpreter.trace = True
    interpreter.run(bootstrap_dictionary["QUIT"].execution_token)


# Just for good measure, lets use the bootstrap interpreter to compile itself
# into a new dictionary.  This proves that we can do this.

python_forth_dictionary = copy.copy(kernel_dictionary)
for file in _PYTHON_FORTH_BRINGUP_SEQUENCE:
    with _get_forth_file(file) as f:
        interpreter = Interpreter(bootstrap_dictionary, f, python_forth_dictionary)
        # interpreter.trace=True
        interpreter.run(bootstrap_dictionary["QUIT"].execution_token)


# Now provide an interactive Forth based on our re-compiled code

interpreter = Interpreter(python_forth_dictionary, sys.stdin)
interpreter.run(python_forth_dictionary["QUIT"].execution_token)
