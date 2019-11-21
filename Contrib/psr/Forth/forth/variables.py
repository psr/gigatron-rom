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
IP = IP_lo = asm.zpByte(2)
IP_hi = IP_lo + 1

_interface_file = pathlib2.Path(__file__).parent.parent / "interface.json"


with _interface_file.open() as fp:
    _interface = json.load(fp)
    globals().update(
        {
            name: int(value, base=0) if not isinstance(value, int) else value
            for name, value in _interface.viewitems()
        }
    )


tmp0 = sysArgs0
tmp1 = sysArgs1
tmp2 = sysArgs2
tmp3 = sysArgs3
tmp4 = sysArgs4
tmp5 = sysArgs5
tmp6 = sysArgs6
tmp7 = sysArgs7
