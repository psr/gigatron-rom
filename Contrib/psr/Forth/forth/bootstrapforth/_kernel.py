"""Built-in words that are implemented in Python"""
import itertools
import operator

from ._dictionary import Dictionary, Flags
from ._runtime import ExecutionToken, State, ThreadExecutionToken

kernel = dictionary = Dictionary()

kernel.system_variable("STATE", "state")


def _make_unary_operator(name, fn):
    """Build a Forth word (n -- n) by applying a Python operator
    """

    def do_operator(state):
        stack = state.data_stack
        stack.append(fn(stack.pop()))

    kernel.word(name)(do_operator)


_make_unary_operator("NEGATE", operator.neg)
_make_unary_operator("INVERT", operator.invert)
_make_unary_operator("0=", operator.not_)


def _make_binary_operator(name, fn):
    """Build a Forth word (n n -- n) by applying a Python operator
    """

    def do_operator(state):
        stack = state.data_stack
        snd, fst = stack.pop(), stack.pop()
        stack.append(fn(fst, snd))

    kernel.word(name)(do_operator)


_make_binary_operator("+", operator.add)
_make_binary_operator("-", operator.sub)
_make_binary_operator("*", operator.mul)
_make_binary_operator("/", operator.floordiv)
_make_binary_operator("MOD", operator.mod)
_make_binary_operator("=", operator.eq)
_make_binary_operator("<>", operator.ne)
_make_binary_operator("<", operator.lt)
_make_binary_operator(">", operator.gt)
_make_binary_operator("AND", operator.and_)
_make_binary_operator("OR", operator.or_)
_make_binary_operator("XOR", operator.xor)

## Stack manipulation words


@kernel.word()
def DUP(state):
    stack = state.data_stack
    stack.append(stack[-1])


@kernel.word()
def DROP(state):
    state.data_stack.pop()


@kernel.word()
def SWAP(state):
    stack = state.data_stack
    stack.extend([stack.pop(), stack.pop()])


@kernel.word()
def ROT(state):
    stack = state.data_stack
    top, second, third = stack.pop(), stack.pop(), stack.pop()
    stack.extend([second, top, third])


## Return stack words
@kernel.word()
def EXIT(state):
    (state.current_thread, state.thread_index) = state.return_stack.pop()
    if state.trace:
        print("-" * 30)
    state.depth -= 1


# "Special" words which are compiled into threads but have no dictionary entries
# They are used by ':', ';', LITERAL, IF etc.


def docol(state, thread):
    state.return_stack.append((state.current_thread, state.thread_index))
    state.current_thread, state.thread_index = thread, 0
    if state.trace:
        print("-" * 30)
    state.depth += 1


def lit(state, value):
    state.data_stack.append(value)


@kernel.word("BRANCH")
def branch(state, offset):
    state.thread_index += offset


@kernel.word("?BRANCH")
def zero_branch(state, offset):
    if not state.data_stack.pop():
        state.thread_index += offset


@kernel.word("@")
def _get(state):
    getter, setter = state.data_stack.pop()
    state.data_stack.append(getter())


@kernel.word("!")
def _set(state):
    value = state.data_stack.pop()
    getter, setter = state.data_stack.pop()
    setter(value)


@kernel.word()
def HIDDEN(state):
    state.target_dictionary.latest.flags ^= Flags.Hidden


@kernel.word(":")
def _colon(state):
    state.current_definition = definition = []
    _skip_while(state, str.isspace)
    name = _parse(state, str.isspace)
    state.state = State.Compiling
    state.target_dictionary.define(
        name, ThreadExecutionToken(name, docol, definition), flags=Flags.Hidden
    )


@kernel.word("COMPILE,")
def _compile_comma(state):
    state.current_definition.append(state.data_stack.pop())


## Parsing

kernel.system_variable(">IN", "input_buffer_offset")


@kernel.word()
def REFILL(state):
    state.input_buffer = state.input.readline()
    state.input_buffer_offset = 0
    if state.trace:
        print(f" *** Read Line: {state.input_buffer}")
    state.data_stack.append(bool(state.input_buffer))


def _skip_while(state, strip_predicate):
    input = state.input_buffer[state.input_buffer_offset :]
    chars = list(itertools.takewhile(strip_predicate, input))
    state.input_buffer_offset += len(chars)


def _parse(state, delimiter_predicate):
    input = state.input_buffer[state.input_buffer_offset :]
    chars = list(itertools.takewhile(lambda c: not delimiter_predicate(c), input))
    state.input_buffer_offset += len(chars) + 1
    return "".join(chars)


@kernel.word()
def WORD(state):
    _skip_while(state, str.isspace)
    state.data_stack.append(_parse(state, str.isspace))


@kernel.word()
def COUNT(state):
    state.data_stack.append(len(state.data_stack[-1]))


def _find_compilation(state, name):
    """Find a word in compilation mode"""
    for search_dictionary in state.search_dictionaries:
        try:
            entry = search_dictionary[name]
            if not entry.is_immediate:
                state.data_stack.append(entry.execution_token)
                state.data_stack.append(-1)
                return
        except KeyError:
            pass
    # Not found, or found, but immediate
    entry = state.interpreter_dictionary[name]
    if not entry.is_immediate:
        raise KeyError
    # Found immediate in the runtime dictionary
    state.data_stack.append(entry.execution_token)
    state.data_stack.append(1)


def _find_interpretation(state, name):
    entry = state.interpreter_dictionary[name]
    state.data_stack.append(entry.execution_token)
    state.data_stack.append(1 if entry.is_immediate else -1)


@kernel.word()
def FIND(state):
    name = state.data_stack.pop()
    try:
        if state.state is State.Compiling:
            _find_compilation(state, name)
        else:
            _find_interpretation(state, name)
    except KeyError:
        state.data_stack.append(name)
        state.data_stack.append(0)


@kernel.word()
def EXECUTE(state):
    state.data_stack.pop()(state)


@kernel.word()
def NUMBER(state):
    string = state.data_stack.pop()
    state.data_stack.append(int(string, base=state.number_base))


@kernel.word(immediate=True)
def LITERAL(state):
    state.current_definition.append(ExecutionToken("LIT", lit, state.data_stack.pop()))


@kernel.word('."', immediate=True)
def _dot_quote(state):
    text = _parse(state, lambda c: c == '"')
    state.current_definition.append(
        ExecutionToken('."', lambda state, text: print(text, end=""), text)
    )  # Quite hacky


@kernel.word()
def CR(state):
    print()


@kernel.word()
def BYE(state):
    state.current_thread = [EXIT]
    state.thread_index = 0
    state.return_stack = [([], 0)]


@kernel.word(".")
def _d(state):
    print(state.data_stack.pop(), end=" ")


@kernel.word(">MARK")
def _forward_mark(state):
    state.data_stack.append(
        len(state.current_definition) - 1
    )  # Index of BRANCH or ?BRANCH


@kernel.word(">RESOLVE")
def _forward_resolve(state):
    branch_source = state.data_stack.pop()
    branch_target = len(state.current_definition)
    relative_jump = branch_target - branch_source - 1
    xt = state.current_definition[branch_source]
    state.current_definition[branch_source] = ExecutionToken(
        xt._name, xt._code, relative_jump
    )


class _ForwardReference:
    def __init__(self, state, name, word):
        self._location = len(state.current_definition)
        self._word = word
        self._name = name
        state.current_definition.append(None)  # Will be replaced when resolved

    def __repr__(self):
        return f"<Unresolved {self._name}>"

    def resolve(self, state):
        branch_target = len(state.current_definition)
        relative_jump = branch_target - self._location - 1
        state.current_definition[self._location] = ExecutionToken(
            self._name, self._word, relative_jump
        )


# TODO: Remove in favour of high-level versions
@kernel.word(immediate=True)
def IF(state):
    state.data_stack.append(_ForwardReference(state, "0BRANCH", zero_branch))


@kernel.word(immediate=True)
def ELSE(state):
    state.data_stack.append(_ForwardReference(state, "BRANCH", branch))
    SWAP(state)
    state.data_stack.pop().resolve(state)


@kernel.word(immediate=True)
def THEN(state):
    state.data_stack.pop().resolve(state)


@kernel.word(immediate=True)
def BEGIN(state):
    state.data_stack.append(len(state.current_definition))


@kernel.word(immediate=True)
def WHILE(state):
    state.data_stack.append(_ForwardReference(state, "0BRANCH", zero_branch))
    SWAP(state)


@kernel.word(immediate=True)
def REPEAT(state):
    branch_to = state.data_stack.pop()
    current_position = len(state.current_definition) + 1
    relative_jump = branch_to - current_position
    state.current_definition.append(ExecutionToken("BRANCH", branch, relative_jump))
    state.data_stack.pop().resolve(state)


@kernel.word(immediate=True)
def UNTIL(state):
    branch_to = state.data_stack.pop()
    current_position = len(state.current_definition) + 1
    relative_jump = branch_to - current_position
    state.current_definition.append(
        ExecutionToken("0BRANCH", zero_branch, relative_jump)
    )


@kernel.word()
def IMMEDIATE(state):
    state.target_dictionary.latest.flags |= Flags.Immediate


@kernel.word()
def CHAR(state):
    WORD(state)
    word = state.data_stack.pop()
    state.data_stack.append(ord(word[0]))


@kernel.word()
def SOURCE(state):
    state.data_stack.append(
        None
    )  # TODO: Append something that gives access to the buffer
    state.data_stack.append(len(state.input_buffer))


@kernel.word()
def KEY(state):
    # TODO: Out of bounds checking!
    char = state.input_buffer[state.input_buffer_offset : state.input_buffer_offset + 1]
    state.input_buffer_offset += 1
    state.data_stack.append(ord(char))
