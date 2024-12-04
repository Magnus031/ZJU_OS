#ifndef __SYSCALL_H__
#define __SYSCALL_H__

#include "stddef.h"
#include "trap.h"

#define SYS_WRITE   64
#define SYS_GETPID  172
#define STDOUT 1

long write(unsigned int fd,const char* buf,size_t count);

long get_pid();

long do_fork(struct pt_regs* regs);


long do_cow_fork(struct pt_regs* regs);
uint64_t checkValid(uint64_t address,uint64_t* pgd);

#endif