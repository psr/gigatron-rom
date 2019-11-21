import pytest

import gtemu


@pytest.fixture
def emulator():
    emulator = gtemu.Emulator()
    emulator.zero_memory()
    yield emulator
    print(emulator.state)
