"""Interactive Forth Environment"""
import sys

from . import Interpreter, python_forth_dictionary

# Now provide an interactive Forth based on our re-compiled code

interpreter = Interpreter(python_forth_dictionary, sys.stdin)
interpreter.run(python_forth_dictionary["QUIT"].execution_token)
