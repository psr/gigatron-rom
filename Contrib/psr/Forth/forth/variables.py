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


interface_file = pathlib2.Path(__file__).parent.parent / "interface.json"


with interface_file.open() as fp:
    globals().update(json.load(fp))
