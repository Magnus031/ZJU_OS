#include "stdint.h"
#include "sbi.h"

#include "stddef.h"


struct sbiret sbi_ecall(uint64_t eid, uint64_t fid,
                        uint64_t arg0, uint64_t arg1, uint64_t arg2,
                        uint64_t arg3, uint64_t arg4, uint64_t arg5) {
    // 1. We Need to move eid into a7 register, move fid into a6 register, move arg[0-5] into a[0-5];
    // 2. We Need to use ecall to go into M mode; 
    struct sbiret result;
    // mv rd rs;
    asm volatile (
        "mv a7, %[Eid]\n"
        "mv a6, %[Fid]\n"
        "mv a0, %[arg0]\n"
        "mv a1, %[arg1]\n"
        "mv a2, %[arg2]\n"
        "mv a3, %[arg3]\n"
        "mv a4, %[arg4]\n"
        "mv a5, %[arg5]\n"
        // use ecall to goto M mode;
        "ecall\n"
        "mv %[error], a0\n"
        "mv %[value], a1\n"

        // output part;
        : [error] "=r" (result.error), [value] "=r" (result.value)
        // input part;
        : [Eid] "r" (eid),[Fid] "r" (fid), // Task1
          [arg0] "r" (arg0),[arg1] "r" (arg1),
          [arg2] "r" (arg2),[arg3] "r" (arg3),
          [arg4] "r" (arg4),[arg5] "r" (arg5)
        : "memory"
    );
    
    
    return result;
}

struct sbiret sbi_debug_console_write_byte(uint8_t byte) {
    return sbi_ecall(0x4442434E,0x2,(uint64_t)byte,0,0,0,0,0);
}

struct sbiret sbi_system_reset(uint32_t reset_type, uint32_t reset_reason) {
    return sbi_ecall(0x53525354,0x0,(uint64_t)reset_type,(uint64_t)reset_reason,0,0,0,0);
}

struct sbiret sbi_set_timer(uint64_t stime_value){
    return sbi_ecall(0x54494D45,0x0,stime_value,0,0,0,0,0);
}

