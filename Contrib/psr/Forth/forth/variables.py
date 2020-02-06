import json
import pathlib

import asm

W = W_lo = asm.zpByte(2)
W_hi = W_lo + 1
mode = asm.zpByte()
IP = IP_lo = asm.zpByte(2)
IP_hi = IP_lo + 1

_interface_file = pathlib.Path(__file__).parent.parent / "interface.json"


with _interface_file.open() as fp:
    _interface = json.load(fp)
    globals().update(
        {
            name: int(value, base=0) if not isinstance(value, int) else value
            for name, value in _interface.items()
        }
    )

tmp0 = sysArgs0  # noqa: F821
tmp1 = sysArgs1  # noqa: F821
tmp2 = sysArgs2  # noqa: F821
tmp3 = sysArgs3  # noqa: F821
tmp4 = sysArgs4  # noqa: F821
tmp5 = sysArgs5  # noqa: F821
tmp6 = sysArgs6  # noqa: F821
tmp7 = sysArgs7  # noqa: F821


data_stack_pointer = vSP  # noqa: F821
data_stack_empty = 0x100
data_stack_full = 129
data_stack_page = 0


return_stack_pointer = asm.zpByte()
return_stack_empty = 0x8000
return_stack_full = 0x7FA0
return_stack_page = return_stack_full >> 8
