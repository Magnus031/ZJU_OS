    .extern trap_handler
    .section .text.entry
    .align 2
    .globl _traps 
    .globl __dummy
    .globl __switch_to

_traps:
    # 在进入 _traps 的时候，也就是我们在进入内核态;
    # sp 指向的是 内核态栈的指针
    # sscratch 指向的是 用户态的sp;
    csrrw sp, sscratch,sp
    bnez sp, 1f
    csrrw sp, sscratch, sp
1: 
    # 移动sp指针 8*33
    addi sp, sp, -288
    # save 32 registers and sepc to stack
    sd x0, 0(sp)
    sd x1, 8(sp)
    sd x2, 16(sp)
    sd x3, 24(sp)
    sd x4, 32(sp)
    sd x5, 40(sp)
    sd x6, 48(sp)
    sd x7, 56(sp)
    sd x8, 64(sp)
    sd x9, 72(sp)
    sd x10, 80(sp)
    sd x11, 88(sp)
    sd x12, 96(sp)
    sd x13, 104(sp)
    sd x14, 112(sp)
    sd x15, 120(sp)
    sd x16, 128(sp)
    sd x17, 136(sp)
    sd x18, 144(sp)
    sd x19, 152(sp)
    sd x20, 160(sp)
    sd x21, 168(sp)
    sd x22, 176(sp)
    sd x23, 184(sp)
    sd x24, 192(sp)
    sd x25, 200(sp)
    sd x26, 208(sp)
    sd x27, 216(sp)
    sd x28, 224(sp)
    sd x29, 232(sp)
    sd x30, 240(sp)
    sd x31, 248(sp)

    # read from sepc register; (sepc == Supervisor Exception Program Counter)
    csrr t0 ,sepc # 存当前PC的值至a0;
    sd t0, 256(sp)

    # we also need to store the stval register to store the VA where happened the exception;
    csrr t0, stval 
    sd t0, 264(sp) 

    csrr t0, sscratch
    sd t0, 272(sp)

    csrr t0,scause
    sd t0,280(sp)

    # call trap_handler 
    # 获取当前的sepc 和scause的内容

    csrr a0 , scause
    csrr a1 , sepc 
    addi a2 , sp, 0
    call trap_handler 

    # update in the Lab5 
    # we can assume that the child process's return address 
    # can be the same as parent process;
    # do_fork->do_syscall->trap_handlers->_traps->uapp;
    # so when the child process is been sheduled,it will return to this part;

    .globl __ret_from_fork
__ret_from_fork:

    ld t0,280(sp)
    csrw scause,t0

    ld t0, 272(sp)
    csrw sscratch , t0

    ld t0, 264(sp)
    csrw stval, t0

    # restore sepc and 32 registers (x2(sp) should be restore last) from stack
    ld t0, 256(sp)
    csrw sepc, t0 

    ld x31, 248(sp)
    ld x30, 240(sp)
    ld x29, 232(sp)
    ld x28, 224(sp)
    ld x27, 216(sp)
    ld x26, 208(sp)
    ld x25, 200(sp)    
    ld x24, 192(sp)
    ld x23, 184(sp)    
    ld x22, 176(sp)
    ld x21, 168(sp)
    ld x20, 160(sp)
    ld x19, 152(sp)
    ld x18, 144(sp)
    ld x17, 136(sp)
    ld x16, 128(sp)
    ld x15, 120(sp)
    ld x14, 112(sp)
    ld x13, 104(sp)
    ld x12, 96(sp)
    ld x11, 88(sp)
    ld x10, 80(sp)
    ld x9, 72(sp)
    ld x8, 64(sp)
    ld x7, 56(sp)
    ld x6, 48(sp)
    ld x5, 40(sp)
    ld x4, 32(sp)
    ld x3, 24(sp)
    ld x1, 8(sp)
    ld x0, 0(sp)
    ld x2, 16(sp)
    addi sp,sp,280

    csrrw sp,sscratch,sp
    bnez sp, 2f
    csrrw sp, sscratch, sp
 2: 
     # return from trap, 我们利用sret指令返回到我们之前重新设置回到的sepc地址。
    sret 

    



__dummy:
    # exchange the stack from the user to the kernel
    csrrw sp, sscratch,sp
    sret 


__switch_to:
    # save state to prev process
    # YOUR CODE HERE
    addi t0, a0, 32
    sd ra, 0(t0)
    sd sp, 8(t0)
    sd s0, 16(t0)
    sd s1, 24(t0)
    sd s2, 32(t0)
    sd s3, 40(t0)
    sd s4, 48(t0)
    sd s5, 56(t0)
    sd s6, 64(t0)
    sd s7, 72(t0)
    sd s8, 80(t0)
    sd s9, 88(t0)
    sd s10, 96(t0)
    sd s11, 104(t0)
    # store for the sepc 
    csrr t1, sepc 
    sd   t1, 112(t0)

    csrr t1, sstatus
    sd   t1, 120(t0)

    csrr t1, sscratch 
    sd   t1, 128(t0)


    # restore state from next process
    # YOUR CODE HERE
    addi t1, a1, 32
    ld ra, 0(t1)
    ld sp, 8(t1)
    ld s0, 16(t1)
    ld s1, 24(t1)
    ld s2, 32(t1)
    ld s3, 40(t1)
    ld s4, 48(t1)
    ld s5, 56(t1)
    ld s6, 64(t1)
    ld s7, 72(t1)
    ld s8, 80(t1)
    ld s9, 88(t1)
    ld s10, 96(t1)
    ld s11, 104(t1)
    
    ld t2, 112(t1)
    csrw sepc , t2

    ld t2, 120(t1)
    csrw sstatus , t2

    ld t2, 128(t1)
    csrw sscratch, t2

    # finish the logical of exchange the page_table;
    # the purpose is to get the physial address of the root page table;
    # in the struct, before the page_table address -> 21 * 8 = 168; 
    # we need to change the satp register to which __switch_to(a0,a1)-> the next task_struct
    addi a1,a1,168
    ld t0, 0(a1)
    li t1, 0xffffffdf80000000
    # change the VA to PA 
    sub t0, t0, t1 
    srl t0, t0, 12

    # set for the satp sv39 3-level every PTE is 9 bit the mode is 0x8.
    li t1 , 0x8000000000000000
    or t0, t0, t1
    csrw satp, t0


    # flush the TLB
    sfence.vma zero, zero 
    

    ret