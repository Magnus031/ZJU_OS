#ifndef __DEFS_H__
#define __DEFS_H__

#include "stdint.h"

// csr_read 宏的用处是 读取 RISC-V 控制状态存储器(CSR)
#define csr_read(csr)                   \
  ({                                    \
    uint64_t __v;                       \
    asm volatile("csrr %0, " #csr       \
                  : "=r" (__v)          \
                  :                     \
                  : "memory");          \
    __v;                                \
  })

// csr_write 宏的作用是 写入RISC-V 控制状态存储器(CSR)
#define csr_write(csr, val)                                    \
  ({                                                           \
    uint64_t __v = (uint64_t)(val);                            \
    asm volatile("csrw " #csr ", %0" : : "r"(__v) : "memory"); \
  })

// Here add the define files
#define PHY_START 0x0000000080000000
#define PHY_SIZE 128 * 1024 * 1024 // 128 MiB，QEMU 默认内存大小
#define PHY_END (PHY_START + PHY_SIZE)

#define PGSIZE 0x1000 // 4 KiB 每个页的大小;
#define PGROUNDUP(addr) ((addr + PGSIZE - 1) & (~(PGSIZE - 1)))
#define PGROUNDDOWN(addr) (addr & (~(PGSIZE - 1)))


// Here add the define files for lab3
#define OPENSBI_SIZE (0x200000)
// here assign the virtual memory address range [VM_START,VM_END]
#define VM_START (0xffffffe000000000)
#define VM_END (0xffffffff00000000)
#define VM_SIZE (VM_END - VM_START)

#define PA2VA_OFFSET (VM_START - PHY_START)

// Here add the define files for lab4
#define USER_START (0x0000000000000000) // user space start virtual address
#define USER_END (0x0000004000000000) // user space end virtual address

// Here add the VMA flags for lab5
#define VM_ANON 0x1 // distinguishi whether it is anonymous;
#define VM_READ 0x2
#define VM_WRITE 0x4
#define VM_EXEC 0x8



#endif
