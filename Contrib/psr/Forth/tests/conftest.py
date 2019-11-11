import pytest

import gtemu


@pytest.fixture
def emulator():
    emulator = gtemu.Emulator()
    yield emulator
    print(emulator.state)
