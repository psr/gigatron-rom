"""Runtime"""
import enum


class State(enum.IntEnum):
    Interpreting = 0
    Compiling = 1
    Aborted = -1

    def __bool__(self):
        return bool(self.value)


class ExecutionToken:
    """Base class for runable Forth code"""

    def __init__(self, name, code, *operands):
        self._name = name
        self._code = code
        self._operands = operands

    def __call__(self, state):
        self._code(state, *self._operands)

    def __repr__(self):
        return f"< {self._name}{'(' + ', '.join(repr(o) for o in self._operands)  + ')' if self._operands else '' } >"


class ThreadExecutionToken(ExecutionToken):
    def __repr__(self):
        return f"< {self._name} >"


class Interpreter:
    def __init__(self, dictionary, input, compilation_dictionary=None):
        self.data_stack = []
        self.return_stack = []
        self.input = input
        self.dictionary = dictionary
        self.compilation_dictionary = (
            compilation_dictionary if compilation_dictionary is not None else dictionary
        )
        self.latest = None
        self.current_thread = []
        self.thread_index = 0
        self.current_definition = []
        self.state = State.Interpreting
        self.number_base = 10
        self.trace = False
        self.depth = 0

    def __next__(self):
        index = self.thread_index
        self.thread_index += 1
        try:
            return self.current_thread[index]
        except IndexError as e:
            raise StopIteration from e

    def __iter__(self):
        return self

    def run(self, execution_token):
        if self.trace:
            print(
                f"{' ' * self.depth}{self.thread_index}: {self.data_stack!r} Running {execution_token!r}"
            )
        execution_token(self)
        for execution_token in self:
            if self.trace:
                print(
                    f"{' ' * self.depth}{self.thread_index}: {self.data_stack!r} Running {execution_token!r}"
                )
            execution_token(self)

    @property
    def state(self):
        return self._state

    @state.setter
    def state(self, value):
        self._state = State(value)
