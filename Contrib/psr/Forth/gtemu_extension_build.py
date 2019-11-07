from cffi import FFI
ffibuilder = FFI()

ffibuilder.cdef("""
typedef struct { // TTL state that the CPU controls
  uint16_t PC;
  uint8_t IR, D, AC, X, Y, OUT, undef;
} CpuState;
""")
ffibuilder.cdef("""extern uint8_t ROM[1<<16][2], RAM[1<<15], IN=0xff;""")
ffibuilder.cdef("CpuState cpuCycle(const CpuState S);")

ffibuilder.set_source("_gtemu",  # name of the output C extension
"""
#include "gtemu.h"
""",
    sources=["gtemu.cpp"],
    libraries=[])
if __name__ == "__main__":
    ffibuilder.compile(verbose=True)
