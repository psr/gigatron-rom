"""Dictionary implementation"""

import collections.abc
import enum
import functools

from ._runtime import ExecutionToken

# The dictionary is a Python dict with word names as keys and DictionaryEntry values as values
# The DictionaryEntry values form a singly linked list


class Flags(enum.Flag):
    Immediate = enum.auto()
    Hidden = enum.auto()


class Dictionary(collections.abc.Mapping):
    def __init__(self):
        self._dict = {}
        self._latest = None

    @property
    def latest(self):
        return self._latest

    def __getitem__(self, name):
        entry = self._dict.get(name, None)
        while entry is not None and entry.flags & Flags.Hidden:
            entry = entry.replaces
        if entry is None:
            raise KeyError
        return entry

    def __len__(self):
        return len(self._dict)

    def __copy__(self):
        new = Dictionary()
        new._dict = self._dict.copy()
        new._latest = self.latest
        return new

    def _iter(self, sentinal):
        """Returns an iterator of entries in reverse addition order"""
        _current = self._latest

        def _next_entry():
            nonlocal _current
            result = _current
            if _current is not None:
                _current = _current.next
            return result

        return iter(_next_entry, sentinal)

    def __iter__(self):
        """Iterate the names in reverse addition order"""
        return (e.name for e in self._iter(None))  # Stop at the end of the list

    def define(self, name, execution_token, flags=Flags(0)):
        """Add an entry to the dictionary"""
        replaces = self.get(name, None)
        entry = _DictionaryEntry(
            name, execution_token, flags, next=self._latest, replaces=replaces
        )
        self._dict[name] = entry
        self._latest = entry
        return entry

    def forget_to(self, stop_at):
        """Remove entries more recent than entry from the dictionary"""
        for entry in self._iter(stop_at):  # Stop when we reach entry
            old_value = entry.replaces
            if old_value is None:
                del self._dict[name]
            else:
                self._dict[name] = old_value
        self._latest = stop_at

    def word(self, name=None, immediate=False):
        """Decorator factory to add words to this dictionary

        use as:

        >>> @dict.word()
        ... def WORD(state):
        ...     ...
        """

        def decorator(fn):
            nonlocal name
            if name is None:
                name = fn.__name__.lstrip("_")
            flags = Flags.Immediate if immediate else Flags(0)
            execution_token = ExecutionToken(name, fn)
            self.define(name, execution_token, flags)
            return execution_token

        return decorator

    def system_variable(self, name, attribute):
        self.define(name, ExecutionToken(name, _get_system_variable, attribute))


class _DictionaryEntry:
    """Singly linked list"""

    def __init__(self, name, execution_token, flags, *, next, replaces):
        self.name = name
        self.execution_token = execution_token
        self.flags = flags
        self.next = next
        self.replaces = replaces

    @property
    def is_immediate(self):
        return bool(self.flags & Flags.Immediate)


def _get_system_variable(state, name):
    state.data_stack.append(
        (lambda: getattr(state, name), lambda value: setattr(state, name, value))
    )
