#ifndef __TRAP_H__
#define __TRAP_H__

#include "stdint.h"

/**
 * 因为我们之前处理的trap只需要是timer_interruptions 
 * 但是，我们在现在的时候，需要引入 ecall 
 * 在引入系统调用的时候，我们也需要引入一下一些寄存器的值
 * 
 * 
*/
struct pt_regs{
    /**
      *在查阅手册的时候，我们发现:
      * 在 riscv的系统调用的过程中:
      * 1. a0-a5是作为参数传入;
      * 2. a0,a1 -> used for get the return value of executing the system call;
      * 3. a7 -> store the sytem call number 
    */
    uint64_t zero;
    uint64_t ra;
    uint64_t sp;
    uint64_t gp;
    uint64_t tp;
    uint64_t t0;
    uint64_t t1;
    uint64_t t2;
    uint64_t s0;
    uint64_t s1;
    uint64_t a0;
    uint64_t a1;
    uint64_t a2;
    uint64_t a3;
    uint64_t a4;
    uint64_t a5;
    uint64_t a6;
    uint64_t a7;
    uint64_t s2;
    uint64_t s3;
    uint64_t s4;
    uint64_t s5;
    uint64_t s6;
    uint64_t s7;
    uint64_t s8;
    uint64_t s9;
    uint64_t s10;
    uint64_t s11;
    uint64_t t3;
    uint64_t t4;
    uint64_t t5;
    uint64_t t6;
    uint64_t sepc;
    // we add a new register to store the stval value where happened the page fault exception;
    uint64_t stval;
    uint64_t sscratch;
    uint64_t scause;
};


void trap_handler(uint64_t scause, uint64_t sepc,struct pt_regs *regs);

void do_page_fault(struct pt_regs *regs);

void untrapped_handler(struct pt_regs *regs);

#endif