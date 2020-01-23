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
