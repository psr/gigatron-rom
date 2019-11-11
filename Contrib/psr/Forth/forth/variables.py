# -*- coding: utf-8 -*-
from __future__ import (
    absolute_import,
    division,
    print_function,
    unicode_literals,
)
import json

import pathlib2

import asm


W = W_lo = asm.zpByte(2)
W_hi = W_lo + 1
mode = asm.zpByte()


_interface_file = pathlib2.Path(__file__).parent.parent / "interface.json"


with _interface_file.open() as fp:
    globals().update(json.load(fp))
