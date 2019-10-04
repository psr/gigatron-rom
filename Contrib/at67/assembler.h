#ifndef ASSEMBLER_H
#define ASSEMBLER_H

#include <stdint.h>


#define DEFAULT_START_ADDRESS  0x0200
#define DEFAULT_CALL_TABLE     0x007E

#define USER_ROM_ADDRESS  0x0B00 // pictures in ROM v1


namespace Assembler
{
    struct ByteCode
    {
        bool _isRomAddress;
        bool _isCustomAddress;
        uint8_t _data;
        uint16_t _address;
    };


    uint16_t getStartAddress(void);
    int getCurrDasmByteCount(void);
    int getPrevDasmByteCount(void);
    int getDisassembledCodeSize(void);
    std::string* getDisassembledCode(int index);

    void setIncludePath(const std::string& includePath);

    int disassemble(uint16_t address);

    void initialise(void);
    void clearAssembler(void);
    bool getNextAssembledByte(ByteCode& byteCode, bool debug=false);
    bool assemble(const std::string& filename, uint16_t startAddress=DEFAULT_START_ADDRESS);

#ifndef STAND_ALONE
    void printGprintfStrings(void);
#endif
}

#endif