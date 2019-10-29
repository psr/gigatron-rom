#ifdef __cplusplus
extern "C" {
#endif


typedef signed __int8     int8_t;
typedef signed __int16    int16_t;
typedef signed __int32    int32_t;
typedef unsigned __int8   uint8_t;
typedef unsigned __int16  uint16_t;
typedef unsigned __int32  uint32_t;


typedef struct { // TTL state that the CPU controls
  uint16_t PC;
  uint8_t IR, D, AC, X, Y, OUT, undef;
} CpuState;

extern uint8_t ROM[1<<16][2], RAM[1<<15], IN;

extern CpuState cpuCycle(const CpuState S);
extern void garble(uint8_t mem[], int len);
extern int main(int argc, char *argv[]);
#ifdef __cplusplus
}
#endif
