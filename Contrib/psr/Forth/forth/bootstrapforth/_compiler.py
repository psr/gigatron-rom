"""A minimal Forth "compiler" which is just sufficient to bring up a full runtime"""

from ._dictionary import Flags
from ._kernel import EXIT, branch, docol, lit, zero_branch
from ._runtime import ExecutionToken, ThreadExecutionToken

# The following bootstrap compiler only understands
# * Colon definitions comprised of lists of other words in the dictionary. The XTs are appended to the thread
# * IMMEDIATE (After a colon definition) - Makes the thread immediate
# * POSTPONE - ignored, all words are treated as non-immediate
# [']
# IF, THEN; IF, ELSE, THEN
# BEGIN, WHILE, REPEAT


def _remove_backslash_comment(line):
    for token in line:
        if token.strip() == "\\":
            return
        yield token


def _remove_paren_comment(tokens):
    skipping_depth = 0
    for token in tokens:
        if token == "(":
            skipping_depth += 1
            continue
        if token == ")":
            skipping_depth -= 1
            continue
        if skipping_depth:
            continue
        yield token


def bootstrap_compiler(input, dictionary):
    # Tokenize

    lines = iter(input)
    tokens_per_line = (_remove_backslash_comment(line.split()) for line in lines)
    tokens = _remove_paren_comment(
        token.strip() for line in tokens_per_line for token in line
    )

    defining = False
    definition = None
    name = None
    control_flow = None

    for token in tokens:
        if not defining and token not in {":", "IMMEDIATE"}:
            raise ValueError(f"Saw {token} outside of colon definition")

        # Colon definitions

        if token == ":":
            defining = True
            name = next(tokens)
            definition = []
            control_flow = []
            continue

        if token == ";":
            assert (
                not control_flow
            ), f"Ended definitition when control flow stack was not empty"
            definition.append(ExecutionToken("EXIT", EXIT))
            defining = False
            dictionary.define(name, ThreadExecutionToken(name, docol, definition))
            continue

        if token == "IMMEDIATE":
            assert not defining
            dictionary.latest.flags |= Flags.Immediate
            continue

        # Control flow words:
        # The basic pattern is that words that branch
        # leave the word that implements the jump behaviour in the definition and leave its
        # index in the control_flow stack.
        # Words that resolve the address work out the relative jump, and replace the
        # jump code with (jump_code, offset)
        # These functions do the thing

        def mark_jump(name, code_word):
            control_flow.append(len(definition))
            definition.append((name, code_word))

        def resolve_branch():
            branch_from_index = control_flow.pop()
            name, code_word = definition[branch_from_index]
            jump_to = len(definition)
            relative_jump = jump_to - branch_from_index - 1
            definition[branch_from_index] = ExecutionToken(
                name, code_word, relative_jump
            )

        def control_flow_swap():
            "SWAP on the control flow stack"
            control_flow[-2:] = control_flow[-1], control_flow[-2]

        if token == "IF":
            mark_jump("0BRANCH", zero_branch)
            continue

        if token == "ELSE":
            mark_jump("BRANCH", branch)
            control_flow_swap()
            resolve_branch()
            continue

        if token == "THEN":
            resolve_branch()
            continue

        if token == "BEGIN":
            # Append index of the next word
            control_flow.append(len(definition))
            continue

        if token == "WHILE":
            mark_jump("0BRANCH", zero_branch)
            control_flow_swap()
            continue

        if token == "REPEAT":
            branch_to = control_flow.pop()
            current_position = len(definition) + 1
            relative_jump = branch_to - current_position
            definition.append(ExecutionToken("BRANCH", branch, relative_jump))
            resolve_branch()
            continue

        ## Handle number literals
        try:
            value = int(token, base=10)
        except ValueError:
            pass
        else:
            definition.append(ExecutionToken("LIT", lit, value))
            continue

        if token == "[']":
            execution_token = dictionary[next(tokens)].execution_token
            definition.append(ExecutionToken("LIT", lit, execution_token))
            continue

        if token == '."':
            parts = []
            word = next(tokens)
            while not word.endswith('"'):
                parts.append(word)
                word = next(tokens)
            parts.append(word[:-1])
            definition.append(
                ExecutionToken(
                    '."', lambda state, text: print(text, end=""), " ".join(parts)
                )
            )
            continue

        if token == "POSTPONE":
            continue

        if token in dictionary:
            definition.append(dictionary[token].execution_token)
            continue

        raise ValueError(f"Did not understand {token}")
