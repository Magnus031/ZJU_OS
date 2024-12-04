
../../vmlinux:     file format elf64-littleriscv


Disassembly of section .text:

ffffffe000200000 <_skernel>:
_start:
    # ------------------
    # - your code here -
    # ------------------
    # 将 CPU 的 Program Counter 移动到内存中 bootloader 的起始地址
    la sp , boot_stack_top
ffffffe000200000:	0000b117          	auipc	sp,0xb
ffffffe000200004:	00010113          	mv	sp,sp

    # set for the virtual memory
    call setup_vm
ffffffe000200008:	458030ef          	jal	ffffffe000203460 <setup_vm>
    call relocate
ffffffe00020000c:	040000ef          	jal	ffffffe00020004c <relocate>

    # 调用 mm_init 函数来初始化内存管理系统;
    call mm_init
ffffffe000200010:	371000ef          	jal	ffffffe000200b80 <mm_init>
    # 分配最终的虚拟地址
    call setup_vm_final
ffffffe000200014:	570030ef          	jal	ffffffe000203584 <setup_vm_final>
    call task_init
ffffffe000200018:	284010ef          	jal	ffffffe00020129c <task_init>

    # (previous) initialize stack 初始化栈
    # set stvec = _trap 开始处理_trap部分 存入发生_trap的状态信息
    la t0 , _traps 
ffffffe00020001c:	00000297          	auipc	t0,0x0
ffffffe000200020:	06428293          	addi	t0,t0,100 # ffffffe000200080 <_traps>
    csrw stvec , t0
ffffffe000200024:	10529073          	csrw	stvec,t0

    # set sie[STIE] = 1 说明可以进行响应对应的中断状态
    li t0, 0x20
ffffffe000200028:	02000293          	li	t0,32
    csrs sie,t0
ffffffe00020002c:	1042a073          	csrs	sie,t0

    # 设置第一次时钟中断
    rdtime a0
ffffffe000200030:	c0102573          	rdtime	a0
    li t1 , 10000000
ffffffe000200034:	00989337          	lui	t1,0x989
ffffffe000200038:	6803031b          	addiw	t1,t1,1664 # 989680 <OPENSBI_SIZE+0x789680>
    add a0, a0, t1 
ffffffe00020003c:	00650533          	add	a0,a0,t1
    # call sbi_set_timer(a0) a0 表示的是我们需要设置中断的时间
    call sbi_set_timer
ffffffe000200040:	769010ef          	jal	ffffffe000201fa8 <sbi_set_timer>
    # li t0, 0x2
    # csrs sstatus, t0

    # call start_kernel
    # 跳转到 start_kernel 函数 
    jal start_kernel 
ffffffe000200044:	291030ef          	jal	ffffffe000203ad4 <start_kernel>
    # 进行循环直到start_kernel停机返回
    j .
ffffffe000200048:	0000006f          	j	ffffffe000200048 <_skernel+0x48>

ffffffe00020004c <relocate>:
    ###################### 
    #   YOUR CODE HERE   #
    ######################

    # set for the PA2VA_OFFSET = VM_START - PHY_START;
    li t1, 0xffffffdf80000000
ffffffe00020004c:	fbf0031b          	addiw	t1,zero,-65
ffffffe000200050:	01f31313          	slli	t1,t1,0x1f

    add ra,ra,t1
ffffffe000200054:	006080b3          	add	ra,ra,t1
    add sp,sp,t1
ffffffe000200058:	00610133          	add	sp,sp,t1
    # everytime we change the page table we all need to flush the TLB cache;
    # otherwise, it will use the old mapping in the TLB cache 
    # especially, nowtime we have nooooot set the ASID correctly
    # it will cause some awful influences;
    
    sfence.vma zero, zero
ffffffe00020005c:	12000073          	sfence.vma
    # 1. Mode 0111 sv39
    # 2. ASID defualt -> 0000000
    # 3. PPN from the early_ptb
    # satp pointer to the first page table

    la t2, early_pgtbl
ffffffe000200060:	0000c397          	auipc	t2,0xc
ffffffe000200064:	fa038393          	addi	t2,t2,-96 # ffffffe00020c000 <early_pgtbl>
    srl t2, t2, 12
ffffffe000200068:	00c3d393          	srli	t2,t2,0xc
    li  t3, 0x8000000000000000
ffffffe00020006c:	fff00e1b          	addiw	t3,zero,-1
ffffffe000200070:	03fe1e13          	slli	t3,t3,0x3f
    or  t2, t2, t3
ffffffe000200074:	01c3e3b3          	or	t2,t2,t3
    csrw satp, t2
ffffffe000200078:	18039073          	csrw	satp,t2

    ret
ffffffe00020007c:	00008067          	ret

ffffffe000200080 <_traps>:

_traps:
    # 在进入 _traps 的时候，也就是我们在进入内核态;
    # sp 指向的是 内核态栈的指针
    # sscratch 指向的是 用户态的sp;
    csrrw sp, sscratch,sp
ffffffe000200080:	14011173          	csrrw	sp,sscratch,sp
    bnez sp, 1f
ffffffe000200084:	00011463          	bnez	sp,ffffffe00020008c <_traps+0xc>
    csrrw sp, sscratch, sp
ffffffe000200088:	14011173          	csrrw	sp,sscratch,sp
1: 
    # 移动sp指针 8*33
    addi sp, sp, -288
ffffffe00020008c:	ee010113          	addi	sp,sp,-288 # ffffffe00020aee0 <_sbss+0xee0>
    # save 32 registers and sepc to stack
    sd x0, 0(sp)
ffffffe000200090:	00013023          	sd	zero,0(sp)
    sd x1, 8(sp)
ffffffe000200094:	00113423          	sd	ra,8(sp)
    sd x2, 16(sp)
ffffffe000200098:	00213823          	sd	sp,16(sp)
    sd x3, 24(sp)
ffffffe00020009c:	00313c23          	sd	gp,24(sp)
    sd x4, 32(sp)
ffffffe0002000a0:	02413023          	sd	tp,32(sp)
    sd x5, 40(sp)
ffffffe0002000a4:	02513423          	sd	t0,40(sp)
    sd x6, 48(sp)
ffffffe0002000a8:	02613823          	sd	t1,48(sp)
    sd x7, 56(sp)
ffffffe0002000ac:	02713c23          	sd	t2,56(sp)
    sd x8, 64(sp)
ffffffe0002000b0:	04813023          	sd	s0,64(sp)
    sd x9, 72(sp)
ffffffe0002000b4:	04913423          	sd	s1,72(sp)
    sd x10, 80(sp)
ffffffe0002000b8:	04a13823          	sd	a0,80(sp)
    sd x11, 88(sp)
ffffffe0002000bc:	04b13c23          	sd	a1,88(sp)
    sd x12, 96(sp)
ffffffe0002000c0:	06c13023          	sd	a2,96(sp)
    sd x13, 104(sp)
ffffffe0002000c4:	06d13423          	sd	a3,104(sp)
    sd x14, 112(sp)
ffffffe0002000c8:	06e13823          	sd	a4,112(sp)
    sd x15, 120(sp)
ffffffe0002000cc:	06f13c23          	sd	a5,120(sp)
    sd x16, 128(sp)
ffffffe0002000d0:	09013023          	sd	a6,128(sp)
    sd x17, 136(sp)
ffffffe0002000d4:	09113423          	sd	a7,136(sp)
    sd x18, 144(sp)
ffffffe0002000d8:	09213823          	sd	s2,144(sp)
    sd x19, 152(sp)
ffffffe0002000dc:	09313c23          	sd	s3,152(sp)
    sd x20, 160(sp)
ffffffe0002000e0:	0b413023          	sd	s4,160(sp)
    sd x21, 168(sp)
ffffffe0002000e4:	0b513423          	sd	s5,168(sp)
    sd x22, 176(sp)
ffffffe0002000e8:	0b613823          	sd	s6,176(sp)
    sd x23, 184(sp)
ffffffe0002000ec:	0b713c23          	sd	s7,184(sp)
    sd x24, 192(sp)
ffffffe0002000f0:	0d813023          	sd	s8,192(sp)
    sd x25, 200(sp)
ffffffe0002000f4:	0d913423          	sd	s9,200(sp)
    sd x26, 208(sp)
ffffffe0002000f8:	0da13823          	sd	s10,208(sp)
    sd x27, 216(sp)
ffffffe0002000fc:	0db13c23          	sd	s11,216(sp)
    sd x28, 224(sp)
ffffffe000200100:	0fc13023          	sd	t3,224(sp)
    sd x29, 232(sp)
ffffffe000200104:	0fd13423          	sd	t4,232(sp)
    sd x30, 240(sp)
ffffffe000200108:	0fe13823          	sd	t5,240(sp)
    sd x31, 248(sp)
ffffffe00020010c:	0ff13c23          	sd	t6,248(sp)

    # read from sepc register; (sepc == Supervisor Exception Program Counter)
    csrr t0 ,sepc # 存当前PC的值至a0;
ffffffe000200110:	141022f3          	csrr	t0,sepc
    sd t0, 256(sp)
ffffffe000200114:	10513023          	sd	t0,256(sp)

    # we also need to store the stval register to store the VA where happened the exception;
    csrr t0, stval 
ffffffe000200118:	143022f3          	csrr	t0,stval
    sd t0, 264(sp) 
ffffffe00020011c:	10513423          	sd	t0,264(sp)

    csrr t0, sscratch
ffffffe000200120:	140022f3          	csrr	t0,sscratch
    sd t0, 272(sp)
ffffffe000200124:	10513823          	sd	t0,272(sp)

    csrr t0,scause
ffffffe000200128:	142022f3          	csrr	t0,scause
    sd t0,280(sp)
ffffffe00020012c:	10513c23          	sd	t0,280(sp)

    # call trap_handler 
    # 获取当前的sepc 和scause的内容

    csrr a0 , scause
ffffffe000200130:	14202573          	csrr	a0,scause
    csrr a1 , sepc 
ffffffe000200134:	141025f3          	csrr	a1,sepc
    addi a2 , sp, 0
ffffffe000200138:	00010613          	mv	a2,sp
    call trap_handler 
ffffffe00020013c:	19d020ef          	jal	ffffffe000202ad8 <trap_handler>

ffffffe000200140 <__ret_from_fork>:
    # so when the child process is been sheduled,it will return to this part;

    .globl __ret_from_fork
__ret_from_fork:

    ld t0,280(sp)
ffffffe000200140:	11813283          	ld	t0,280(sp)
    csrw scause,t0
ffffffe000200144:	14229073          	csrw	scause,t0

    ld t0, 272(sp)
ffffffe000200148:	11013283          	ld	t0,272(sp)
    csrw sscratch , t0
ffffffe00020014c:	14029073          	csrw	sscratch,t0

    ld t0, 264(sp)
ffffffe000200150:	10813283          	ld	t0,264(sp)
    csrw stval, t0
ffffffe000200154:	14329073          	csrw	stval,t0

    # restore sepc and 32 registers (x2(sp) should be restore last) from stack
    ld t0, 256(sp)
ffffffe000200158:	10013283          	ld	t0,256(sp)
    csrw sepc, t0 
ffffffe00020015c:	14129073          	csrw	sepc,t0

    ld x31, 248(sp)
ffffffe000200160:	0f813f83          	ld	t6,248(sp)
    ld x30, 240(sp)
ffffffe000200164:	0f013f03          	ld	t5,240(sp)
    ld x29, 232(sp)
ffffffe000200168:	0e813e83          	ld	t4,232(sp)
    ld x28, 224(sp)
ffffffe00020016c:	0e013e03          	ld	t3,224(sp)
    ld x27, 216(sp)
ffffffe000200170:	0d813d83          	ld	s11,216(sp)
    ld x26, 208(sp)
ffffffe000200174:	0d013d03          	ld	s10,208(sp)
    ld x25, 200(sp)    
ffffffe000200178:	0c813c83          	ld	s9,200(sp)
    ld x24, 192(sp)
ffffffe00020017c:	0c013c03          	ld	s8,192(sp)
    ld x23, 184(sp)    
ffffffe000200180:	0b813b83          	ld	s7,184(sp)
    ld x22, 176(sp)
ffffffe000200184:	0b013b03          	ld	s6,176(sp)
    ld x21, 168(sp)
ffffffe000200188:	0a813a83          	ld	s5,168(sp)
    ld x20, 160(sp)
ffffffe00020018c:	0a013a03          	ld	s4,160(sp)
    ld x19, 152(sp)
ffffffe000200190:	09813983          	ld	s3,152(sp)
    ld x18, 144(sp)
ffffffe000200194:	09013903          	ld	s2,144(sp)
    ld x17, 136(sp)
ffffffe000200198:	08813883          	ld	a7,136(sp)
    ld x16, 128(sp)
ffffffe00020019c:	08013803          	ld	a6,128(sp)
    ld x15, 120(sp)
ffffffe0002001a0:	07813783          	ld	a5,120(sp)
    ld x14, 112(sp)
ffffffe0002001a4:	07013703          	ld	a4,112(sp)
    ld x13, 104(sp)
ffffffe0002001a8:	06813683          	ld	a3,104(sp)
    ld x12, 96(sp)
ffffffe0002001ac:	06013603          	ld	a2,96(sp)
    ld x11, 88(sp)
ffffffe0002001b0:	05813583          	ld	a1,88(sp)
    ld x10, 80(sp)
ffffffe0002001b4:	05013503          	ld	a0,80(sp)
    ld x9, 72(sp)
ffffffe0002001b8:	04813483          	ld	s1,72(sp)
    ld x8, 64(sp)
ffffffe0002001bc:	04013403          	ld	s0,64(sp)
    ld x7, 56(sp)
ffffffe0002001c0:	03813383          	ld	t2,56(sp)
    ld x6, 48(sp)
ffffffe0002001c4:	03013303          	ld	t1,48(sp)
    ld x5, 40(sp)
ffffffe0002001c8:	02813283          	ld	t0,40(sp)
    ld x4, 32(sp)
ffffffe0002001cc:	02013203          	ld	tp,32(sp)
    ld x3, 24(sp)
ffffffe0002001d0:	01813183          	ld	gp,24(sp)
    ld x1, 8(sp)
ffffffe0002001d4:	00813083          	ld	ra,8(sp)
    ld x0, 0(sp)
ffffffe0002001d8:	00013003          	ld	zero,0(sp)
    ld x2, 16(sp)
ffffffe0002001dc:	01013103          	ld	sp,16(sp)
    addi sp,sp,280
ffffffe0002001e0:	11810113          	addi	sp,sp,280

    csrrw sp,sscratch,sp
ffffffe0002001e4:	14011173          	csrrw	sp,sscratch,sp
    bnez sp, 2f
ffffffe0002001e8:	00011463          	bnez	sp,ffffffe0002001f0 <__ret_from_fork+0xb0>
    csrrw sp, sscratch, sp
ffffffe0002001ec:	14011173          	csrrw	sp,sscratch,sp
 2: 
     # return from trap, 我们利用sret指令返回到我们之前重新设置回到的sepc地址。
    sret 
ffffffe0002001f0:	10200073          	sret

ffffffe0002001f4 <__dummy>:



__dummy:
    # exchange the stack from the user to the kernel
    csrrw sp, sscratch,sp
ffffffe0002001f4:	14011173          	csrrw	sp,sscratch,sp
    sret 
ffffffe0002001f8:	10200073          	sret

ffffffe0002001fc <__switch_to>:


__switch_to:
    # save state to prev process
    # YOUR CODE HERE
    addi t0, a0, 32
ffffffe0002001fc:	02050293          	addi	t0,a0,32
    sd ra, 0(t0)
ffffffe000200200:	0012b023          	sd	ra,0(t0)
    sd sp, 8(t0)
ffffffe000200204:	0022b423          	sd	sp,8(t0)
    sd s0, 16(t0)
ffffffe000200208:	0082b823          	sd	s0,16(t0)
    sd s1, 24(t0)
ffffffe00020020c:	0092bc23          	sd	s1,24(t0)
    sd s2, 32(t0)
ffffffe000200210:	0322b023          	sd	s2,32(t0)
    sd s3, 40(t0)
ffffffe000200214:	0332b423          	sd	s3,40(t0)
    sd s4, 48(t0)
ffffffe000200218:	0342b823          	sd	s4,48(t0)
    sd s5, 56(t0)
ffffffe00020021c:	0352bc23          	sd	s5,56(t0)
    sd s6, 64(t0)
ffffffe000200220:	0562b023          	sd	s6,64(t0)
    sd s7, 72(t0)
ffffffe000200224:	0572b423          	sd	s7,72(t0)
    sd s8, 80(t0)
ffffffe000200228:	0582b823          	sd	s8,80(t0)
    sd s9, 88(t0)
ffffffe00020022c:	0592bc23          	sd	s9,88(t0)
    sd s10, 96(t0)
ffffffe000200230:	07a2b023          	sd	s10,96(t0)
    sd s11, 104(t0)
ffffffe000200234:	07b2b423          	sd	s11,104(t0)
    # store for the sepc 
    csrr t1, sepc 
ffffffe000200238:	14102373          	csrr	t1,sepc
    sd   t1, 112(t0)
ffffffe00020023c:	0662b823          	sd	t1,112(t0)

    csrr t1, sstatus
ffffffe000200240:	10002373          	csrr	t1,sstatus
    sd   t1, 120(t0)
ffffffe000200244:	0662bc23          	sd	t1,120(t0)

    csrr t1, sscratch 
ffffffe000200248:	14002373          	csrr	t1,sscratch
    sd   t1, 128(t0)
ffffffe00020024c:	0862b023          	sd	t1,128(t0)


    # restore state from next process
    # YOUR CODE HERE
    addi t1, a1, 32
ffffffe000200250:	02058313          	addi	t1,a1,32
    ld ra, 0(t1)
ffffffe000200254:	00033083          	ld	ra,0(t1)
    ld sp, 8(t1)
ffffffe000200258:	00833103          	ld	sp,8(t1)
    ld s0, 16(t1)
ffffffe00020025c:	01033403          	ld	s0,16(t1)
    ld s1, 24(t1)
ffffffe000200260:	01833483          	ld	s1,24(t1)
    ld s2, 32(t1)
ffffffe000200264:	02033903          	ld	s2,32(t1)
    ld s3, 40(t1)
ffffffe000200268:	02833983          	ld	s3,40(t1)
    ld s4, 48(t1)
ffffffe00020026c:	03033a03          	ld	s4,48(t1)
    ld s5, 56(t1)
ffffffe000200270:	03833a83          	ld	s5,56(t1)
    ld s6, 64(t1)
ffffffe000200274:	04033b03          	ld	s6,64(t1)
    ld s7, 72(t1)
ffffffe000200278:	04833b83          	ld	s7,72(t1)
    ld s8, 80(t1)
ffffffe00020027c:	05033c03          	ld	s8,80(t1)
    ld s9, 88(t1)
ffffffe000200280:	05833c83          	ld	s9,88(t1)
    ld s10, 96(t1)
ffffffe000200284:	06033d03          	ld	s10,96(t1)
    ld s11, 104(t1)
ffffffe000200288:	06833d83          	ld	s11,104(t1)
    
    ld t2, 112(t1)
ffffffe00020028c:	07033383          	ld	t2,112(t1)
    csrw sepc , t2
ffffffe000200290:	14139073          	csrw	sepc,t2

    ld t2, 120(t1)
ffffffe000200294:	07833383          	ld	t2,120(t1)
    csrw sstatus , t2
ffffffe000200298:	10039073          	csrw	sstatus,t2

    ld t2, 128(t1)
ffffffe00020029c:	08033383          	ld	t2,128(t1)
    csrw sscratch, t2
ffffffe0002002a0:	14039073          	csrw	sscratch,t2

    # finish the logical of exchange the page_table;
    # the purpose is to get the physial address of the root page table;
    # in the struct, before the page_table address -> 21 * 8 = 168; 
    # we need to change the satp register to which __switch_to(a0,a1)-> the next task_struct
    addi a1,a1,168
ffffffe0002002a4:	0a858593          	addi	a1,a1,168
    ld t0, 0(a1)
ffffffe0002002a8:	0005b283          	ld	t0,0(a1)
    li t1, 0xffffffdf80000000
ffffffe0002002ac:	fbf0031b          	addiw	t1,zero,-65
ffffffe0002002b0:	01f31313          	slli	t1,t1,0x1f
    # change the VA to PA 
    sub t0, t0, t1 
ffffffe0002002b4:	406282b3          	sub	t0,t0,t1
    srl t0, t0, 12
ffffffe0002002b8:	00c2d293          	srli	t0,t0,0xc

    # set for the satp sv39 3-level every PTE is 9 bit the mode is 0x8.
    li t1 , 0x8000000000000000
ffffffe0002002bc:	fff0031b          	addiw	t1,zero,-1
ffffffe0002002c0:	03f31313          	slli	t1,t1,0x3f
    or t0, t0, t1
ffffffe0002002c4:	0062e2b3          	or	t0,t0,t1
    csrw satp, t0
ffffffe0002002c8:	18029073          	csrw	satp,t0


    # flush the TLB
    sfence.vma zero, zero 
ffffffe0002002cc:	12000073          	sfence.vma
    

ffffffe0002002d0:	00008067          	ret

ffffffe0002002d4 <get_cycles>:
#include "clock.h"

// QEMU 中时钟的频率是 10MHz，也就是 1 秒钟相当于 10000000 个时钟周期
uint64_t TIMECLOCK = 10000000;

uint64_t get_cycles() {
ffffffe0002002d4:	fe010113          	addi	sp,sp,-32
ffffffe0002002d8:	00813c23          	sd	s0,24(sp)
ffffffe0002002dc:	02010413          	addi	s0,sp,32
    // 编写内联汇编，使用 rdtime 获取 time 寄存器中（也就是 mtime 寄存器）的值并返回
    uint64_t t_result;
    asm(
ffffffe0002002e0:	c01027f3          	rdtime	a5
ffffffe0002002e4:	fef43423          	sd	a5,-24(s0)
        "rdtime %[t_result]\n"
        : [t_result] "=r" (t_result)
        : 
        : 
    );
    return t_result;
ffffffe0002002e8:	fe843783          	ld	a5,-24(s0)
}
ffffffe0002002ec:	00078513          	mv	a0,a5
ffffffe0002002f0:	01813403          	ld	s0,24(sp)
ffffffe0002002f4:	02010113          	addi	sp,sp,32
ffffffe0002002f8:	00008067          	ret

ffffffe0002002fc <clock_set_next_event>:

void clock_set_next_event() {
ffffffe0002002fc:	fe010113          	addi	sp,sp,-32
ffffffe000200300:	00113c23          	sd	ra,24(sp)
ffffffe000200304:	00813823          	sd	s0,16(sp)
ffffffe000200308:	02010413          	addi	s0,sp,32
    // 下一次时钟中断的时间点
    uint64_t next = get_cycles() + TIMECLOCK;
ffffffe00020030c:	fc9ff0ef          	jal	ffffffe0002002d4 <get_cycles>
ffffffe000200310:	00050713          	mv	a4,a0
ffffffe000200314:	00007797          	auipc	a5,0x7
ffffffe000200318:	cec78793          	addi	a5,a5,-788 # ffffffe000207000 <TIMECLOCK>
ffffffe00020031c:	0007b783          	ld	a5,0(a5)
ffffffe000200320:	00f707b3          	add	a5,a4,a5
ffffffe000200324:	fef43423          	sd	a5,-24(s0)

    // 使用 sbi_set_timer 来完成对下一次时钟中断的设置
    sbi_set_timer(next);
ffffffe000200328:	fe843503          	ld	a0,-24(s0)
ffffffe00020032c:	47d010ef          	jal	ffffffe000201fa8 <sbi_set_timer>
ffffffe000200330:	00000013          	nop
ffffffe000200334:	01813083          	ld	ra,24(sp)
ffffffe000200338:	01013403          	ld	s0,16(sp)
ffffffe00020033c:	02010113          	addi	sp,sp,32
ffffffe000200340:	00008067          	ret

ffffffe000200344 <fixsize>:

// from the end of the kernel in the memory;
void *free_page_start = &_ekernel;
struct buddy buddy;

static uint64_t fixsize(uint64_t size) {
ffffffe000200344:	fe010113          	addi	sp,sp,-32
ffffffe000200348:	00813c23          	sd	s0,24(sp)
ffffffe00020034c:	02010413          	addi	s0,sp,32
ffffffe000200350:	fea43423          	sd	a0,-24(s0)
    size --;
ffffffe000200354:	fe843783          	ld	a5,-24(s0)
ffffffe000200358:	fff78793          	addi	a5,a5,-1
ffffffe00020035c:	fef43423          	sd	a5,-24(s0)
    size |= size >> 1;
ffffffe000200360:	fe843783          	ld	a5,-24(s0)
ffffffe000200364:	0017d793          	srli	a5,a5,0x1
ffffffe000200368:	fe843703          	ld	a4,-24(s0)
ffffffe00020036c:	00f767b3          	or	a5,a4,a5
ffffffe000200370:	fef43423          	sd	a5,-24(s0)
    size |= size >> 2;
ffffffe000200374:	fe843783          	ld	a5,-24(s0)
ffffffe000200378:	0027d793          	srli	a5,a5,0x2
ffffffe00020037c:	fe843703          	ld	a4,-24(s0)
ffffffe000200380:	00f767b3          	or	a5,a4,a5
ffffffe000200384:	fef43423          	sd	a5,-24(s0)
    size |= size >> 4;
ffffffe000200388:	fe843783          	ld	a5,-24(s0)
ffffffe00020038c:	0047d793          	srli	a5,a5,0x4
ffffffe000200390:	fe843703          	ld	a4,-24(s0)
ffffffe000200394:	00f767b3          	or	a5,a4,a5
ffffffe000200398:	fef43423          	sd	a5,-24(s0)
    size |= size >> 8;
ffffffe00020039c:	fe843783          	ld	a5,-24(s0)
ffffffe0002003a0:	0087d793          	srli	a5,a5,0x8
ffffffe0002003a4:	fe843703          	ld	a4,-24(s0)
ffffffe0002003a8:	00f767b3          	or	a5,a4,a5
ffffffe0002003ac:	fef43423          	sd	a5,-24(s0)
    size |= size >> 16;
ffffffe0002003b0:	fe843783          	ld	a5,-24(s0)
ffffffe0002003b4:	0107d793          	srli	a5,a5,0x10
ffffffe0002003b8:	fe843703          	ld	a4,-24(s0)
ffffffe0002003bc:	00f767b3          	or	a5,a4,a5
ffffffe0002003c0:	fef43423          	sd	a5,-24(s0)
    size |= size >> 32;
ffffffe0002003c4:	fe843783          	ld	a5,-24(s0)
ffffffe0002003c8:	0207d793          	srli	a5,a5,0x20
ffffffe0002003cc:	fe843703          	ld	a4,-24(s0)
ffffffe0002003d0:	00f767b3          	or	a5,a4,a5
ffffffe0002003d4:	fef43423          	sd	a5,-24(s0)
    return size + 1;
ffffffe0002003d8:	fe843783          	ld	a5,-24(s0)
ffffffe0002003dc:	00178793          	addi	a5,a5,1
}
ffffffe0002003e0:	00078513          	mv	a0,a5
ffffffe0002003e4:	01813403          	ld	s0,24(sp)
ffffffe0002003e8:	02010113          	addi	sp,sp,32
ffffffe0002003ec:	00008067          	ret

ffffffe0002003f0 <buddy_init>:

void buddy_init() {
ffffffe0002003f0:	fd010113          	addi	sp,sp,-48
ffffffe0002003f4:	02113423          	sd	ra,40(sp)
ffffffe0002003f8:	02813023          	sd	s0,32(sp)
ffffffe0002003fc:	03010413          	addi	s0,sp,48
    uint64_t buddy_size = (uint64_t)PHY_SIZE / PGSIZE;
ffffffe000200400:	000087b7          	lui	a5,0x8
ffffffe000200404:	fef43423          	sd	a5,-24(s0)
    // we assume the size of the buddy is the power of 2;
    if (!IS_POWER_OF_2(buddy_size))
ffffffe000200408:	fe843783          	ld	a5,-24(s0)
ffffffe00020040c:	fff78713          	addi	a4,a5,-1 # 7fff <PGSIZE+0x6fff>
ffffffe000200410:	fe843783          	ld	a5,-24(s0)
ffffffe000200414:	00f777b3          	and	a5,a4,a5
ffffffe000200418:	00078863          	beqz	a5,ffffffe000200428 <buddy_init+0x38>
        buddy_size = fixsize(buddy_size);
ffffffe00020041c:	fe843503          	ld	a0,-24(s0)
ffffffe000200420:	f25ff0ef          	jal	ffffffe000200344 <fixsize>
ffffffe000200424:	fea43423          	sd	a0,-24(s0)

    buddy.size = buddy_size;
ffffffe000200428:	0000b797          	auipc	a5,0xb
ffffffe00020042c:	bf878793          	addi	a5,a5,-1032 # ffffffe00020b020 <buddy>
ffffffe000200430:	fe843703          	ld	a4,-24(s0)
ffffffe000200434:	00e7b023          	sd	a4,0(a5)
    /***
     *  The buddy is the form of a complete binary tree;
     *  // ___(kernel)____ ___(bit_map)___ 
     * 
    */
    buddy.bitmap = free_page_start;
ffffffe000200438:	00007797          	auipc	a5,0x7
ffffffe00020043c:	bd078793          	addi	a5,a5,-1072 # ffffffe000207008 <free_page_start>
ffffffe000200440:	0007b703          	ld	a4,0(a5)
ffffffe000200444:	0000b797          	auipc	a5,0xb
ffffffe000200448:	bdc78793          	addi	a5,a5,-1060 # ffffffe00020b020 <buddy>
ffffffe00020044c:	00e7b423          	sd	a4,8(a5)
    free_page_start += 2 * buddy.size * sizeof(*buddy.bitmap);
ffffffe000200450:	00007797          	auipc	a5,0x7
ffffffe000200454:	bb878793          	addi	a5,a5,-1096 # ffffffe000207008 <free_page_start>
ffffffe000200458:	0007b703          	ld	a4,0(a5)
ffffffe00020045c:	0000b797          	auipc	a5,0xb
ffffffe000200460:	bc478793          	addi	a5,a5,-1084 # ffffffe00020b020 <buddy>
ffffffe000200464:	0007b783          	ld	a5,0(a5)
ffffffe000200468:	00479793          	slli	a5,a5,0x4
ffffffe00020046c:	00f70733          	add	a4,a4,a5
ffffffe000200470:	00007797          	auipc	a5,0x7
ffffffe000200474:	b9878793          	addi	a5,a5,-1128 # ffffffe000207008 <free_page_start>
ffffffe000200478:	00e7b023          	sd	a4,0(a5)
    memset(buddy.bitmap, 0, 2 * buddy.size * sizeof(*buddy.bitmap));
ffffffe00020047c:	0000b797          	auipc	a5,0xb
ffffffe000200480:	ba478793          	addi	a5,a5,-1116 # ffffffe00020b020 <buddy>
ffffffe000200484:	0087b703          	ld	a4,8(a5)
ffffffe000200488:	0000b797          	auipc	a5,0xb
ffffffe00020048c:	b9878793          	addi	a5,a5,-1128 # ffffffe00020b020 <buddy>
ffffffe000200490:	0007b783          	ld	a5,0(a5)
ffffffe000200494:	00479793          	slli	a5,a5,0x4
ffffffe000200498:	00078613          	mv	a2,a5
ffffffe00020049c:	00000593          	li	a1,0
ffffffe0002004a0:	00070513          	mv	a0,a4
ffffffe0002004a4:	668040ef          	jal	ffffffe000204b0c <memset>
    buddy.ref_cnt = free_page_start;
ffffffe0002004a8:	00007797          	auipc	a5,0x7
ffffffe0002004ac:	b6078793          	addi	a5,a5,-1184 # ffffffe000207008 <free_page_start>
ffffffe0002004b0:	0007b703          	ld	a4,0(a5)
ffffffe0002004b4:	0000b797          	auipc	a5,0xb
ffffffe0002004b8:	b6c78793          	addi	a5,a5,-1172 # ffffffe00020b020 <buddy>
ffffffe0002004bc:	00e7b823          	sd	a4,16(a5)
    free_page_start += buddy.size * sizeof(*buddy.ref_cnt);
ffffffe0002004c0:	00007797          	auipc	a5,0x7
ffffffe0002004c4:	b4878793          	addi	a5,a5,-1208 # ffffffe000207008 <free_page_start>
ffffffe0002004c8:	0007b703          	ld	a4,0(a5)
ffffffe0002004cc:	0000b797          	auipc	a5,0xb
ffffffe0002004d0:	b5478793          	addi	a5,a5,-1196 # ffffffe00020b020 <buddy>
ffffffe0002004d4:	0007b783          	ld	a5,0(a5)
ffffffe0002004d8:	00379793          	slli	a5,a5,0x3
ffffffe0002004dc:	00f70733          	add	a4,a4,a5
ffffffe0002004e0:	00007797          	auipc	a5,0x7
ffffffe0002004e4:	b2878793          	addi	a5,a5,-1240 # ffffffe000207008 <free_page_start>
ffffffe0002004e8:	00e7b023          	sd	a4,0(a5)
    memset(buddy.ref_cnt, 0, buddy.size * sizeof(*buddy.ref_cnt));
ffffffe0002004ec:	0000b797          	auipc	a5,0xb
ffffffe0002004f0:	b3478793          	addi	a5,a5,-1228 # ffffffe00020b020 <buddy>
ffffffe0002004f4:	0107b703          	ld	a4,16(a5)
ffffffe0002004f8:	0000b797          	auipc	a5,0xb
ffffffe0002004fc:	b2878793          	addi	a5,a5,-1240 # ffffffe00020b020 <buddy>
ffffffe000200500:	0007b783          	ld	a5,0(a5)
ffffffe000200504:	00379793          	slli	a5,a5,0x3
ffffffe000200508:	00078613          	mv	a2,a5
ffffffe00020050c:	00000593          	li	a1,0
ffffffe000200510:	00070513          	mv	a0,a4
ffffffe000200514:	5f8040ef          	jal	ffffffe000204b0c <memset>
    

    uint64_t node_size = buddy.size * 2;
ffffffe000200518:	0000b797          	auipc	a5,0xb
ffffffe00020051c:	b0878793          	addi	a5,a5,-1272 # ffffffe00020b020 <buddy>
ffffffe000200520:	0007b783          	ld	a5,0(a5)
ffffffe000200524:	00179793          	slli	a5,a5,0x1
ffffffe000200528:	fef43023          	sd	a5,-32(s0)
    for (uint64_t i = 0; i < 2 * buddy.size - 1; ++i) {
ffffffe00020052c:	fc043c23          	sd	zero,-40(s0)
ffffffe000200530:	0500006f          	j	ffffffe000200580 <buddy_init+0x190>
        if (IS_POWER_OF_2(i + 1))
ffffffe000200534:	fd843783          	ld	a5,-40(s0)
ffffffe000200538:	00178713          	addi	a4,a5,1
ffffffe00020053c:	fd843783          	ld	a5,-40(s0)
ffffffe000200540:	00f777b3          	and	a5,a4,a5
ffffffe000200544:	00079863          	bnez	a5,ffffffe000200554 <buddy_init+0x164>
            node_size /= 2;
ffffffe000200548:	fe043783          	ld	a5,-32(s0)
ffffffe00020054c:	0017d793          	srli	a5,a5,0x1
ffffffe000200550:	fef43023          	sd	a5,-32(s0)
        buddy.bitmap[i] = node_size;
ffffffe000200554:	0000b797          	auipc	a5,0xb
ffffffe000200558:	acc78793          	addi	a5,a5,-1332 # ffffffe00020b020 <buddy>
ffffffe00020055c:	0087b703          	ld	a4,8(a5)
ffffffe000200560:	fd843783          	ld	a5,-40(s0)
ffffffe000200564:	00379793          	slli	a5,a5,0x3
ffffffe000200568:	00f707b3          	add	a5,a4,a5
ffffffe00020056c:	fe043703          	ld	a4,-32(s0)
ffffffe000200570:	00e7b023          	sd	a4,0(a5)
    for (uint64_t i = 0; i < 2 * buddy.size - 1; ++i) {
ffffffe000200574:	fd843783          	ld	a5,-40(s0)
ffffffe000200578:	00178793          	addi	a5,a5,1
ffffffe00020057c:	fcf43c23          	sd	a5,-40(s0)
ffffffe000200580:	0000b797          	auipc	a5,0xb
ffffffe000200584:	aa078793          	addi	a5,a5,-1376 # ffffffe00020b020 <buddy>
ffffffe000200588:	0007b783          	ld	a5,0(a5)
ffffffe00020058c:	00179793          	slli	a5,a5,0x1
ffffffe000200590:	fff78793          	addi	a5,a5,-1
ffffffe000200594:	fd843703          	ld	a4,-40(s0)
ffffffe000200598:	f8f76ee3          	bltu	a4,a5,ffffffe000200534 <buddy_init+0x144>
    }

    for (uint64_t pfn = 0; (uint64_t)PFN2PHYS(pfn) < VA2PA((uint64_t)free_page_start); ++pfn) {
ffffffe00020059c:	fc043823          	sd	zero,-48(s0)
ffffffe0002005a0:	0180006f          	j	ffffffe0002005b8 <buddy_init+0x1c8>
        buddy_alloc(1);
ffffffe0002005a4:	00100513          	li	a0,1
ffffffe0002005a8:	21c000ef          	jal	ffffffe0002007c4 <buddy_alloc>
    for (uint64_t pfn = 0; (uint64_t)PFN2PHYS(pfn) < VA2PA((uint64_t)free_page_start); ++pfn) {
ffffffe0002005ac:	fd043783          	ld	a5,-48(s0)
ffffffe0002005b0:	00178793          	addi	a5,a5,1
ffffffe0002005b4:	fcf43823          	sd	a5,-48(s0)
ffffffe0002005b8:	fd043783          	ld	a5,-48(s0)
ffffffe0002005bc:	00c79713          	slli	a4,a5,0xc
ffffffe0002005c0:	00100793          	li	a5,1
ffffffe0002005c4:	01f79793          	slli	a5,a5,0x1f
ffffffe0002005c8:	00f70733          	add	a4,a4,a5
ffffffe0002005cc:	00007797          	auipc	a5,0x7
ffffffe0002005d0:	a3c78793          	addi	a5,a5,-1476 # ffffffe000207008 <free_page_start>
ffffffe0002005d4:	0007b783          	ld	a5,0(a5)
ffffffe0002005d8:	00078693          	mv	a3,a5
ffffffe0002005dc:	04100793          	li	a5,65
ffffffe0002005e0:	01f79793          	slli	a5,a5,0x1f
ffffffe0002005e4:	00f687b3          	add	a5,a3,a5
ffffffe0002005e8:	faf76ee3          	bltu	a4,a5,ffffffe0002005a4 <buddy_init+0x1b4>
    }

    printk("...buddy_init done!\n");
ffffffe0002005ec:	00005517          	auipc	a0,0x5
ffffffe0002005f0:	a2c50513          	addi	a0,a0,-1492 # ffffffe000205018 <__func__.0+0x8>
ffffffe0002005f4:	3f8040ef          	jal	ffffffe0002049ec <printk>
    return;
ffffffe0002005f8:	00000013          	nop
}
ffffffe0002005fc:	02813083          	ld	ra,40(sp)
ffffffe000200600:	02013403          	ld	s0,32(sp)
ffffffe000200604:	03010113          	addi	sp,sp,48
ffffffe000200608:	00008067          	ret

ffffffe00020060c <buddy_free>:

void buddy_free(uint64_t pfn) {
ffffffe00020060c:	fc010113          	addi	sp,sp,-64
ffffffe000200610:	02813c23          	sd	s0,56(sp)
ffffffe000200614:	04010413          	addi	s0,sp,64
ffffffe000200618:	fca43423          	sd	a0,-56(s0)
    if (buddy.ref_cnt[pfn]) {
ffffffe00020061c:	0000b797          	auipc	a5,0xb
ffffffe000200620:	a0478793          	addi	a5,a5,-1532 # ffffffe00020b020 <buddy>
ffffffe000200624:	0107b703          	ld	a4,16(a5)
ffffffe000200628:	fc843783          	ld	a5,-56(s0)
ffffffe00020062c:	00379793          	slli	a5,a5,0x3
ffffffe000200630:	00f707b3          	add	a5,a4,a5
ffffffe000200634:	0007b783          	ld	a5,0(a5)
ffffffe000200638:	16079e63          	bnez	a5,ffffffe0002007b4 <buddy_free+0x1a8>
        return;
    }
    uint64_t node_size, index = 0;
ffffffe00020063c:	fe043023          	sd	zero,-32(s0)
    uint64_t left_longest, right_longest;

    node_size = 1;
ffffffe000200640:	00100793          	li	a5,1
ffffffe000200644:	fef43423          	sd	a5,-24(s0)
    index = pfn + buddy.size - 1;
ffffffe000200648:	0000b797          	auipc	a5,0xb
ffffffe00020064c:	9d878793          	addi	a5,a5,-1576 # ffffffe00020b020 <buddy>
ffffffe000200650:	0007b703          	ld	a4,0(a5)
ffffffe000200654:	fc843783          	ld	a5,-56(s0)
ffffffe000200658:	00f707b3          	add	a5,a4,a5
ffffffe00020065c:	fff78793          	addi	a5,a5,-1
ffffffe000200660:	fef43023          	sd	a5,-32(s0)

    for (; buddy.bitmap[index]; index = PARENT(index)) {
ffffffe000200664:	02c0006f          	j	ffffffe000200690 <buddy_free+0x84>
        node_size *= 2;
ffffffe000200668:	fe843783          	ld	a5,-24(s0)
ffffffe00020066c:	00179793          	slli	a5,a5,0x1
ffffffe000200670:	fef43423          	sd	a5,-24(s0)
        if (index == 0)
ffffffe000200674:	fe043783          	ld	a5,-32(s0)
ffffffe000200678:	02078e63          	beqz	a5,ffffffe0002006b4 <buddy_free+0xa8>
    for (; buddy.bitmap[index]; index = PARENT(index)) {
ffffffe00020067c:	fe043783          	ld	a5,-32(s0)
ffffffe000200680:	00178793          	addi	a5,a5,1
ffffffe000200684:	0017d793          	srli	a5,a5,0x1
ffffffe000200688:	fff78793          	addi	a5,a5,-1
ffffffe00020068c:	fef43023          	sd	a5,-32(s0)
ffffffe000200690:	0000b797          	auipc	a5,0xb
ffffffe000200694:	99078793          	addi	a5,a5,-1648 # ffffffe00020b020 <buddy>
ffffffe000200698:	0087b703          	ld	a4,8(a5)
ffffffe00020069c:	fe043783          	ld	a5,-32(s0)
ffffffe0002006a0:	00379793          	slli	a5,a5,0x3
ffffffe0002006a4:	00f707b3          	add	a5,a4,a5
ffffffe0002006a8:	0007b783          	ld	a5,0(a5)
ffffffe0002006ac:	fa079ee3          	bnez	a5,ffffffe000200668 <buddy_free+0x5c>
ffffffe0002006b0:	0080006f          	j	ffffffe0002006b8 <buddy_free+0xac>
            break;
ffffffe0002006b4:	00000013          	nop
    }

    buddy.bitmap[index] = node_size;
ffffffe0002006b8:	0000b797          	auipc	a5,0xb
ffffffe0002006bc:	96878793          	addi	a5,a5,-1688 # ffffffe00020b020 <buddy>
ffffffe0002006c0:	0087b703          	ld	a4,8(a5)
ffffffe0002006c4:	fe043783          	ld	a5,-32(s0)
ffffffe0002006c8:	00379793          	slli	a5,a5,0x3
ffffffe0002006cc:	00f707b3          	add	a5,a4,a5
ffffffe0002006d0:	fe843703          	ld	a4,-24(s0)
ffffffe0002006d4:	00e7b023          	sd	a4,0(a5)

    while (index) {
ffffffe0002006d8:	0d00006f          	j	ffffffe0002007a8 <buddy_free+0x19c>
        index = PARENT(index);
ffffffe0002006dc:	fe043783          	ld	a5,-32(s0)
ffffffe0002006e0:	00178793          	addi	a5,a5,1
ffffffe0002006e4:	0017d793          	srli	a5,a5,0x1
ffffffe0002006e8:	fff78793          	addi	a5,a5,-1
ffffffe0002006ec:	fef43023          	sd	a5,-32(s0)
        node_size *= 2;
ffffffe0002006f0:	fe843783          	ld	a5,-24(s0)
ffffffe0002006f4:	00179793          	slli	a5,a5,0x1
ffffffe0002006f8:	fef43423          	sd	a5,-24(s0)

        left_longest = buddy.bitmap[LEFT_LEAF(index)];
ffffffe0002006fc:	0000b797          	auipc	a5,0xb
ffffffe000200700:	92478793          	addi	a5,a5,-1756 # ffffffe00020b020 <buddy>
ffffffe000200704:	0087b703          	ld	a4,8(a5)
ffffffe000200708:	fe043783          	ld	a5,-32(s0)
ffffffe00020070c:	00479793          	slli	a5,a5,0x4
ffffffe000200710:	00878793          	addi	a5,a5,8
ffffffe000200714:	00f707b3          	add	a5,a4,a5
ffffffe000200718:	0007b783          	ld	a5,0(a5)
ffffffe00020071c:	fcf43c23          	sd	a5,-40(s0)
        right_longest = buddy.bitmap[RIGHT_LEAF(index)];
ffffffe000200720:	0000b797          	auipc	a5,0xb
ffffffe000200724:	90078793          	addi	a5,a5,-1792 # ffffffe00020b020 <buddy>
ffffffe000200728:	0087b703          	ld	a4,8(a5)
ffffffe00020072c:	fe043783          	ld	a5,-32(s0)
ffffffe000200730:	00178793          	addi	a5,a5,1
ffffffe000200734:	00479793          	slli	a5,a5,0x4
ffffffe000200738:	00f707b3          	add	a5,a4,a5
ffffffe00020073c:	0007b783          	ld	a5,0(a5)
ffffffe000200740:	fcf43823          	sd	a5,-48(s0)

        if (left_longest + right_longest == node_size) 
ffffffe000200744:	fd843703          	ld	a4,-40(s0)
ffffffe000200748:	fd043783          	ld	a5,-48(s0)
ffffffe00020074c:	00f707b3          	add	a5,a4,a5
ffffffe000200750:	fe843703          	ld	a4,-24(s0)
ffffffe000200754:	02f71463          	bne	a4,a5,ffffffe00020077c <buddy_free+0x170>
            buddy.bitmap[index] = node_size;
ffffffe000200758:	0000b797          	auipc	a5,0xb
ffffffe00020075c:	8c878793          	addi	a5,a5,-1848 # ffffffe00020b020 <buddy>
ffffffe000200760:	0087b703          	ld	a4,8(a5)
ffffffe000200764:	fe043783          	ld	a5,-32(s0)
ffffffe000200768:	00379793          	slli	a5,a5,0x3
ffffffe00020076c:	00f707b3          	add	a5,a4,a5
ffffffe000200770:	fe843703          	ld	a4,-24(s0)
ffffffe000200774:	00e7b023          	sd	a4,0(a5)
ffffffe000200778:	0300006f          	j	ffffffe0002007a8 <buddy_free+0x19c>
        else
            buddy.bitmap[index] = MAX(left_longest, right_longest);
ffffffe00020077c:	0000b797          	auipc	a5,0xb
ffffffe000200780:	8a478793          	addi	a5,a5,-1884 # ffffffe00020b020 <buddy>
ffffffe000200784:	0087b703          	ld	a4,8(a5)
ffffffe000200788:	fe043783          	ld	a5,-32(s0)
ffffffe00020078c:	00379793          	slli	a5,a5,0x3
ffffffe000200790:	00f706b3          	add	a3,a4,a5
ffffffe000200794:	fd843703          	ld	a4,-40(s0)
ffffffe000200798:	fd043783          	ld	a5,-48(s0)
ffffffe00020079c:	00e7f463          	bgeu	a5,a4,ffffffe0002007a4 <buddy_free+0x198>
ffffffe0002007a0:	00070793          	mv	a5,a4
ffffffe0002007a4:	00f6b023          	sd	a5,0(a3)
    while (index) {
ffffffe0002007a8:	fe043783          	ld	a5,-32(s0)
ffffffe0002007ac:	f20798e3          	bnez	a5,ffffffe0002006dc <buddy_free+0xd0>
ffffffe0002007b0:	0080006f          	j	ffffffe0002007b8 <buddy_free+0x1ac>
        return;
ffffffe0002007b4:	00000013          	nop
    }
}
ffffffe0002007b8:	03813403          	ld	s0,56(sp)
ffffffe0002007bc:	04010113          	addi	sp,sp,64
ffffffe0002007c0:	00008067          	ret

ffffffe0002007c4 <buddy_alloc>:

uint64_t buddy_alloc(uint64_t nrpages) {
ffffffe0002007c4:	fc010113          	addi	sp,sp,-64
ffffffe0002007c8:	02113c23          	sd	ra,56(sp)
ffffffe0002007cc:	02813823          	sd	s0,48(sp)
ffffffe0002007d0:	04010413          	addi	s0,sp,64
ffffffe0002007d4:	fca43423          	sd	a0,-56(s0)
    uint64_t index = 0;
ffffffe0002007d8:	fe043423          	sd	zero,-24(s0)
    uint64_t node_size;
    uint64_t pfn = 0;
ffffffe0002007dc:	fc043c23          	sd	zero,-40(s0)

    if (nrpages <= 0)
ffffffe0002007e0:	fc843783          	ld	a5,-56(s0)
ffffffe0002007e4:	00079863          	bnez	a5,ffffffe0002007f4 <buddy_alloc+0x30>
        nrpages = 1;
ffffffe0002007e8:	00100793          	li	a5,1
ffffffe0002007ec:	fcf43423          	sd	a5,-56(s0)
ffffffe0002007f0:	0240006f          	j	ffffffe000200814 <buddy_alloc+0x50>
    else if (!IS_POWER_OF_2(nrpages))
ffffffe0002007f4:	fc843783          	ld	a5,-56(s0)
ffffffe0002007f8:	fff78713          	addi	a4,a5,-1
ffffffe0002007fc:	fc843783          	ld	a5,-56(s0)
ffffffe000200800:	00f777b3          	and	a5,a4,a5
ffffffe000200804:	00078863          	beqz	a5,ffffffe000200814 <buddy_alloc+0x50>
        nrpages = fixsize(nrpages);
ffffffe000200808:	fc843503          	ld	a0,-56(s0)
ffffffe00020080c:	b39ff0ef          	jal	ffffffe000200344 <fixsize>
ffffffe000200810:	fca43423          	sd	a0,-56(s0)

    if (buddy.bitmap[index] < nrpages)
ffffffe000200814:	0000b797          	auipc	a5,0xb
ffffffe000200818:	80c78793          	addi	a5,a5,-2036 # ffffffe00020b020 <buddy>
ffffffe00020081c:	0087b703          	ld	a4,8(a5)
ffffffe000200820:	fe843783          	ld	a5,-24(s0)
ffffffe000200824:	00379793          	slli	a5,a5,0x3
ffffffe000200828:	00f707b3          	add	a5,a4,a5
ffffffe00020082c:	0007b783          	ld	a5,0(a5)
ffffffe000200830:	fc843703          	ld	a4,-56(s0)
ffffffe000200834:	00e7f663          	bgeu	a5,a4,ffffffe000200840 <buddy_alloc+0x7c>
        return 0;
ffffffe000200838:	00000793          	li	a5,0
ffffffe00020083c:	18c0006f          	j	ffffffe0002009c8 <buddy_alloc+0x204>

    for(node_size = buddy.size; node_size != nrpages; node_size /= 2 ) {
ffffffe000200840:	0000a797          	auipc	a5,0xa
ffffffe000200844:	7e078793          	addi	a5,a5,2016 # ffffffe00020b020 <buddy>
ffffffe000200848:	0007b783          	ld	a5,0(a5)
ffffffe00020084c:	fef43023          	sd	a5,-32(s0)
ffffffe000200850:	05c0006f          	j	ffffffe0002008ac <buddy_alloc+0xe8>
        if (buddy.bitmap[LEFT_LEAF(index)] >= nrpages)
ffffffe000200854:	0000a797          	auipc	a5,0xa
ffffffe000200858:	7cc78793          	addi	a5,a5,1996 # ffffffe00020b020 <buddy>
ffffffe00020085c:	0087b703          	ld	a4,8(a5)
ffffffe000200860:	fe843783          	ld	a5,-24(s0)
ffffffe000200864:	00479793          	slli	a5,a5,0x4
ffffffe000200868:	00878793          	addi	a5,a5,8
ffffffe00020086c:	00f707b3          	add	a5,a4,a5
ffffffe000200870:	0007b783          	ld	a5,0(a5)
ffffffe000200874:	fc843703          	ld	a4,-56(s0)
ffffffe000200878:	00e7ec63          	bltu	a5,a4,ffffffe000200890 <buddy_alloc+0xcc>
            index = LEFT_LEAF(index);
ffffffe00020087c:	fe843783          	ld	a5,-24(s0)
ffffffe000200880:	00179793          	slli	a5,a5,0x1
ffffffe000200884:	00178793          	addi	a5,a5,1
ffffffe000200888:	fef43423          	sd	a5,-24(s0)
ffffffe00020088c:	0140006f          	j	ffffffe0002008a0 <buddy_alloc+0xdc>
        else
            index = RIGHT_LEAF(index);
ffffffe000200890:	fe843783          	ld	a5,-24(s0)
ffffffe000200894:	00178793          	addi	a5,a5,1
ffffffe000200898:	00179793          	slli	a5,a5,0x1
ffffffe00020089c:	fef43423          	sd	a5,-24(s0)
    for(node_size = buddy.size; node_size != nrpages; node_size /= 2 ) {
ffffffe0002008a0:	fe043783          	ld	a5,-32(s0)
ffffffe0002008a4:	0017d793          	srli	a5,a5,0x1
ffffffe0002008a8:	fef43023          	sd	a5,-32(s0)
ffffffe0002008ac:	fe043703          	ld	a4,-32(s0)
ffffffe0002008b0:	fc843783          	ld	a5,-56(s0)
ffffffe0002008b4:	faf710e3          	bne	a4,a5,ffffffe000200854 <buddy_alloc+0x90>
    }

    buddy.bitmap[index] = 0;
ffffffe0002008b8:	0000a797          	auipc	a5,0xa
ffffffe0002008bc:	76878793          	addi	a5,a5,1896 # ffffffe00020b020 <buddy>
ffffffe0002008c0:	0087b703          	ld	a4,8(a5)
ffffffe0002008c4:	fe843783          	ld	a5,-24(s0)
ffffffe0002008c8:	00379793          	slli	a5,a5,0x3
ffffffe0002008cc:	00f707b3          	add	a5,a4,a5
ffffffe0002008d0:	0007b023          	sd	zero,0(a5)
    pfn = (index + 1) * node_size - buddy.size;
ffffffe0002008d4:	fe843783          	ld	a5,-24(s0)
ffffffe0002008d8:	00178713          	addi	a4,a5,1
ffffffe0002008dc:	fe043783          	ld	a5,-32(s0)
ffffffe0002008e0:	02f70733          	mul	a4,a4,a5
ffffffe0002008e4:	0000a797          	auipc	a5,0xa
ffffffe0002008e8:	73c78793          	addi	a5,a5,1852 # ffffffe00020b020 <buddy>
ffffffe0002008ec:	0007b783          	ld	a5,0(a5)
ffffffe0002008f0:	40f707b3          	sub	a5,a4,a5
ffffffe0002008f4:	fcf43c23          	sd	a5,-40(s0)
    buddy.ref_cnt[pfn] = 1;
ffffffe0002008f8:	0000a797          	auipc	a5,0xa
ffffffe0002008fc:	72878793          	addi	a5,a5,1832 # ffffffe00020b020 <buddy>
ffffffe000200900:	0107b703          	ld	a4,16(a5)
ffffffe000200904:	fd843783          	ld	a5,-40(s0)
ffffffe000200908:	00379793          	slli	a5,a5,0x3
ffffffe00020090c:	00f707b3          	add	a5,a4,a5
ffffffe000200910:	00100713          	li	a4,1
ffffffe000200914:	00e7b023          	sd	a4,0(a5)

    pfn = (index + 1) * node_size - buddy.size;
ffffffe000200918:	fe843783          	ld	a5,-24(s0)
ffffffe00020091c:	00178713          	addi	a4,a5,1
ffffffe000200920:	fe043783          	ld	a5,-32(s0)
ffffffe000200924:	02f70733          	mul	a4,a4,a5
ffffffe000200928:	0000a797          	auipc	a5,0xa
ffffffe00020092c:	6f878793          	addi	a5,a5,1784 # ffffffe00020b020 <buddy>
ffffffe000200930:	0007b783          	ld	a5,0(a5)
ffffffe000200934:	40f707b3          	sub	a5,a4,a5
ffffffe000200938:	fcf43c23          	sd	a5,-40(s0)

    while (index) {
ffffffe00020093c:	0800006f          	j	ffffffe0002009bc <buddy_alloc+0x1f8>
        index = PARENT(index);
ffffffe000200940:	fe843783          	ld	a5,-24(s0)
ffffffe000200944:	00178793          	addi	a5,a5,1
ffffffe000200948:	0017d793          	srli	a5,a5,0x1
ffffffe00020094c:	fff78793          	addi	a5,a5,-1
ffffffe000200950:	fef43423          	sd	a5,-24(s0)
        buddy.bitmap[index] = 
            MAX(buddy.bitmap[LEFT_LEAF(index)], buddy.bitmap[RIGHT_LEAF(index)]);
ffffffe000200954:	0000a797          	auipc	a5,0xa
ffffffe000200958:	6cc78793          	addi	a5,a5,1740 # ffffffe00020b020 <buddy>
ffffffe00020095c:	0087b703          	ld	a4,8(a5)
ffffffe000200960:	fe843783          	ld	a5,-24(s0)
ffffffe000200964:	00178793          	addi	a5,a5,1
ffffffe000200968:	00479793          	slli	a5,a5,0x4
ffffffe00020096c:	00f707b3          	add	a5,a4,a5
ffffffe000200970:	0007b603          	ld	a2,0(a5)
ffffffe000200974:	0000a797          	auipc	a5,0xa
ffffffe000200978:	6ac78793          	addi	a5,a5,1708 # ffffffe00020b020 <buddy>
ffffffe00020097c:	0087b703          	ld	a4,8(a5)
ffffffe000200980:	fe843783          	ld	a5,-24(s0)
ffffffe000200984:	00479793          	slli	a5,a5,0x4
ffffffe000200988:	00878793          	addi	a5,a5,8
ffffffe00020098c:	00f707b3          	add	a5,a4,a5
ffffffe000200990:	0007b703          	ld	a4,0(a5)
        buddy.bitmap[index] = 
ffffffe000200994:	0000a797          	auipc	a5,0xa
ffffffe000200998:	68c78793          	addi	a5,a5,1676 # ffffffe00020b020 <buddy>
ffffffe00020099c:	0087b683          	ld	a3,8(a5)
ffffffe0002009a0:	fe843783          	ld	a5,-24(s0)
ffffffe0002009a4:	00379793          	slli	a5,a5,0x3
ffffffe0002009a8:	00f686b3          	add	a3,a3,a5
            MAX(buddy.bitmap[LEFT_LEAF(index)], buddy.bitmap[RIGHT_LEAF(index)]);
ffffffe0002009ac:	00060793          	mv	a5,a2
ffffffe0002009b0:	00e7f463          	bgeu	a5,a4,ffffffe0002009b8 <buddy_alloc+0x1f4>
ffffffe0002009b4:	00070793          	mv	a5,a4
        buddy.bitmap[index] = 
ffffffe0002009b8:	00f6b023          	sd	a5,0(a3)
    while (index) {
ffffffe0002009bc:	fe843783          	ld	a5,-24(s0)
ffffffe0002009c0:	f80790e3          	bnez	a5,ffffffe000200940 <buddy_alloc+0x17c>
    }
    
    return pfn;
ffffffe0002009c4:	fd843783          	ld	a5,-40(s0)
}
ffffffe0002009c8:	00078513          	mv	a0,a5
ffffffe0002009cc:	03813083          	ld	ra,56(sp)
ffffffe0002009d0:	03013403          	ld	s0,48(sp)
ffffffe0002009d4:	04010113          	addi	sp,sp,64
ffffffe0002009d8:	00008067          	ret

ffffffe0002009dc <alloc_pages>:


void *alloc_pages(uint64_t nrpages) {
ffffffe0002009dc:	fd010113          	addi	sp,sp,-48
ffffffe0002009e0:	02113423          	sd	ra,40(sp)
ffffffe0002009e4:	02813023          	sd	s0,32(sp)
ffffffe0002009e8:	03010413          	addi	s0,sp,48
ffffffe0002009ec:	fca43c23          	sd	a0,-40(s0)
    uint64_t pfn = buddy_alloc(nrpages);
ffffffe0002009f0:	fd843503          	ld	a0,-40(s0)
ffffffe0002009f4:	dd1ff0ef          	jal	ffffffe0002007c4 <buddy_alloc>
ffffffe0002009f8:	fea43423          	sd	a0,-24(s0)
    if (pfn == 0)
ffffffe0002009fc:	fe843783          	ld	a5,-24(s0)
ffffffe000200a00:	00079663          	bnez	a5,ffffffe000200a0c <alloc_pages+0x30>
        return 0;
ffffffe000200a04:	00000793          	li	a5,0
ffffffe000200a08:	0180006f          	j	ffffffe000200a20 <alloc_pages+0x44>
    return (void *)(PA2VA(PFN2PHYS(pfn)));
ffffffe000200a0c:	fe843783          	ld	a5,-24(s0)
ffffffe000200a10:	00c79713          	slli	a4,a5,0xc
ffffffe000200a14:	fff00793          	li	a5,-1
ffffffe000200a18:	02579793          	slli	a5,a5,0x25
ffffffe000200a1c:	00f707b3          	add	a5,a4,a5
}
ffffffe000200a20:	00078513          	mv	a0,a5
ffffffe000200a24:	02813083          	ld	ra,40(sp)
ffffffe000200a28:	02013403          	ld	s0,32(sp)
ffffffe000200a2c:	03010113          	addi	sp,sp,48
ffffffe000200a30:	00008067          	ret

ffffffe000200a34 <alloc_page>:

void *alloc_page() {
ffffffe000200a34:	ff010113          	addi	sp,sp,-16
ffffffe000200a38:	00113423          	sd	ra,8(sp)
ffffffe000200a3c:	00813023          	sd	s0,0(sp)
ffffffe000200a40:	01010413          	addi	s0,sp,16
    return alloc_pages(1);
ffffffe000200a44:	00100513          	li	a0,1
ffffffe000200a48:	f95ff0ef          	jal	ffffffe0002009dc <alloc_pages>
ffffffe000200a4c:	00050793          	mv	a5,a0
}
ffffffe000200a50:	00078513          	mv	a0,a5
ffffffe000200a54:	00813083          	ld	ra,8(sp)
ffffffe000200a58:	00013403          	ld	s0,0(sp)
ffffffe000200a5c:	01010113          	addi	sp,sp,16
ffffffe000200a60:	00008067          	ret

ffffffe000200a64 <free_pages>:

void free_pages(void *va) {
ffffffe000200a64:	fe010113          	addi	sp,sp,-32
ffffffe000200a68:	00113c23          	sd	ra,24(sp)
ffffffe000200a6c:	00813823          	sd	s0,16(sp)
ffffffe000200a70:	02010413          	addi	s0,sp,32
ffffffe000200a74:	fea43423          	sd	a0,-24(s0)
    buddy_free(PHYS2PFN(VA2PA((uint64_t)va)));
ffffffe000200a78:	fe843703          	ld	a4,-24(s0)
ffffffe000200a7c:	00100793          	li	a5,1
ffffffe000200a80:	02579793          	slli	a5,a5,0x25
ffffffe000200a84:	00f707b3          	add	a5,a4,a5
ffffffe000200a88:	00c7d793          	srli	a5,a5,0xc
ffffffe000200a8c:	00078513          	mv	a0,a5
ffffffe000200a90:	b7dff0ef          	jal	ffffffe00020060c <buddy_free>
}
ffffffe000200a94:	00000013          	nop
ffffffe000200a98:	01813083          	ld	ra,24(sp)
ffffffe000200a9c:	01013403          	ld	s0,16(sp)
ffffffe000200aa0:	02010113          	addi	sp,sp,32
ffffffe000200aa4:	00008067          	ret

ffffffe000200aa8 <kalloc>:

void *kalloc() {
ffffffe000200aa8:	ff010113          	addi	sp,sp,-16
ffffffe000200aac:	00113423          	sd	ra,8(sp)
ffffffe000200ab0:	00813023          	sd	s0,0(sp)
ffffffe000200ab4:	01010413          	addi	s0,sp,16
    // r = kmem.freelist;
    // kmem.freelist = r->next;
    
    // memset((void *)r, 0x0, PGSIZE);
    // return (void *)r;
    return alloc_page();
ffffffe000200ab8:	f7dff0ef          	jal	ffffffe000200a34 <alloc_page>
ffffffe000200abc:	00050793          	mv	a5,a0
}
ffffffe000200ac0:	00078513          	mv	a0,a5
ffffffe000200ac4:	00813083          	ld	ra,8(sp)
ffffffe000200ac8:	00013403          	ld	s0,0(sp)
ffffffe000200acc:	01010113          	addi	sp,sp,16
ffffffe000200ad0:	00008067          	ret

ffffffe000200ad4 <kfree>:

void kfree(void *addr) {
ffffffe000200ad4:	fe010113          	addi	sp,sp,-32
ffffffe000200ad8:	00113c23          	sd	ra,24(sp)
ffffffe000200adc:	00813823          	sd	s0,16(sp)
ffffffe000200ae0:	02010413          	addi	s0,sp,32
ffffffe000200ae4:	fea43423          	sd	a0,-24(s0)
    // memset(addr, 0x0, (uint64_t)PGSIZE);

    // r = (struct run *)addr;
    // r->next = kmem.freelist;
    // kmem.freelist = r;
    free_pages(addr);
ffffffe000200ae8:	fe843503          	ld	a0,-24(s0)
ffffffe000200aec:	f79ff0ef          	jal	ffffffe000200a64 <free_pages>

    return;
ffffffe000200af0:	00000013          	nop
}
ffffffe000200af4:	01813083          	ld	ra,24(sp)
ffffffe000200af8:	01013403          	ld	s0,16(sp)
ffffffe000200afc:	02010113          	addi	sp,sp,32
ffffffe000200b00:	00008067          	ret

ffffffe000200b04 <kfreerange>:

void kfreerange(char *start, char *end) {
ffffffe000200b04:	fd010113          	addi	sp,sp,-48
ffffffe000200b08:	02113423          	sd	ra,40(sp)
ffffffe000200b0c:	02813023          	sd	s0,32(sp)
ffffffe000200b10:	03010413          	addi	s0,sp,48
ffffffe000200b14:	fca43c23          	sd	a0,-40(s0)
ffffffe000200b18:	fcb43823          	sd	a1,-48(s0)
    char *addr = (char *)PGROUNDUP((uintptr_t)start);
ffffffe000200b1c:	fd843703          	ld	a4,-40(s0)
ffffffe000200b20:	000017b7          	lui	a5,0x1
ffffffe000200b24:	fff78793          	addi	a5,a5,-1 # fff <PGSIZE-0x1>
ffffffe000200b28:	00f70733          	add	a4,a4,a5
ffffffe000200b2c:	fffff7b7          	lui	a5,0xfffff
ffffffe000200b30:	00f777b3          	and	a5,a4,a5
ffffffe000200b34:	fef43423          	sd	a5,-24(s0)
    for (; (uintptr_t)(addr) + PGSIZE <= (uintptr_t)end; addr += PGSIZE) {
ffffffe000200b38:	01c0006f          	j	ffffffe000200b54 <kfreerange+0x50>
        kfree((void *)addr);
ffffffe000200b3c:	fe843503          	ld	a0,-24(s0)
ffffffe000200b40:	f95ff0ef          	jal	ffffffe000200ad4 <kfree>
    for (; (uintptr_t)(addr) + PGSIZE <= (uintptr_t)end; addr += PGSIZE) {
ffffffe000200b44:	fe843703          	ld	a4,-24(s0)
ffffffe000200b48:	000017b7          	lui	a5,0x1
ffffffe000200b4c:	00f707b3          	add	a5,a4,a5
ffffffe000200b50:	fef43423          	sd	a5,-24(s0)
ffffffe000200b54:	fe843703          	ld	a4,-24(s0)
ffffffe000200b58:	000017b7          	lui	a5,0x1
ffffffe000200b5c:	00f70733          	add	a4,a4,a5
ffffffe000200b60:	fd043783          	ld	a5,-48(s0)
ffffffe000200b64:	fce7fce3          	bgeu	a5,a4,ffffffe000200b3c <kfreerange+0x38>
    }
}
ffffffe000200b68:	00000013          	nop
ffffffe000200b6c:	00000013          	nop
ffffffe000200b70:	02813083          	ld	ra,40(sp)
ffffffe000200b74:	02013403          	ld	s0,32(sp)
ffffffe000200b78:	03010113          	addi	sp,sp,48
ffffffe000200b7c:	00008067          	ret

ffffffe000200b80 <mm_init>:

void mm_init(void) {
ffffffe000200b80:	ff010113          	addi	sp,sp,-16
ffffffe000200b84:	00113423          	sd	ra,8(sp)
ffffffe000200b88:	00813023          	sd	s0,0(sp)
ffffffe000200b8c:	01010413          	addi	s0,sp,16
    // kfreerange(_ekernel, (char *)PHY_END+PA2VA_OFFSET);
    buddy_init();
ffffffe000200b90:	861ff0ef          	jal	ffffffe0002003f0 <buddy_init>
    printk("...mm_init done!\n");
ffffffe000200b94:	00004517          	auipc	a0,0x4
ffffffe000200b98:	49c50513          	addi	a0,a0,1180 # ffffffe000205030 <__func__.0+0x20>
ffffffe000200b9c:	651030ef          	jal	ffffffe0002049ec <printk>
}
ffffffe000200ba0:	00000013          	nop
ffffffe000200ba4:	00813083          	ld	ra,8(sp)
ffffffe000200ba8:	00013403          	ld	s0,0(sp)
ffffffe000200bac:	01010113          	addi	sp,sp,16
ffffffe000200bb0:	00008067          	ret

ffffffe000200bb4 <get_page>:

// 增加计数;
uint64_t get_page(void* va){
ffffffe000200bb4:	fd010113          	addi	sp,sp,-48
ffffffe000200bb8:	02113423          	sd	ra,40(sp)
ffffffe000200bbc:	02813023          	sd	s0,32(sp)
ffffffe000200bc0:	03010413          	addi	s0,sp,48
ffffffe000200bc4:	fca43c23          	sd	a0,-40(s0)
    uint64_t pfn = PHYS2PFN(VA2PA((uint64_t)va));
ffffffe000200bc8:	fd843703          	ld	a4,-40(s0)
ffffffe000200bcc:	00100793          	li	a5,1
ffffffe000200bd0:	02579793          	slli	a5,a5,0x25
ffffffe000200bd4:	00f707b3          	add	a5,a4,a5
ffffffe000200bd8:	00c7d793          	srli	a5,a5,0xc
ffffffe000200bdc:	fef43423          	sd	a5,-24(s0)
    // check if the page is already allocated
    if (buddy.ref_cnt[pfn] == 0) {
ffffffe000200be0:	0000a797          	auipc	a5,0xa
ffffffe000200be4:	44078793          	addi	a5,a5,1088 # ffffffe00020b020 <buddy>
ffffffe000200be8:	0107b703          	ld	a4,16(a5)
ffffffe000200bec:	fe843783          	ld	a5,-24(s0)
ffffffe000200bf0:	00379793          	slli	a5,a5,0x3
ffffffe000200bf4:	00f707b3          	add	a5,a4,a5
ffffffe000200bf8:	0007b783          	ld	a5,0(a5)
ffffffe000200bfc:	00079663          	bnez	a5,ffffffe000200c08 <get_page+0x54>
        return 1;
ffffffe000200c00:	00100793          	li	a5,1
ffffffe000200c04:	0100006f          	j	ffffffe000200c14 <get_page+0x60>
    }
    page_ref_inc(pfn);
ffffffe000200c08:	fe843503          	ld	a0,-24(s0)
ffffffe000200c0c:	0c8000ef          	jal	ffffffe000200cd4 <page_ref_inc>
    return 0;
ffffffe000200c10:	00000793          	li	a5,0
}
ffffffe000200c14:	00078513          	mv	a0,a5
ffffffe000200c18:	02813083          	ld	ra,40(sp)
ffffffe000200c1c:	02013403          	ld	s0,32(sp)
ffffffe000200c20:	03010113          	addi	sp,sp,48
ffffffe000200c24:	00008067          	ret

ffffffe000200c28 <put_page>:
// 减少计数;
void put_page(void* va){
ffffffe000200c28:	fd010113          	addi	sp,sp,-48
ffffffe000200c2c:	02113423          	sd	ra,40(sp)
ffffffe000200c30:	02813023          	sd	s0,32(sp)
ffffffe000200c34:	03010413          	addi	s0,sp,48
ffffffe000200c38:	fca43c23          	sd	a0,-40(s0)
    uint64_t pfn = PHYS2PFN(VA2PA((uint64_t)va));
ffffffe000200c3c:	fd843703          	ld	a4,-40(s0)
ffffffe000200c40:	00100793          	li	a5,1
ffffffe000200c44:	02579793          	slli	a5,a5,0x25
ffffffe000200c48:	00f707b3          	add	a5,a4,a5
ffffffe000200c4c:	00c7d793          	srli	a5,a5,0xc
ffffffe000200c50:	fef43423          	sd	a5,-24(s0)
    printk("COW : %016lx\n",pfn);
ffffffe000200c54:	fe843583          	ld	a1,-24(s0)
ffffffe000200c58:	00004517          	auipc	a0,0x4
ffffffe000200c5c:	3f050513          	addi	a0,a0,1008 # ffffffe000205048 <__func__.0+0x38>
ffffffe000200c60:	58d030ef          	jal	ffffffe0002049ec <printk>
    page_ref_dec(pfn);
ffffffe000200c64:	fe843503          	ld	a0,-24(s0)
ffffffe000200c68:	0b0000ef          	jal	ffffffe000200d18 <page_ref_dec>
}
ffffffe000200c6c:	00000013          	nop
ffffffe000200c70:	02813083          	ld	ra,40(sp)
ffffffe000200c74:	02013403          	ld	s0,32(sp)
ffffffe000200c78:	03010113          	addi	sp,sp,48
ffffffe000200c7c:	00008067          	ret

ffffffe000200c80 <get_page_refcnt>:
// 获取计数;
uint64_t get_page_refcnt(void* va){
ffffffe000200c80:	fd010113          	addi	sp,sp,-48
ffffffe000200c84:	02813423          	sd	s0,40(sp)
ffffffe000200c88:	03010413          	addi	s0,sp,48
ffffffe000200c8c:	fca43c23          	sd	a0,-40(s0)
    uint64_t pfn = PHYS2PFN(VA2PA((uint64_t)va));
ffffffe000200c90:	fd843703          	ld	a4,-40(s0)
ffffffe000200c94:	00100793          	li	a5,1
ffffffe000200c98:	02579793          	slli	a5,a5,0x25
ffffffe000200c9c:	00f707b3          	add	a5,a4,a5
ffffffe000200ca0:	00c7d793          	srli	a5,a5,0xc
ffffffe000200ca4:	fef43423          	sd	a5,-24(s0)
    return buddy.ref_cnt[pfn];
ffffffe000200ca8:	0000a797          	auipc	a5,0xa
ffffffe000200cac:	37878793          	addi	a5,a5,888 # ffffffe00020b020 <buddy>
ffffffe000200cb0:	0107b703          	ld	a4,16(a5)
ffffffe000200cb4:	fe843783          	ld	a5,-24(s0)
ffffffe000200cb8:	00379793          	slli	a5,a5,0x3
ffffffe000200cbc:	00f707b3          	add	a5,a4,a5
ffffffe000200cc0:	0007b783          	ld	a5,0(a5)
}
ffffffe000200cc4:	00078513          	mv	a0,a5
ffffffe000200cc8:	02813403          	ld	s0,40(sp)
ffffffe000200ccc:	03010113          	addi	sp,sp,48
ffffffe000200cd0:	00008067          	ret

ffffffe000200cd4 <page_ref_inc>:

void page_ref_inc(uint64_t pfn) {
ffffffe000200cd4:	fe010113          	addi	sp,sp,-32
ffffffe000200cd8:	00813c23          	sd	s0,24(sp)
ffffffe000200cdc:	02010413          	addi	s0,sp,32
ffffffe000200ce0:	fea43423          	sd	a0,-24(s0)
    buddy.ref_cnt[pfn]++;
ffffffe000200ce4:	0000a797          	auipc	a5,0xa
ffffffe000200ce8:	33c78793          	addi	a5,a5,828 # ffffffe00020b020 <buddy>
ffffffe000200cec:	0107b703          	ld	a4,16(a5)
ffffffe000200cf0:	fe843783          	ld	a5,-24(s0)
ffffffe000200cf4:	00379793          	slli	a5,a5,0x3
ffffffe000200cf8:	00f707b3          	add	a5,a4,a5
ffffffe000200cfc:	0007b703          	ld	a4,0(a5)
ffffffe000200d00:	00170713          	addi	a4,a4,1
ffffffe000200d04:	00e7b023          	sd	a4,0(a5)
}
ffffffe000200d08:	00000013          	nop
ffffffe000200d0c:	01813403          	ld	s0,24(sp)
ffffffe000200d10:	02010113          	addi	sp,sp,32
ffffffe000200d14:	00008067          	ret

ffffffe000200d18 <page_ref_dec>:

void page_ref_dec(uint64_t pfn) {
ffffffe000200d18:	fe010113          	addi	sp,sp,-32
ffffffe000200d1c:	00113c23          	sd	ra,24(sp)
ffffffe000200d20:	00813823          	sd	s0,16(sp)
ffffffe000200d24:	02010413          	addi	s0,sp,32
ffffffe000200d28:	fea43423          	sd	a0,-24(s0)
    if (buddy.ref_cnt[pfn] > 0) {
ffffffe000200d2c:	0000a797          	auipc	a5,0xa
ffffffe000200d30:	2f478793          	addi	a5,a5,756 # ffffffe00020b020 <buddy>
ffffffe000200d34:	0107b703          	ld	a4,16(a5)
ffffffe000200d38:	fe843783          	ld	a5,-24(s0)
ffffffe000200d3c:	00379793          	slli	a5,a5,0x3
ffffffe000200d40:	00f707b3          	add	a5,a4,a5
ffffffe000200d44:	0007b783          	ld	a5,0(a5)
ffffffe000200d48:	02078463          	beqz	a5,ffffffe000200d70 <page_ref_dec+0x58>
        buddy.ref_cnt[pfn]--;
ffffffe000200d4c:	0000a797          	auipc	a5,0xa
ffffffe000200d50:	2d478793          	addi	a5,a5,724 # ffffffe00020b020 <buddy>
ffffffe000200d54:	0107b703          	ld	a4,16(a5)
ffffffe000200d58:	fe843783          	ld	a5,-24(s0)
ffffffe000200d5c:	00379793          	slli	a5,a5,0x3
ffffffe000200d60:	00f707b3          	add	a5,a4,a5
ffffffe000200d64:	0007b703          	ld	a4,0(a5)
ffffffe000200d68:	fff70713          	addi	a4,a4,-1
ffffffe000200d6c:	00e7b023          	sd	a4,0(a5)
    }
    if (buddy.ref_cnt[pfn] == 0) {
ffffffe000200d70:	0000a797          	auipc	a5,0xa
ffffffe000200d74:	2b078793          	addi	a5,a5,688 # ffffffe00020b020 <buddy>
ffffffe000200d78:	0107b703          	ld	a4,16(a5)
ffffffe000200d7c:	fe843783          	ld	a5,-24(s0)
ffffffe000200d80:	00379793          	slli	a5,a5,0x3
ffffffe000200d84:	00f707b3          	add	a5,a4,a5
ffffffe000200d88:	0007b783          	ld	a5,0(a5)
ffffffe000200d8c:	04079263          	bnez	a5,ffffffe000200dd0 <page_ref_dec+0xb8>
        Log("free page: %p", PFN2PHYS(pfn));
ffffffe000200d90:	fe843783          	ld	a5,-24(s0)
ffffffe000200d94:	00c79713          	slli	a4,a5,0xc
ffffffe000200d98:	00100793          	li	a5,1
ffffffe000200d9c:	01f79793          	slli	a5,a5,0x1f
ffffffe000200da0:	00f707b3          	add	a5,a4,a5
ffffffe000200da4:	00078713          	mv	a4,a5
ffffffe000200da8:	00004697          	auipc	a3,0x4
ffffffe000200dac:	2e068693          	addi	a3,a3,736 # ffffffe000205088 <__func__.0>
ffffffe000200db0:	0e300613          	li	a2,227
ffffffe000200db4:	00004597          	auipc	a1,0x4
ffffffe000200db8:	2a458593          	addi	a1,a1,676 # ffffffe000205058 <__func__.0+0x48>
ffffffe000200dbc:	00004517          	auipc	a0,0x4
ffffffe000200dc0:	2a450513          	addi	a0,a0,676 # ffffffe000205060 <__func__.0+0x50>
ffffffe000200dc4:	429030ef          	jal	ffffffe0002049ec <printk>
        buddy_free(pfn);
ffffffe000200dc8:	fe843503          	ld	a0,-24(s0)
ffffffe000200dcc:	841ff0ef          	jal	ffffffe00020060c <buddy_free>
    }
ffffffe000200dd0:	00000013          	nop
ffffffe000200dd4:	01813083          	ld	ra,24(sp)
ffffffe000200dd8:	01013403          	ld	s0,16(sp)
ffffffe000200ddc:	02010113          	addi	sp,sp,32
ffffffe000200de0:	00008067          	ret

ffffffe000200de4 <VMA_init>:
 * [phdr->p_vaddr ] -> offset phdr->p_offset 
 *  
 * For user stack [USER_END-PGSIZE,USER_END] VM_READ|VM_WRITE 
 * 
*/
static uint64_t VMA_init(struct task_struct* task){
ffffffe000200de4:	f8010113          	addi	sp,sp,-128
ffffffe000200de8:	06113c23          	sd	ra,120(sp)
ffffffe000200dec:	06813823          	sd	s0,112(sp)
ffffffe000200df0:	08010413          	addi	s0,sp,128
ffffffe000200df4:	f8a43423          	sd	a0,-120(s0)
    // from the `_sramdisk` is the address of elf life
    Elf64_Ehdr *ehdr = (Elf64_Ehdr *)_sramdisk;
ffffffe000200df8:	00007797          	auipc	a5,0x7
ffffffe000200dfc:	20878793          	addi	a5,a5,520 # ffffffe000208000 <_sramdisk>
ffffffe000200e00:	fef43023          	sd	a5,-32(s0)
    // get the programs headers
    Elf64_Phdr *phdrs = (Elf64_Phdr *)(_sramdisk+ehdr->e_phoff);
ffffffe000200e04:	fe043783          	ld	a5,-32(s0)
ffffffe000200e08:	0207b703          	ld	a4,32(a5)
ffffffe000200e0c:	00007797          	auipc	a5,0x7
ffffffe000200e10:	1f478793          	addi	a5,a5,500 # ffffffe000208000 <_sramdisk>
ffffffe000200e14:	00f707b3          	add	a5,a4,a5
ffffffe000200e18:	fcf43c23          	sd	a5,-40(s0)
    for(int i=0;i<ehdr->e_phnum;i++){
ffffffe000200e1c:	fe042623          	sw	zero,-20(s0)
ffffffe000200e20:	1740006f          	j	ffffffe000200f94 <VMA_init+0x1b0>
        Elf64_Phdr *phdr = phdrs + i;
ffffffe000200e24:	fec42703          	lw	a4,-20(s0)
ffffffe000200e28:	00070793          	mv	a5,a4
ffffffe000200e2c:	00379793          	slli	a5,a5,0x3
ffffffe000200e30:	40e787b3          	sub	a5,a5,a4
ffffffe000200e34:	00379793          	slli	a5,a5,0x3
ffffffe000200e38:	00078713          	mv	a4,a5
ffffffe000200e3c:	fd843783          	ld	a5,-40(s0)
ffffffe000200e40:	00e787b3          	add	a5,a5,a4
ffffffe000200e44:	fcf43823          	sd	a5,-48(s0)
        if(phdr->p_type == PT_LOAD){
ffffffe000200e48:	fd043783          	ld	a5,-48(s0)
ffffffe000200e4c:	0007a783          	lw	a5,0(a5)
ffffffe000200e50:	00078713          	mv	a4,a5
ffffffe000200e54:	00100793          	li	a5,1
ffffffe000200e58:	12f71863          	bne	a4,a5,ffffffe000200f88 <VMA_init+0x1a4>
            uint64_t VA = phdr->p_vaddr;
ffffffe000200e5c:	fd043783          	ld	a5,-48(s0)
ffffffe000200e60:	0107b783          	ld	a5,16(a5)
ffffffe000200e64:	fcf43423          	sd	a5,-56(s0)
            uint64_t offset = phdr->p_offset;
ffffffe000200e68:	fd043783          	ld	a5,-48(s0)
ffffffe000200e6c:	0087b783          	ld	a5,8(a5)
ffffffe000200e70:	fcf43023          	sd	a5,-64(s0)
            uint64_t page_offset = VA&0xFFF;
ffffffe000200e74:	fc843703          	ld	a4,-56(s0)
ffffffe000200e78:	000017b7          	lui	a5,0x1
ffffffe000200e7c:	fff78793          	addi	a5,a5,-1 # fff <PGSIZE-0x1>
ffffffe000200e80:	00f777b3          	and	a5,a4,a5
ffffffe000200e84:	faf43c23          	sd	a5,-72(s0)
            uint64_t file_size = phdr->p_filesz;
ffffffe000200e88:	fd043783          	ld	a5,-48(s0)
ffffffe000200e8c:	0207b783          	ld	a5,32(a5)
ffffffe000200e90:	faf43823          	sd	a5,-80(s0)
            uint64_t memory_size = phdr->p_memsz;
ffffffe000200e94:	fd043783          	ld	a5,-48(s0)
ffffffe000200e98:	0287b783          	ld	a5,40(a5)
ffffffe000200e9c:	faf43423          	sd	a5,-88(s0)
            uint64_t flags = phdr->p_flags;
ffffffe000200ea0:	fd043783          	ld	a5,-48(s0)
ffffffe000200ea4:	0047a783          	lw	a5,4(a5)
ffffffe000200ea8:	02079793          	slli	a5,a5,0x20
ffffffe000200eac:	0207d793          	srli	a5,a5,0x20
ffffffe000200eb0:	faf43023          	sd	a5,-96(s0)
            // phdr->flags R W X -> x w r p
            uint64_t perm = ((phdr->p_flags&0x2)<<1)|((phdr->p_flags&0x4)>>1)|((phdr->p_flags&0x1)<<3);
ffffffe000200eb4:	fd043783          	ld	a5,-48(s0)
ffffffe000200eb8:	0047a783          	lw	a5,4(a5)
ffffffe000200ebc:	0017979b          	slliw	a5,a5,0x1
ffffffe000200ec0:	0007879b          	sext.w	a5,a5
ffffffe000200ec4:	0047f793          	andi	a5,a5,4
ffffffe000200ec8:	0007871b          	sext.w	a4,a5
ffffffe000200ecc:	fd043783          	ld	a5,-48(s0)
ffffffe000200ed0:	0047a783          	lw	a5,4(a5)
ffffffe000200ed4:	0017d79b          	srliw	a5,a5,0x1
ffffffe000200ed8:	0007879b          	sext.w	a5,a5
ffffffe000200edc:	0027f793          	andi	a5,a5,2
ffffffe000200ee0:	0007879b          	sext.w	a5,a5
ffffffe000200ee4:	00f767b3          	or	a5,a4,a5
ffffffe000200ee8:	0007871b          	sext.w	a4,a5
ffffffe000200eec:	fd043783          	ld	a5,-48(s0)
ffffffe000200ef0:	0047a783          	lw	a5,4(a5)
ffffffe000200ef4:	0037979b          	slliw	a5,a5,0x3
ffffffe000200ef8:	0007879b          	sext.w	a5,a5
ffffffe000200efc:	0087f793          	andi	a5,a5,8
ffffffe000200f00:	0007879b          	sext.w	a5,a5
ffffffe000200f04:	00f767b3          	or	a5,a4,a5
ffffffe000200f08:	0007879b          	sext.w	a5,a5
ffffffe000200f0c:	02079793          	slli	a5,a5,0x20
ffffffe000200f10:	0207d793          	srli	a5,a5,0x20
ffffffe000200f14:	f8f43c23          	sd	a5,-104(s0)

            // set the valid virtual memory space for them.
            Log(BLUE"We have created the valid VMA mmap [%016lx,%016lx),perm = %d",PGROUNDDOWN(VA),PGROUNDDOWN(VA+memory_size),perm,CLEAR);
ffffffe000200f18:	fc843703          	ld	a4,-56(s0)
ffffffe000200f1c:	fffff7b7          	lui	a5,0xfffff
ffffffe000200f20:	00f776b3          	and	a3,a4,a5
ffffffe000200f24:	fc843703          	ld	a4,-56(s0)
ffffffe000200f28:	fa843783          	ld	a5,-88(s0)
ffffffe000200f2c:	00f70733          	add	a4,a4,a5
ffffffe000200f30:	fffff7b7          	lui	a5,0xfffff
ffffffe000200f34:	00f777b3          	and	a5,a4,a5
ffffffe000200f38:	00004897          	auipc	a7,0x4
ffffffe000200f3c:	16088893          	addi	a7,a7,352 # ffffffe000205098 <__func__.0+0x10>
ffffffe000200f40:	f9843803          	ld	a6,-104(s0)
ffffffe000200f44:	00068713          	mv	a4,a3
ffffffe000200f48:	00004697          	auipc	a3,0x4
ffffffe000200f4c:	3b868693          	addi	a3,a3,952 # ffffffe000205300 <__func__.3>
ffffffe000200f50:	03800613          	li	a2,56
ffffffe000200f54:	00004597          	auipc	a1,0x4
ffffffe000200f58:	14c58593          	addi	a1,a1,332 # ffffffe0002050a0 <__func__.0+0x18>
ffffffe000200f5c:	00004517          	auipc	a0,0x4
ffffffe000200f60:	14c50513          	addi	a0,a0,332 # ffffffe0002050a8 <__func__.0+0x20>
ffffffe000200f64:	289030ef          	jal	ffffffe0002049ec <printk>
            do_mmap(&task->mm,VA,memory_size,offset,file_size,perm);
ffffffe000200f68:	f8843783          	ld	a5,-120(s0)
ffffffe000200f6c:	0b078513          	addi	a0,a5,176 # fffffffffffff0b0 <VM_END+0xfffff0b0>
ffffffe000200f70:	f9843783          	ld	a5,-104(s0)
ffffffe000200f74:	fb043703          	ld	a4,-80(s0)
ffffffe000200f78:	fc043683          	ld	a3,-64(s0)
ffffffe000200f7c:	fa843603          	ld	a2,-88(s0)
ffffffe000200f80:	fc843583          	ld	a1,-56(s0)
ffffffe000200f84:	545000ef          	jal	ffffffe000201cc8 <do_mmap>
    for(int i=0;i<ehdr->e_phnum;i++){
ffffffe000200f88:	fec42783          	lw	a5,-20(s0)
ffffffe000200f8c:	0017879b          	addiw	a5,a5,1
ffffffe000200f90:	fef42623          	sw	a5,-20(s0)
ffffffe000200f94:	fe043783          	ld	a5,-32(s0)
ffffffe000200f98:	0387d783          	lhu	a5,56(a5)
ffffffe000200f9c:	0007871b          	sext.w	a4,a5
ffffffe000200fa0:	fec42783          	lw	a5,-20(s0)
ffffffe000200fa4:	0007879b          	sext.w	a5,a5
ffffffe000200fa8:	e6e7cee3          	blt	a5,a4,ffffffe000200e24 <VMA_init+0x40>

        }
    }
    // set for the user stack for them;
    /* flags : ->  */
    do_mmap(&task->mm,USER_END-PGSIZE,PGSIZE,0,0,0x7);
ffffffe000200fac:	f8843783          	ld	a5,-120(s0)
ffffffe000200fb0:	0b078513          	addi	a0,a5,176
ffffffe000200fb4:	00700793          	li	a5,7
ffffffe000200fb8:	00000713          	li	a4,0
ffffffe000200fbc:	00000693          	li	a3,0
ffffffe000200fc0:	00001637          	lui	a2,0x1
ffffffe000200fc4:	040005b7          	lui	a1,0x4000
ffffffe000200fc8:	fff58593          	addi	a1,a1,-1 # 3ffffff <OPENSBI_SIZE+0x3dfffff>
ffffffe000200fcc:	00c59593          	slli	a1,a1,0xc
ffffffe000200fd0:	4f9000ef          	jal	ffffffe000201cc8 <do_mmap>
    // store 
    task->thread.sepc = ehdr->e_entry;
ffffffe000200fd4:	fe043783          	ld	a5,-32(s0)
ffffffe000200fd8:	0187b703          	ld	a4,24(a5)
ffffffe000200fdc:	f8843783          	ld	a5,-120(s0)
ffffffe000200fe0:	08e7b823          	sd	a4,144(a5)
    return 0;
ffffffe000200fe4:	00000793          	li	a5,0
}
ffffffe000200fe8:	00078513          	mv	a0,a5
ffffffe000200fec:	07813083          	ld	ra,120(sp)
ffffffe000200ff0:	07013403          	ld	s0,112(sp)
ffffffe000200ff4:	08010113          	addi	sp,sp,128
ffffffe000200ff8:	00008067          	ret

ffffffe000200ffc <load_program>:


/**
 * @param task the program which need to load into the memory
*/
static uint64_t load_program(struct task_struct* task){
ffffffe000200ffc:	f7010113          	addi	sp,sp,-144
ffffffe000201000:	08113423          	sd	ra,136(sp)
ffffffe000201004:	08813023          	sd	s0,128(sp)
ffffffe000201008:	09010413          	addi	s0,sp,144
ffffffe00020100c:	f6a43c23          	sd	a0,-136(s0)
    // from the `_sramdisk` is the address of elf file
    Elf64_Ehdr *ehdr = (Elf64_Ehdr *)_sramdisk;
ffffffe000201010:	00007797          	auipc	a5,0x7
ffffffe000201014:	ff078793          	addi	a5,a5,-16 # ffffffe000208000 <_sramdisk>
ffffffe000201018:	fef43023          	sd	a5,-32(s0)
    // get the programs headers 
    Elf64_Phdr *phdrs = (Elf64_Phdr *)(_sramdisk + ehdr->e_phoff);
ffffffe00020101c:	fe043783          	ld	a5,-32(s0)
ffffffe000201020:	0207b703          	ld	a4,32(a5)
ffffffe000201024:	00007797          	auipc	a5,0x7
ffffffe000201028:	fdc78793          	addi	a5,a5,-36 # ffffffe000208000 <_sramdisk>
ffffffe00020102c:	00f707b3          	add	a5,a4,a5
ffffffe000201030:	fcf43c23          	sd	a5,-40(s0)
    for (int i = 0; i < ehdr->e_phnum; ++i) {
ffffffe000201034:	fe042623          	sw	zero,-20(s0)
ffffffe000201038:	1e40006f          	j	ffffffe00020121c <load_program+0x220>
        Elf64_Phdr *phdr = phdrs + i;
ffffffe00020103c:	fec42703          	lw	a4,-20(s0)
ffffffe000201040:	00070793          	mv	a5,a4
ffffffe000201044:	00379793          	slli	a5,a5,0x3
ffffffe000201048:	40e787b3          	sub	a5,a5,a4
ffffffe00020104c:	00379793          	slli	a5,a5,0x3
ffffffe000201050:	00078713          	mv	a4,a5
ffffffe000201054:	fd843783          	ld	a5,-40(s0)
ffffffe000201058:	00e787b3          	add	a5,a5,a4
ffffffe00020105c:	fcf43423          	sd	a5,-56(s0)
        // we just need to deal with the PT_LOAD part;
        if (phdr->p_type == PT_LOAD) {
ffffffe000201060:	fc843783          	ld	a5,-56(s0)
ffffffe000201064:	0007a783          	lw	a5,0(a5)
ffffffe000201068:	00078713          	mv	a4,a5
ffffffe00020106c:	00100793          	li	a5,1
ffffffe000201070:	1af71063          	bne	a4,a5,ffffffe000201210 <load_program+0x214>
            // alloc space and copy content
            // do mapping
            // code...
            // used to find the progrem content;
            // the start address in the virtual address
            uint64_t VA = phdr->p_vaddr;
ffffffe000201074:	fc843783          	ld	a5,-56(s0)
ffffffe000201078:	0107b783          	ld	a5,16(a5)
ffffffe00020107c:	fcf43023          	sd	a5,-64(s0)
            uint64_t page_offset = VA&0xFFF;
ffffffe000201080:	fc043703          	ld	a4,-64(s0)
ffffffe000201084:	000017b7          	lui	a5,0x1
ffffffe000201088:	fff78793          	addi	a5,a5,-1 # fff <PGSIZE-0x1>
ffffffe00020108c:	00f777b3          	and	a5,a4,a5
ffffffe000201090:	faf43c23          	sd	a5,-72(s0)
            uint64_t file_size = phdr->p_filesz;
ffffffe000201094:	fc843783          	ld	a5,-56(s0)
ffffffe000201098:	0207b783          	ld	a5,32(a5)
ffffffe00020109c:	faf43823          	sd	a5,-80(s0)
            // in order to supplement 0;
            uint64_t memory_size = phdr->p_memsz;
ffffffe0002010a0:	fc843783          	ld	a5,-56(s0)
ffffffe0002010a4:	0287b783          	ld	a5,40(a5)
ffffffe0002010a8:	faf43423          	sd	a5,-88(s0)
            uint64_t offset = phdr->p_offset;
ffffffe0002010ac:	fc843783          	ld	a5,-56(s0)
ffffffe0002010b0:	0087b783          	ld	a5,8(a5)
ffffffe0002010b4:	faf43023          	sd	a5,-96(s0)
            // the physical address
            char* PVA = (char*)alloc_pages((memory_size-1+PGSIZE)/PGSIZE);
ffffffe0002010b8:	fa843703          	ld	a4,-88(s0)
ffffffe0002010bc:	000017b7          	lui	a5,0x1
ffffffe0002010c0:	fff78793          	addi	a5,a5,-1 # fff <PGSIZE-0x1>
ffffffe0002010c4:	00f707b3          	add	a5,a4,a5
ffffffe0002010c8:	00c7d793          	srli	a5,a5,0xc
ffffffe0002010cc:	00078513          	mv	a0,a5
ffffffe0002010d0:	90dff0ef          	jal	ffffffe0002009dc <alloc_pages>
ffffffe0002010d4:	f8a43c23          	sd	a0,-104(s0)
            char* content = (char*)(_sramdisk+offset);
ffffffe0002010d8:	fa043703          	ld	a4,-96(s0)
ffffffe0002010dc:	00007797          	auipc	a5,0x7
ffffffe0002010e0:	f2478793          	addi	a5,a5,-220 # ffffffe000208000 <_sramdisk>
ffffffe0002010e4:	00f707b3          	add	a5,a4,a5
ffffffe0002010e8:	f8f43823          	sd	a5,-112(s0)
            // copy for the content;
            for(int i =0;i<memory_size;i++){
ffffffe0002010ec:	fe042423          	sw	zero,-24(s0)
ffffffe0002010f0:	0600006f          	j	ffffffe000201150 <load_program+0x154>
                    if(i<file_size)
ffffffe0002010f4:	fe842783          	lw	a5,-24(s0)
ffffffe0002010f8:	fb043703          	ld	a4,-80(s0)
ffffffe0002010fc:	02e7f863          	bgeu	a5,a4,ffffffe00020112c <load_program+0x130>
                        PVA[page_offset+i] = content[i];
ffffffe000201100:	fe842783          	lw	a5,-24(s0)
ffffffe000201104:	f9043703          	ld	a4,-112(s0)
ffffffe000201108:	00f70733          	add	a4,a4,a5
ffffffe00020110c:	fe842683          	lw	a3,-24(s0)
ffffffe000201110:	fb843783          	ld	a5,-72(s0)
ffffffe000201114:	00f687b3          	add	a5,a3,a5
ffffffe000201118:	f9843683          	ld	a3,-104(s0)
ffffffe00020111c:	00f687b3          	add	a5,a3,a5
ffffffe000201120:	00074703          	lbu	a4,0(a4)
ffffffe000201124:	00e78023          	sb	a4,0(a5)
ffffffe000201128:	01c0006f          	j	ffffffe000201144 <load_program+0x148>
                    else 
                        PVA[page_offset+i] = 0x0;
ffffffe00020112c:	fe842703          	lw	a4,-24(s0)
ffffffe000201130:	fb843783          	ld	a5,-72(s0)
ffffffe000201134:	00f707b3          	add	a5,a4,a5
ffffffe000201138:	f9843703          	ld	a4,-104(s0)
ffffffe00020113c:	00f707b3          	add	a5,a4,a5
ffffffe000201140:	00078023          	sb	zero,0(a5)
            for(int i =0;i<memory_size;i++){
ffffffe000201144:	fe842783          	lw	a5,-24(s0)
ffffffe000201148:	0017879b          	addiw	a5,a5,1
ffffffe00020114c:	fef42423          	sw	a5,-24(s0)
ffffffe000201150:	fe842783          	lw	a5,-24(s0)
ffffffe000201154:	fa843703          	ld	a4,-88(s0)
ffffffe000201158:	f8e7eee3          	bltu	a5,a4,ffffffe0002010f4 <load_program+0xf8>
            }
            //memset(PA+phdr->p_filesz,0,memory_size-file_size);
            uint64_t perm = 0x0;
ffffffe00020115c:	f8043423          	sd	zero,-120(s0)
            // 权限 U & V
            perm |= 1<<4|1<<0;
ffffffe000201160:	f8843783          	ld	a5,-120(s0)
ffffffe000201164:	0117e793          	ori	a5,a5,17
ffffffe000201168:	f8f43423          	sd	a5,-120(s0)
            // for R
            perm |= (phdr->p_flags&0x4) >>1;
ffffffe00020116c:	fc843783          	ld	a5,-56(s0)
ffffffe000201170:	0047a783          	lw	a5,4(a5)
ffffffe000201174:	0017d79b          	srliw	a5,a5,0x1
ffffffe000201178:	0007879b          	sext.w	a5,a5
ffffffe00020117c:	02079793          	slli	a5,a5,0x20
ffffffe000201180:	0207d793          	srli	a5,a5,0x20
ffffffe000201184:	0027f793          	andi	a5,a5,2
ffffffe000201188:	f8843703          	ld	a4,-120(s0)
ffffffe00020118c:	00f767b3          	or	a5,a4,a5
ffffffe000201190:	f8f43423          	sd	a5,-120(s0)
            // for W 
            perm |= (phdr->p_flags&0x2) <<1;
ffffffe000201194:	fc843783          	ld	a5,-56(s0)
ffffffe000201198:	0047a783          	lw	a5,4(a5)
ffffffe00020119c:	0017979b          	slliw	a5,a5,0x1
ffffffe0002011a0:	0007879b          	sext.w	a5,a5
ffffffe0002011a4:	02079793          	slli	a5,a5,0x20
ffffffe0002011a8:	0207d793          	srli	a5,a5,0x20
ffffffe0002011ac:	0047f793          	andi	a5,a5,4
ffffffe0002011b0:	f8843703          	ld	a4,-120(s0)
ffffffe0002011b4:	00f767b3          	or	a5,a4,a5
ffffffe0002011b8:	f8f43423          	sd	a5,-120(s0)
            // for X execute
            perm |= (phdr->p_flags&0x1) <<3;
ffffffe0002011bc:	fc843783          	ld	a5,-56(s0)
ffffffe0002011c0:	0047a783          	lw	a5,4(a5)
ffffffe0002011c4:	0037979b          	slliw	a5,a5,0x3
ffffffe0002011c8:	0007879b          	sext.w	a5,a5
ffffffe0002011cc:	02079793          	slli	a5,a5,0x20
ffffffe0002011d0:	0207d793          	srli	a5,a5,0x20
ffffffe0002011d4:	0087f793          	andi	a5,a5,8
ffffffe0002011d8:	f8843703          	ld	a4,-120(s0)
ffffffe0002011dc:	00f767b3          	or	a5,a4,a5
ffffffe0002011e0:	f8f43423          	sd	a5,-120(s0)

            create_mapping(task->pgd,VA,(uint64_t)PVA-PA2VA_OFFSET,memory_size,perm);
ffffffe0002011e4:	f7843783          	ld	a5,-136(s0)
ffffffe0002011e8:	0a87b503          	ld	a0,168(a5)
ffffffe0002011ec:	f9843703          	ld	a4,-104(s0)
ffffffe0002011f0:	04100793          	li	a5,65
ffffffe0002011f4:	01f79793          	slli	a5,a5,0x1f
ffffffe0002011f8:	00f707b3          	add	a5,a4,a5
ffffffe0002011fc:	f8843703          	ld	a4,-120(s0)
ffffffe000201200:	fa843683          	ld	a3,-88(s0)
ffffffe000201204:	00078613          	mv	a2,a5
ffffffe000201208:	fc043583          	ld	a1,-64(s0)
ffffffe00020120c:	558020ef          	jal	ffffffe000203764 <create_mapping>
    for (int i = 0; i < ehdr->e_phnum; ++i) {
ffffffe000201210:	fec42783          	lw	a5,-20(s0)
ffffffe000201214:	0017879b          	addiw	a5,a5,1
ffffffe000201218:	fef42623          	sw	a5,-20(s0)
ffffffe00020121c:	fe043783          	ld	a5,-32(s0)
ffffffe000201220:	0387d783          	lhu	a5,56(a5)
ffffffe000201224:	0007871b          	sext.w	a4,a5
ffffffe000201228:	fec42783          	lw	a5,-20(s0)
ffffffe00020122c:	0007879b          	sext.w	a5,a5
ffffffe000201230:	e0e7c6e3          	blt	a5,a4,ffffffe00020103c <load_program+0x40>
        }
    }
    uint64_t user_stack = (uint64_t)alloc_page();
ffffffe000201234:	801ff0ef          	jal	ffffffe000200a34 <alloc_page>
ffffffe000201238:	00050793          	mv	a5,a0
ffffffe00020123c:	fcf43823          	sd	a5,-48(s0)
    create_mapping(task->pgd,USER_END-PGSIZE,user_stack-PA2VA_OFFSET,PGSIZE,0x17);
ffffffe000201240:	f7843783          	ld	a5,-136(s0)
ffffffe000201244:	0a87b503          	ld	a0,168(a5)
ffffffe000201248:	fd043703          	ld	a4,-48(s0)
ffffffe00020124c:	04100793          	li	a5,65
ffffffe000201250:	01f79793          	slli	a5,a5,0x1f
ffffffe000201254:	00f707b3          	add	a5,a4,a5
ffffffe000201258:	01700713          	li	a4,23
ffffffe00020125c:	000016b7          	lui	a3,0x1
ffffffe000201260:	00078613          	mv	a2,a5
ffffffe000201264:	040007b7          	lui	a5,0x4000
ffffffe000201268:	fff78793          	addi	a5,a5,-1 # 3ffffff <OPENSBI_SIZE+0x3dfffff>
ffffffe00020126c:	00c79593          	slli	a1,a5,0xc
ffffffe000201270:	4f4020ef          	jal	ffffffe000203764 <create_mapping>
    task->thread.sepc = ehdr->e_entry;
ffffffe000201274:	fe043783          	ld	a5,-32(s0)
ffffffe000201278:	0187b703          	ld	a4,24(a5)
ffffffe00020127c:	f7843783          	ld	a5,-136(s0)
ffffffe000201280:	08e7b823          	sd	a4,144(a5)
}
ffffffe000201284:	00000013          	nop
ffffffe000201288:	00078513          	mv	a0,a5
ffffffe00020128c:	08813083          	ld	ra,136(sp)
ffffffe000201290:	08013403          	ld	s0,128(sp)
ffffffe000201294:	09010113          	addi	sp,sp,144
ffffffe000201298:	00008067          	ret

ffffffe00020129c <task_init>:
 * - The reason that ,we do this is to use the demanding paging avoiding the case that cause page waste;
 * - so at this part,we directly set the VMA for data/text and user stack; 
 * 
 * 
*/
void task_init() {
ffffffe00020129c:	fc010113          	addi	sp,sp,-64
ffffffe0002012a0:	02113c23          	sd	ra,56(sp)
ffffffe0002012a4:	02813823          	sd	s0,48(sp)
ffffffe0002012a8:	02913423          	sd	s1,40(sp)
ffffffe0002012ac:	04010413          	addi	s0,sp,64
    srand(2024);
ffffffe0002012b0:	7e800513          	li	a0,2024
ffffffe0002012b4:	7b8030ef          	jal	ffffffe000204a6c <srand>
    // 5. 将 current 和 task[0] 指向 idle

    /* YOUR CODE HERE */
    // Part one we need to init the idle process;
    // initial part;
    Log(PURPLE "the number of tasks is %d",tasks_number,CLEAR);
ffffffe0002012b8:	00006797          	auipc	a5,0x6
ffffffe0002012bc:	d5878793          	addi	a5,a5,-680 # ffffffe000207010 <tasks_number>
ffffffe0002012c0:	0007b703          	ld	a4,0(a5)
ffffffe0002012c4:	00004797          	auipc	a5,0x4
ffffffe0002012c8:	dd478793          	addi	a5,a5,-556 # ffffffe000205098 <__func__.0+0x10>
ffffffe0002012cc:	00004697          	auipc	a3,0x4
ffffffe0002012d0:	04468693          	addi	a3,a3,68 # ffffffe000205310 <__func__.2>
ffffffe0002012d4:	0a200613          	li	a2,162
ffffffe0002012d8:	00004597          	auipc	a1,0x4
ffffffe0002012dc:	dc858593          	addi	a1,a1,-568 # ffffffe0002050a0 <__func__.0+0x18>
ffffffe0002012e0:	00004517          	auipc	a0,0x4
ffffffe0002012e4:	e2850513          	addi	a0,a0,-472 # ffffffe000205108 <__func__.0+0x80>
ffffffe0002012e8:	704030ef          	jal	ffffffe0002049ec <printk>
    Log(RED "We start to task_init" CLEAR);
ffffffe0002012ec:	00004697          	auipc	a3,0x4
ffffffe0002012f0:	02468693          	addi	a3,a3,36 # ffffffe000205310 <__func__.2>
ffffffe0002012f4:	0a300613          	li	a2,163
ffffffe0002012f8:	00004597          	auipc	a1,0x4
ffffffe0002012fc:	da858593          	addi	a1,a1,-600 # ffffffe0002050a0 <__func__.0+0x18>
ffffffe000201300:	00004517          	auipc	a0,0x4
ffffffe000201304:	e4050513          	addi	a0,a0,-448 # ffffffe000205140 <__func__.0+0xb8>
ffffffe000201308:	6e4030ef          	jal	ffffffe0002049ec <printk>
    idle = (struct task_struct*)kalloc(); // 分配一个物理页面; idle 是指一个闲置的进程;
ffffffe00020130c:	f9cff0ef          	jal	ffffffe000200aa8 <kalloc>
ffffffe000201310:	00050713          	mv	a4,a0
ffffffe000201314:	0000a797          	auipc	a5,0xa
ffffffe000201318:	cf478793          	addi	a5,a5,-780 # ffffffe00020b008 <idle>
ffffffe00020131c:	00e7b023          	sd	a4,0(a5)
    idle->state = TASK_RUNNING;
ffffffe000201320:	0000a797          	auipc	a5,0xa
ffffffe000201324:	ce878793          	addi	a5,a5,-792 # ffffffe00020b008 <idle>
ffffffe000201328:	0007b783          	ld	a5,0(a5)
ffffffe00020132c:	0007b023          	sd	zero,0(a5)
    idle->counter = 0;
ffffffe000201330:	0000a797          	auipc	a5,0xa
ffffffe000201334:	cd878793          	addi	a5,a5,-808 # ffffffe00020b008 <idle>
ffffffe000201338:	0007b783          	ld	a5,0(a5)
ffffffe00020133c:	0007b423          	sd	zero,8(a5)
    idle->priority = 0;
ffffffe000201340:	0000a797          	auipc	a5,0xa
ffffffe000201344:	cc878793          	addi	a5,a5,-824 # ffffffe00020b008 <idle>
ffffffe000201348:	0007b783          	ld	a5,0(a5)
ffffffe00020134c:	0007b823          	sd	zero,16(a5)
    idle->pid = 0;
ffffffe000201350:	0000a797          	auipc	a5,0xa
ffffffe000201354:	cb878793          	addi	a5,a5,-840 # ffffffe00020b008 <idle>
ffffffe000201358:	0007b783          	ld	a5,0(a5)
ffffffe00020135c:	0007bc23          	sd	zero,24(a5)
    for(int i =0;i<12;i++)
ffffffe000201360:	fc042e23          	sw	zero,-36(s0)
ffffffe000201364:	0300006f          	j	ffffffe000201394 <task_init+0xf8>
        idle->thread.s[i] = 0;
ffffffe000201368:	0000a797          	auipc	a5,0xa
ffffffe00020136c:	ca078793          	addi	a5,a5,-864 # ffffffe00020b008 <idle>
ffffffe000201370:	0007b703          	ld	a4,0(a5)
ffffffe000201374:	fdc42783          	lw	a5,-36(s0)
ffffffe000201378:	00678793          	addi	a5,a5,6
ffffffe00020137c:	00379793          	slli	a5,a5,0x3
ffffffe000201380:	00f707b3          	add	a5,a4,a5
ffffffe000201384:	0007b023          	sd	zero,0(a5)
    for(int i =0;i<12;i++)
ffffffe000201388:	fdc42783          	lw	a5,-36(s0)
ffffffe00020138c:	0017879b          	addiw	a5,a5,1
ffffffe000201390:	fcf42e23          	sw	a5,-36(s0)
ffffffe000201394:	fdc42783          	lw	a5,-36(s0)
ffffffe000201398:	0007871b          	sext.w	a4,a5
ffffffe00020139c:	00b00793          	li	a5,11
ffffffe0002013a0:	fce7d4e3          	bge	a5,a4,ffffffe000201368 <task_init+0xcc>

    current = idle;
ffffffe0002013a4:	0000a797          	auipc	a5,0xa
ffffffe0002013a8:	c6478793          	addi	a5,a5,-924 # ffffffe00020b008 <idle>
ffffffe0002013ac:	0007b703          	ld	a4,0(a5)
ffffffe0002013b0:	0000a797          	auipc	a5,0xa
ffffffe0002013b4:	c6078793          	addi	a5,a5,-928 # ffffffe00020b010 <current>
ffffffe0002013b8:	00e7b023          	sd	a4,0(a5)
    task[0] = idle;
ffffffe0002013bc:	0000a797          	auipc	a5,0xa
ffffffe0002013c0:	c4c78793          	addi	a5,a5,-948 # ffffffe00020b008 <idle>
ffffffe0002013c4:	0007b703          	ld	a4,0(a5)
ffffffe0002013c8:	0000a797          	auipc	a5,0xa
ffffffe0002013cc:	c7078793          	addi	a5,a5,-912 # ffffffe00020b038 <task>
ffffffe0002013d0:	00e7b023          	sd	a4,0(a5)
    //     - counter  = 0;
    //     - priority = rand() 产生的随机数（控制范围在 [PRIORITY_MIN, PRIORITY_MAX] 之间）
    // 3. 为 task[1] ~ task[NR_TASKS - 1] 设置 thread_struct 中的 ra 和 sp
    //     - ra 设置为 __dummy（见 4.2.2）的地址
    //     - sp 设置为该线程申请的物理页的高地址
    for(int i=1;i<=tasks_number;i++){
ffffffe0002013d4:	00100793          	li	a5,1
ffffffe0002013d8:	fcf42c23          	sw	a5,-40(s0)
ffffffe0002013dc:	3400006f          	j	ffffffe00020171c <task_init+0x480>
        /**
         * here we only init the first process.
         * and make other process as NULL, because they are waiting for initialization;
        */
        task[i] = (struct task_struct*)kalloc();
ffffffe0002013e0:	ec8ff0ef          	jal	ffffffe000200aa8 <kalloc>
ffffffe0002013e4:	00050693          	mv	a3,a0
ffffffe0002013e8:	0000a717          	auipc	a4,0xa
ffffffe0002013ec:	c5070713          	addi	a4,a4,-944 # ffffffe00020b038 <task>
ffffffe0002013f0:	fd842783          	lw	a5,-40(s0)
ffffffe0002013f4:	00379793          	slli	a5,a5,0x3
ffffffe0002013f8:	00f707b3          	add	a5,a4,a5
ffffffe0002013fc:	00d7b023          	sd	a3,0(a5)
        task[i]->state = TASK_RUNNING;
ffffffe000201400:	0000a717          	auipc	a4,0xa
ffffffe000201404:	c3870713          	addi	a4,a4,-968 # ffffffe00020b038 <task>
ffffffe000201408:	fd842783          	lw	a5,-40(s0)
ffffffe00020140c:	00379793          	slli	a5,a5,0x3
ffffffe000201410:	00f707b3          	add	a5,a4,a5
ffffffe000201414:	0007b783          	ld	a5,0(a5)
ffffffe000201418:	0007b023          	sd	zero,0(a5)
        task[i]->counter = 0;
ffffffe00020141c:	0000a717          	auipc	a4,0xa
ffffffe000201420:	c1c70713          	addi	a4,a4,-996 # ffffffe00020b038 <task>
ffffffe000201424:	fd842783          	lw	a5,-40(s0)
ffffffe000201428:	00379793          	slli	a5,a5,0x3
ffffffe00020142c:	00f707b3          	add	a5,a4,a5
ffffffe000201430:	0007b783          	ld	a5,0(a5)
ffffffe000201434:	0007b423          	sd	zero,8(a5)
        int random_number = (rand()%(PRIORITY_MAX-PRIORITY_MIN+1))+PRIORITY_MIN;
ffffffe000201438:	678030ef          	jal	ffffffe000204ab0 <rand>
ffffffe00020143c:	00050793          	mv	a5,a0
ffffffe000201440:	00078713          	mv	a4,a5
ffffffe000201444:	00a00793          	li	a5,10
ffffffe000201448:	02f767bb          	remw	a5,a4,a5
ffffffe00020144c:	0007879b          	sext.w	a5,a5
ffffffe000201450:	0017879b          	addiw	a5,a5,1
ffffffe000201454:	fcf42623          	sw	a5,-52(s0)
        task[i]->priority = random_number;
ffffffe000201458:	0000a717          	auipc	a4,0xa
ffffffe00020145c:	be070713          	addi	a4,a4,-1056 # ffffffe00020b038 <task>
ffffffe000201460:	fd842783          	lw	a5,-40(s0)
ffffffe000201464:	00379793          	slli	a5,a5,0x3
ffffffe000201468:	00f707b3          	add	a5,a4,a5
ffffffe00020146c:	0007b783          	ld	a5,0(a5)
ffffffe000201470:	fcc42703          	lw	a4,-52(s0)
ffffffe000201474:	00e7b823          	sd	a4,16(a5)
        task[i]->pid = i;
ffffffe000201478:	0000a717          	auipc	a4,0xa
ffffffe00020147c:	bc070713          	addi	a4,a4,-1088 # ffffffe00020b038 <task>
ffffffe000201480:	fd842783          	lw	a5,-40(s0)
ffffffe000201484:	00379793          	slli	a5,a5,0x3
ffffffe000201488:	00f707b3          	add	a5,a4,a5
ffffffe00020148c:	0007b783          	ld	a5,0(a5)
ffffffe000201490:	fd842703          	lw	a4,-40(s0)
ffffffe000201494:	00e7bc23          	sd	a4,24(a5)
        //Log(GREEN "%d %d", i,random_number ,CLEAR);
        task[i]->thread.ra = (uint64_t)__dummy;
ffffffe000201498:	0000a717          	auipc	a4,0xa
ffffffe00020149c:	ba070713          	addi	a4,a4,-1120 # ffffffe00020b038 <task>
ffffffe0002014a0:	fd842783          	lw	a5,-40(s0)
ffffffe0002014a4:	00379793          	slli	a5,a5,0x3
ffffffe0002014a8:	00f707b3          	add	a5,a4,a5
ffffffe0002014ac:	0007b783          	ld	a5,0(a5)
ffffffe0002014b0:	fffff717          	auipc	a4,0xfffff
ffffffe0002014b4:	d4470713          	addi	a4,a4,-700 # ffffffe0002001f4 <__dummy>
ffffffe0002014b8:	02e7b023          	sd	a4,32(a5)
        // 这里的 sp 表示的是我们申请了一个页的高地址，也就是 页的开头;
        task[i]->thread.sp = (uint64_t)task[i] + PGSIZE;
ffffffe0002014bc:	0000a717          	auipc	a4,0xa
ffffffe0002014c0:	b7c70713          	addi	a4,a4,-1156 # ffffffe00020b038 <task>
ffffffe0002014c4:	fd842783          	lw	a5,-40(s0)
ffffffe0002014c8:	00379793          	slli	a5,a5,0x3
ffffffe0002014cc:	00f707b3          	add	a5,a4,a5
ffffffe0002014d0:	0007b783          	ld	a5,0(a5)
ffffffe0002014d4:	00078693          	mv	a3,a5
ffffffe0002014d8:	0000a717          	auipc	a4,0xa
ffffffe0002014dc:	b6070713          	addi	a4,a4,-1184 # ffffffe00020b038 <task>
ffffffe0002014e0:	fd842783          	lw	a5,-40(s0)
ffffffe0002014e4:	00379793          	slli	a5,a5,0x3
ffffffe0002014e8:	00f707b3          	add	a5,a4,a5
ffffffe0002014ec:	0007b783          	ld	a5,0(a5)
ffffffe0002014f0:	00001737          	lui	a4,0x1
ffffffe0002014f4:	00e68733          	add	a4,a3,a4
ffffffe0002014f8:	02e7b423          	sd	a4,40(a5)
        for(int j=0;j<12;j++)
ffffffe0002014fc:	fc042a23          	sw	zero,-44(s0)
ffffffe000201500:	03c0006f          	j	ffffffe00020153c <task_init+0x2a0>
            task[i]->thread.s[j] = 0;     
ffffffe000201504:	0000a717          	auipc	a4,0xa
ffffffe000201508:	b3470713          	addi	a4,a4,-1228 # ffffffe00020b038 <task>
ffffffe00020150c:	fd842783          	lw	a5,-40(s0)
ffffffe000201510:	00379793          	slli	a5,a5,0x3
ffffffe000201514:	00f707b3          	add	a5,a4,a5
ffffffe000201518:	0007b703          	ld	a4,0(a5)
ffffffe00020151c:	fd442783          	lw	a5,-44(s0)
ffffffe000201520:	00678793          	addi	a5,a5,6
ffffffe000201524:	00379793          	slli	a5,a5,0x3
ffffffe000201528:	00f707b3          	add	a5,a4,a5
ffffffe00020152c:	0007b023          	sd	zero,0(a5)
        for(int j=0;j<12;j++)
ffffffe000201530:	fd442783          	lw	a5,-44(s0)
ffffffe000201534:	0017879b          	addiw	a5,a5,1
ffffffe000201538:	fcf42a23          	sw	a5,-44(s0)
ffffffe00020153c:	fd442783          	lw	a5,-44(s0)
ffffffe000201540:	0007871b          	sext.w	a4,a5
ffffffe000201544:	00b00793          	li	a5,11
ffffffe000201548:	fae7dee3          	bge	a5,a4,ffffffe000201504 <task_init+0x268>
         * The initial status :
         *    SPIE = 1 5-bit
         *    SPP = 0 8-bit
         *    SUM = 1 18-bit 
         * */ 
        task[i]->thread.sepc = USER_START;
ffffffe00020154c:	0000a717          	auipc	a4,0xa
ffffffe000201550:	aec70713          	addi	a4,a4,-1300 # ffffffe00020b038 <task>
ffffffe000201554:	fd842783          	lw	a5,-40(s0)
ffffffe000201558:	00379793          	slli	a5,a5,0x3
ffffffe00020155c:	00f707b3          	add	a5,a4,a5
ffffffe000201560:	0007b783          	ld	a5,0(a5)
ffffffe000201564:	0807b823          	sd	zero,144(a5)
        task[i]->thread.sscratch = USER_END;
ffffffe000201568:	0000a717          	auipc	a4,0xa
ffffffe00020156c:	ad070713          	addi	a4,a4,-1328 # ffffffe00020b038 <task>
ffffffe000201570:	fd842783          	lw	a5,-40(s0)
ffffffe000201574:	00379793          	slli	a5,a5,0x3
ffffffe000201578:	00f707b3          	add	a5,a4,a5
ffffffe00020157c:	0007b783          	ld	a5,0(a5)
ffffffe000201580:	00100713          	li	a4,1
ffffffe000201584:	02671713          	slli	a4,a4,0x26
ffffffe000201588:	0ae7b023          	sd	a4,160(a5)
        task[i]->thread.sstatus = 0x40020;   
ffffffe00020158c:	0000a717          	auipc	a4,0xa
ffffffe000201590:	aac70713          	addi	a4,a4,-1364 # ffffffe00020b038 <task>
ffffffe000201594:	fd842783          	lw	a5,-40(s0)
ffffffe000201598:	00379793          	slli	a5,a5,0x3
ffffffe00020159c:	00f707b3          	add	a5,a4,a5
ffffffe0002015a0:	0007b783          	ld	a5,0(a5)
ffffffe0002015a4:	00040737          	lui	a4,0x40
ffffffe0002015a8:	02070713          	addi	a4,a4,32 # 40020 <PGSIZE+0x3f020>
ffffffe0002015ac:	08e7bc23          	sd	a4,152(a5)
        // copy for the page table
        task[i]->pgd = (uint64_t*)alloc_page();
ffffffe0002015b0:	0000a717          	auipc	a4,0xa
ffffffe0002015b4:	a8870713          	addi	a4,a4,-1400 # ffffffe00020b038 <task>
ffffffe0002015b8:	fd842783          	lw	a5,-40(s0)
ffffffe0002015bc:	00379793          	slli	a5,a5,0x3
ffffffe0002015c0:	00f707b3          	add	a5,a4,a5
ffffffe0002015c4:	0007b483          	ld	s1,0(a5)
ffffffe0002015c8:	c6cff0ef          	jal	ffffffe000200a34 <alloc_page>
ffffffe0002015cc:	00050793          	mv	a5,a0
ffffffe0002015d0:	0af4b423          	sd	a5,168(s1)
        Log(RED "task[1]->pgd: %016lx",task[i]->pgd,CLEAR);
ffffffe0002015d4:	0000a717          	auipc	a4,0xa
ffffffe0002015d8:	a6470713          	addi	a4,a4,-1436 # ffffffe00020b038 <task>
ffffffe0002015dc:	fd842783          	lw	a5,-40(s0)
ffffffe0002015e0:	00379793          	slli	a5,a5,0x3
ffffffe0002015e4:	00f707b3          	add	a5,a4,a5
ffffffe0002015e8:	0007b783          	ld	a5,0(a5)
ffffffe0002015ec:	0a87b703          	ld	a4,168(a5)
ffffffe0002015f0:	00004797          	auipc	a5,0x4
ffffffe0002015f4:	aa878793          	addi	a5,a5,-1368 # ffffffe000205098 <__func__.0+0x10>
ffffffe0002015f8:	00004697          	auipc	a3,0x4
ffffffe0002015fc:	d1868693          	addi	a3,a3,-744 # ffffffe000205310 <__func__.2>
ffffffe000201600:	0d300613          	li	a2,211
ffffffe000201604:	00004597          	auipc	a1,0x4
ffffffe000201608:	a9c58593          	addi	a1,a1,-1380 # ffffffe0002050a0 <__func__.0+0x18>
ffffffe00020160c:	00004517          	auipc	a0,0x4
ffffffe000201610:	b6c50513          	addi	a0,a0,-1172 # ffffffe000205178 <__func__.0+0xf0>
ffffffe000201614:	3d8030ef          	jal	ffffffe0002049ec <printk>
        for(int j=0;j<PGSIZE/8;j++)
ffffffe000201618:	fc042823          	sw	zero,-48(s0)
ffffffe00020161c:	0540006f          	j	ffffffe000201670 <task_init+0x3d4>
            task[i]->pgd[j] = swapper_pg_dir[j];
ffffffe000201620:	0000a717          	auipc	a4,0xa
ffffffe000201624:	a1870713          	addi	a4,a4,-1512 # ffffffe00020b038 <task>
ffffffe000201628:	fd842783          	lw	a5,-40(s0)
ffffffe00020162c:	00379793          	slli	a5,a5,0x3
ffffffe000201630:	00f707b3          	add	a5,a4,a5
ffffffe000201634:	0007b783          	ld	a5,0(a5)
ffffffe000201638:	0a87b703          	ld	a4,168(a5)
ffffffe00020163c:	fd042783          	lw	a5,-48(s0)
ffffffe000201640:	00379793          	slli	a5,a5,0x3
ffffffe000201644:	00f707b3          	add	a5,a4,a5
ffffffe000201648:	0000c697          	auipc	a3,0xc
ffffffe00020164c:	9b868693          	addi	a3,a3,-1608 # ffffffe00020d000 <swapper_pg_dir>
ffffffe000201650:	fd042703          	lw	a4,-48(s0)
ffffffe000201654:	00371713          	slli	a4,a4,0x3
ffffffe000201658:	00e68733          	add	a4,a3,a4
ffffffe00020165c:	00073703          	ld	a4,0(a4)
ffffffe000201660:	00e7b023          	sd	a4,0(a5)
        for(int j=0;j<PGSIZE/8;j++)
ffffffe000201664:	fd042783          	lw	a5,-48(s0)
ffffffe000201668:	0017879b          	addiw	a5,a5,1
ffffffe00020166c:	fcf42823          	sw	a5,-48(s0)
ffffffe000201670:	fd042783          	lw	a5,-48(s0)
ffffffe000201674:	0007871b          	sext.w	a4,a5
ffffffe000201678:	1ff00793          	li	a5,511
ffffffe00020167c:	fae7d2e3          	bge	a5,a4,ffffffe000201620 <task_init+0x384>
        /**
         * @todo
         * we change the method for demand-paging
         * 
        */
       task[i]->mm = *(struct mm_struct*)alloc_page();
ffffffe000201680:	bb4ff0ef          	jal	ffffffe000200a34 <alloc_page>
ffffffe000201684:	00050693          	mv	a3,a0
ffffffe000201688:	0000a717          	auipc	a4,0xa
ffffffe00020168c:	9b070713          	addi	a4,a4,-1616 # ffffffe00020b038 <task>
ffffffe000201690:	fd842783          	lw	a5,-40(s0)
ffffffe000201694:	00379793          	slli	a5,a5,0x3
ffffffe000201698:	00f707b3          	add	a5,a4,a5
ffffffe00020169c:	0007b783          	ld	a5,0(a5)
ffffffe0002016a0:	0006b703          	ld	a4,0(a3)
ffffffe0002016a4:	0ae7b823          	sd	a4,176(a5)
       memset(&task[i]->mm,0,sizeof(struct mm_struct));
ffffffe0002016a8:	0000a717          	auipc	a4,0xa
ffffffe0002016ac:	99070713          	addi	a4,a4,-1648 # ffffffe00020b038 <task>
ffffffe0002016b0:	fd842783          	lw	a5,-40(s0)
ffffffe0002016b4:	00379793          	slli	a5,a5,0x3
ffffffe0002016b8:	00f707b3          	add	a5,a4,a5
ffffffe0002016bc:	0007b783          	ld	a5,0(a5)
ffffffe0002016c0:	0b078793          	addi	a5,a5,176
ffffffe0002016c4:	00800613          	li	a2,8
ffffffe0002016c8:	00000593          	li	a1,0
ffffffe0002016cc:	00078513          	mv	a0,a5
ffffffe0002016d0:	43c030ef          	jal	ffffffe000204b0c <memset>
       task[i]->mm.mmap = NULL;
ffffffe0002016d4:	0000a717          	auipc	a4,0xa
ffffffe0002016d8:	96470713          	addi	a4,a4,-1692 # ffffffe00020b038 <task>
ffffffe0002016dc:	fd842783          	lw	a5,-40(s0)
ffffffe0002016e0:	00379793          	slli	a5,a5,0x3
ffffffe0002016e4:	00f707b3          	add	a5,a4,a5
ffffffe0002016e8:	0007b783          	ld	a5,0(a5)
ffffffe0002016ec:	0a07b823          	sd	zero,176(a5)
       VMA_init(task[i]);
ffffffe0002016f0:	0000a717          	auipc	a4,0xa
ffffffe0002016f4:	94870713          	addi	a4,a4,-1720 # ffffffe00020b038 <task>
ffffffe0002016f8:	fd842783          	lw	a5,-40(s0)
ffffffe0002016fc:	00379793          	slli	a5,a5,0x3
ffffffe000201700:	00f707b3          	add	a5,a4,a5
ffffffe000201704:	0007b783          	ld	a5,0(a5)
ffffffe000201708:	00078513          	mv	a0,a5
ffffffe00020170c:	ed8ff0ef          	jal	ffffffe000200de4 <VMA_init>
    for(int i=1;i<=tasks_number;i++){
ffffffe000201710:	fd842783          	lw	a5,-40(s0)
ffffffe000201714:	0017879b          	addiw	a5,a5,1
ffffffe000201718:	fcf42c23          	sw	a5,-40(s0)
ffffffe00020171c:	fd842703          	lw	a4,-40(s0)
ffffffe000201720:	00006797          	auipc	a5,0x6
ffffffe000201724:	8f078793          	addi	a5,a5,-1808 # ffffffe000207010 <tasks_number>
ffffffe000201728:	0007b783          	ld	a5,0(a5)
ffffffe00020172c:	cae7fae3          	bgeu	a5,a4,ffffffe0002013e0 <task_init+0x144>
    }
    //Log(PURPLE "Finish the assign" CLEAR);
    /* YOUR CODE HERE */
    printk("...task_init done!\n");
ffffffe000201730:	00004517          	auipc	a0,0x4
ffffffe000201734:	a8050513          	addi	a0,a0,-1408 # ffffffe0002051b0 <__func__.0+0x128>
ffffffe000201738:	2b4030ef          	jal	ffffffe0002049ec <printk>

    //test_switch();
}
ffffffe00020173c:	00000013          	nop
ffffffe000201740:	03813083          	ld	ra,56(sp)
ffffffe000201744:	03013403          	ld	s0,48(sp)
ffffffe000201748:	02813483          	ld	s1,40(sp)
ffffffe00020174c:	04010113          	addi	sp,sp,64
ffffffe000201750:	00008067          	ret

ffffffe000201754 <dummy>:
char expected_output[] = "2222222222111111133334222222222211111113";
#include "sbi.h"
#endif

// 简单占用CPU运行的空任务
void dummy() {
ffffffe000201754:	fd010113          	addi	sp,sp,-48
ffffffe000201758:	02113423          	sd	ra,40(sp)
ffffffe00020175c:	02813023          	sd	s0,32(sp)
ffffffe000201760:	03010413          	addi	s0,sp,48
    // 大数取模;
    uint64_t MOD = 1000000007;
ffffffe000201764:	3b9ad7b7          	lui	a5,0x3b9ad
ffffffe000201768:	a0778793          	addi	a5,a5,-1529 # 3b9aca07 <PHY_SIZE+0x339aca07>
ffffffe00020176c:	fcf43c23          	sd	a5,-40(s0)
    uint64_t auto_inc_local_var = 0;
ffffffe000201770:	fe043423          	sd	zero,-24(s0)
    // 表明是否有新的线程进入，有新的线程进入 说明last_counter = -1;
    int last_counter = -1;
ffffffe000201774:	fff00793          	li	a5,-1
ffffffe000201778:	fef42223          	sw	a5,-28(s0)
    while (1) {
        // 如果这个线程是第一次接受调度/他的时间片段被改变了，那么我们就需要重新给任务进行调度
        if ((last_counter == -1 || current->counter != last_counter) && current->counter > 0) {
ffffffe00020177c:	fe442783          	lw	a5,-28(s0)
ffffffe000201780:	0007871b          	sext.w	a4,a5
ffffffe000201784:	fff00793          	li	a5,-1
ffffffe000201788:	00f70e63          	beq	a4,a5,ffffffe0002017a4 <dummy+0x50>
ffffffe00020178c:	0000a797          	auipc	a5,0xa
ffffffe000201790:	88478793          	addi	a5,a5,-1916 # ffffffe00020b010 <current>
ffffffe000201794:	0007b783          	ld	a5,0(a5)
ffffffe000201798:	0087b703          	ld	a4,8(a5)
ffffffe00020179c:	fe442783          	lw	a5,-28(s0)
ffffffe0002017a0:	fcf70ee3          	beq	a4,a5,ffffffe00020177c <dummy+0x28>
ffffffe0002017a4:	0000a797          	auipc	a5,0xa
ffffffe0002017a8:	86c78793          	addi	a5,a5,-1940 # ffffffe00020b010 <current>
ffffffe0002017ac:	0007b783          	ld	a5,0(a5)
ffffffe0002017b0:	0087b783          	ld	a5,8(a5)
ffffffe0002017b4:	fc0784e3          	beqz	a5,ffffffe00020177c <dummy+0x28>
            if (current->counter == 1) {
ffffffe0002017b8:	0000a797          	auipc	a5,0xa
ffffffe0002017bc:	85878793          	addi	a5,a5,-1960 # ffffffe00020b010 <current>
ffffffe0002017c0:	0007b783          	ld	a5,0(a5)
ffffffe0002017c4:	0087b703          	ld	a4,8(a5)
ffffffe0002017c8:	00100793          	li	a5,1
ffffffe0002017cc:	00f71e63          	bne	a4,a5,ffffffe0002017e8 <dummy+0x94>
                --(current->counter);   // forced the counter to be zero if this thread is going to be scheduled
ffffffe0002017d0:	0000a797          	auipc	a5,0xa
ffffffe0002017d4:	84078793          	addi	a5,a5,-1984 # ffffffe00020b010 <current>
ffffffe0002017d8:	0007b783          	ld	a5,0(a5)
ffffffe0002017dc:	0087b703          	ld	a4,8(a5)
ffffffe0002017e0:	fff70713          	addi	a4,a4,-1
ffffffe0002017e4:	00e7b423          	sd	a4,8(a5)
            }                           // in case that the new counter is also 1, leading the information not printed.
            last_counter = current->counter;
ffffffe0002017e8:	0000a797          	auipc	a5,0xa
ffffffe0002017ec:	82878793          	addi	a5,a5,-2008 # ffffffe00020b010 <current>
ffffffe0002017f0:	0007b783          	ld	a5,0(a5)
ffffffe0002017f4:	0087b783          	ld	a5,8(a5)
ffffffe0002017f8:	fef42223          	sw	a5,-28(s0)
            auto_inc_local_var = (auto_inc_local_var + 1) % MOD;
ffffffe0002017fc:	fe843783          	ld	a5,-24(s0)
ffffffe000201800:	00178713          	addi	a4,a5,1
ffffffe000201804:	fd843783          	ld	a5,-40(s0)
ffffffe000201808:	02f777b3          	remu	a5,a4,a5
ffffffe00020180c:	fef43423          	sd	a5,-24(s0)
            printk("[PID = %d] is running. auto_inc_local_var = %d\n", current->pid, auto_inc_local_var);
ffffffe000201810:	0000a797          	auipc	a5,0xa
ffffffe000201814:	80078793          	addi	a5,a5,-2048 # ffffffe00020b010 <current>
ffffffe000201818:	0007b783          	ld	a5,0(a5)
ffffffe00020181c:	0187b783          	ld	a5,24(a5)
ffffffe000201820:	fe843603          	ld	a2,-24(s0)
ffffffe000201824:	00078593          	mv	a1,a5
ffffffe000201828:	00004517          	auipc	a0,0x4
ffffffe00020182c:	9a050513          	addi	a0,a0,-1632 # ffffffe0002051c8 <__func__.0+0x140>
ffffffe000201830:	1bc030ef          	jal	ffffffe0002049ec <printk>
        if ((last_counter == -1 || current->counter != last_counter) && current->counter > 0) {
ffffffe000201834:	f49ff06f          	j	ffffffe00020177c <dummy+0x28>

ffffffe000201838 <switch_to>:

/**
 * @brief use to distinguish whether 2 threads are the same
 * 
*/
void switch_to(struct task_struct* next) {
ffffffe000201838:	fd010113          	addi	sp,sp,-48
ffffffe00020183c:	02113423          	sd	ra,40(sp)
ffffffe000201840:	02813023          	sd	s0,32(sp)
ffffffe000201844:	03010413          	addi	s0,sp,48
ffffffe000201848:	fca43c23          	sd	a0,-40(s0)
    // YOUR CODE HERE
    // If next is the same with current thread we do no handler;
    if(next == current)
ffffffe00020184c:	00009797          	auipc	a5,0x9
ffffffe000201850:	7c478793          	addi	a5,a5,1988 # ffffffe00020b010 <current>
ffffffe000201854:	0007b783          	ld	a5,0(a5)
ffffffe000201858:	fd843703          	ld	a4,-40(s0)
ffffffe00020185c:	02f70a63          	beq	a4,a5,ffffffe000201890 <switch_to+0x58>
        return ; 
    
    //Log(RED "priority: %d",next->priority,CLEAR);
    struct task_struct* prev = current;
ffffffe000201860:	00009797          	auipc	a5,0x9
ffffffe000201864:	7b078793          	addi	a5,a5,1968 # ffffffe00020b010 <current>
ffffffe000201868:	0007b783          	ld	a5,0(a5)
ffffffe00020186c:	fef43423          	sd	a5,-24(s0)
    current = next; 
ffffffe000201870:	00009797          	auipc	a5,0x9
ffffffe000201874:	7a078793          	addi	a5,a5,1952 # ffffffe00020b010 <current>
ffffffe000201878:	fd843703          	ld	a4,-40(s0)
ffffffe00020187c:	00e7b023          	sd	a4,0(a5)
    // Log(BLUE "Switching from PID = %d, PC = %lx to PID = %d\n", prev->pid, pc, next->pid, CLEAR);

    // Log(RED "2" CLEAR);

    // call __switch_to 函数的目的是切换线程;
    __switch_to(prev,next);
ffffffe000201880:	fd843583          	ld	a1,-40(s0)
ffffffe000201884:	fe843503          	ld	a0,-24(s0)
ffffffe000201888:	975fe0ef          	jal	ffffffe0002001fc <__switch_to>
ffffffe00020188c:	0080006f          	j	ffffffe000201894 <switch_to+0x5c>
        return ; 
ffffffe000201890:	00000013          	nop

    // Log(RED "1" CLEAR);

    // asm volatile ("mv %0, ra" : "=r"(pc));
    // Log(BLUE "Switching from PID = %d, PC = %lx to PID = %d\n", prev->pid, pc, next->pid, CLEAR);
}
ffffffe000201894:	02813083          	ld	ra,40(sp)
ffffffe000201898:	02013403          	ld	s0,32(sp)
ffffffe00020189c:	03010113          	addi	sp,sp,48
ffffffe0002018a0:	00008067          	ret

ffffffe0002018a4 <test_switch>:

void test_switch(){
ffffffe0002018a4:	ff010113          	addi	sp,sp,-16
ffffffe0002018a8:	00113423          	sd	ra,8(sp)
ffffffe0002018ac:	00813023          	sd	s0,0(sp)
ffffffe0002018b0:	01010413          	addi	s0,sp,16
    current = task[1];
ffffffe0002018b4:	00009797          	auipc	a5,0x9
ffffffe0002018b8:	78478793          	addi	a5,a5,1924 # ffffffe00020b038 <task>
ffffffe0002018bc:	0087b703          	ld	a4,8(a5)
ffffffe0002018c0:	00009797          	auipc	a5,0x9
ffffffe0002018c4:	75078793          	addi	a5,a5,1872 # ffffffe00020b010 <current>
ffffffe0002018c8:	00e7b023          	sd	a4,0(a5)
    Log(RED "Before switching : current pid : %d\n",current->pid);
ffffffe0002018cc:	00009797          	auipc	a5,0x9
ffffffe0002018d0:	74478793          	addi	a5,a5,1860 # ffffffe00020b010 <current>
ffffffe0002018d4:	0007b783          	ld	a5,0(a5)
ffffffe0002018d8:	0187b783          	ld	a5,24(a5)
ffffffe0002018dc:	00078713          	mv	a4,a5
ffffffe0002018e0:	00004697          	auipc	a3,0x4
ffffffe0002018e4:	a4068693          	addi	a3,a3,-1472 # ffffffe000205320 <__func__.1>
ffffffe0002018e8:	14a00613          	li	a2,330
ffffffe0002018ec:	00003597          	auipc	a1,0x3
ffffffe0002018f0:	7b458593          	addi	a1,a1,1972 # ffffffe0002050a0 <__func__.0+0x18>
ffffffe0002018f4:	00004517          	auipc	a0,0x4
ffffffe0002018f8:	90450513          	addi	a0,a0,-1788 # ffffffe0002051f8 <__func__.0+0x170>
ffffffe0002018fc:	0f0030ef          	jal	ffffffe0002049ec <printk>

    switch_to(task[2]);
ffffffe000201900:	00009797          	auipc	a5,0x9
ffffffe000201904:	73878793          	addi	a5,a5,1848 # ffffffe00020b038 <task>
ffffffe000201908:	0107b783          	ld	a5,16(a5)
ffffffe00020190c:	00078513          	mv	a0,a5
ffffffe000201910:	f29ff0ef          	jal	ffffffe000201838 <switch_to>

    Log(RED "After switching : current pid : %d\n",current->pid);
ffffffe000201914:	00009797          	auipc	a5,0x9
ffffffe000201918:	6fc78793          	addi	a5,a5,1788 # ffffffe00020b010 <current>
ffffffe00020191c:	0007b783          	ld	a5,0(a5)
ffffffe000201920:	0187b783          	ld	a5,24(a5)
ffffffe000201924:	00078713          	mv	a4,a5
ffffffe000201928:	00004697          	auipc	a3,0x4
ffffffe00020192c:	9f868693          	addi	a3,a3,-1544 # ffffffe000205320 <__func__.1>
ffffffe000201930:	14e00613          	li	a2,334
ffffffe000201934:	00003597          	auipc	a1,0x3
ffffffe000201938:	76c58593          	addi	a1,a1,1900 # ffffffe0002050a0 <__func__.0+0x18>
ffffffe00020193c:	00004517          	auipc	a0,0x4
ffffffe000201940:	90450513          	addi	a0,a0,-1788 # ffffffe000205240 <__func__.0+0x1b8>
ffffffe000201944:	0a8030ef          	jal	ffffffe0002049ec <printk>

}
ffffffe000201948:	00000013          	nop
ffffffe00020194c:	00813083          	ld	ra,8(sp)
ffffffe000201950:	00013403          	ld	s0,0(sp)
ffffffe000201954:	01010113          	addi	sp,sp,16
ffffffe000201958:	00008067          	ret

ffffffe00020195c <do_timer>:

void do_timer(){
ffffffe00020195c:	ff010113          	addi	sp,sp,-16
ffffffe000201960:	00113423          	sd	ra,8(sp)
ffffffe000201964:	00813023          	sd	s0,0(sp)
ffffffe000201968:	01010413          	addi	s0,sp,16
    //Log(PURPLE "current pid: %lu ",current->pid,CLEAR);
    if(current==idle||current->counter == 0)
ffffffe00020196c:	00009797          	auipc	a5,0x9
ffffffe000201970:	6a478793          	addi	a5,a5,1700 # ffffffe00020b010 <current>
ffffffe000201974:	0007b703          	ld	a4,0(a5)
ffffffe000201978:	00009797          	auipc	a5,0x9
ffffffe00020197c:	69078793          	addi	a5,a5,1680 # ffffffe00020b008 <idle>
ffffffe000201980:	0007b783          	ld	a5,0(a5)
ffffffe000201984:	00f70c63          	beq	a4,a5,ffffffe00020199c <do_timer+0x40>
ffffffe000201988:	00009797          	auipc	a5,0x9
ffffffe00020198c:	68878793          	addi	a5,a5,1672 # ffffffe00020b010 <current>
ffffffe000201990:	0007b783          	ld	a5,0(a5)
ffffffe000201994:	0087b783          	ld	a5,8(a5)
ffffffe000201998:	00079663          	bnez	a5,ffffffe0002019a4 <do_timer+0x48>
        schedule();
ffffffe00020199c:	044000ef          	jal	ffffffe0002019e0 <schedule>
ffffffe0002019a0:	0300006f          	j	ffffffe0002019d0 <do_timer+0x74>
    else{
        // 如果对当前线程的运行剩余时间为1，则完成调度;
        if(--current->counter==0)
ffffffe0002019a4:	00009797          	auipc	a5,0x9
ffffffe0002019a8:	66c78793          	addi	a5,a5,1644 # ffffffe00020b010 <current>
ffffffe0002019ac:	0007b783          	ld	a5,0(a5)
ffffffe0002019b0:	0087b703          	ld	a4,8(a5)
ffffffe0002019b4:	fff70713          	addi	a4,a4,-1
ffffffe0002019b8:	00e7b423          	sd	a4,8(a5)
ffffffe0002019bc:	0087b783          	ld	a5,8(a5)
ffffffe0002019c0:	00079663          	bnez	a5,ffffffe0002019cc <do_timer+0x70>
            schedule();
ffffffe0002019c4:	01c000ef          	jal	ffffffe0002019e0 <schedule>
ffffffe0002019c8:	0080006f          	j	ffffffe0002019d0 <do_timer+0x74>
        else 
            return ;
ffffffe0002019cc:	00000013          	nop
    }

}
ffffffe0002019d0:	00813083          	ld	ra,8(sp)
ffffffe0002019d4:	00013403          	ld	s0,0(sp)
ffffffe0002019d8:	01010113          	addi	sp,sp,16
ffffffe0002019dc:	00008067          	ret

ffffffe0002019e0 <schedule>:

void schedule(){
ffffffe0002019e0:	fd010113          	addi	sp,sp,-48
ffffffe0002019e4:	02113423          	sd	ra,40(sp)
ffffffe0002019e8:	02813023          	sd	s0,32(sp)
ffffffe0002019ec:	03010413          	addi	s0,sp,48
    // 上面的task_init已经为各个线程赋予了优先级;
    // 找到最大的time-counter;
    int max = 0;
ffffffe0002019f0:	fe042623          	sw	zero,-20(s0)
    int next = 0; // the index of the next thread;
ffffffe0002019f4:	fe042423          	sw	zero,-24(s0)
    int flag = 0; // flag 为 1 只要出现了全0 那就是 0;
ffffffe0002019f8:	fe042223          	sw	zero,-28(s0)
    for(int i=1;i<=tasks_number;i++){
ffffffe0002019fc:	00100793          	li	a5,1
ffffffe000201a00:	fef42023          	sw	a5,-32(s0)
ffffffe000201a04:	0b80006f          	j	ffffffe000201abc <schedule+0xdc>
        if(task[i]->counter==0)
ffffffe000201a08:	00009717          	auipc	a4,0x9
ffffffe000201a0c:	63070713          	addi	a4,a4,1584 # ffffffe00020b038 <task>
ffffffe000201a10:	fe042783          	lw	a5,-32(s0)
ffffffe000201a14:	00379793          	slli	a5,a5,0x3
ffffffe000201a18:	00f707b3          	add	a5,a4,a5
ffffffe000201a1c:	0007b783          	ld	a5,0(a5)
ffffffe000201a20:	0087b783          	ld	a5,8(a5)
ffffffe000201a24:	08078463          	beqz	a5,ffffffe000201aac <schedule+0xcc>
            continue;
        if(!flag&&task[i]->counter>0)
ffffffe000201a28:	fe442783          	lw	a5,-28(s0)
ffffffe000201a2c:	0007879b          	sext.w	a5,a5
ffffffe000201a30:	02079663          	bnez	a5,ffffffe000201a5c <schedule+0x7c>
ffffffe000201a34:	00009717          	auipc	a4,0x9
ffffffe000201a38:	60470713          	addi	a4,a4,1540 # ffffffe00020b038 <task>
ffffffe000201a3c:	fe042783          	lw	a5,-32(s0)
ffffffe000201a40:	00379793          	slli	a5,a5,0x3
ffffffe000201a44:	00f707b3          	add	a5,a4,a5
ffffffe000201a48:	0007b783          	ld	a5,0(a5)
ffffffe000201a4c:	0087b783          	ld	a5,8(a5)
ffffffe000201a50:	00078663          	beqz	a5,ffffffe000201a5c <schedule+0x7c>
            flag = 1;
ffffffe000201a54:	00100793          	li	a5,1
ffffffe000201a58:	fef42223          	sw	a5,-28(s0)
        // Log(PURPLE "i : %d, counter: %d",i,task[i]->counter,CLEAR);
        // Log(GREEN "max : %d",max,CLEAR);
        // Log(GREEN "next : %d",next,CLEAR);
        if((task[i]->counter)>max){
ffffffe000201a5c:	00009717          	auipc	a4,0x9
ffffffe000201a60:	5dc70713          	addi	a4,a4,1500 # ffffffe00020b038 <task>
ffffffe000201a64:	fe042783          	lw	a5,-32(s0)
ffffffe000201a68:	00379793          	slli	a5,a5,0x3
ffffffe000201a6c:	00f707b3          	add	a5,a4,a5
ffffffe000201a70:	0007b783          	ld	a5,0(a5)
ffffffe000201a74:	0087b703          	ld	a4,8(a5)
ffffffe000201a78:	fec42783          	lw	a5,-20(s0)
ffffffe000201a7c:	02e7fa63          	bgeu	a5,a4,ffffffe000201ab0 <schedule+0xd0>
            max = task[i]->counter;
ffffffe000201a80:	00009717          	auipc	a4,0x9
ffffffe000201a84:	5b870713          	addi	a4,a4,1464 # ffffffe00020b038 <task>
ffffffe000201a88:	fe042783          	lw	a5,-32(s0)
ffffffe000201a8c:	00379793          	slli	a5,a5,0x3
ffffffe000201a90:	00f707b3          	add	a5,a4,a5
ffffffe000201a94:	0007b783          	ld	a5,0(a5)
ffffffe000201a98:	0087b783          	ld	a5,8(a5)
ffffffe000201a9c:	fef42623          	sw	a5,-20(s0)
            next = i;
ffffffe000201aa0:	fe042783          	lw	a5,-32(s0)
ffffffe000201aa4:	fef42423          	sw	a5,-24(s0)
ffffffe000201aa8:	0080006f          	j	ffffffe000201ab0 <schedule+0xd0>
            continue;
ffffffe000201aac:	00000013          	nop
    for(int i=1;i<=tasks_number;i++){
ffffffe000201ab0:	fe042783          	lw	a5,-32(s0)
ffffffe000201ab4:	0017879b          	addiw	a5,a5,1
ffffffe000201ab8:	fef42023          	sw	a5,-32(s0)
ffffffe000201abc:	fe042703          	lw	a4,-32(s0)
ffffffe000201ac0:	00005797          	auipc	a5,0x5
ffffffe000201ac4:	55078793          	addi	a5,a5,1360 # ffffffe000207010 <tasks_number>
ffffffe000201ac8:	0007b783          	ld	a5,0(a5)
ffffffe000201acc:	f2e7fee3          	bgeu	a5,a4,ffffffe000201a08 <schedule+0x28>
        }
    }
    // Log(GREEN "shedule next: %d",next,CLEAR);
    // Log(RED " flag : %d",flag,CLEAR);
    if(!flag){
ffffffe000201ad0:	fe442783          	lw	a5,-28(s0)
ffffffe000201ad4:	0007879b          	sext.w	a5,a5
ffffffe000201ad8:	0c079063          	bnez	a5,ffffffe000201b98 <schedule+0x1b8>
        for(int i=1;i<=tasks_number;i++){
ffffffe000201adc:	00100793          	li	a5,1
ffffffe000201ae0:	fcf42e23          	sw	a5,-36(s0)
ffffffe000201ae4:	0980006f          	j	ffffffe000201b7c <schedule+0x19c>
            task[i]->counter = task[i]->priority;
ffffffe000201ae8:	00009717          	auipc	a4,0x9
ffffffe000201aec:	55070713          	addi	a4,a4,1360 # ffffffe00020b038 <task>
ffffffe000201af0:	fdc42783          	lw	a5,-36(s0)
ffffffe000201af4:	00379793          	slli	a5,a5,0x3
ffffffe000201af8:	00f707b3          	add	a5,a4,a5
ffffffe000201afc:	0007b703          	ld	a4,0(a5)
ffffffe000201b00:	00009697          	auipc	a3,0x9
ffffffe000201b04:	53868693          	addi	a3,a3,1336 # ffffffe00020b038 <task>
ffffffe000201b08:	fdc42783          	lw	a5,-36(s0)
ffffffe000201b0c:	00379793          	slli	a5,a5,0x3
ffffffe000201b10:	00f687b3          	add	a5,a3,a5
ffffffe000201b14:	0007b783          	ld	a5,0(a5)
ffffffe000201b18:	01073703          	ld	a4,16(a4)
ffffffe000201b1c:	00e7b423          	sd	a4,8(a5)
            printk("SET [PID = %d PRIORITY = %d COUNTER = %d]\n",i,task[i]->priority,task[i]->counter);
ffffffe000201b20:	00009717          	auipc	a4,0x9
ffffffe000201b24:	51870713          	addi	a4,a4,1304 # ffffffe00020b038 <task>
ffffffe000201b28:	fdc42783          	lw	a5,-36(s0)
ffffffe000201b2c:	00379793          	slli	a5,a5,0x3
ffffffe000201b30:	00f707b3          	add	a5,a4,a5
ffffffe000201b34:	0007b783          	ld	a5,0(a5)
ffffffe000201b38:	0107b603          	ld	a2,16(a5)
ffffffe000201b3c:	00009717          	auipc	a4,0x9
ffffffe000201b40:	4fc70713          	addi	a4,a4,1276 # ffffffe00020b038 <task>
ffffffe000201b44:	fdc42783          	lw	a5,-36(s0)
ffffffe000201b48:	00379793          	slli	a5,a5,0x3
ffffffe000201b4c:	00f707b3          	add	a5,a4,a5
ffffffe000201b50:	0007b783          	ld	a5,0(a5)
ffffffe000201b54:	0087b703          	ld	a4,8(a5)
ffffffe000201b58:	fdc42783          	lw	a5,-36(s0)
ffffffe000201b5c:	00070693          	mv	a3,a4
ffffffe000201b60:	00078593          	mv	a1,a5
ffffffe000201b64:	00003517          	auipc	a0,0x3
ffffffe000201b68:	71c50513          	addi	a0,a0,1820 # ffffffe000205280 <__func__.0+0x1f8>
ffffffe000201b6c:	681020ef          	jal	ffffffe0002049ec <printk>
        for(int i=1;i<=tasks_number;i++){
ffffffe000201b70:	fdc42783          	lw	a5,-36(s0)
ffffffe000201b74:	0017879b          	addiw	a5,a5,1
ffffffe000201b78:	fcf42e23          	sw	a5,-36(s0)
ffffffe000201b7c:	fdc42703          	lw	a4,-36(s0)
ffffffe000201b80:	00005797          	auipc	a5,0x5
ffffffe000201b84:	49078793          	addi	a5,a5,1168 # ffffffe000207010 <tasks_number>
ffffffe000201b88:	0007b783          	ld	a5,0(a5)
ffffffe000201b8c:	f4e7fee3          	bgeu	a5,a4,ffffffe000201ae8 <schedule+0x108>
        }
        schedule();
ffffffe000201b90:	e51ff0ef          	jal	ffffffe0002019e0 <schedule>
    }else{
        Log(RED "switch to [PID = %lx PRIORITY = %lx COUNTER = %lx] ",task[next]->pid,task[next]->priority,task[next]->counter,CLEAR);
        switch_to(task[next]);
    }
}
ffffffe000201b94:	0ac0006f          	j	ffffffe000201c40 <schedule+0x260>
        Log(RED "switch to [PID = %lx PRIORITY = %lx COUNTER = %lx] ",task[next]->pid,task[next]->priority,task[next]->counter,CLEAR);
ffffffe000201b98:	00009717          	auipc	a4,0x9
ffffffe000201b9c:	4a070713          	addi	a4,a4,1184 # ffffffe00020b038 <task>
ffffffe000201ba0:	fe842783          	lw	a5,-24(s0)
ffffffe000201ba4:	00379793          	slli	a5,a5,0x3
ffffffe000201ba8:	00f707b3          	add	a5,a4,a5
ffffffe000201bac:	0007b783          	ld	a5,0(a5)
ffffffe000201bb0:	0187b683          	ld	a3,24(a5)
ffffffe000201bb4:	00009717          	auipc	a4,0x9
ffffffe000201bb8:	48470713          	addi	a4,a4,1156 # ffffffe00020b038 <task>
ffffffe000201bbc:	fe842783          	lw	a5,-24(s0)
ffffffe000201bc0:	00379793          	slli	a5,a5,0x3
ffffffe000201bc4:	00f707b3          	add	a5,a4,a5
ffffffe000201bc8:	0007b783          	ld	a5,0(a5)
ffffffe000201bcc:	0107b603          	ld	a2,16(a5)
ffffffe000201bd0:	00009717          	auipc	a4,0x9
ffffffe000201bd4:	46870713          	addi	a4,a4,1128 # ffffffe00020b038 <task>
ffffffe000201bd8:	fe842783          	lw	a5,-24(s0)
ffffffe000201bdc:	00379793          	slli	a5,a5,0x3
ffffffe000201be0:	00f707b3          	add	a5,a4,a5
ffffffe000201be4:	0007b783          	ld	a5,0(a5)
ffffffe000201be8:	0087b783          	ld	a5,8(a5)
ffffffe000201bec:	00003897          	auipc	a7,0x3
ffffffe000201bf0:	4ac88893          	addi	a7,a7,1196 # ffffffe000205098 <__func__.0+0x10>
ffffffe000201bf4:	00078813          	mv	a6,a5
ffffffe000201bf8:	00060793          	mv	a5,a2
ffffffe000201bfc:	00068713          	mv	a4,a3
ffffffe000201c00:	00003697          	auipc	a3,0x3
ffffffe000201c04:	73068693          	addi	a3,a3,1840 # ffffffe000205330 <__func__.0>
ffffffe000201c08:	17c00613          	li	a2,380
ffffffe000201c0c:	00003597          	auipc	a1,0x3
ffffffe000201c10:	49458593          	addi	a1,a1,1172 # ffffffe0002050a0 <__func__.0+0x18>
ffffffe000201c14:	00003517          	auipc	a0,0x3
ffffffe000201c18:	69c50513          	addi	a0,a0,1692 # ffffffe0002052b0 <__func__.0+0x228>
ffffffe000201c1c:	5d1020ef          	jal	ffffffe0002049ec <printk>
        switch_to(task[next]);
ffffffe000201c20:	00009717          	auipc	a4,0x9
ffffffe000201c24:	41870713          	addi	a4,a4,1048 # ffffffe00020b038 <task>
ffffffe000201c28:	fe842783          	lw	a5,-24(s0)
ffffffe000201c2c:	00379793          	slli	a5,a5,0x3
ffffffe000201c30:	00f707b3          	add	a5,a4,a5
ffffffe000201c34:	0007b783          	ld	a5,0(a5)
ffffffe000201c38:	00078513          	mv	a0,a5
ffffffe000201c3c:	bfdff0ef          	jal	ffffffe000201838 <switch_to>
}
ffffffe000201c40:	00000013          	nop
ffffffe000201c44:	02813083          	ld	ra,40(sp)
ffffffe000201c48:	02013403          	ld	s0,32(sp)
ffffffe000201c4c:	03010113          	addi	sp,sp,48
ffffffe000201c50:	00008067          	ret

ffffffe000201c54 <find_vma>:
 * 
 * @param mm -> the memory manager need be find;
 * @param addr -> the va waited for seeking
 * @return return the found struct else return null;
*/
struct vm_area_struct *find_vma(struct mm_struct *mm, uint64_t addr){
ffffffe000201c54:	fd010113          	addi	sp,sp,-48
ffffffe000201c58:	02813423          	sd	s0,40(sp)
ffffffe000201c5c:	03010413          	addi	s0,sp,48
ffffffe000201c60:	fca43c23          	sd	a0,-40(s0)
ffffffe000201c64:	fcb43823          	sd	a1,-48(s0)
    struct vm_area_struct* ptr = mm->mmap;
ffffffe000201c68:	fd843783          	ld	a5,-40(s0)
ffffffe000201c6c:	0007b783          	ld	a5,0(a5)
ffffffe000201c70:	fef43423          	sd	a5,-24(s0)
    for(;ptr!=NULL;ptr = ptr->vm_next){
ffffffe000201c74:	0380006f          	j	ffffffe000201cac <find_vma+0x58>
        if(addr>=ptr->vm_start&&addr<=ptr->vm_end){
ffffffe000201c78:	fe843783          	ld	a5,-24(s0)
ffffffe000201c7c:	0087b783          	ld	a5,8(a5)
ffffffe000201c80:	fd043703          	ld	a4,-48(s0)
ffffffe000201c84:	00f76e63          	bltu	a4,a5,ffffffe000201ca0 <find_vma+0x4c>
ffffffe000201c88:	fe843783          	ld	a5,-24(s0)
ffffffe000201c8c:	0107b783          	ld	a5,16(a5)
ffffffe000201c90:	fd043703          	ld	a4,-48(s0)
ffffffe000201c94:	00e7e663          	bltu	a5,a4,ffffffe000201ca0 <find_vma+0x4c>
            return ptr;
ffffffe000201c98:	fe843783          	ld	a5,-24(s0)
ffffffe000201c9c:	01c0006f          	j	ffffffe000201cb8 <find_vma+0x64>
    for(;ptr!=NULL;ptr = ptr->vm_next){
ffffffe000201ca0:	fe843783          	ld	a5,-24(s0)
ffffffe000201ca4:	0187b783          	ld	a5,24(a5)
ffffffe000201ca8:	fef43423          	sd	a5,-24(s0)
ffffffe000201cac:	fe843783          	ld	a5,-24(s0)
ffffffe000201cb0:	fc0794e3          	bnez	a5,ffffffe000201c78 <find_vma+0x24>
        }
    }
    return NULL;
ffffffe000201cb4:	00000793          	li	a5,0
}
ffffffe000201cb8:	00078513          	mv	a0,a5
ffffffe000201cbc:	02813403          	ld	s0,40(sp)
ffffffe000201cc0:	03010113          	addi	sp,sp,48
ffffffe000201cc4:	00008067          	ret

ffffffe000201cc8 <do_mmap>:
* @flags    : flags for the new VMA
*
* @return   : start va
* we choose to add the nodes in the header of the linked-list;
*/
uint64_t do_mmap(struct mm_struct *mm, uint64_t addr, uint64_t len, uint64_t vm_pgoff, uint64_t vm_filesz, uint64_t flags){
ffffffe000201cc8:	fb010113          	addi	sp,sp,-80
ffffffe000201ccc:	04113423          	sd	ra,72(sp)
ffffffe000201cd0:	04813023          	sd	s0,64(sp)
ffffffe000201cd4:	05010413          	addi	s0,sp,80
ffffffe000201cd8:	fca43c23          	sd	a0,-40(s0)
ffffffe000201cdc:	fcb43823          	sd	a1,-48(s0)
ffffffe000201ce0:	fcc43423          	sd	a2,-56(s0)
ffffffe000201ce4:	fcd43023          	sd	a3,-64(s0)
ffffffe000201ce8:	fae43c23          	sd	a4,-72(s0)
ffffffe000201cec:	faf43823          	sd	a5,-80(s0)
    struct vm_area_struct* temp = (struct vm_area_struct*)alloc_page();
ffffffe000201cf0:	d45fe0ef          	jal	ffffffe000200a34 <alloc_page>
ffffffe000201cf4:	fea43423          	sd	a0,-24(s0)
    //memset(temp,0,sizeof(struct vm_area_struct));
    // initial the vm_area_struct
    temp->vm_start = addr;
ffffffe000201cf8:	fe843783          	ld	a5,-24(s0)
ffffffe000201cfc:	fd043703          	ld	a4,-48(s0)
ffffffe000201d00:	00e7b423          	sd	a4,8(a5)
    temp->vm_end = addr+len;
ffffffe000201d04:	fd043703          	ld	a4,-48(s0)
ffffffe000201d08:	fc843783          	ld	a5,-56(s0)
ffffffe000201d0c:	00f70733          	add	a4,a4,a5
ffffffe000201d10:	fe843783          	ld	a5,-24(s0)
ffffffe000201d14:	00e7b823          	sd	a4,16(a5)
    temp->vm_prev = NULL;
ffffffe000201d18:	fe843783          	ld	a5,-24(s0)
ffffffe000201d1c:	0207b023          	sd	zero,32(a5)
    temp->vm_next = NULL;
ffffffe000201d20:	fe843783          	ld	a5,-24(s0)
ffffffe000201d24:	0007bc23          	sd	zero,24(a5)
    temp->vm_flags = flags;
ffffffe000201d28:	fe843783          	ld	a5,-24(s0)
ffffffe000201d2c:	fb043703          	ld	a4,-80(s0)
ffffffe000201d30:	02e7b423          	sd	a4,40(a5)
    temp->vm_filesz = vm_filesz;
ffffffe000201d34:	fe843783          	ld	a5,-24(s0)
ffffffe000201d38:	fb843703          	ld	a4,-72(s0)
ffffffe000201d3c:	02e7bc23          	sd	a4,56(a5)
    temp->vm_pgoff = vm_pgoff;
ffffffe000201d40:	fe843783          	ld	a5,-24(s0)
ffffffe000201d44:	fc043703          	ld	a4,-64(s0)
ffffffe000201d48:	02e7b823          	sd	a4,48(a5)
    if(mm->mmap==NULL){
ffffffe000201d4c:	fd843783          	ld	a5,-40(s0)
ffffffe000201d50:	0007b783          	ld	a5,0(a5)
ffffffe000201d54:	00079a63          	bnez	a5,ffffffe000201d68 <do_mmap+0xa0>
        mm->mmap = temp;
ffffffe000201d58:	fd843783          	ld	a5,-40(s0)
ffffffe000201d5c:	fe843703          	ld	a4,-24(s0)
ffffffe000201d60:	00e7b023          	sd	a4,0(a5)
ffffffe000201d64:	0340006f          	j	ffffffe000201d98 <do_mmap+0xd0>
    }else{
        struct vm_area_struct *ptr = mm->mmap;
ffffffe000201d68:	fd843783          	ld	a5,-40(s0)
ffffffe000201d6c:	0007b783          	ld	a5,0(a5)
ffffffe000201d70:	fef43023          	sd	a5,-32(s0)
        temp->vm_next = ptr;
ffffffe000201d74:	fe843783          	ld	a5,-24(s0)
ffffffe000201d78:	fe043703          	ld	a4,-32(s0)
ffffffe000201d7c:	00e7bc23          	sd	a4,24(a5)
        ptr->vm_prev = temp;
ffffffe000201d80:	fe043783          	ld	a5,-32(s0)
ffffffe000201d84:	fe843703          	ld	a4,-24(s0)
ffffffe000201d88:	02e7b023          	sd	a4,32(a5)
        mm->mmap = temp;
ffffffe000201d8c:	fd843783          	ld	a5,-40(s0)
ffffffe000201d90:	fe843703          	ld	a4,-24(s0)
ffffffe000201d94:	00e7b023          	sd	a4,0(a5)
    }
    temp->vm_mm = mm;
ffffffe000201d98:	fe843783          	ld	a5,-24(s0)
ffffffe000201d9c:	fd843703          	ld	a4,-40(s0)
ffffffe000201da0:	00e7b023          	sd	a4,0(a5)
    return temp->vm_start;
ffffffe000201da4:	fe843783          	ld	a5,-24(s0)
ffffffe000201da8:	0087b783          	ld	a5,8(a5)
}
ffffffe000201dac:	00078513          	mv	a0,a5
ffffffe000201db0:	04813083          	ld	ra,72(sp)
ffffffe000201db4:	04013403          	ld	s0,64(sp)
ffffffe000201db8:	05010113          	addi	sp,sp,80
ffffffe000201dbc:	00008067          	ret

ffffffe000201dc0 <sbi_ecall>:
#include "stddef.h"


struct sbiret sbi_ecall(uint64_t eid, uint64_t fid,
                        uint64_t arg0, uint64_t arg1, uint64_t arg2,
                        uint64_t arg3, uint64_t arg4, uint64_t arg5) {
ffffffe000201dc0:	f9010113          	addi	sp,sp,-112
ffffffe000201dc4:	06813423          	sd	s0,104(sp)
ffffffe000201dc8:	07010413          	addi	s0,sp,112
ffffffe000201dcc:	fca43423          	sd	a0,-56(s0)
ffffffe000201dd0:	fcb43023          	sd	a1,-64(s0)
ffffffe000201dd4:	fac43c23          	sd	a2,-72(s0)
ffffffe000201dd8:	fad43823          	sd	a3,-80(s0)
ffffffe000201ddc:	fae43423          	sd	a4,-88(s0)
ffffffe000201de0:	faf43023          	sd	a5,-96(s0)
ffffffe000201de4:	f9043c23          	sd	a6,-104(s0)
ffffffe000201de8:	f9143823          	sd	a7,-112(s0)
    // 1. We Need to move eid into a7 register, move fid into a6 register, move arg[0-5] into a[0-5];
    // 2. We Need to use ecall to go into M mode; 
    struct sbiret result;
    // mv rd rs;
    asm volatile (
ffffffe000201dec:	fc843783          	ld	a5,-56(s0)
ffffffe000201df0:	fc043703          	ld	a4,-64(s0)
ffffffe000201df4:	fb843683          	ld	a3,-72(s0)
ffffffe000201df8:	fb043603          	ld	a2,-80(s0)
ffffffe000201dfc:	fa843583          	ld	a1,-88(s0)
ffffffe000201e00:	fa043503          	ld	a0,-96(s0)
ffffffe000201e04:	f9843803          	ld	a6,-104(s0)
ffffffe000201e08:	f9043883          	ld	a7,-112(s0)
ffffffe000201e0c:	00078893          	mv	a7,a5
ffffffe000201e10:	00070813          	mv	a6,a4
ffffffe000201e14:	00068513          	mv	a0,a3
ffffffe000201e18:	00060593          	mv	a1,a2
ffffffe000201e1c:	00058613          	mv	a2,a1
ffffffe000201e20:	00050693          	mv	a3,a0
ffffffe000201e24:	00080713          	mv	a4,a6
ffffffe000201e28:	00088793          	mv	a5,a7
ffffffe000201e2c:	00000073          	ecall
ffffffe000201e30:	00050713          	mv	a4,a0
ffffffe000201e34:	00058793          	mv	a5,a1
ffffffe000201e38:	fce43823          	sd	a4,-48(s0)
ffffffe000201e3c:	fcf43c23          	sd	a5,-40(s0)
          [arg4] "r" (arg4),[arg5] "r" (arg5)
        : "memory"
    );
    
    
    return result;
ffffffe000201e40:	fd043783          	ld	a5,-48(s0)
ffffffe000201e44:	fef43023          	sd	a5,-32(s0)
ffffffe000201e48:	fd843783          	ld	a5,-40(s0)
ffffffe000201e4c:	fef43423          	sd	a5,-24(s0)
ffffffe000201e50:	fe043703          	ld	a4,-32(s0)
ffffffe000201e54:	fe843783          	ld	a5,-24(s0)
ffffffe000201e58:	00070313          	mv	t1,a4
ffffffe000201e5c:	00078393          	mv	t2,a5
ffffffe000201e60:	00030713          	mv	a4,t1
ffffffe000201e64:	00038793          	mv	a5,t2
}
ffffffe000201e68:	00070513          	mv	a0,a4
ffffffe000201e6c:	00078593          	mv	a1,a5
ffffffe000201e70:	06813403          	ld	s0,104(sp)
ffffffe000201e74:	07010113          	addi	sp,sp,112
ffffffe000201e78:	00008067          	ret

ffffffe000201e7c <sbi_debug_console_write_byte>:

struct sbiret sbi_debug_console_write_byte(uint8_t byte) {
ffffffe000201e7c:	fc010113          	addi	sp,sp,-64
ffffffe000201e80:	02113c23          	sd	ra,56(sp)
ffffffe000201e84:	02813823          	sd	s0,48(sp)
ffffffe000201e88:	03213423          	sd	s2,40(sp)
ffffffe000201e8c:	03313023          	sd	s3,32(sp)
ffffffe000201e90:	04010413          	addi	s0,sp,64
ffffffe000201e94:	00050793          	mv	a5,a0
ffffffe000201e98:	fcf407a3          	sb	a5,-49(s0)
    return sbi_ecall(0x4442434E,0x2,(uint64_t)byte,0,0,0,0,0);
ffffffe000201e9c:	fcf44603          	lbu	a2,-49(s0)
ffffffe000201ea0:	00000893          	li	a7,0
ffffffe000201ea4:	00000813          	li	a6,0
ffffffe000201ea8:	00000793          	li	a5,0
ffffffe000201eac:	00000713          	li	a4,0
ffffffe000201eb0:	00000693          	li	a3,0
ffffffe000201eb4:	00200593          	li	a1,2
ffffffe000201eb8:	44424537          	lui	a0,0x44424
ffffffe000201ebc:	34e50513          	addi	a0,a0,846 # 4442434e <PHY_SIZE+0x3c42434e>
ffffffe000201ec0:	f01ff0ef          	jal	ffffffe000201dc0 <sbi_ecall>
ffffffe000201ec4:	00050713          	mv	a4,a0
ffffffe000201ec8:	00058793          	mv	a5,a1
ffffffe000201ecc:	fce43823          	sd	a4,-48(s0)
ffffffe000201ed0:	fcf43c23          	sd	a5,-40(s0)
ffffffe000201ed4:	fd043703          	ld	a4,-48(s0)
ffffffe000201ed8:	fd843783          	ld	a5,-40(s0)
ffffffe000201edc:	00070913          	mv	s2,a4
ffffffe000201ee0:	00078993          	mv	s3,a5
ffffffe000201ee4:	00090713          	mv	a4,s2
ffffffe000201ee8:	00098793          	mv	a5,s3
}
ffffffe000201eec:	00070513          	mv	a0,a4
ffffffe000201ef0:	00078593          	mv	a1,a5
ffffffe000201ef4:	03813083          	ld	ra,56(sp)
ffffffe000201ef8:	03013403          	ld	s0,48(sp)
ffffffe000201efc:	02813903          	ld	s2,40(sp)
ffffffe000201f00:	02013983          	ld	s3,32(sp)
ffffffe000201f04:	04010113          	addi	sp,sp,64
ffffffe000201f08:	00008067          	ret

ffffffe000201f0c <sbi_system_reset>:

struct sbiret sbi_system_reset(uint32_t reset_type, uint32_t reset_reason) {
ffffffe000201f0c:	fc010113          	addi	sp,sp,-64
ffffffe000201f10:	02113c23          	sd	ra,56(sp)
ffffffe000201f14:	02813823          	sd	s0,48(sp)
ffffffe000201f18:	03213423          	sd	s2,40(sp)
ffffffe000201f1c:	03313023          	sd	s3,32(sp)
ffffffe000201f20:	04010413          	addi	s0,sp,64
ffffffe000201f24:	00050793          	mv	a5,a0
ffffffe000201f28:	00058713          	mv	a4,a1
ffffffe000201f2c:	fcf42623          	sw	a5,-52(s0)
ffffffe000201f30:	00070793          	mv	a5,a4
ffffffe000201f34:	fcf42423          	sw	a5,-56(s0)
    return sbi_ecall(0x53525354,0x0,(uint64_t)reset_type,(uint64_t)reset_reason,0,0,0,0);
ffffffe000201f38:	fcc46603          	lwu	a2,-52(s0)
ffffffe000201f3c:	fc846683          	lwu	a3,-56(s0)
ffffffe000201f40:	00000893          	li	a7,0
ffffffe000201f44:	00000813          	li	a6,0
ffffffe000201f48:	00000793          	li	a5,0
ffffffe000201f4c:	00000713          	li	a4,0
ffffffe000201f50:	00000593          	li	a1,0
ffffffe000201f54:	53525537          	lui	a0,0x53525
ffffffe000201f58:	35450513          	addi	a0,a0,852 # 53525354 <PHY_SIZE+0x4b525354>
ffffffe000201f5c:	e65ff0ef          	jal	ffffffe000201dc0 <sbi_ecall>
ffffffe000201f60:	00050713          	mv	a4,a0
ffffffe000201f64:	00058793          	mv	a5,a1
ffffffe000201f68:	fce43823          	sd	a4,-48(s0)
ffffffe000201f6c:	fcf43c23          	sd	a5,-40(s0)
ffffffe000201f70:	fd043703          	ld	a4,-48(s0)
ffffffe000201f74:	fd843783          	ld	a5,-40(s0)
ffffffe000201f78:	00070913          	mv	s2,a4
ffffffe000201f7c:	00078993          	mv	s3,a5
ffffffe000201f80:	00090713          	mv	a4,s2
ffffffe000201f84:	00098793          	mv	a5,s3
}
ffffffe000201f88:	00070513          	mv	a0,a4
ffffffe000201f8c:	00078593          	mv	a1,a5
ffffffe000201f90:	03813083          	ld	ra,56(sp)
ffffffe000201f94:	03013403          	ld	s0,48(sp)
ffffffe000201f98:	02813903          	ld	s2,40(sp)
ffffffe000201f9c:	02013983          	ld	s3,32(sp)
ffffffe000201fa0:	04010113          	addi	sp,sp,64
ffffffe000201fa4:	00008067          	ret

ffffffe000201fa8 <sbi_set_timer>:

struct sbiret sbi_set_timer(uint64_t stime_value){
ffffffe000201fa8:	fc010113          	addi	sp,sp,-64
ffffffe000201fac:	02113c23          	sd	ra,56(sp)
ffffffe000201fb0:	02813823          	sd	s0,48(sp)
ffffffe000201fb4:	03213423          	sd	s2,40(sp)
ffffffe000201fb8:	03313023          	sd	s3,32(sp)
ffffffe000201fbc:	04010413          	addi	s0,sp,64
ffffffe000201fc0:	fca43423          	sd	a0,-56(s0)
    return sbi_ecall(0x54494D45,0x0,stime_value,0,0,0,0,0);
ffffffe000201fc4:	00000893          	li	a7,0
ffffffe000201fc8:	00000813          	li	a6,0
ffffffe000201fcc:	00000793          	li	a5,0
ffffffe000201fd0:	00000713          	li	a4,0
ffffffe000201fd4:	00000693          	li	a3,0
ffffffe000201fd8:	fc843603          	ld	a2,-56(s0)
ffffffe000201fdc:	00000593          	li	a1,0
ffffffe000201fe0:	54495537          	lui	a0,0x54495
ffffffe000201fe4:	d4550513          	addi	a0,a0,-699 # 54494d45 <PHY_SIZE+0x4c494d45>
ffffffe000201fe8:	dd9ff0ef          	jal	ffffffe000201dc0 <sbi_ecall>
ffffffe000201fec:	00050713          	mv	a4,a0
ffffffe000201ff0:	00058793          	mv	a5,a1
ffffffe000201ff4:	fce43823          	sd	a4,-48(s0)
ffffffe000201ff8:	fcf43c23          	sd	a5,-40(s0)
ffffffe000201ffc:	fd043703          	ld	a4,-48(s0)
ffffffe000202000:	fd843783          	ld	a5,-40(s0)
ffffffe000202004:	00070913          	mv	s2,a4
ffffffe000202008:	00078993          	mv	s3,a5
ffffffe00020200c:	00090713          	mv	a4,s2
ffffffe000202010:	00098793          	mv	a5,s3
}
ffffffe000202014:	00070513          	mv	a0,a4
ffffffe000202018:	00078593          	mv	a1,a5
ffffffe00020201c:	03813083          	ld	ra,56(sp)
ffffffe000202020:	03013403          	ld	s0,48(sp)
ffffffe000202024:	02813903          	ld	s2,40(sp)
ffffffe000202028:	02013983          	ld	s3,32(sp)
ffffffe00020202c:	04010113          	addi	sp,sp,64
ffffffe000202030:	00008067          	ret

ffffffe000202034 <write>:
extern int tasks_number;
extern void __ret_from_fork();
extern uint64_t swapper_pg_dir[512] __attribute__((__aligned__(0x1000)));
extern void create_mapping(uint64_t *pgtbl, uint64_t va, uint64_t pa, uint64_t sz, uint64_t perm);

long write(unsigned int fd,const char* buf,size_t count){
ffffffe000202034:	fc010113          	addi	sp,sp,-64
ffffffe000202038:	02113c23          	sd	ra,56(sp)
ffffffe00020203c:	02813823          	sd	s0,48(sp)
ffffffe000202040:	04010413          	addi	s0,sp,64
ffffffe000202044:	00050793          	mv	a5,a0
ffffffe000202048:	fcb43823          	sd	a1,-48(s0)
ffffffe00020204c:	fcc43423          	sd	a2,-56(s0)
ffffffe000202050:	fcf42e23          	sw	a5,-36(s0)
    if(fd!=STDOUT){
ffffffe000202054:	fdc42783          	lw	a5,-36(s0)
ffffffe000202058:	0007871b          	sext.w	a4,a5
ffffffe00020205c:	00100793          	li	a5,1
ffffffe000202060:	02f70663          	beq	a4,a5,ffffffe00020208c <write+0x58>
        Log(RED "sys_write: fd != STDOUT\n" CLEAR);
ffffffe000202064:	00003697          	auipc	a3,0x3
ffffffe000202068:	f9c68693          	addi	a3,a3,-100 # ffffffe000205000 <__func__.2>
ffffffe00020206c:	01100613          	li	a2,17
ffffffe000202070:	00003597          	auipc	a1,0x3
ffffffe000202074:	2d058593          	addi	a1,a1,720 # ffffffe000205340 <__func__.0+0x10>
ffffffe000202078:	00003517          	auipc	a0,0x3
ffffffe00020207c:	2d850513          	addi	a0,a0,728 # ffffffe000205350 <__func__.0+0x20>
ffffffe000202080:	16d020ef          	jal	ffffffe0002049ec <printk>
        return -1;
ffffffe000202084:	fff00793          	li	a5,-1
ffffffe000202088:	0500006f          	j	ffffffe0002020d8 <write+0xa4>
    }
    if(count<=0){
ffffffe00020208c:	fc843783          	ld	a5,-56(s0)
ffffffe000202090:	02079663          	bnez	a5,ffffffe0002020bc <write+0x88>
        Log(RED "sys_write: count<=0\n" CLEAR);
ffffffe000202094:	00003697          	auipc	a3,0x3
ffffffe000202098:	f6c68693          	addi	a3,a3,-148 # ffffffe000205000 <__func__.2>
ffffffe00020209c:	01500613          	li	a2,21
ffffffe0002020a0:	00003597          	auipc	a1,0x3
ffffffe0002020a4:	2a058593          	addi	a1,a1,672 # ffffffe000205340 <__func__.0+0x10>
ffffffe0002020a8:	00003517          	auipc	a0,0x3
ffffffe0002020ac:	2e850513          	addi	a0,a0,744 # ffffffe000205390 <__func__.0+0x60>
ffffffe0002020b0:	13d020ef          	jal	ffffffe0002049ec <printk>
        return -1;
ffffffe0002020b4:	fff00793          	li	a5,-1
ffffffe0002020b8:	0200006f          	j	ffffffe0002020d8 <write+0xa4>
    }
    long cnt = printk("%s",buf);
ffffffe0002020bc:	fd043583          	ld	a1,-48(s0)
ffffffe0002020c0:	00003517          	auipc	a0,0x3
ffffffe0002020c4:	30850513          	addi	a0,a0,776 # ffffffe0002053c8 <__func__.0+0x98>
ffffffe0002020c8:	125020ef          	jal	ffffffe0002049ec <printk>
ffffffe0002020cc:	00050793          	mv	a5,a0
ffffffe0002020d0:	fef43423          	sd	a5,-24(s0)
    return cnt;
ffffffe0002020d4:	fe843783          	ld	a5,-24(s0)
}
ffffffe0002020d8:	00078513          	mv	a0,a5
ffffffe0002020dc:	03813083          	ld	ra,56(sp)
ffffffe0002020e0:	03013403          	ld	s0,48(sp)
ffffffe0002020e4:	04010113          	addi	sp,sp,64
ffffffe0002020e8:	00008067          	ret

ffffffe0002020ec <get_pid>:

long get_pid(){
ffffffe0002020ec:	ff010113          	addi	sp,sp,-16
ffffffe0002020f0:	00813423          	sd	s0,8(sp)
ffffffe0002020f4:	01010413          	addi	s0,sp,16
    return current->pid;
ffffffe0002020f8:	00009797          	auipc	a5,0x9
ffffffe0002020fc:	f1878793          	addi	a5,a5,-232 # ffffffe00020b010 <current>
ffffffe000202100:	0007b783          	ld	a5,0(a5)
ffffffe000202104:	0187b783          	ld	a5,24(a5)
}
ffffffe000202108:	00078513          	mv	a0,a5
ffffffe00020210c:	00813403          	ld	s0,8(sp)
ffffffe000202110:	01010113          	addi	sp,sp,16
ffffffe000202114:	00008067          	ret

ffffffe000202118 <checkValid>:
 * in this funciton, our purpose is to confirm whether this address's content is valid;
 * 
 * @param address the address waiting for confirmed whether it is valid;
 * @param pgd the page table root address;
*/
uint64_t checkValid(uint64_t address,uint64_t* pgd){
ffffffe000202118:	fa010113          	addi	sp,sp,-96
ffffffe00020211c:	04813c23          	sd	s0,88(sp)
ffffffe000202120:	06010413          	addi	s0,sp,96
ffffffe000202124:	faa43423          	sd	a0,-88(s0)
ffffffe000202128:	fab43023          	sd	a1,-96(s0)
    uint64_t VPN[3];
    VPN[2] = (address>>30)&0x1ff;
ffffffe00020212c:	fa843783          	ld	a5,-88(s0)
ffffffe000202130:	01e7d793          	srli	a5,a5,0x1e
ffffffe000202134:	1ff7f793          	andi	a5,a5,511
ffffffe000202138:	fcf43423          	sd	a5,-56(s0)
    VPN[1] = (address>>21)&0x1ff;
ffffffe00020213c:	fa843783          	ld	a5,-88(s0)
ffffffe000202140:	0157d793          	srli	a5,a5,0x15
ffffffe000202144:	1ff7f793          	andi	a5,a5,511
ffffffe000202148:	fcf43023          	sd	a5,-64(s0)
    VPN[0] = (address>>12)&0x1ff;
ffffffe00020214c:	fa843783          	ld	a5,-88(s0)
ffffffe000202150:	00c7d793          	srli	a5,a5,0xc
ffffffe000202154:	1ff7f793          	andi	a5,a5,511
ffffffe000202158:	faf43c23          	sd	a5,-72(s0)
    uint64_t* ptr = pgd;
ffffffe00020215c:	fa043783          	ld	a5,-96(s0)
ffffffe000202160:	fef43423          	sd	a5,-24(s0)
    //printk("root pg address : %016lx\n");
    for(int i=2;i>0;i--){
ffffffe000202164:	00200793          	li	a5,2
ffffffe000202168:	fef42223          	sw	a5,-28(s0)
ffffffe00020216c:	0880006f          	j	ffffffe0002021f4 <checkValid+0xdc>
        // v-bit is 0;
        //printk("ptr[VPN[%d]] : %016lx\n",i,ptr[VPN[i]]);
        uint64_t f = ptr[VPN[i]]&0x1;
ffffffe000202170:	fe442783          	lw	a5,-28(s0)
ffffffe000202174:	00379793          	slli	a5,a5,0x3
ffffffe000202178:	ff078793          	addi	a5,a5,-16
ffffffe00020217c:	008787b3          	add	a5,a5,s0
ffffffe000202180:	fc87b783          	ld	a5,-56(a5)
ffffffe000202184:	00379793          	slli	a5,a5,0x3
ffffffe000202188:	fe843703          	ld	a4,-24(s0)
ffffffe00020218c:	00f707b3          	add	a5,a4,a5
ffffffe000202190:	0007b783          	ld	a5,0(a5)
ffffffe000202194:	0017f793          	andi	a5,a5,1
ffffffe000202198:	fcf43823          	sd	a5,-48(s0)
        if(f==0)
ffffffe00020219c:	fd043783          	ld	a5,-48(s0)
ffffffe0002021a0:	00079663          	bnez	a5,ffffffe0002021ac <checkValid+0x94>
             return 0;
ffffffe0002021a4:	00000793          	li	a5,0
ffffffe0002021a8:	0880006f          	j	ffffffe000202230 <checkValid+0x118>
        // the ptr records for the next page table address;
        // printk("PTE %d is %016lx\n",i,ptr[VPN[i]],CLEAR);
        ptr = (uint64_t*)(((ptr[VPN[i]]>>10)<<12) + PA2VA_OFFSET);
ffffffe0002021ac:	fe442783          	lw	a5,-28(s0)
ffffffe0002021b0:	00379793          	slli	a5,a5,0x3
ffffffe0002021b4:	ff078793          	addi	a5,a5,-16
ffffffe0002021b8:	008787b3          	add	a5,a5,s0
ffffffe0002021bc:	fc87b783          	ld	a5,-56(a5)
ffffffe0002021c0:	00379793          	slli	a5,a5,0x3
ffffffe0002021c4:	fe843703          	ld	a4,-24(s0)
ffffffe0002021c8:	00f707b3          	add	a5,a4,a5
ffffffe0002021cc:	0007b783          	ld	a5,0(a5)
ffffffe0002021d0:	00a7d793          	srli	a5,a5,0xa
ffffffe0002021d4:	00c79713          	slli	a4,a5,0xc
ffffffe0002021d8:	fbf00793          	li	a5,-65
ffffffe0002021dc:	01f79793          	slli	a5,a5,0x1f
ffffffe0002021e0:	00f707b3          	add	a5,a4,a5
ffffffe0002021e4:	fef43423          	sd	a5,-24(s0)
    for(int i=2;i>0;i--){
ffffffe0002021e8:	fe442783          	lw	a5,-28(s0)
ffffffe0002021ec:	fff7879b          	addiw	a5,a5,-1
ffffffe0002021f0:	fef42223          	sw	a5,-28(s0)
ffffffe0002021f4:	fe442783          	lw	a5,-28(s0)
ffffffe0002021f8:	0007879b          	sext.w	a5,a5
ffffffe0002021fc:	f6f04ae3          	bgtz	a5,ffffffe000202170 <checkValid+0x58>
        // printk("page table address is %016lx\n",ptr);
    }

    //printk("ptr[VPN[0]] : %016lx\n",ptr[VPN[0]]);
    uint64_t flag = ptr[VPN[0]]&0x1;
ffffffe000202200:	fb843783          	ld	a5,-72(s0)
ffffffe000202204:	00379793          	slli	a5,a5,0x3
ffffffe000202208:	fe843703          	ld	a4,-24(s0)
ffffffe00020220c:	00f707b3          	add	a5,a4,a5
ffffffe000202210:	0007b783          	ld	a5,0(a5)
ffffffe000202214:	0017f793          	andi	a5,a5,1
ffffffe000202218:	fcf43c23          	sd	a5,-40(s0)
    // printk("flag : %d\n",flag);
    if(flag==0)
ffffffe00020221c:	fd843783          	ld	a5,-40(s0)
ffffffe000202220:	00079663          	bnez	a5,ffffffe00020222c <checkValid+0x114>
        return 0;
ffffffe000202224:	00000793          	li	a5,0
ffffffe000202228:	0080006f          	j	ffffffe000202230 <checkValid+0x118>
    return 1;
ffffffe00020222c:	00100793          	li	a5,1
}
ffffffe000202230:	00078513          	mv	a0,a5
ffffffe000202234:	05813403          	ld	s0,88(sp)
ffffffe000202238:	06010113          	addi	sp,sp,96
ffffffe00020223c:	00008067          	ret

ffffffe000202240 <do_fork>:
 * used to achieve the system call -> fork;
 * @param regs the parent process's registers information
 * @return if we fork the child process successfully, return child pid. Otherwise, return -1;
 * 
*/
long do_fork(struct pt_regs* regs){
ffffffe000202240:	f9010113          	addi	sp,sp,-112
ffffffe000202244:	06113423          	sd	ra,104(sp)
ffffffe000202248:	06813023          	sd	s0,96(sp)
ffffffe00020224c:	07010413          	addi	s0,sp,112
ffffffe000202250:	f8a43c23          	sd	a0,-104(s0)
     * 3. traversal parents' VMA and its page-table
     * 4. add the process into the schedule queue;
     * 5. deal with parents' process return value;
    */
    // create a new child process;
    printk("\n");
ffffffe000202254:	00003517          	auipc	a0,0x3
ffffffe000202258:	17c50513          	addi	a0,a0,380 # ffffffe0002053d0 <__func__.0+0xa0>
ffffffe00020225c:	790020ef          	jal	ffffffe0002049ec <printk>
    struct task_struct* child = (struct task_struct*)alloc_page();
ffffffe000202260:	fd4fe0ef          	jal	ffffffe000200a34 <alloc_page>
ffffffe000202264:	fca43823          	sd	a0,-48(s0)
    // adding into the schedule queue;
    // we do the deep copy first for the child process;
    int index = -1;
ffffffe000202268:	fff00793          	li	a5,-1
ffffffe00020226c:	fef42623          	sw	a5,-20(s0)
    //memset((void*)child,0,PGSIZE);
    memcpy((void*)child,(void*)current,PGSIZE);
ffffffe000202270:	00009797          	auipc	a5,0x9
ffffffe000202274:	da078793          	addi	a5,a5,-608 # ffffffe00020b010 <current>
ffffffe000202278:	0007b783          	ld	a5,0(a5)
ffffffe00020227c:	00001637          	lui	a2,0x1
ffffffe000202280:	00078593          	mv	a1,a5
ffffffe000202284:	fd043503          	ld	a0,-48(s0)
ffffffe000202288:	0f5020ef          	jal	ffffffe000204b7c <memcpy>
    for(int i=0;i<NR_TASKS;i++){
ffffffe00020228c:	fe042423          	sw	zero,-24(s0)
ffffffe000202290:	0480006f          	j	ffffffe0002022d8 <do_fork+0x98>
        if(task[i]==NULL){
ffffffe000202294:	00009717          	auipc	a4,0x9
ffffffe000202298:	da470713          	addi	a4,a4,-604 # ffffffe00020b038 <task>
ffffffe00020229c:	fe842783          	lw	a5,-24(s0)
ffffffe0002022a0:	00379793          	slli	a5,a5,0x3
ffffffe0002022a4:	00f707b3          	add	a5,a4,a5
ffffffe0002022a8:	0007b783          	ld	a5,0(a5)
ffffffe0002022ac:	02079063          	bnez	a5,ffffffe0002022cc <do_fork+0x8c>
            index = i;
ffffffe0002022b0:	fe842783          	lw	a5,-24(s0)
ffffffe0002022b4:	fef42623          	sw	a5,-20(s0)
            tasks_number = index;
ffffffe0002022b8:	00005797          	auipc	a5,0x5
ffffffe0002022bc:	d5878793          	addi	a5,a5,-680 # ffffffe000207010 <tasks_number>
ffffffe0002022c0:	fec42703          	lw	a4,-20(s0)
ffffffe0002022c4:	00e7a023          	sw	a4,0(a5)
            break;
ffffffe0002022c8:	0200006f          	j	ffffffe0002022e8 <do_fork+0xa8>
    for(int i=0;i<NR_TASKS;i++){
ffffffe0002022cc:	fe842783          	lw	a5,-24(s0)
ffffffe0002022d0:	0017879b          	addiw	a5,a5,1
ffffffe0002022d4:	fef42423          	sw	a5,-24(s0)
ffffffe0002022d8:	fe842783          	lw	a5,-24(s0)
ffffffe0002022dc:	0007871b          	sext.w	a4,a5
ffffffe0002022e0:	00800793          	li	a5,8
ffffffe0002022e4:	fae7d8e3          	bge	a5,a4,ffffffe000202294 <do_fork+0x54>
        }
    }
    if(index==-1){
ffffffe0002022e8:	fec42783          	lw	a5,-20(s0)
ffffffe0002022ec:	0007871b          	sext.w	a4,a5
ffffffe0002022f0:	fff00793          	li	a5,-1
ffffffe0002022f4:	00f71c63          	bne	a4,a5,ffffffe00020230c <do_fork+0xcc>
        printk("the array is full!\n");
ffffffe0002022f8:	00003517          	auipc	a0,0x3
ffffffe0002022fc:	0e050513          	addi	a0,a0,224 # ffffffe0002053d8 <__func__.0+0xa8>
ffffffe000202300:	6ec020ef          	jal	ffffffe0002049ec <printk>
        return -1;
ffffffe000202304:	fff00793          	li	a5,-1
ffffffe000202308:	32c0006f          	j	ffffffe000202634 <do_fork+0x3f4>
    }
    task[tasks_number] = child;
ffffffe00020230c:	00005797          	auipc	a5,0x5
ffffffe000202310:	d0478793          	addi	a5,a5,-764 # ffffffe000207010 <tasks_number>
ffffffe000202314:	0007a783          	lw	a5,0(a5)
ffffffe000202318:	00009717          	auipc	a4,0x9
ffffffe00020231c:	d2070713          	addi	a4,a4,-736 # ffffffe00020b038 <task>
ffffffe000202320:	00379793          	slli	a5,a5,0x3
ffffffe000202324:	00f707b3          	add	a5,a4,a5
ffffffe000202328:	fd043703          	ld	a4,-48(s0)
ffffffe00020232c:	00e7b023          	sd	a4,0(a5)
    child->pid = tasks_number;
ffffffe000202330:	00005797          	auipc	a5,0x5
ffffffe000202334:	ce078793          	addi	a5,a5,-800 # ffffffe000207010 <tasks_number>
ffffffe000202338:	0007a783          	lw	a5,0(a5)
ffffffe00020233c:	00078713          	mv	a4,a5
ffffffe000202340:	fd043783          	ld	a5,-48(s0)
ffffffe000202344:	00e7bc23          	sd	a4,24(a5)
    child->thread.ra = (uint64_t)__ret_from_fork;
ffffffe000202348:	ffffe717          	auipc	a4,0xffffe
ffffffe00020234c:	df870713          	addi	a4,a4,-520 # ffffffe000200140 <__ret_from_fork>
ffffffe000202350:	fd043783          	ld	a5,-48(s0)
ffffffe000202354:	02e7b023          	sd	a4,32(a5)
     *    ****************  ->  low address            
    */


    // its turn to the regs 
    uint64_t offset = (uint64_t)regs-PGROUNDDOWN((uint64_t)regs);
ffffffe000202358:	f9843703          	ld	a4,-104(s0)
ffffffe00020235c:	000017b7          	lui	a5,0x1
ffffffe000202360:	fff78793          	addi	a5,a5,-1 # fff <PGSIZE-0x1>
ffffffe000202364:	00f777b3          	and	a5,a4,a5
ffffffe000202368:	fcf43423          	sd	a5,-56(s0)
    struct pt_regs* child_regs = (struct pt_regs*) ((uint64_t)child+offset);
ffffffe00020236c:	fd043703          	ld	a4,-48(s0)
ffffffe000202370:	fc843783          	ld	a5,-56(s0)
ffffffe000202374:	00f707b3          	add	a5,a4,a5
ffffffe000202378:	fcf43023          	sd	a5,-64(s0)
    child->thread.sp = (uint64_t)child_regs;
ffffffe00020237c:	fc043703          	ld	a4,-64(s0)
ffffffe000202380:	fd043783          	ld	a5,-48(s0)
ffffffe000202384:	02e7b423          	sd	a4,40(a5)
    //child->thread.sscratch = regs->sscratch;
    // create a new page table for the child process;
    child->pgd = (uint64_t*)alloc_page();
ffffffe000202388:	eacfe0ef          	jal	ffffffe000200a34 <alloc_page>
ffffffe00020238c:	00050713          	mv	a4,a0
ffffffe000202390:	fd043783          	ld	a5,-48(s0)
ffffffe000202394:	0ae7b423          	sd	a4,168(a5)
    // first copy for the kernel page table 
    // for(int i=0;i<PGSIZE/8;i++)
    //     child->pgd[i] = swapper_pg_dir[i];
    memset((void*)child->pgd,0,PGSIZE);
ffffffe000202398:	fd043783          	ld	a5,-48(s0)
ffffffe00020239c:	0a87b783          	ld	a5,168(a5)
ffffffe0002023a0:	00001637          	lui	a2,0x1
ffffffe0002023a4:	00000593          	li	a1,0
ffffffe0002023a8:	00078513          	mv	a0,a5
ffffffe0002023ac:	760020ef          	jal	ffffffe000204b0c <memset>
    memcpy((void*)child->pgd,(void*)swapper_pg_dir,PGSIZE);
ffffffe0002023b0:	fd043783          	ld	a5,-48(s0)
ffffffe0002023b4:	0a87b783          	ld	a5,168(a5)
ffffffe0002023b8:	00001637          	lui	a2,0x1
ffffffe0002023bc:	0000b597          	auipc	a1,0xb
ffffffe0002023c0:	c4458593          	addi	a1,a1,-956 # ffffffe00020d000 <swapper_pg_dir>
ffffffe0002023c4:	00078513          	mv	a0,a5
ffffffe0002023c8:	7b4020ef          	jal	ffffffe000204b7c <memcpy>
    // we start to do mapping for the VMA valid area;
    //child->mm = *(struct mm_struct*)alloc_page();
    // memset(&child->mm,0,PGSIZE);
    //child->mm.mmap = NULL;
    // if fork successfully, the child process return value is 0
    child_regs->a0 = 0;
ffffffe0002023cc:	fc043783          	ld	a5,-64(s0)
ffffffe0002023d0:	0407b823          	sd	zero,80(a5)
    child_regs->sp = child_regs->sp - (uint64_t)current + (uint64_t)task[tasks_number];  
ffffffe0002023d4:	fc043783          	ld	a5,-64(s0)
ffffffe0002023d8:	0107b783          	ld	a5,16(a5)
ffffffe0002023dc:	00009717          	auipc	a4,0x9
ffffffe0002023e0:	c3470713          	addi	a4,a4,-972 # ffffffe00020b010 <current>
ffffffe0002023e4:	00073703          	ld	a4,0(a4)
ffffffe0002023e8:	40e787b3          	sub	a5,a5,a4
ffffffe0002023ec:	00005717          	auipc	a4,0x5
ffffffe0002023f0:	c2470713          	addi	a4,a4,-988 # ffffffe000207010 <tasks_number>
ffffffe0002023f4:	00072703          	lw	a4,0(a4)
ffffffe0002023f8:	00009697          	auipc	a3,0x9
ffffffe0002023fc:	c4068693          	addi	a3,a3,-960 # ffffffe00020b038 <task>
ffffffe000202400:	00371713          	slli	a4,a4,0x3
ffffffe000202404:	00e68733          	add	a4,a3,a4
ffffffe000202408:	00073703          	ld	a4,0(a4)
ffffffe00020240c:	00e78733          	add	a4,a5,a4
ffffffe000202410:	fc043783          	ld	a5,-64(s0)
ffffffe000202414:	00e7b823          	sd	a4,16(a5)
    child_regs->sepc = regs->sepc + 4;
ffffffe000202418:	f9843783          	ld	a5,-104(s0)
ffffffe00020241c:	1007b783          	ld	a5,256(a5)
ffffffe000202420:	00478713          	addi	a4,a5,4
ffffffe000202424:	fc043783          	ld	a5,-64(s0)
ffffffe000202428:	10e7b023          	sd	a4,256(a5)
    struct vm_area_struct* start_area = current->mm.mmap;
ffffffe00020242c:	00009797          	auipc	a5,0x9
ffffffe000202430:	be478793          	addi	a5,a5,-1052 # ffffffe00020b010 <current>
ffffffe000202434:	0007b783          	ld	a5,0(a5)
ffffffe000202438:	0b07b783          	ld	a5,176(a5)
ffffffe00020243c:	fef43023          	sd	a5,-32(s0)
    for(;start_area!=NULL;){
ffffffe000202440:	1a00006f          	j	ffffffe0002025e0 <do_fork+0x3a0>
        // add the vma into the vma_list;
        do_mmap(&child->mm,start_area->vm_start,(start_area->vm_end-start_area->vm_start),start_area->vm_pgoff,start_area->vm_filesz,start_area->vm_flags);
ffffffe000202444:	fd043783          	ld	a5,-48(s0)
ffffffe000202448:	0b078513          	addi	a0,a5,176
ffffffe00020244c:	fe043783          	ld	a5,-32(s0)
ffffffe000202450:	0087b583          	ld	a1,8(a5)
ffffffe000202454:	fe043783          	ld	a5,-32(s0)
ffffffe000202458:	0107b703          	ld	a4,16(a5)
ffffffe00020245c:	fe043783          	ld	a5,-32(s0)
ffffffe000202460:	0087b783          	ld	a5,8(a5)
ffffffe000202464:	40f70633          	sub	a2,a4,a5
ffffffe000202468:	fe043783          	ld	a5,-32(s0)
ffffffe00020246c:	0307b683          	ld	a3,48(a5)
ffffffe000202470:	fe043783          	ld	a5,-32(s0)
ffffffe000202474:	0387b703          	ld	a4,56(a5)
ffffffe000202478:	fe043783          	ld	a5,-32(s0)
ffffffe00020247c:	0287b783          	ld	a5,40(a5)
ffffffe000202480:	849ff0ef          	jal	ffffffe000201cc8 <do_mmap>
        Log(RED "WE FIND THE FIRST PART [%016lx,%016lx)",start_area->vm_start,start_area->vm_end,CLEAR);
ffffffe000202484:	fe043783          	ld	a5,-32(s0)
ffffffe000202488:	0087b703          	ld	a4,8(a5)
ffffffe00020248c:	fe043783          	ld	a5,-32(s0)
ffffffe000202490:	0107b783          	ld	a5,16(a5)
ffffffe000202494:	00003817          	auipc	a6,0x3
ffffffe000202498:	f5c80813          	addi	a6,a6,-164 # ffffffe0002053f0 <__func__.0+0xc0>
ffffffe00020249c:	00003697          	auipc	a3,0x3
ffffffe0002024a0:	b6c68693          	addi	a3,a3,-1172 # ffffffe000205008 <__func__.1>
ffffffe0002024a4:	09200613          	li	a2,146
ffffffe0002024a8:	00003597          	auipc	a1,0x3
ffffffe0002024ac:	e9858593          	addi	a1,a1,-360 # ffffffe000205340 <__func__.0+0x10>
ffffffe0002024b0:	00003517          	auipc	a0,0x3
ffffffe0002024b4:	f4850513          	addi	a0,a0,-184 # ffffffe0002053f8 <__func__.0+0xc8>
ffffffe0002024b8:	534020ef          	jal	ffffffe0002049ec <printk>
        uint64_t page_start = PGROUNDDOWN(start_area->vm_start);
ffffffe0002024bc:	fe043783          	ld	a5,-32(s0)
ffffffe0002024c0:	0087b703          	ld	a4,8(a5)
ffffffe0002024c4:	fffff7b7          	lui	a5,0xfffff
ffffffe0002024c8:	00f777b3          	and	a5,a4,a5
ffffffe0002024cc:	fcf43c23          	sd	a5,-40(s0)
        while(page_start<start_area->vm_end){
ffffffe0002024d0:	0f40006f          	j	ffffffe0002025c4 <do_fork+0x384>
            uint64_t fg = checkValid(page_start,current->pgd);
ffffffe0002024d4:	00009797          	auipc	a5,0x9
ffffffe0002024d8:	b3c78793          	addi	a5,a5,-1220 # ffffffe00020b010 <current>
ffffffe0002024dc:	0007b783          	ld	a5,0(a5)
ffffffe0002024e0:	0a87b783          	ld	a5,168(a5)
ffffffe0002024e4:	00078593          	mv	a1,a5
ffffffe0002024e8:	fd843503          	ld	a0,-40(s0)
ffffffe0002024ec:	c2dff0ef          	jal	ffffffe000202118 <checkValid>
ffffffe0002024f0:	faa43c23          	sd	a0,-72(s0)
            printk("%d\n",fg);
ffffffe0002024f4:	fb843583          	ld	a1,-72(s0)
ffffffe0002024f8:	00003517          	auipc	a0,0x3
ffffffe0002024fc:	f4850513          	addi	a0,a0,-184 # ffffffe000205440 <__func__.0+0x110>
ffffffe000202500:	4ec020ef          	jal	ffffffe0002049ec <printk>
            if(fg==0x1){
ffffffe000202504:	fb843703          	ld	a4,-72(s0)
ffffffe000202508:	00100793          	li	a5,1
ffffffe00020250c:	0af71463          	bne	a4,a5,ffffffe0002025b4 <do_fork+0x374>
                 * 
                 * vma perm : XWRA
                 * page_table_perm: UXWRV;
                 * 
                 * */ 
                Log(RED"We have entered the valid part [%016lx,%016lx);",page_start,page_start+PGSIZE,CLEAR);
ffffffe000202510:	fd843703          	ld	a4,-40(s0)
ffffffe000202514:	000017b7          	lui	a5,0x1
ffffffe000202518:	00f707b3          	add	a5,a4,a5
ffffffe00020251c:	00003817          	auipc	a6,0x3
ffffffe000202520:	ed480813          	addi	a6,a6,-300 # ffffffe0002053f0 <__func__.0+0xc0>
ffffffe000202524:	fd843703          	ld	a4,-40(s0)
ffffffe000202528:	00003697          	auipc	a3,0x3
ffffffe00020252c:	ae068693          	addi	a3,a3,-1312 # ffffffe000205008 <__func__.1>
ffffffe000202530:	0a100613          	li	a2,161
ffffffe000202534:	00003597          	auipc	a1,0x3
ffffffe000202538:	e0c58593          	addi	a1,a1,-500 # ffffffe000205340 <__func__.0+0x10>
ffffffe00020253c:	00003517          	auipc	a0,0x3
ffffffe000202540:	f0c50513          	addi	a0,a0,-244 # ffffffe000205448 <__func__.0+0x118>
ffffffe000202544:	4a8020ef          	jal	ffffffe0002049ec <printk>
                uint64_t* add_page = (uint64_t*)alloc_page();
ffffffe000202548:	cecfe0ef          	jal	ffffffe000200a34 <alloc_page>
ffffffe00020254c:	faa43823          	sd	a0,-80(s0)
                memset((void*)add_page,0,PGSIZE);
ffffffe000202550:	00001637          	lui	a2,0x1
ffffffe000202554:	00000593          	li	a1,0
ffffffe000202558:	fb043503          	ld	a0,-80(s0)
ffffffe00020255c:	5b0020ef          	jal	ffffffe000204b0c <memset>
                memcpy((void*)add_page,(void*)page_start,PGSIZE);
ffffffe000202560:	fd843783          	ld	a5,-40(s0)
ffffffe000202564:	00001637          	lui	a2,0x1
ffffffe000202568:	00078593          	mv	a1,a5
ffffffe00020256c:	fb043503          	ld	a0,-80(s0)
ffffffe000202570:	60c020ef          	jal	ffffffe000204b7c <memcpy>
                uint64_t perm = 0x11|(start_area->vm_flags&0b1110);
ffffffe000202574:	fe043783          	ld	a5,-32(s0)
ffffffe000202578:	0287b783          	ld	a5,40(a5) # 1028 <PGSIZE+0x28>
ffffffe00020257c:	00e7f793          	andi	a5,a5,14
ffffffe000202580:	0117e793          	ori	a5,a5,17
ffffffe000202584:	faf43423          	sd	a5,-88(s0)
                create_mapping(child->pgd,page_start,(uint64_t)add_page-PA2VA_OFFSET,PGSIZE,perm);
ffffffe000202588:	fd043783          	ld	a5,-48(s0)
ffffffe00020258c:	0a87b503          	ld	a0,168(a5)
ffffffe000202590:	fb043703          	ld	a4,-80(s0)
ffffffe000202594:	04100793          	li	a5,65
ffffffe000202598:	01f79793          	slli	a5,a5,0x1f
ffffffe00020259c:	00f707b3          	add	a5,a4,a5
ffffffe0002025a0:	fa843703          	ld	a4,-88(s0)
ffffffe0002025a4:	000016b7          	lui	a3,0x1
ffffffe0002025a8:	00078613          	mv	a2,a5
ffffffe0002025ac:	fd843583          	ld	a1,-40(s0)
ffffffe0002025b0:	1b4010ef          	jal	ffffffe000203764 <create_mapping>
            }
            page_start+=PGSIZE;
ffffffe0002025b4:	fd843703          	ld	a4,-40(s0)
ffffffe0002025b8:	000017b7          	lui	a5,0x1
ffffffe0002025bc:	00f707b3          	add	a5,a4,a5
ffffffe0002025c0:	fcf43c23          	sd	a5,-40(s0)
        while(page_start<start_area->vm_end){
ffffffe0002025c4:	fe043783          	ld	a5,-32(s0)
ffffffe0002025c8:	0107b783          	ld	a5,16(a5) # 1010 <PGSIZE+0x10>
ffffffe0002025cc:	fd843703          	ld	a4,-40(s0)
ffffffe0002025d0:	f0f762e3          	bltu	a4,a5,ffffffe0002024d4 <do_fork+0x294>
        }
        start_area = start_area->vm_next;
ffffffe0002025d4:	fe043783          	ld	a5,-32(s0)
ffffffe0002025d8:	0187b783          	ld	a5,24(a5)
ffffffe0002025dc:	fef43023          	sd	a5,-32(s0)
    for(;start_area!=NULL;){
ffffffe0002025e0:	fe043783          	ld	a5,-32(s0)
ffffffe0002025e4:	e60790e3          	bnez	a5,ffffffe000202444 <do_fork+0x204>
    }
    Log(RED "pid:%d is fork from the pid: %d",tasks_number,current->pid,CLEAR);
ffffffe0002025e8:	00005797          	auipc	a5,0x5
ffffffe0002025ec:	a2878793          	addi	a5,a5,-1496 # ffffffe000207010 <tasks_number>
ffffffe0002025f0:	0007a703          	lw	a4,0(a5)
ffffffe0002025f4:	00009797          	auipc	a5,0x9
ffffffe0002025f8:	a1c78793          	addi	a5,a5,-1508 # ffffffe00020b010 <current>
ffffffe0002025fc:	0007b783          	ld	a5,0(a5)
ffffffe000202600:	0187b783          	ld	a5,24(a5)
ffffffe000202604:	00003817          	auipc	a6,0x3
ffffffe000202608:	dec80813          	addi	a6,a6,-532 # ffffffe0002053f0 <__func__.0+0xc0>
ffffffe00020260c:	00003697          	auipc	a3,0x3
ffffffe000202610:	9fc68693          	addi	a3,a3,-1540 # ffffffe000205008 <__func__.1>
ffffffe000202614:	0ac00613          	li	a2,172
ffffffe000202618:	00003597          	auipc	a1,0x3
ffffffe00020261c:	d2858593          	addi	a1,a1,-728 # ffffffe000205340 <__func__.0+0x10>
ffffffe000202620:	00003517          	auipc	a0,0x3
ffffffe000202624:	e7850513          	addi	a0,a0,-392 # ffffffe000205498 <__func__.0+0x168>
ffffffe000202628:	3c4020ef          	jal	ffffffe0002049ec <printk>
    return child->pid;
ffffffe00020262c:	fd043783          	ld	a5,-48(s0)
ffffffe000202630:	0187b783          	ld	a5,24(a5)
    
}
ffffffe000202634:	00078513          	mv	a0,a5
ffffffe000202638:	06813083          	ld	ra,104(sp)
ffffffe00020263c:	06013403          	ld	s0,96(sp)
ffffffe000202640:	07010113          	addi	sp,sp,112
ffffffe000202644:	00008067          	ret

ffffffe000202648 <do_cow_fork>:


long do_cow_fork(struct pt_regs* regs){
ffffffe000202648:	f6010113          	addi	sp,sp,-160
ffffffe00020264c:	08113c23          	sd	ra,152(sp)
ffffffe000202650:	08813823          	sd	s0,144(sp)
ffffffe000202654:	08913423          	sd	s1,136(sp)
ffffffe000202658:	0a010413          	addi	s0,sp,160
ffffffe00020265c:	f6a43423          	sd	a0,-152(s0)
    printk("COW : ENTER!\n");
ffffffe000202660:	00003517          	auipc	a0,0x3
ffffffe000202664:	e7850513          	addi	a0,a0,-392 # ffffffe0002054d8 <__func__.0+0x1a8>
ffffffe000202668:	384020ef          	jal	ffffffe0002049ec <printk>
     * 3. 但是父和子的页表映射的是同一块物理地址 -> 都保证了只读;
     * 4. 只有当需要写的时候，才会报 page_fault
     * 
    */
    // we create a new child process;
    struct task_struct* child = (struct task_struct*)alloc_page();
ffffffe00020266c:	bc8fe0ef          	jal	ffffffe000200a34 <alloc_page>
ffffffe000202670:	faa43823          	sd	a0,-80(s0)
    memset((void*)child,0,PGSIZE);
ffffffe000202674:	00001637          	lui	a2,0x1
ffffffe000202678:	00000593          	li	a1,0
ffffffe00020267c:	fb043503          	ld	a0,-80(s0)
ffffffe000202680:	48c020ef          	jal	ffffffe000204b0c <memset>
    memcpy((void*)child,(void*)current,PGSIZE);
ffffffe000202684:	00009797          	auipc	a5,0x9
ffffffe000202688:	98c78793          	addi	a5,a5,-1652 # ffffffe00020b010 <current>
ffffffe00020268c:	0007b783          	ld	a5,0(a5)
ffffffe000202690:	00001637          	lui	a2,0x1
ffffffe000202694:	00078593          	mv	a1,a5
ffffffe000202698:	fb043503          	ld	a0,-80(s0)
ffffffe00020269c:	4e0020ef          	jal	ffffffe000204b7c <memcpy>
    int idx = -1;
ffffffe0002026a0:	fff00793          	li	a5,-1
ffffffe0002026a4:	fcf42e23          	sw	a5,-36(s0)
    for(int i=0;i<NR_TASKS;i++){
ffffffe0002026a8:	fc042c23          	sw	zero,-40(s0)
ffffffe0002026ac:	0500006f          	j	ffffffe0002026fc <do_cow_fork+0xb4>
        // find the process 
        if(task[i]==NULL){
ffffffe0002026b0:	00009717          	auipc	a4,0x9
ffffffe0002026b4:	98870713          	addi	a4,a4,-1656 # ffffffe00020b038 <task>
ffffffe0002026b8:	fd842783          	lw	a5,-40(s0)
ffffffe0002026bc:	00379793          	slli	a5,a5,0x3
ffffffe0002026c0:	00f707b3          	add	a5,a4,a5
ffffffe0002026c4:	0007b783          	ld	a5,0(a5)
ffffffe0002026c8:	02079463          	bnez	a5,ffffffe0002026f0 <do_cow_fork+0xa8>
            tasks_number = i;
ffffffe0002026cc:	00005797          	auipc	a5,0x5
ffffffe0002026d0:	94478793          	addi	a5,a5,-1724 # ffffffe000207010 <tasks_number>
ffffffe0002026d4:	fd842703          	lw	a4,-40(s0)
ffffffe0002026d8:	00e7a023          	sw	a4,0(a5)
            idx = tasks_number;
ffffffe0002026dc:	00005797          	auipc	a5,0x5
ffffffe0002026e0:	93478793          	addi	a5,a5,-1740 # ffffffe000207010 <tasks_number>
ffffffe0002026e4:	0007a783          	lw	a5,0(a5)
ffffffe0002026e8:	fcf42e23          	sw	a5,-36(s0)
            break;
ffffffe0002026ec:	0200006f          	j	ffffffe00020270c <do_cow_fork+0xc4>
    for(int i=0;i<NR_TASKS;i++){
ffffffe0002026f0:	fd842783          	lw	a5,-40(s0)
ffffffe0002026f4:	0017879b          	addiw	a5,a5,1
ffffffe0002026f8:	fcf42c23          	sw	a5,-40(s0)
ffffffe0002026fc:	fd842783          	lw	a5,-40(s0)
ffffffe000202700:	0007871b          	sext.w	a4,a5
ffffffe000202704:	00800793          	li	a5,8
ffffffe000202708:	fae7d4e3          	bge	a5,a4,ffffffe0002026b0 <do_cow_fork+0x68>
        }
    }
    if(idx == -1){
ffffffe00020270c:	fdc42783          	lw	a5,-36(s0)
ffffffe000202710:	0007871b          	sext.w	a4,a5
ffffffe000202714:	fff00793          	li	a5,-1
ffffffe000202718:	00f71c63          	bne	a4,a5,ffffffe000202730 <do_cow_fork+0xe8>
        printk("WE CREATE the PROCESS DEFEATED!\n");
ffffffe00020271c:	00003517          	auipc	a0,0x3
ffffffe000202720:	dcc50513          	addi	a0,a0,-564 # ffffffe0002054e8 <__func__.0+0x1b8>
ffffffe000202724:	2c8020ef          	jal	ffffffe0002049ec <printk>
        return -1;
ffffffe000202728:	fff00793          	li	a5,-1
ffffffe00020272c:	3940006f          	j	ffffffe000202ac0 <do_cow_fork+0x478>
    }
    task[tasks_number] = child;
ffffffe000202730:	00005797          	auipc	a5,0x5
ffffffe000202734:	8e078793          	addi	a5,a5,-1824 # ffffffe000207010 <tasks_number>
ffffffe000202738:	0007a783          	lw	a5,0(a5)
ffffffe00020273c:	00009717          	auipc	a4,0x9
ffffffe000202740:	8fc70713          	addi	a4,a4,-1796 # ffffffe00020b038 <task>
ffffffe000202744:	00379793          	slli	a5,a5,0x3
ffffffe000202748:	00f707b3          	add	a5,a4,a5
ffffffe00020274c:	fb043703          	ld	a4,-80(s0)
ffffffe000202750:	00e7b023          	sd	a4,0(a5)
    child->pid = tasks_number;
ffffffe000202754:	00005797          	auipc	a5,0x5
ffffffe000202758:	8bc78793          	addi	a5,a5,-1860 # ffffffe000207010 <tasks_number>
ffffffe00020275c:	0007a783          	lw	a5,0(a5)
ffffffe000202760:	00078713          	mv	a4,a5
ffffffe000202764:	fb043783          	ld	a5,-80(s0)
ffffffe000202768:	00e7bc23          	sd	a4,24(a5)
     *    *              * 
     *    ****************  ->  low address            
    */

    // Now we do the copy for the child process;
    uint64_t offset = (uint64_t) regs - PGROUNDDOWN((uint64_t)regs);
ffffffe00020276c:	f6843703          	ld	a4,-152(s0)
ffffffe000202770:	000017b7          	lui	a5,0x1
ffffffe000202774:	fff78793          	addi	a5,a5,-1 # fff <PGSIZE-0x1>
ffffffe000202778:	00f777b3          	and	a5,a4,a5
ffffffe00020277c:	faf43423          	sd	a5,-88(s0)
    struct pt_regs* child_regs = (struct pt_regs*)((uint64_t)child+offset);
ffffffe000202780:	fb043703          	ld	a4,-80(s0)
ffffffe000202784:	fa843783          	ld	a5,-88(s0)
ffffffe000202788:	00f707b3          	add	a5,a4,a5
ffffffe00020278c:	faf43023          	sd	a5,-96(s0)
    // 和 parent process 一样，在 thread.sp 中保存了当前的内核栈开始的位置;
    child->thread.sp = (uint64_t)child_regs;
ffffffe000202790:	fa043703          	ld	a4,-96(s0)
ffffffe000202794:	fb043783          	ld	a5,-80(s0)
ffffffe000202798:	02e7b423          	sd	a4,40(a5)
    // change the return address of the child process;
    child->thread.ra = (uint64_t)__ret_from_fork;
ffffffe00020279c:	ffffe717          	auipc	a4,0xffffe
ffffffe0002027a0:	9a470713          	addi	a4,a4,-1628 # ffffffe000200140 <__ret_from_fork>
ffffffe0002027a4:	fb043783          	ld	a5,-80(s0)
ffffffe0002027a8:	02e7b023          	sd	a4,32(a5)
    // child->thread.sscratch = regs->sscratch;
    // 需要更改栈顶 sp 的位置;
    child_regs ->sp = child_regs->sp + (uint64_t)task[tasks_number] - (uint64_t)current;
ffffffe0002027ac:	fa043783          	ld	a5,-96(s0)
ffffffe0002027b0:	0107b783          	ld	a5,16(a5)
ffffffe0002027b4:	00005717          	auipc	a4,0x5
ffffffe0002027b8:	85c70713          	addi	a4,a4,-1956 # ffffffe000207010 <tasks_number>
ffffffe0002027bc:	00072703          	lw	a4,0(a4)
ffffffe0002027c0:	00009697          	auipc	a3,0x9
ffffffe0002027c4:	87868693          	addi	a3,a3,-1928 # ffffffe00020b038 <task>
ffffffe0002027c8:	00371713          	slli	a4,a4,0x3
ffffffe0002027cc:	00e68733          	add	a4,a3,a4
ffffffe0002027d0:	00073703          	ld	a4,0(a4)
ffffffe0002027d4:	00e787b3          	add	a5,a5,a4
ffffffe0002027d8:	00009717          	auipc	a4,0x9
ffffffe0002027dc:	83870713          	addi	a4,a4,-1992 # ffffffe00020b010 <current>
ffffffe0002027e0:	00073703          	ld	a4,0(a4)
ffffffe0002027e4:	40e78733          	sub	a4,a5,a4
ffffffe0002027e8:	fa043783          	ld	a5,-96(s0)
ffffffe0002027ec:	00e7b823          	sd	a4,16(a5)
    child_regs ->a0 = 0;
ffffffe0002027f0:	fa043783          	ld	a5,-96(s0)
ffffffe0002027f4:	0407b823          	sd	zero,80(a5)
    child_regs ->sepc += 4;
ffffffe0002027f8:	fa043783          	ld	a5,-96(s0)
ffffffe0002027fc:	1007b783          	ld	a5,256(a5)
ffffffe000202800:	00478713          	addi	a4,a5,4
ffffffe000202804:	fa043783          	ld	a5,-96(s0)
ffffffe000202808:	10e7b023          	sd	a4,256(a5)

    // create the page_table;
    child->pgd = (uint64_t*) alloc_page();
ffffffe00020280c:	a28fe0ef          	jal	ffffffe000200a34 <alloc_page>
ffffffe000202810:	00050713          	mv	a4,a0
ffffffe000202814:	fb043783          	ld	a5,-80(s0)
ffffffe000202818:	0ae7b423          	sd	a4,168(a5)
    memcpy((void*)child->pgd,(void*)swapper_pg_dir,PGSIZE);
ffffffe00020281c:	fb043783          	ld	a5,-80(s0)
ffffffe000202820:	0a87b783          	ld	a5,168(a5)
ffffffe000202824:	00001637          	lui	a2,0x1
ffffffe000202828:	0000a597          	auipc	a1,0xa
ffffffe00020282c:	7d858593          	addi	a1,a1,2008 # ffffffe00020d000 <swapper_pg_dir>
ffffffe000202830:	00078513          	mv	a0,a5
ffffffe000202834:	348020ef          	jal	ffffffe000204b7c <memcpy>
     *  so that the child process can share the memory with the parent process;
     * 
     * 
     *  find the valid area and set the area's PTE to PTE_W = 0;
     */
    struct vm_area_struct* start_area = current->mm.mmap;
ffffffe000202838:	00008797          	auipc	a5,0x8
ffffffe00020283c:	7d878793          	addi	a5,a5,2008 # ffffffe00020b010 <current>
ffffffe000202840:	0007b783          	ld	a5,0(a5)
ffffffe000202844:	0b07b783          	ld	a5,176(a5)
ffffffe000202848:	fcf43823          	sd	a5,-48(s0)
    for(;start_area!=NULL;start_area = start_area->vm_next){
ffffffe00020284c:	21c0006f          	j	ffffffe000202a68 <do_cow_fork+0x420>
        uint64_t VA = PGROUNDDOWN(start_area->vm_start);
ffffffe000202850:	fd043783          	ld	a5,-48(s0)
ffffffe000202854:	0087b703          	ld	a4,8(a5)
ffffffe000202858:	fffff7b7          	lui	a5,0xfffff
ffffffe00020285c:	00f777b3          	and	a5,a4,a5
ffffffe000202860:	fcf43423          	sd	a5,-56(s0)
        uint64_t VA_END = start_area->vm_end;
ffffffe000202864:	fd043783          	ld	a5,-48(s0)
ffffffe000202868:	0107b783          	ld	a5,16(a5) # fffffffffffff010 <VM_END+0xfffff010>
ffffffe00020286c:	f8f43c23          	sd	a5,-104(s0)
        while(VA<VA_END){
ffffffe000202870:	1e00006f          	j	ffffffe000202a50 <do_cow_fork+0x408>
            uint64_t f_check = checkValid(VA,current->pgd);
ffffffe000202874:	00008797          	auipc	a5,0x8
ffffffe000202878:	79c78793          	addi	a5,a5,1948 # ffffffe00020b010 <current>
ffffffe00020287c:	0007b783          	ld	a5,0(a5)
ffffffe000202880:	0a87b783          	ld	a5,168(a5)
ffffffe000202884:	00078593          	mv	a1,a5
ffffffe000202888:	fc843503          	ld	a0,-56(s0)
ffffffe00020288c:	88dff0ef          	jal	ffffffe000202118 <checkValid>
ffffffe000202890:	f8a43823          	sd	a0,-112(s0)
            if(f_check==1){
ffffffe000202894:	f9043703          	ld	a4,-112(s0)
ffffffe000202898:	00100793          	li	a5,1
ffffffe00020289c:	1af71263          	bne	a4,a5,ffffffe000202a40 <do_cow_fork+0x3f8>
                uint64_t VPN[3];
                VPN[2] = (VA>>30)&0x1ff;
ffffffe0002028a0:	fc843783          	ld	a5,-56(s0)
ffffffe0002028a4:	01e7d793          	srli	a5,a5,0x1e
ffffffe0002028a8:	1ff7f793          	andi	a5,a5,511
ffffffe0002028ac:	f8f43023          	sd	a5,-128(s0)
                VPN[1] = (VA>>21)&0x1ff;
ffffffe0002028b0:	fc843783          	ld	a5,-56(s0)
ffffffe0002028b4:	0157d793          	srli	a5,a5,0x15
ffffffe0002028b8:	1ff7f793          	andi	a5,a5,511
ffffffe0002028bc:	f6f43c23          	sd	a5,-136(s0)
                VPN[0] = (VA>>12)&0x1ff;
ffffffe0002028c0:	fc843783          	ld	a5,-56(s0)
ffffffe0002028c4:	00c7d793          	srli	a5,a5,0xc
ffffffe0002028c8:	1ff7f793          	andi	a5,a5,511
ffffffe0002028cc:	f6f43823          	sd	a5,-144(s0)
                uint64_t* ptr = current->pgd;
ffffffe0002028d0:	00008797          	auipc	a5,0x8
ffffffe0002028d4:	74078793          	addi	a5,a5,1856 # ffffffe00020b010 <current>
ffffffe0002028d8:	0007b783          	ld	a5,0(a5)
ffffffe0002028dc:	0a87b783          	ld	a5,168(a5)
ffffffe0002028e0:	fcf43023          	sd	a5,-64(s0)
                for(int j=2;j>0;j--){
ffffffe0002028e4:	00200793          	li	a5,2
ffffffe0002028e8:	faf42e23          	sw	a5,-68(s0)
ffffffe0002028ec:	04c0006f          	j	ffffffe000202938 <do_cow_fork+0x2f0>
                    ptr = (uint64_t*) (((ptr[VPN[j]]>>10)<<12) + PA2VA_OFFSET);
ffffffe0002028f0:	fbc42783          	lw	a5,-68(s0)
ffffffe0002028f4:	00379793          	slli	a5,a5,0x3
ffffffe0002028f8:	fe078793          	addi	a5,a5,-32
ffffffe0002028fc:	008787b3          	add	a5,a5,s0
ffffffe000202900:	f907b783          	ld	a5,-112(a5)
ffffffe000202904:	00379793          	slli	a5,a5,0x3
ffffffe000202908:	fc043703          	ld	a4,-64(s0)
ffffffe00020290c:	00f707b3          	add	a5,a4,a5
ffffffe000202910:	0007b783          	ld	a5,0(a5)
ffffffe000202914:	00a7d793          	srli	a5,a5,0xa
ffffffe000202918:	00c79713          	slli	a4,a5,0xc
ffffffe00020291c:	fbf00793          	li	a5,-65
ffffffe000202920:	01f79793          	slli	a5,a5,0x1f
ffffffe000202924:	00f707b3          	add	a5,a4,a5
ffffffe000202928:	fcf43023          	sd	a5,-64(s0)
                for(int j=2;j>0;j--){
ffffffe00020292c:	fbc42783          	lw	a5,-68(s0)
ffffffe000202930:	fff7879b          	addiw	a5,a5,-1
ffffffe000202934:	faf42e23          	sw	a5,-68(s0)
ffffffe000202938:	fbc42783          	lw	a5,-68(s0)
ffffffe00020293c:	0007879b          	sext.w	a5,a5
ffffffe000202940:	faf048e3          	bgtz	a5,ffffffe0002028f0 <do_cow_fork+0x2a8>
                }
                ptr[VPN[0]] = ptr[VPN[0]]&0xfffffffffffffffb;
ffffffe000202944:	f7043783          	ld	a5,-144(s0)
ffffffe000202948:	00379793          	slli	a5,a5,0x3
ffffffe00020294c:	fc043703          	ld	a4,-64(s0)
ffffffe000202950:	00f707b3          	add	a5,a4,a5
ffffffe000202954:	0007b703          	ld	a4,0(a5)
ffffffe000202958:	f7043783          	ld	a5,-144(s0)
ffffffe00020295c:	00379793          	slli	a5,a5,0x3
ffffffe000202960:	fc043683          	ld	a3,-64(s0)
ffffffe000202964:	00f687b3          	add	a5,a3,a5
ffffffe000202968:	ffb77713          	andi	a4,a4,-5
ffffffe00020296c:	00e7b023          	sd	a4,0(a5)
                // VA reference + 1;
                // create PTE for child process; and point to the same physical address;
                uint64_t PA = (ptr[VPN[0]]>>10)<<12 + (VA&0xfff);
ffffffe000202970:	f7043783          	ld	a5,-144(s0)
ffffffe000202974:	00379793          	slli	a5,a5,0x3
ffffffe000202978:	fc043703          	ld	a4,-64(s0)
ffffffe00020297c:	00f707b3          	add	a5,a4,a5
ffffffe000202980:	0007b783          	ld	a5,0(a5)
ffffffe000202984:	00a7d793          	srli	a5,a5,0xa
ffffffe000202988:	fc843703          	ld	a4,-56(s0)
ffffffe00020298c:	0007071b          	sext.w	a4,a4
ffffffe000202990:	00070693          	mv	a3,a4
ffffffe000202994:	00001737          	lui	a4,0x1
ffffffe000202998:	fff70713          	addi	a4,a4,-1 # fff <PGSIZE-0x1>
ffffffe00020299c:	00e6f733          	and	a4,a3,a4
ffffffe0002029a0:	0007071b          	sext.w	a4,a4
ffffffe0002029a4:	00c7071b          	addiw	a4,a4,12
ffffffe0002029a8:	0007071b          	sext.w	a4,a4
ffffffe0002029ac:	00e797b3          	sll	a5,a5,a4
ffffffe0002029b0:	f8f43423          	sd	a5,-120(s0)
                get_page(PA+PA2VA_OFFSET);
ffffffe0002029b4:	f8843703          	ld	a4,-120(s0)
ffffffe0002029b8:	fbf00793          	li	a5,-65
ffffffe0002029bc:	01f79793          	slli	a5,a5,0x1f
ffffffe0002029c0:	00f707b3          	add	a5,a4,a5
ffffffe0002029c4:	00078513          	mv	a0,a5
ffffffe0002029c8:	9ecfe0ef          	jal	ffffffe000200bb4 <get_page>
                printk("the number of virtual address : %016lx is %d",PA+PA2VA_OFFSET,get_page_refcnt(PA+PA2VA_OFFSET));
ffffffe0002029cc:	f8843703          	ld	a4,-120(s0)
ffffffe0002029d0:	fbf00793          	li	a5,-65
ffffffe0002029d4:	01f79793          	slli	a5,a5,0x1f
ffffffe0002029d8:	00f704b3          	add	s1,a4,a5
ffffffe0002029dc:	f8843703          	ld	a4,-120(s0)
ffffffe0002029e0:	fbf00793          	li	a5,-65
ffffffe0002029e4:	01f79793          	slli	a5,a5,0x1f
ffffffe0002029e8:	00f707b3          	add	a5,a4,a5
ffffffe0002029ec:	00078513          	mv	a0,a5
ffffffe0002029f0:	a90fe0ef          	jal	ffffffe000200c80 <get_page_refcnt>
ffffffe0002029f4:	00050793          	mv	a5,a0
ffffffe0002029f8:	00078613          	mv	a2,a5
ffffffe0002029fc:	00048593          	mv	a1,s1
ffffffe000202a00:	00003517          	auipc	a0,0x3
ffffffe000202a04:	b1050513          	addi	a0,a0,-1264 # ffffffe000205510 <__func__.0+0x1e0>
ffffffe000202a08:	7e5010ef          	jal	ffffffe0002049ec <printk>
                create_mapping(child->pgd,VA,PA,PGSIZE,ptr[VPN[0]]&0x1f);
ffffffe000202a0c:	fb043783          	ld	a5,-80(s0)
ffffffe000202a10:	0a87b503          	ld	a0,168(a5)
ffffffe000202a14:	f7043783          	ld	a5,-144(s0)
ffffffe000202a18:	00379793          	slli	a5,a5,0x3
ffffffe000202a1c:	fc043703          	ld	a4,-64(s0)
ffffffe000202a20:	00f707b3          	add	a5,a4,a5
ffffffe000202a24:	0007b783          	ld	a5,0(a5)
ffffffe000202a28:	01f7f793          	andi	a5,a5,31
ffffffe000202a2c:	00078713          	mv	a4,a5
ffffffe000202a30:	000016b7          	lui	a3,0x1
ffffffe000202a34:	f8843603          	ld	a2,-120(s0)
ffffffe000202a38:	fc843583          	ld	a1,-56(s0)
ffffffe000202a3c:	529000ef          	jal	ffffffe000203764 <create_mapping>
            }
            VA+=PGSIZE;
ffffffe000202a40:	fc843703          	ld	a4,-56(s0)
ffffffe000202a44:	000017b7          	lui	a5,0x1
ffffffe000202a48:	00f707b3          	add	a5,a4,a5
ffffffe000202a4c:	fcf43423          	sd	a5,-56(s0)
        while(VA<VA_END){
ffffffe000202a50:	fc843703          	ld	a4,-56(s0)
ffffffe000202a54:	f9843783          	ld	a5,-104(s0)
ffffffe000202a58:	e0f76ee3          	bltu	a4,a5,ffffffe000202874 <do_cow_fork+0x22c>
    for(;start_area!=NULL;start_area = start_area->vm_next){
ffffffe000202a5c:	fd043783          	ld	a5,-48(s0)
ffffffe000202a60:	0187b783          	ld	a5,24(a5) # 1018 <PGSIZE+0x18>
ffffffe000202a64:	fcf43823          	sd	a5,-48(s0)
ffffffe000202a68:	fd043783          	ld	a5,-48(s0)
ffffffe000202a6c:	de0792e3          	bnez	a5,ffffffe000202850 <do_cow_fork+0x208>
        }
    }
    // refresh the TLB;
    asm volatile("sfence.vma zero, zero");
ffffffe000202a70:	12000073          	sfence.vma
    Log(RED "pid:%d is fork from the pid: %d",tasks_number,current->pid,CLEAR);
ffffffe000202a74:	00004797          	auipc	a5,0x4
ffffffe000202a78:	59c78793          	addi	a5,a5,1436 # ffffffe000207010 <tasks_number>
ffffffe000202a7c:	0007a703          	lw	a4,0(a5)
ffffffe000202a80:	00008797          	auipc	a5,0x8
ffffffe000202a84:	59078793          	addi	a5,a5,1424 # ffffffe00020b010 <current>
ffffffe000202a88:	0007b783          	ld	a5,0(a5)
ffffffe000202a8c:	0187b783          	ld	a5,24(a5)
ffffffe000202a90:	00003817          	auipc	a6,0x3
ffffffe000202a94:	96080813          	addi	a6,a6,-1696 # ffffffe0002053f0 <__func__.0+0xc0>
ffffffe000202a98:	00003697          	auipc	a3,0x3
ffffffe000202a9c:	aa868693          	addi	a3,a3,-1368 # ffffffe000205540 <__func__.0>
ffffffe000202aa0:	11300613          	li	a2,275
ffffffe000202aa4:	00003597          	auipc	a1,0x3
ffffffe000202aa8:	89c58593          	addi	a1,a1,-1892 # ffffffe000205340 <__func__.0+0x10>
ffffffe000202aac:	00003517          	auipc	a0,0x3
ffffffe000202ab0:	9ec50513          	addi	a0,a0,-1556 # ffffffe000205498 <__func__.0+0x168>
ffffffe000202ab4:	739010ef          	jal	ffffffe0002049ec <printk>
    return child->pid;
ffffffe000202ab8:	fb043783          	ld	a5,-80(s0)
ffffffe000202abc:	0187b783          	ld	a5,24(a5)
ffffffe000202ac0:	00078513          	mv	a0,a5
ffffffe000202ac4:	09813083          	ld	ra,152(sp)
ffffffe000202ac8:	09013403          	ld	s0,144(sp)
ffffffe000202acc:	08813483          	ld	s1,136(sp)
ffffffe000202ad0:	0a010113          	addi	sp,sp,160
ffffffe000202ad4:	00008067          	ret

ffffffe000202ad8 <trap_handler>:
extern char _sramdisk[],_eramdisk[];
extern uint64_t tasks_number;
uint64_t checkValid(uint64_t address,uint64_t* pgd);


void trap_handler(uint64_t scause, uint64_t sepc, struct pt_regs *regs){
ffffffe000202ad8:	fb010113          	addi	sp,sp,-80
ffffffe000202adc:	04113423          	sd	ra,72(sp)
ffffffe000202ae0:	04813023          	sd	s0,64(sp)
ffffffe000202ae4:	05010413          	addi	s0,sp,80
ffffffe000202ae8:	fca43423          	sd	a0,-56(s0)
ffffffe000202aec:	fcb43023          	sd	a1,-64(s0)
ffffffe000202af0:	fac43c23          	sd	a2,-72(s0)
    // 其他 interrupt / exception 可以直接忽略，推荐打印出来供以后调试
    // 通过查阅手册，我们得知 scause 寄存器在最高位置1表示的是trap，后面跟着的Exception Code表示的是trap的类型;
    // 判断 scause = 0x5
    //Log(YELLOW "scause: %lx\n",scause,CLEAR);
    
    if((scause >> 63)==0x1){
ffffffe000202af4:	fc843783          	ld	a5,-56(s0)
ffffffe000202af8:	03f7d713          	srli	a4,a5,0x3f
ffffffe000202afc:	00100793          	li	a5,1
ffffffe000202b00:	02f71863          	bne	a4,a5,ffffffe000202b30 <trap_handler+0x58>
        // We distinguish if it is a trap;
        uint64_t cause_code = scause & 0x7FFFFFFFFFFFFFFF;
ffffffe000202b04:	fc843703          	ld	a4,-56(s0)
ffffffe000202b08:	fff00793          	li	a5,-1
ffffffe000202b0c:	0017d793          	srli	a5,a5,0x1
ffffffe000202b10:	00f777b3          	and	a5,a4,a5
ffffffe000202b14:	fcf43c23          	sd	a5,-40(s0)
        //printk("exception_code: %lx\n",cause_code);
        if(cause_code == 5){
ffffffe000202b18:	fd843703          	ld	a4,-40(s0)
ffffffe000202b1c:	00500793          	li	a5,5
ffffffe000202b20:	1af71e63          	bne	a4,a5,ffffffe000202cdc <trap_handler+0x204>
            // Indicate that it is the time_interrupt;
            //printk("[S] Supervisor Mode Timer Interrupt\n");
            clock_set_next_event();
ffffffe000202b24:	fd8fd0ef          	jal	ffffffe0002002fc <clock_set_next_event>
            do_timer();
ffffffe000202b28:	e35fe0ef          	jal	ffffffe00020195c <do_timer>
            Log(RED "[S] Unhandled Exception: scause = %lx, sepc = %lx , stval = %lx",regs->scause,regs->sepc,regs->stval,CLEAR);
            do_page_fault(regs);
            break;
        }
    }
}
ffffffe000202b2c:	1b00006f          	j	ffffffe000202cdc <trap_handler+0x204>
        uint64_t cause_code = scause & 0x7FFFFFFFFFFFFFFF;
ffffffe000202b30:	fc843703          	ld	a4,-56(s0)
ffffffe000202b34:	fff00793          	li	a5,-1
ffffffe000202b38:	0017d793          	srli	a5,a5,0x1
ffffffe000202b3c:	00f777b3          	and	a5,a4,a5
ffffffe000202b40:	fef43423          	sd	a5,-24(s0)
        switch(cause_code){
ffffffe000202b44:	fe843703          	ld	a4,-24(s0)
ffffffe000202b48:	00f00793          	li	a5,15
ffffffe000202b4c:	12f70e63          	beq	a4,a5,ffffffe000202c88 <trap_handler+0x1b0>
ffffffe000202b50:	fe843703          	ld	a4,-24(s0)
ffffffe000202b54:	00f00793          	li	a5,15
ffffffe000202b58:	18e7e263          	bltu	a5,a4,ffffffe000202cdc <trap_handler+0x204>
ffffffe000202b5c:	fe843703          	ld	a4,-24(s0)
ffffffe000202b60:	00800793          	li	a5,8
ffffffe000202b64:	02f70263          	beq	a4,a5,ffffffe000202b88 <trap_handler+0xb0>
ffffffe000202b68:	fe843703          	ld	a4,-24(s0)
ffffffe000202b6c:	00800793          	li	a5,8
ffffffe000202b70:	16f76663          	bltu	a4,a5,ffffffe000202cdc <trap_handler+0x204>
ffffffe000202b74:	fe843783          	ld	a5,-24(s0)
ffffffe000202b78:	ff478713          	addi	a4,a5,-12
ffffffe000202b7c:	00100793          	li	a5,1
ffffffe000202b80:	14e7ee63          	bltu	a5,a4,ffffffe000202cdc <trap_handler+0x204>
ffffffe000202b84:	1040006f          	j	ffffffe000202c88 <trap_handler+0x1b0>
                uint64_t syscall_number = regs->a7;
ffffffe000202b88:	fb843783          	ld	a5,-72(s0)
ffffffe000202b8c:	0887b783          	ld	a5,136(a5)
ffffffe000202b90:	fef43023          	sd	a5,-32(s0)
                Log(BLUE "the syscall_number is %lx",syscall_number,CLEAR);
ffffffe000202b94:	00003797          	auipc	a5,0x3
ffffffe000202b98:	9bc78793          	addi	a5,a5,-1604 # ffffffe000205550 <__func__.0+0x10>
ffffffe000202b9c:	fe043703          	ld	a4,-32(s0)
ffffffe000202ba0:	00003697          	auipc	a3,0x3
ffffffe000202ba4:	d3868693          	addi	a3,a3,-712 # ffffffe0002058d8 <__func__.2>
ffffffe000202ba8:	03300613          	li	a2,51
ffffffe000202bac:	00003597          	auipc	a1,0x3
ffffffe000202bb0:	9ac58593          	addi	a1,a1,-1620 # ffffffe000205558 <__func__.0+0x18>
ffffffe000202bb4:	00003517          	auipc	a0,0x3
ffffffe000202bb8:	9ac50513          	addi	a0,a0,-1620 # ffffffe000205560 <__func__.0+0x20>
ffffffe000202bbc:	631010ef          	jal	ffffffe0002049ec <printk>
ffffffe000202bc0:	fe043703          	ld	a4,-32(s0)
ffffffe000202bc4:	0dc00793          	li	a5,220
ffffffe000202bc8:	08f70463          	beq	a4,a5,ffffffe000202c50 <trap_handler+0x178>
ffffffe000202bcc:	fe043703          	ld	a4,-32(s0)
ffffffe000202bd0:	0dc00793          	li	a5,220
ffffffe000202bd4:	08e7ec63          	bltu	a5,a4,ffffffe000202c6c <trap_handler+0x194>
ffffffe000202bd8:	fe043703          	ld	a4,-32(s0)
ffffffe000202bdc:	04000793          	li	a5,64
ffffffe000202be0:	00f70a63          	beq	a4,a5,ffffffe000202bf4 <trap_handler+0x11c>
ffffffe000202be4:	fe043703          	ld	a4,-32(s0)
ffffffe000202be8:	0ac00793          	li	a5,172
ffffffe000202bec:	04f70663          	beq	a4,a5,ffffffe000202c38 <trap_handler+0x160>
                    break; 
ffffffe000202bf0:	07c0006f          	j	ffffffe000202c6c <trap_handler+0x194>
                        regs->a0 = write(regs->a0,(const char*)regs->a1,regs->a2);
ffffffe000202bf4:	fb843783          	ld	a5,-72(s0)
ffffffe000202bf8:	0507b783          	ld	a5,80(a5)
ffffffe000202bfc:	0007871b          	sext.w	a4,a5
ffffffe000202c00:	fb843783          	ld	a5,-72(s0)
ffffffe000202c04:	0587b783          	ld	a5,88(a5)
ffffffe000202c08:	00078693          	mv	a3,a5
ffffffe000202c0c:	fb843783          	ld	a5,-72(s0)
ffffffe000202c10:	0607b783          	ld	a5,96(a5)
ffffffe000202c14:	00078613          	mv	a2,a5
ffffffe000202c18:	00068593          	mv	a1,a3
ffffffe000202c1c:	00070513          	mv	a0,a4
ffffffe000202c20:	c14ff0ef          	jal	ffffffe000202034 <write>
ffffffe000202c24:	00050793          	mv	a5,a0
ffffffe000202c28:	00078713          	mv	a4,a5
ffffffe000202c2c:	fb843783          	ld	a5,-72(s0)
ffffffe000202c30:	04e7b823          	sd	a4,80(a5)
                    break;
ffffffe000202c34:	03c0006f          	j	ffffffe000202c70 <trap_handler+0x198>
                        regs->a0 = get_pid();
ffffffe000202c38:	cb4ff0ef          	jal	ffffffe0002020ec <get_pid>
ffffffe000202c3c:	00050793          	mv	a5,a0
ffffffe000202c40:	00078713          	mv	a4,a5
ffffffe000202c44:	fb843783          	ld	a5,-72(s0)
ffffffe000202c48:	04e7b823          	sd	a4,80(a5)
                    break;
ffffffe000202c4c:	0240006f          	j	ffffffe000202c70 <trap_handler+0x198>
                        regs->a0 = do_cow_fork(regs);
ffffffe000202c50:	fb843503          	ld	a0,-72(s0)
ffffffe000202c54:	9f5ff0ef          	jal	ffffffe000202648 <do_cow_fork>
ffffffe000202c58:	00050793          	mv	a5,a0
ffffffe000202c5c:	00078713          	mv	a4,a5
ffffffe000202c60:	fb843783          	ld	a5,-72(s0)
ffffffe000202c64:	04e7b823          	sd	a4,80(a5)
                    break;
ffffffe000202c68:	0080006f          	j	ffffffe000202c70 <trap_handler+0x198>
                    break; 
ffffffe000202c6c:	00000013          	nop
            regs->sepc+=4;
ffffffe000202c70:	fb843783          	ld	a5,-72(s0)
ffffffe000202c74:	1007b783          	ld	a5,256(a5)
ffffffe000202c78:	00478713          	addi	a4,a5,4
ffffffe000202c7c:	fb843783          	ld	a5,-72(s0)
ffffffe000202c80:	10e7b023          	sd	a4,256(a5)
            break;
ffffffe000202c84:	0580006f          	j	ffffffe000202cdc <trap_handler+0x204>
            Log(RED "[S] Unhandled Exception: scause = %lx, sepc = %lx , stval = %lx",regs->scause,regs->sepc,regs->stval,CLEAR);
ffffffe000202c88:	fb843783          	ld	a5,-72(s0)
ffffffe000202c8c:	1187b703          	ld	a4,280(a5)
ffffffe000202c90:	fb843783          	ld	a5,-72(s0)
ffffffe000202c94:	1007b683          	ld	a3,256(a5)
ffffffe000202c98:	fb843783          	ld	a5,-72(s0)
ffffffe000202c9c:	1087b783          	ld	a5,264(a5)
ffffffe000202ca0:	00003897          	auipc	a7,0x3
ffffffe000202ca4:	8b088893          	addi	a7,a7,-1872 # ffffffe000205550 <__func__.0+0x10>
ffffffe000202ca8:	00078813          	mv	a6,a5
ffffffe000202cac:	00068793          	mv	a5,a3
ffffffe000202cb0:	00003697          	auipc	a3,0x3
ffffffe000202cb4:	c2868693          	addi	a3,a3,-984 # ffffffe0002058d8 <__func__.2>
ffffffe000202cb8:	04b00613          	li	a2,75
ffffffe000202cbc:	00003597          	auipc	a1,0x3
ffffffe000202cc0:	89c58593          	addi	a1,a1,-1892 # ffffffe000205558 <__func__.0+0x18>
ffffffe000202cc4:	00003517          	auipc	a0,0x3
ffffffe000202cc8:	8d450513          	addi	a0,a0,-1836 # ffffffe000205598 <__func__.0+0x58>
ffffffe000202ccc:	521010ef          	jal	ffffffe0002049ec <printk>
            do_page_fault(regs);
ffffffe000202cd0:	fb843503          	ld	a0,-72(s0)
ffffffe000202cd4:	01c000ef          	jal	ffffffe000202cf0 <do_page_fault>
            break;
ffffffe000202cd8:	00000013          	nop
}
ffffffe000202cdc:	00000013          	nop
ffffffe000202ce0:	04813083          	ld	ra,72(sp)
ffffffe000202ce4:	04013403          	ld	s0,64(sp)
ffffffe000202ce8:	05010113          	addi	sp,sp,80
ffffffe000202cec:	00008067          	ret

ffffffe000202cf0 <do_page_fault>:
 *  13 Load Page Fault;
 *  15 Store/AMO Page Fault
 * 
 * 
*/
void do_page_fault(struct pt_regs *regs){
ffffffe000202cf0:	f0010113          	addi	sp,sp,-256
ffffffe000202cf4:	0e113c23          	sd	ra,248(sp)
ffffffe000202cf8:	0e813823          	sd	s0,240(sp)
ffffffe000202cfc:	0e913423          	sd	s1,232(sp)
ffffffe000202d00:	10010413          	addi	s0,sp,256
ffffffe000202d04:	f0a43423          	sd	a0,-248(s0)
    Log(BLUE "WE HAVE ENTERED INTO THE DEAL_PG_FAULT DEAL WITH PART" CLEAR);
ffffffe000202d08:	00003697          	auipc	a3,0x3
ffffffe000202d0c:	be068693          	addi	a3,a3,-1056 # ffffffe0002058e8 <__func__.1>
ffffffe000202d10:	05c00613          	li	a2,92
ffffffe000202d14:	00003597          	auipc	a1,0x3
ffffffe000202d18:	84458593          	addi	a1,a1,-1980 # ffffffe000205558 <__func__.0+0x18>
ffffffe000202d1c:	00003517          	auipc	a0,0x3
ffffffe000202d20:	8dc50513          	addi	a0,a0,-1828 # ffffffe0002055f8 <__func__.0+0xb8>
ffffffe000202d24:	4c9010ef          	jal	ffffffe0002049ec <printk>
    uint64_t fault_address = regs->stval;
ffffffe000202d28:	f0843783          	ld	a5,-248(s0)
ffffffe000202d2c:	1087b783          	ld	a5,264(a5)
ffffffe000202d30:	faf43c23          	sd	a5,-72(s0)
    Log(YELLOW "fault_address: %016lx",regs->stval,CLEAR);
ffffffe000202d34:	f0843783          	ld	a5,-248(s0)
ffffffe000202d38:	1087b703          	ld	a4,264(a5)
ffffffe000202d3c:	00003797          	auipc	a5,0x3
ffffffe000202d40:	81478793          	addi	a5,a5,-2028 # ffffffe000205550 <__func__.0+0x10>
ffffffe000202d44:	00003697          	auipc	a3,0x3
ffffffe000202d48:	ba468693          	addi	a3,a3,-1116 # ffffffe0002058e8 <__func__.1>
ffffffe000202d4c:	05e00613          	li	a2,94
ffffffe000202d50:	00003597          	auipc	a1,0x3
ffffffe000202d54:	80858593          	addi	a1,a1,-2040 # ffffffe000205558 <__func__.0+0x18>
ffffffe000202d58:	00003517          	auipc	a0,0x3
ffffffe000202d5c:	8f850513          	addi	a0,a0,-1800 # ffffffe000205650 <__func__.0+0x110>
ffffffe000202d60:	48d010ef          	jal	ffffffe0002049ec <printk>
    struct vm_area_struct* ptr = find_vma(&current->mm,fault_address);
ffffffe000202d64:	00008797          	auipc	a5,0x8
ffffffe000202d68:	2ac78793          	addi	a5,a5,684 # ffffffe00020b010 <current>
ffffffe000202d6c:	0007b783          	ld	a5,0(a5)
ffffffe000202d70:	0b078793          	addi	a5,a5,176
ffffffe000202d74:	fb843583          	ld	a1,-72(s0)
ffffffe000202d78:	00078513          	mv	a0,a5
ffffffe000202d7c:	ed9fe0ef          	jal	ffffffe000201c54 <find_vma>
ffffffe000202d80:	faa43823          	sd	a0,-80(s0)
    if(ptr == NULL){
ffffffe000202d84:	fb043783          	ld	a5,-80(s0)
ffffffe000202d88:	02079663          	bnez	a5,ffffffe000202db4 <do_page_fault+0xc4>
        Log(RED "ERROR! YOU HAVE FOUND THE ERROR EREA!" CLEAR);
ffffffe000202d8c:	00003697          	auipc	a3,0x3
ffffffe000202d90:	b5c68693          	addi	a3,a3,-1188 # ffffffe0002058e8 <__func__.1>
ffffffe000202d94:	06100613          	li	a2,97
ffffffe000202d98:	00002597          	auipc	a1,0x2
ffffffe000202d9c:	7c058593          	addi	a1,a1,1984 # ffffffe000205558 <__func__.0+0x18>
ffffffe000202da0:	00003517          	auipc	a0,0x3
ffffffe000202da4:	8e850513          	addi	a0,a0,-1816 # ffffffe000205688 <__func__.0+0x148>
ffffffe000202da8:	445010ef          	jal	ffffffe0002049ec <printk>
        untrapped_handler(regs);
ffffffe000202dac:	f0843503          	ld	a0,-248(s0)
ffffffe000202db0:	62c000ef          	jal	ffffffe0002033dc <untrapped_handler>
    }
    Log(PURPLE "We have found the VMA : [%016lx, %016lx]",PGROUNDDOWN(ptr->vm_start),PGROUNDDOWN(ptr->vm_end),CLEAR);
ffffffe000202db4:	fb043783          	ld	a5,-80(s0)
ffffffe000202db8:	0087b703          	ld	a4,8(a5)
ffffffe000202dbc:	fffff7b7          	lui	a5,0xfffff
ffffffe000202dc0:	00f776b3          	and	a3,a4,a5
ffffffe000202dc4:	fb043783          	ld	a5,-80(s0)
ffffffe000202dc8:	0107b703          	ld	a4,16(a5) # fffffffffffff010 <VM_END+0xfffff010>
ffffffe000202dcc:	fffff7b7          	lui	a5,0xfffff
ffffffe000202dd0:	00f777b3          	and	a5,a4,a5
ffffffe000202dd4:	00002817          	auipc	a6,0x2
ffffffe000202dd8:	77c80813          	addi	a6,a6,1916 # ffffffe000205550 <__func__.0+0x10>
ffffffe000202ddc:	00068713          	mv	a4,a3
ffffffe000202de0:	00003697          	auipc	a3,0x3
ffffffe000202de4:	b0868693          	addi	a3,a3,-1272 # ffffffe0002058e8 <__func__.1>
ffffffe000202de8:	06400613          	li	a2,100
ffffffe000202dec:	00002597          	auipc	a1,0x2
ffffffe000202df0:	76c58593          	addi	a1,a1,1900 # ffffffe000205558 <__func__.0+0x18>
ffffffe000202df4:	00003517          	auipc	a0,0x3
ffffffe000202df8:	8dc50513          	addi	a0,a0,-1828 # ffffffe0002056d0 <__func__.0+0x190>
ffffffe000202dfc:	3f1010ef          	jal	ffffffe0002049ec <printk>
     * In the PTE -> the flags: 
     * U X W R V
     * 
    */
    
    uint64_t FLAG = ptr->vm_flags;
ffffffe000202e00:	fb043783          	ld	a5,-80(s0)
ffffffe000202e04:	0287b783          	ld	a5,40(a5) # fffffffffffff028 <VM_END+0xfffff028>
ffffffe000202e08:	faf43423          	sd	a5,-88(s0)
    if(((regs->scause==0xc)&&!(FLAG&VM_EXEC))||((regs->scause==0xd)&&!(FLAG&VM_READ))||((regs->scause==0xf)&&!(FLAG&VM_WRITE))){
ffffffe000202e0c:	f0843783          	ld	a5,-248(s0)
ffffffe000202e10:	1187b703          	ld	a4,280(a5)
ffffffe000202e14:	00c00793          	li	a5,12
ffffffe000202e18:	00f71863          	bne	a4,a5,ffffffe000202e28 <do_page_fault+0x138>
ffffffe000202e1c:	fa843783          	ld	a5,-88(s0)
ffffffe000202e20:	0087f793          	andi	a5,a5,8
ffffffe000202e24:	02078e63          	beqz	a5,ffffffe000202e60 <do_page_fault+0x170>
ffffffe000202e28:	f0843783          	ld	a5,-248(s0)
ffffffe000202e2c:	1187b703          	ld	a4,280(a5)
ffffffe000202e30:	00d00793          	li	a5,13
ffffffe000202e34:	00f71863          	bne	a4,a5,ffffffe000202e44 <do_page_fault+0x154>
ffffffe000202e38:	fa843783          	ld	a5,-88(s0)
ffffffe000202e3c:	0027f793          	andi	a5,a5,2
ffffffe000202e40:	02078063          	beqz	a5,ffffffe000202e60 <do_page_fault+0x170>
ffffffe000202e44:	f0843783          	ld	a5,-248(s0)
ffffffe000202e48:	1187b703          	ld	a4,280(a5)
ffffffe000202e4c:	00f00793          	li	a5,15
ffffffe000202e50:	00f71c63          	bne	a4,a5,ffffffe000202e68 <do_page_fault+0x178>
ffffffe000202e54:	fa843783          	ld	a5,-88(s0)
ffffffe000202e58:	0047f793          	andi	a5,a5,4
ffffffe000202e5c:	00079663          	bnez	a5,ffffffe000202e68 <do_page_fault+0x178>
        untrapped_handler(regs);
ffffffe000202e60:	f0843503          	ld	a0,-248(s0)
ffffffe000202e64:	578000ef          	jal	ffffffe0002033dc <untrapped_handler>
    }

    uint64_t flag = FLAG&0x1;
ffffffe000202e68:	fa843783          	ld	a5,-88(s0)
ffffffe000202e6c:	0017f793          	andi	a5,a5,1
ffffffe000202e70:	faf43023          	sd	a5,-96(s0)
    
    // The ANON area;
    // Allocate a PAGE
    char* VA = (char*)alloc_page();
ffffffe000202e74:	bc1fd0ef          	jal	ffffffe000200a34 <alloc_page>
ffffffe000202e78:	f8a43c23          	sd	a0,-104(s0)
    memset(VA,0,sizeof(uint64_t));
ffffffe000202e7c:	00800613          	li	a2,8
ffffffe000202e80:	00000593          	li	a1,0
ffffffe000202e84:	f9843503          	ld	a0,-104(s0)
ffffffe000202e88:	485010ef          	jal	ffffffe000204b0c <memset>
    // 在 elf 需要映射到的内存上的 VA 地址上的报错位置;
    uint64_t VMA_VA = regs->stval;
ffffffe000202e8c:	f0843783          	ld	a5,-248(s0)
ffffffe000202e90:	1087b783          	ld	a5,264(a5)
ffffffe000202e94:	f8f43823          	sd	a5,-112(s0)
    uint64_t flag_cow = checkValid(VMA_VA,current->pgd);
ffffffe000202e98:	00008797          	auipc	a5,0x8
ffffffe000202e9c:	17878793          	addi	a5,a5,376 # ffffffe00020b010 <current>
ffffffe000202ea0:	0007b783          	ld	a5,0(a5)
ffffffe000202ea4:	0a87b783          	ld	a5,168(a5)
ffffffe000202ea8:	00078593          	mv	a1,a5
ffffffe000202eac:	f9043503          	ld	a0,-112(s0)
ffffffe000202eb0:	a68ff0ef          	jal	ffffffe000202118 <checkValid>
ffffffe000202eb4:	f8a43423          	sd	a0,-120(s0)

    if(flag_cow==0){
ffffffe000202eb8:	f8843783          	ld	a5,-120(s0)
ffffffe000202ebc:	1c079863          	bnez	a5,ffffffe00020308c <do_page_fault+0x39c>
        // get the page offset;
        uint64_t perm = 0x11;
ffffffe000202ec0:	01100793          	li	a5,17
ffffffe000202ec4:	f4f43823          	sd	a5,-176(s0)
        // Now we set for the perm;
        perm |= FLAG&0xe;
ffffffe000202ec8:	fa843783          	ld	a5,-88(s0)
ffffffe000202ecc:	00e7f793          	andi	a5,a5,14
ffffffe000202ed0:	f5043703          	ld	a4,-176(s0)
ffffffe000202ed4:	00f767b3          	or	a5,a4,a5
ffffffe000202ed8:	f4f43823          	sd	a5,-176(s0)
        create_mapping(current->pgd,VMA_VA,(uint64_t)VA-PA2VA_OFFSET,PGSIZE,perm);
ffffffe000202edc:	00008797          	auipc	a5,0x8
ffffffe000202ee0:	13478793          	addi	a5,a5,308 # ffffffe00020b010 <current>
ffffffe000202ee4:	0007b783          	ld	a5,0(a5)
ffffffe000202ee8:	0a87b503          	ld	a0,168(a5)
ffffffe000202eec:	f9843703          	ld	a4,-104(s0)
ffffffe000202ef0:	04100793          	li	a5,65
ffffffe000202ef4:	01f79793          	slli	a5,a5,0x1f
ffffffe000202ef8:	00f707b3          	add	a5,a4,a5
ffffffe000202efc:	f5043703          	ld	a4,-176(s0)
ffffffe000202f00:	000016b7          	lui	a3,0x1
ffffffe000202f04:	00078613          	mv	a2,a5
ffffffe000202f08:	f9043583          	ld	a1,-112(s0)
ffffffe000202f0c:	059000ef          	jal	ffffffe000203764 <create_mapping>
        
        
        // NOT ANON area;
        if(flag!=1){
ffffffe000202f10:	fa043703          	ld	a4,-96(s0)
ffffffe000202f14:	00100793          	li	a5,1
ffffffe000202f18:	4af70863          	beq	a4,a5,ffffffe0002033c8 <do_page_fault+0x6d8>
            uint64_t elf_offset = ptr->vm_pgoff;
ffffffe000202f1c:	fb043783          	ld	a5,-80(s0)
ffffffe000202f20:	0307b783          	ld	a5,48(a5)
ffffffe000202f24:	f4f43423          	sd	a5,-184(s0)
            // 表示的是在 elf 文件中的开始位置
            uint64_t VM_VA = ptr->vm_start;
ffffffe000202f28:	fb043783          	ld	a5,-80(s0)
ffffffe000202f2c:	0087b783          	ld	a5,8(a5)
ffffffe000202f30:	f4f43023          	sd	a5,-192(s0)
            uint64_t start_elf_va = (uint64_t)(_sramdisk+ptr->vm_pgoff);
ffffffe000202f34:	fb043783          	ld	a5,-80(s0)
ffffffe000202f38:	0307b703          	ld	a4,48(a5)
ffffffe000202f3c:	00005797          	auipc	a5,0x5
ffffffe000202f40:	0c478793          	addi	a5,a5,196 # ffffffe000208000 <_sramdisk>
ffffffe000202f44:	00f707b3          	add	a5,a4,a5
ffffffe000202f48:	f2f43c23          	sd	a5,-200(s0)
            uint64_t offset = 0; 
ffffffe000202f4c:	fc043c23          	sd	zero,-40(s0)
            uint64_t end_elf_va = (uint64_t)(_sramdisk+ptr->vm_pgoff+ptr->vm_filesz);
ffffffe000202f50:	fb043783          	ld	a5,-80(s0)
ffffffe000202f54:	0307b703          	ld	a4,48(a5)
ffffffe000202f58:	fb043783          	ld	a5,-80(s0)
ffffffe000202f5c:	0387b783          	ld	a5,56(a5)
ffffffe000202f60:	00f70733          	add	a4,a4,a5
ffffffe000202f64:	00005797          	auipc	a5,0x5
ffffffe000202f68:	09c78793          	addi	a5,a5,156 # ffffffe000208000 <_sramdisk>
ffffffe000202f6c:	00f707b3          	add	a5,a4,a5
ffffffe000202f70:	f2f43823          	sd	a5,-208(s0)
            uint64_t start_copy = VMA_VA;
ffffffe000202f74:	f9043783          	ld	a5,-112(s0)
ffffffe000202f78:	fcf43823          	sd	a5,-48(s0)
            // now we consider the case for that 
            /**
             * 1. start_elf_va and VMA_VA is in the same page;
             * we need to copy the first part of the elf segment;
            */  
            if(PGROUNDUP(start_elf_va)==PGROUNDUP(VMA_VA - VM_VA + start_elf_va)){
ffffffe000202f7c:	f3843703          	ld	a4,-200(s0)
ffffffe000202f80:	000017b7          	lui	a5,0x1
ffffffe000202f84:	fff78793          	addi	a5,a5,-1 # fff <PGSIZE-0x1>
ffffffe000202f88:	00f70733          	add	a4,a4,a5
ffffffe000202f8c:	f9043683          	ld	a3,-112(s0)
ffffffe000202f90:	f4043783          	ld	a5,-192(s0)
ffffffe000202f94:	40f686b3          	sub	a3,a3,a5
ffffffe000202f98:	f3843783          	ld	a5,-200(s0)
ffffffe000202f9c:	00f686b3          	add	a3,a3,a5
ffffffe000202fa0:	000017b7          	lui	a5,0x1
ffffffe000202fa4:	fff78793          	addi	a5,a5,-1 # fff <PGSIZE-0x1>
ffffffe000202fa8:	00f687b3          	add	a5,a3,a5
ffffffe000202fac:	00f74733          	xor	a4,a4,a5
ffffffe000202fb0:	000017b7          	lui	a5,0x1
ffffffe000202fb4:	02f77263          	bgeu	a4,a5,ffffffe000202fd8 <do_page_fault+0x2e8>
                // update the start_copy address from VMA_VA to start_elf_va;
                start_copy = start_elf_va;
ffffffe000202fb8:	f3843783          	ld	a5,-200(s0)
ffffffe000202fbc:	fcf43823          	sd	a5,-48(s0)
                offset = VM_VA&0xFFF;
ffffffe000202fc0:	f4043703          	ld	a4,-192(s0)
ffffffe000202fc4:	000017b7          	lui	a5,0x1
ffffffe000202fc8:	fff78793          	addi	a5,a5,-1 # fff <PGSIZE-0x1>
ffffffe000202fcc:	00f777b3          	and	a5,a4,a5
ffffffe000202fd0:	fcf43c23          	sd	a5,-40(s0)
ffffffe000202fd4:	0240006f          	j	ffffffe000202ff8 <do_page_fault+0x308>
            }else{
                // from the sepecific paged start copy;
                // vm->start 表示的是 elf 文件中的segment 开始的部分需要在内存中映射的VA地址;
                // 我们接下来要求的是在 elf文件中的 segment 需要开始复制的开始地址;
                start_copy = start_elf_va + PGROUNDDOWN(VMA_VA) - VM_VA; 
ffffffe000202fd8:	f9043703          	ld	a4,-112(s0)
ffffffe000202fdc:	fffff7b7          	lui	a5,0xfffff
ffffffe000202fe0:	00f77733          	and	a4,a4,a5
ffffffe000202fe4:	f3843783          	ld	a5,-200(s0)
ffffffe000202fe8:	00f70733          	add	a4,a4,a5
ffffffe000202fec:	f4043783          	ld	a5,-192(s0)
ffffffe000202ff0:	40f707b3          	sub	a5,a4,a5
ffffffe000202ff4:	fcf43823          	sd	a5,-48(s0)
             * The following we consider for the end of the elf_file;
             * 1. start_copy+PGSIZE < end_elf_va; 整段复制
             * 2. start_copy < end_elf_va < start_copy+PGSIZE; 复制前面一部分
             * 3. start_copy > end_elf_va; 不需要处理 
            */
            if(end_elf_va>=start_copy&&end_elf_va<=start_copy+PGSIZE){
ffffffe000202ff8:	f3043703          	ld	a4,-208(s0)
ffffffe000202ffc:	fd043783          	ld	a5,-48(s0)
ffffffe000203000:	04f76663          	bltu	a4,a5,ffffffe00020304c <do_page_fault+0x35c>
ffffffe000203004:	fd043703          	ld	a4,-48(s0)
ffffffe000203008:	000017b7          	lui	a5,0x1
ffffffe00020300c:	00f707b3          	add	a5,a4,a5
ffffffe000203010:	f3043703          	ld	a4,-208(s0)
ffffffe000203014:	02e7ec63          	bltu	a5,a4,ffffffe00020304c <do_page_fault+0x35c>
                memcpy((void*)(VA+offset),(void*)(start_copy),end_elf_va-start_copy-offset);
ffffffe000203018:	f9843703          	ld	a4,-104(s0)
ffffffe00020301c:	fd843783          	ld	a5,-40(s0)
ffffffe000203020:	00f706b3          	add	a3,a4,a5
ffffffe000203024:	fd043583          	ld	a1,-48(s0)
ffffffe000203028:	f3043703          	ld	a4,-208(s0)
ffffffe00020302c:	fd043783          	ld	a5,-48(s0)
ffffffe000203030:	40f70733          	sub	a4,a4,a5
ffffffe000203034:	fd843783          	ld	a5,-40(s0)
ffffffe000203038:	40f707b3          	sub	a5,a4,a5
ffffffe00020303c:	00078613          	mv	a2,a5
ffffffe000203040:	00068513          	mv	a0,a3
ffffffe000203044:	339010ef          	jal	ffffffe000204b7c <memcpy>
ffffffe000203048:	3800006f          	j	ffffffe0002033c8 <do_page_fault+0x6d8>
            }else if(end_elf_va>start_copy+PGSIZE){
ffffffe00020304c:	fd043703          	ld	a4,-48(s0)
ffffffe000203050:	000017b7          	lui	a5,0x1
ffffffe000203054:	00f707b3          	add	a5,a4,a5
ffffffe000203058:	f3043703          	ld	a4,-208(s0)
ffffffe00020305c:	36e7f663          	bgeu	a5,a4,ffffffe0002033c8 <do_page_fault+0x6d8>
                memcpy((void*)(VA+offset),(void*)(start_copy),PGSIZE-offset);
ffffffe000203060:	f9843703          	ld	a4,-104(s0)
ffffffe000203064:	fd843783          	ld	a5,-40(s0)
ffffffe000203068:	00f706b3          	add	a3,a4,a5
ffffffe00020306c:	fd043583          	ld	a1,-48(s0)
ffffffe000203070:	00001737          	lui	a4,0x1
ffffffe000203074:	fd843783          	ld	a5,-40(s0)
ffffffe000203078:	40f707b3          	sub	a5,a4,a5
ffffffe00020307c:	00078613          	mv	a2,a5
ffffffe000203080:	00068513          	mv	a0,a3
ffffffe000203084:	2f9010ef          	jal	ffffffe000204b7c <memcpy>
ffffffe000203088:	3400006f          	j	ffffffe0002033c8 <do_page_fault+0x6d8>
            }
        }   
    }else{
        uint64_t f = 0;
ffffffe00020308c:	f8043023          	sd	zero,-128(s0)
        /**
         * here we add the logical for dealing with the cow-fork;
         * 
        */
        printk("we start to cow _ in the page fault deal with\n");
ffffffe000203090:	00002517          	auipc	a0,0x2
ffffffe000203094:	68850513          	addi	a0,a0,1672 # ffffffe000205718 <__func__.0+0x1d8>
ffffffe000203098:	155010ef          	jal	ffffffe0002049ec <printk>
        uint64_t p = 0x0;
ffffffe00020309c:	f6043c23          	sd	zero,-136(s0)
        uint64_t VPN[3];
        VPN[2] = (VMA_VA>>30)&0x1ff;
ffffffe0002030a0:	f9043783          	ld	a5,-112(s0)
ffffffe0002030a4:	01e7d793          	srli	a5,a5,0x1e
ffffffe0002030a8:	1ff7f793          	andi	a5,a5,511
ffffffe0002030ac:	f2f43423          	sd	a5,-216(s0)
        VPN[1] = (VMA_VA>>21)&0x1ff;
ffffffe0002030b0:	f9043783          	ld	a5,-112(s0)
ffffffe0002030b4:	0157d793          	srli	a5,a5,0x15
ffffffe0002030b8:	1ff7f793          	andi	a5,a5,511
ffffffe0002030bc:	f2f43023          	sd	a5,-224(s0)
        VPN[0] = (VMA_VA>>12)&0x1ff;
ffffffe0002030c0:	f9043783          	ld	a5,-112(s0)
ffffffe0002030c4:	00c7d793          	srli	a5,a5,0xc
ffffffe0002030c8:	1ff7f793          	andi	a5,a5,511
ffffffe0002030cc:	f0f43c23          	sd	a5,-232(s0)
        uint64_t* ptrp = current->pgd;
ffffffe0002030d0:	00008797          	auipc	a5,0x8
ffffffe0002030d4:	f4078793          	addi	a5,a5,-192 # ffffffe00020b010 <current>
ffffffe0002030d8:	0007b783          	ld	a5,0(a5)
ffffffe0002030dc:	0a87b783          	ld	a5,168(a5)
ffffffe0002030e0:	fcf43423          	sd	a5,-56(s0)
        for(int j=2;j>0;j--){
ffffffe0002030e4:	00200793          	li	a5,2
ffffffe0002030e8:	fcf42223          	sw	a5,-60(s0)
ffffffe0002030ec:	04c0006f          	j	ffffffe000203138 <do_page_fault+0x448>
            ptrp = (uint64_t*) (((ptrp[VPN[j]]>>10)<<12) + PA2VA_OFFSET);
ffffffe0002030f0:	fc442783          	lw	a5,-60(s0)
ffffffe0002030f4:	00379793          	slli	a5,a5,0x3
ffffffe0002030f8:	fe078793          	addi	a5,a5,-32
ffffffe0002030fc:	008787b3          	add	a5,a5,s0
ffffffe000203100:	f387b783          	ld	a5,-200(a5)
ffffffe000203104:	00379793          	slli	a5,a5,0x3
ffffffe000203108:	fc843703          	ld	a4,-56(s0)
ffffffe00020310c:	00f707b3          	add	a5,a4,a5
ffffffe000203110:	0007b783          	ld	a5,0(a5)
ffffffe000203114:	00a7d793          	srli	a5,a5,0xa
ffffffe000203118:	00c79713          	slli	a4,a5,0xc
ffffffe00020311c:	fbf00793          	li	a5,-65
ffffffe000203120:	01f79793          	slli	a5,a5,0x1f
ffffffe000203124:	00f707b3          	add	a5,a4,a5
ffffffe000203128:	fcf43423          	sd	a5,-56(s0)
        for(int j=2;j>0;j--){
ffffffe00020312c:	fc442783          	lw	a5,-60(s0)
ffffffe000203130:	fff7879b          	addiw	a5,a5,-1
ffffffe000203134:	fcf42223          	sw	a5,-60(s0)
ffffffe000203138:	fc442783          	lw	a5,-60(s0)
ffffffe00020313c:	0007879b          	sext.w	a5,a5
ffffffe000203140:	faf048e3          	bgtz	a5,ffffffe0002030f0 <do_page_fault+0x400>
        }
        printk("ptrp = %016lx\n",ptrp[VPN[0]]);
ffffffe000203144:	f1843783          	ld	a5,-232(s0)
ffffffe000203148:	00379793          	slli	a5,a5,0x3
ffffffe00020314c:	fc843703          	ld	a4,-56(s0)
ffffffe000203150:	00f707b3          	add	a5,a4,a5
ffffffe000203154:	0007b783          	ld	a5,0(a5)
ffffffe000203158:	00078593          	mv	a1,a5
ffffffe00020315c:	00002517          	auipc	a0,0x2
ffffffe000203160:	5ec50513          	addi	a0,a0,1516 # ffffffe000205748 <__func__.0+0x208>
ffffffe000203164:	089010ef          	jal	ffffffe0002049ec <printk>
        uint64_t number = get_page_refcnt(((ptrp[VPN[0]]>>10)<<12)+PA2VA_OFFSET);
ffffffe000203168:	f1843783          	ld	a5,-232(s0)
ffffffe00020316c:	00379793          	slli	a5,a5,0x3
ffffffe000203170:	fc843703          	ld	a4,-56(s0)
ffffffe000203174:	00f707b3          	add	a5,a4,a5
ffffffe000203178:	0007b783          	ld	a5,0(a5)
ffffffe00020317c:	00a7d793          	srli	a5,a5,0xa
ffffffe000203180:	00c79713          	slli	a4,a5,0xc
ffffffe000203184:	fbf00793          	li	a5,-65
ffffffe000203188:	01f79793          	slli	a5,a5,0x1f
ffffffe00020318c:	00f707b3          	add	a5,a4,a5
ffffffe000203190:	00078513          	mv	a0,a5
ffffffe000203194:	aedfd0ef          	jal	ffffffe000200c80 <get_page_refcnt>
ffffffe000203198:	f6a43823          	sd	a0,-144(s0)
        uint64_t f_write = ptrp[VPN[0]]&0x4;
ffffffe00020319c:	f1843783          	ld	a5,-232(s0)
ffffffe0002031a0:	00379793          	slli	a5,a5,0x3
ffffffe0002031a4:	fc843703          	ld	a4,-56(s0)
ffffffe0002031a8:	00f707b3          	add	a5,a4,a5
ffffffe0002031ac:	0007b783          	ld	a5,0(a5)
ffffffe0002031b0:	0047f793          	andi	a5,a5,4
ffffffe0002031b4:	f6f43423          	sd	a5,-152(s0)
            f = (regs->scause==15)&&((FLAG&VM_WRITE)==4)&&(f_write==0);
ffffffe0002031b8:	f0843783          	ld	a5,-248(s0)
ffffffe0002031bc:	1187b703          	ld	a4,280(a5)
ffffffe0002031c0:	00f00793          	li	a5,15
ffffffe0002031c4:	02f71063          	bne	a4,a5,ffffffe0002031e4 <do_page_fault+0x4f4>
ffffffe0002031c8:	fa843783          	ld	a5,-88(s0)
ffffffe0002031cc:	0047f793          	andi	a5,a5,4
ffffffe0002031d0:	00078a63          	beqz	a5,ffffffe0002031e4 <do_page_fault+0x4f4>
ffffffe0002031d4:	f6843783          	ld	a5,-152(s0)
ffffffe0002031d8:	00079663          	bnez	a5,ffffffe0002031e4 <do_page_fault+0x4f4>
ffffffe0002031dc:	00100793          	li	a5,1
ffffffe0002031e0:	0080006f          	j	ffffffe0002031e8 <do_page_fault+0x4f8>
ffffffe0002031e4:	00000793          	li	a5,0
ffffffe0002031e8:	f8f43023          	sd	a5,-128(s0)
        printk("f: %d\n",f);
ffffffe0002031ec:	f8043583          	ld	a1,-128(s0)
ffffffe0002031f0:	00002517          	auipc	a0,0x2
ffffffe0002031f4:	56850513          	addi	a0,a0,1384 # ffffffe000205758 <__func__.0+0x218>
ffffffe0002031f8:	7f4010ef          	jal	ffffffe0002049ec <printk>
        if(f==1){
ffffffe0002031fc:	f8043703          	ld	a4,-128(s0)
ffffffe000203200:	00100793          	li	a5,1
ffffffe000203204:	1af71e63          	bne	a4,a5,ffffffe0002033c0 <do_page_fault+0x6d0>
             * 1. we will copy for this cow 
             * 2. we will recreate the mapping 
             * 3. distinguish with the number;
             * */ 

            if(number==1){
ffffffe000203208:	f7043703          	ld	a4,-144(s0)
ffffffe00020320c:	00100793          	li	a5,1
ffffffe000203210:	04f71063          	bne	a4,a5,ffffffe000203250 <do_page_fault+0x560>
                ptrp[VPN[0]] |= 0x4;
ffffffe000203214:	f1843783          	ld	a5,-232(s0)
ffffffe000203218:	00379793          	slli	a5,a5,0x3
ffffffe00020321c:	fc843703          	ld	a4,-56(s0)
ffffffe000203220:	00f707b3          	add	a5,a4,a5
ffffffe000203224:	0007b703          	ld	a4,0(a5)
ffffffe000203228:	f1843783          	ld	a5,-232(s0)
ffffffe00020322c:	00379793          	slli	a5,a5,0x3
ffffffe000203230:	fc843683          	ld	a3,-56(s0)
ffffffe000203234:	00f687b3          	add	a5,a3,a5
ffffffe000203238:	00476713          	ori	a4,a4,4
ffffffe00020323c:	00e7b023          	sd	a4,0(a5)
                // save for one copy time;
                printk("COW number is 1,we directly change the PTE_WRITE to 1\n");
ffffffe000203240:	00002517          	auipc	a0,0x2
ffffffe000203244:	52050513          	addi	a0,a0,1312 # ffffffe000205760 <__func__.0+0x220>
ffffffe000203248:	7a4010ef          	jal	ffffffe0002049ec <printk>
                Log(YELLOW "COW: THE New VA_perm is %016lx",VA_perm,CLEAR);
                asm volatile("sfence.vma zero, zero");
                create_mapping(current->pgd,VMA_VA,(uint64_t)VA_Address-PA2VA_OFFSET,PGSIZE,VA_perm);
                printk("COW number is 2, and we create the mapping\n");
            }
            return ;
ffffffe00020324c:	17c0006f          	j	ffffffe0002033c8 <do_page_fault+0x6d8>
                put_page(((ptrp[VPN[0]]>>10)<<12)+PA2VA_OFFSET);
ffffffe000203250:	f1843783          	ld	a5,-232(s0)
ffffffe000203254:	00379793          	slli	a5,a5,0x3
ffffffe000203258:	fc843703          	ld	a4,-56(s0)
ffffffe00020325c:	00f707b3          	add	a5,a4,a5
ffffffe000203260:	0007b783          	ld	a5,0(a5)
ffffffe000203264:	00a7d793          	srli	a5,a5,0xa
ffffffe000203268:	00c79713          	slli	a4,a5,0xc
ffffffe00020326c:	fbf00793          	li	a5,-65
ffffffe000203270:	01f79793          	slli	a5,a5,0x1f
ffffffe000203274:	00f707b3          	add	a5,a4,a5
ffffffe000203278:	00078513          	mv	a0,a5
ffffffe00020327c:	9adfd0ef          	jal	ffffffe000200c28 <put_page>
                printk("the number of virtual address : %016lx is %d\n",((ptrp[VPN[0]]>>10)<<12)+PA2VA_OFFSET,get_page_refcnt(((ptrp[VPN[0]]>>10)<<12)+PA2VA_OFFSET));
ffffffe000203280:	f1843783          	ld	a5,-232(s0)
ffffffe000203284:	00379793          	slli	a5,a5,0x3
ffffffe000203288:	fc843703          	ld	a4,-56(s0)
ffffffe00020328c:	00f707b3          	add	a5,a4,a5
ffffffe000203290:	0007b783          	ld	a5,0(a5)
ffffffe000203294:	00a7d793          	srli	a5,a5,0xa
ffffffe000203298:	00c79713          	slli	a4,a5,0xc
ffffffe00020329c:	fbf00793          	li	a5,-65
ffffffe0002032a0:	01f79793          	slli	a5,a5,0x1f
ffffffe0002032a4:	00f704b3          	add	s1,a4,a5
ffffffe0002032a8:	f1843783          	ld	a5,-232(s0)
ffffffe0002032ac:	00379793          	slli	a5,a5,0x3
ffffffe0002032b0:	fc843703          	ld	a4,-56(s0)
ffffffe0002032b4:	00f707b3          	add	a5,a4,a5
ffffffe0002032b8:	0007b783          	ld	a5,0(a5)
ffffffe0002032bc:	00a7d793          	srli	a5,a5,0xa
ffffffe0002032c0:	00c79713          	slli	a4,a5,0xc
ffffffe0002032c4:	fbf00793          	li	a5,-65
ffffffe0002032c8:	01f79793          	slli	a5,a5,0x1f
ffffffe0002032cc:	00f707b3          	add	a5,a4,a5
ffffffe0002032d0:	00078513          	mv	a0,a5
ffffffe0002032d4:	9adfd0ef          	jal	ffffffe000200c80 <get_page_refcnt>
ffffffe0002032d8:	00050793          	mv	a5,a0
ffffffe0002032dc:	00078613          	mv	a2,a5
ffffffe0002032e0:	00048593          	mv	a1,s1
ffffffe0002032e4:	00002517          	auipc	a0,0x2
ffffffe0002032e8:	4b450513          	addi	a0,a0,1204 # ffffffe000205798 <__func__.0+0x258>
ffffffe0002032ec:	700010ef          	jal	ffffffe0002049ec <printk>
                char* VA_Address = (char*)alloc_page();
ffffffe0002032f0:	f44fd0ef          	jal	ffffffe000200a34 <alloc_page>
ffffffe0002032f4:	f6a43023          	sd	a0,-160(s0)
                memset(VA_Address,0,PGSIZE);
ffffffe0002032f8:	00001637          	lui	a2,0x1
ffffffe0002032fc:	00000593          	li	a1,0
ffffffe000203300:	f6043503          	ld	a0,-160(s0)
ffffffe000203304:	009010ef          	jal	ffffffe000204b0c <memset>
                memcpy((void*) VA_Address,(void*)PGROUNDDOWN(VMA_VA),PGSIZE);
ffffffe000203308:	f9043703          	ld	a4,-112(s0)
ffffffe00020330c:	fffff7b7          	lui	a5,0xfffff
ffffffe000203310:	00f777b3          	and	a5,a4,a5
ffffffe000203314:	00001637          	lui	a2,0x1
ffffffe000203318:	00078593          	mv	a1,a5
ffffffe00020331c:	f6043503          	ld	a0,-160(s0)
ffffffe000203320:	05d010ef          	jal	ffffffe000204b7c <memcpy>
                uint64_t VA_perm = ptrp[VPN[0]] & 0x1f;
ffffffe000203324:	f1843783          	ld	a5,-232(s0)
ffffffe000203328:	00379793          	slli	a5,a5,0x3
ffffffe00020332c:	fc843703          	ld	a4,-56(s0)
ffffffe000203330:	00f707b3          	add	a5,a4,a5
ffffffe000203334:	0007b783          	ld	a5,0(a5) # fffffffffffff000 <VM_END+0xfffff000>
ffffffe000203338:	01f7f793          	andi	a5,a5,31
ffffffe00020333c:	f4f43c23          	sd	a5,-168(s0)
                VA_perm |= 0x4;
ffffffe000203340:	f5843783          	ld	a5,-168(s0)
ffffffe000203344:	0047e793          	ori	a5,a5,4
ffffffe000203348:	f4f43c23          	sd	a5,-168(s0)
                Log(YELLOW "COW: THE New VA_perm is %016lx",VA_perm,CLEAR);
ffffffe00020334c:	00002797          	auipc	a5,0x2
ffffffe000203350:	20478793          	addi	a5,a5,516 # ffffffe000205550 <__func__.0+0x10>
ffffffe000203354:	f5843703          	ld	a4,-168(s0)
ffffffe000203358:	00002697          	auipc	a3,0x2
ffffffe00020335c:	59068693          	addi	a3,a3,1424 # ffffffe0002058e8 <__func__.1>
ffffffe000203360:	0db00613          	li	a2,219
ffffffe000203364:	00002597          	auipc	a1,0x2
ffffffe000203368:	1f458593          	addi	a1,a1,500 # ffffffe000205558 <__func__.0+0x18>
ffffffe00020336c:	00002517          	auipc	a0,0x2
ffffffe000203370:	45c50513          	addi	a0,a0,1116 # ffffffe0002057c8 <__func__.0+0x288>
ffffffe000203374:	678010ef          	jal	ffffffe0002049ec <printk>
                asm volatile("sfence.vma zero, zero");
ffffffe000203378:	12000073          	sfence.vma
                create_mapping(current->pgd,VMA_VA,(uint64_t)VA_Address-PA2VA_OFFSET,PGSIZE,VA_perm);
ffffffe00020337c:	00008797          	auipc	a5,0x8
ffffffe000203380:	c9478793          	addi	a5,a5,-876 # ffffffe00020b010 <current>
ffffffe000203384:	0007b783          	ld	a5,0(a5)
ffffffe000203388:	0a87b503          	ld	a0,168(a5)
ffffffe00020338c:	f6043703          	ld	a4,-160(s0)
ffffffe000203390:	04100793          	li	a5,65
ffffffe000203394:	01f79793          	slli	a5,a5,0x1f
ffffffe000203398:	00f707b3          	add	a5,a4,a5
ffffffe00020339c:	f5843703          	ld	a4,-168(s0)
ffffffe0002033a0:	000016b7          	lui	a3,0x1
ffffffe0002033a4:	00078613          	mv	a2,a5
ffffffe0002033a8:	f9043583          	ld	a1,-112(s0)
ffffffe0002033ac:	3b8000ef          	jal	ffffffe000203764 <create_mapping>
                printk("COW number is 2, and we create the mapping\n");
ffffffe0002033b0:	00002517          	auipc	a0,0x2
ffffffe0002033b4:	45850513          	addi	a0,a0,1112 # ffffffe000205808 <__func__.0+0x2c8>
ffffffe0002033b8:	634010ef          	jal	ffffffe0002049ec <printk>
ffffffe0002033bc:	00c0006f          	j	ffffffe0002033c8 <do_page_fault+0x6d8>
        }else{
            untrapped_handler(regs);
ffffffe0002033c0:	f0843503          	ld	a0,-248(s0)
ffffffe0002033c4:	018000ef          	jal	ffffffe0002033dc <untrapped_handler>
        }   
        
    }
}
ffffffe0002033c8:	0f813083          	ld	ra,248(sp)
ffffffe0002033cc:	0f013403          	ld	s0,240(sp)
ffffffe0002033d0:	0e813483          	ld	s1,232(sp)
ffffffe0002033d4:	10010113          	addi	sp,sp,256
ffffffe0002033d8:	00008067          	ret

ffffffe0002033dc <untrapped_handler>:

/**
 * This function is to handler those problem that has no permission or accessing the invalid memory;
*/
void untrapped_handler(struct pt_regs *regs){
ffffffe0002033dc:	fe010113          	addi	sp,sp,-32
ffffffe0002033e0:	00113c23          	sd	ra,24(sp)
ffffffe0002033e4:	00813823          	sd	s0,16(sp)
ffffffe0002033e8:	02010413          	addi	s0,sp,32
ffffffe0002033ec:	fea43423          	sd	a0,-24(s0)
    Log(RED "YOU HAVE ENTERED THE ERROR AREA! sepc = %lx, scause = %lx, stval = %lx",regs->sepc,regs->scause,regs->stval,CLEAR);
ffffffe0002033f0:	fe843783          	ld	a5,-24(s0)
ffffffe0002033f4:	1007b703          	ld	a4,256(a5)
ffffffe0002033f8:	fe843783          	ld	a5,-24(s0)
ffffffe0002033fc:	1187b683          	ld	a3,280(a5)
ffffffe000203400:	fe843783          	ld	a5,-24(s0)
ffffffe000203404:	1087b783          	ld	a5,264(a5)
ffffffe000203408:	00002897          	auipc	a7,0x2
ffffffe00020340c:	14888893          	addi	a7,a7,328 # ffffffe000205550 <__func__.0+0x10>
ffffffe000203410:	00078813          	mv	a6,a5
ffffffe000203414:	00068793          	mv	a5,a3
ffffffe000203418:	00002697          	auipc	a3,0x2
ffffffe00020341c:	4e068693          	addi	a3,a3,1248 # ffffffe0002058f8 <__func__.0>
ffffffe000203420:	0ec00613          	li	a2,236
ffffffe000203424:	00002597          	auipc	a1,0x2
ffffffe000203428:	13458593          	addi	a1,a1,308 # ffffffe000205558 <__func__.0+0x18>
ffffffe00020342c:	00002517          	auipc	a0,0x2
ffffffe000203430:	40c50513          	addi	a0,a0,1036 # ffffffe000205838 <__func__.0+0x2f8>
ffffffe000203434:	5b8010ef          	jal	ffffffe0002049ec <printk>
    // we set for stopping.
    Log(BLUE "YOU CAN'T EXECUTE AGAIN" CLEAR);
ffffffe000203438:	00002697          	auipc	a3,0x2
ffffffe00020343c:	4c068693          	addi	a3,a3,1216 # ffffffe0002058f8 <__func__.0>
ffffffe000203440:	0ee00613          	li	a2,238
ffffffe000203444:	00002597          	auipc	a1,0x2
ffffffe000203448:	11458593          	addi	a1,a1,276 # ffffffe000205558 <__func__.0+0x18>
ffffffe00020344c:	00002517          	auipc	a0,0x2
ffffffe000203450:	45450513          	addi	a0,a0,1108 # ffffffe0002058a0 <__func__.0+0x360>
ffffffe000203454:	598010ef          	jal	ffffffe0002049ec <printk>
    while(1);
ffffffe000203458:	00000013          	nop
ffffffe00020345c:	ffdff06f          	j	ffffffe000203458 <untrapped_handler+0x7c>

ffffffe000203460 <setup_vm>:
 * The purpose for this function is to set 2 mapping
 * 1. The equal value mapping PA==VA
 * 2. The direct mapping area PA + PV2VA_OFFSET == VA
 * 
*/
void setup_vm() {
ffffffe000203460:	fc010113          	addi	sp,sp,-64
ffffffe000203464:	02113c23          	sd	ra,56(sp)
ffffffe000203468:	02813823          	sd	s0,48(sp)
ffffffe00020346c:	04010413          	addi	s0,sp,64
     * | Reserved bit | PPN[2] | PPN[1] | PPN[0] | RSW | D | A | G | U | X | W | R | V | 
     * 
     * 
    */
    // The first equal value mapping PA == VA 
    Log(RED "We enter the part of the setup_vm" CLEAR);
ffffffe000203470:	00002697          	auipc	a3,0x2
ffffffe000203474:	6d068693          	addi	a3,a3,1744 # ffffffe000205b40 <__func__.2>
ffffffe000203478:	02f00613          	li	a2,47
ffffffe00020347c:	00002597          	auipc	a1,0x2
ffffffe000203480:	49458593          	addi	a1,a1,1172 # ffffffe000205910 <__func__.0+0x18>
ffffffe000203484:	00002517          	auipc	a0,0x2
ffffffe000203488:	49450513          	addi	a0,a0,1172 # ffffffe000205918 <__func__.0+0x20>
ffffffe00020348c:	560010ef          	jal	ffffffe0002049ec <printk>
    uint64_t PA = PHY_START;
ffffffe000203490:	00100793          	li	a5,1
ffffffe000203494:	01f79793          	slli	a5,a5,0x1f
ffffffe000203498:	fef43423          	sd	a5,-24(s0)
    // The first step to map;
    uint64_t virtualMemory_ = PA;
ffffffe00020349c:	fe843783          	ld	a5,-24(s0)
ffffffe0002034a0:	fef43023          	sd	a5,-32(s0)
    // index 9 bits
    uint64_t index = (virtualMemory_>>30)&0x1ff;
ffffffe0002034a4:	fe043783          	ld	a5,-32(s0)
ffffffe0002034a8:	01e7d793          	srli	a5,a5,0x1e
ffffffe0002034ac:	1ff7f793          	andi	a5,a5,511
ffffffe0002034b0:	fcf43c23          	sd	a5,-40(s0)
    uint64_t PPN = (PA>>30)&0x1ff;
ffffffe0002034b4:	fe843783          	ld	a5,-24(s0)
ffffffe0002034b8:	01e7d793          	srli	a5,a5,0x1e
ffffffe0002034bc:	1ff7f793          	andi	a5,a5,511
ffffffe0002034c0:	fcf43823          	sd	a5,-48(s0)
    // set for early_pagetable PNN;
    early_pgtbl[index] = (PPN)<<28;
ffffffe0002034c4:	fd043783          	ld	a5,-48(s0)
ffffffe0002034c8:	01c79713          	slli	a4,a5,0x1c
ffffffe0002034cc:	00009697          	auipc	a3,0x9
ffffffe0002034d0:	b3468693          	addi	a3,a3,-1228 # ffffffe00020c000 <early_pgtbl>
ffffffe0002034d4:	fd843783          	ld	a5,-40(s0)
ffffffe0002034d8:	00379793          	slli	a5,a5,0x3
ffffffe0002034dc:	00f687b3          	add	a5,a3,a5
ffffffe0002034e0:	00e7b023          	sd	a4,0(a5)
    // set for the priority;
    early_pgtbl[index] = early_pgtbl[index] | 0xf;  // X | W | R | V |
ffffffe0002034e4:	00009717          	auipc	a4,0x9
ffffffe0002034e8:	b1c70713          	addi	a4,a4,-1252 # ffffffe00020c000 <early_pgtbl>
ffffffe0002034ec:	fd843783          	ld	a5,-40(s0)
ffffffe0002034f0:	00379793          	slli	a5,a5,0x3
ffffffe0002034f4:	00f707b3          	add	a5,a4,a5
ffffffe0002034f8:	0007b783          	ld	a5,0(a5)
ffffffe0002034fc:	00f7e713          	ori	a4,a5,15
ffffffe000203500:	00009697          	auipc	a3,0x9
ffffffe000203504:	b0068693          	addi	a3,a3,-1280 # ffffffe00020c000 <early_pgtbl>
ffffffe000203508:	fd843783          	ld	a5,-40(s0)
ffffffe00020350c:	00379793          	slli	a5,a5,0x3
ffffffe000203510:	00f687b3          	add	a5,a3,a5
ffffffe000203514:	00e7b023          	sd	a4,0(a5)
    // The second value mapping PA + Offset == VA;

    uint64_t virtualMemory = VM_START;
ffffffe000203518:	fff00793          	li	a5,-1
ffffffe00020351c:	02579793          	slli	a5,a5,0x25
ffffffe000203520:	fcf43423          	sd	a5,-56(s0)
    index = (VM_START>>30)&0x1ff;
ffffffe000203524:	18000793          	li	a5,384
ffffffe000203528:	fcf43c23          	sd	a5,-40(s0)
    early_pgtbl[index] = (PPN)<<28 | 0xf;
ffffffe00020352c:	fd043783          	ld	a5,-48(s0)
ffffffe000203530:	01c79793          	slli	a5,a5,0x1c
ffffffe000203534:	00f7e713          	ori	a4,a5,15
ffffffe000203538:	00009697          	auipc	a3,0x9
ffffffe00020353c:	ac868693          	addi	a3,a3,-1336 # ffffffe00020c000 <early_pgtbl>
ffffffe000203540:	fd843783          	ld	a5,-40(s0)
ffffffe000203544:	00379793          	slli	a5,a5,0x3
ffffffe000203548:	00f687b3          	add	a5,a3,a5
ffffffe00020354c:	00e7b023          	sd	a4,0(a5)

    Log(RED "Over the set_vm" CLEAR);
ffffffe000203550:	00002697          	auipc	a3,0x2
ffffffe000203554:	5f068693          	addi	a3,a3,1520 # ffffffe000205b40 <__func__.2>
ffffffe000203558:	04000613          	li	a2,64
ffffffe00020355c:	00002597          	auipc	a1,0x2
ffffffe000203560:	3b458593          	addi	a1,a1,948 # ffffffe000205910 <__func__.0+0x18>
ffffffe000203564:	00002517          	auipc	a0,0x2
ffffffe000203568:	3fc50513          	addi	a0,a0,1020 # ffffffe000205960 <__func__.0+0x68>
ffffffe00020356c:	480010ef          	jal	ffffffe0002049ec <printk>
}
ffffffe000203570:	00000013          	nop
ffffffe000203574:	03813083          	ld	ra,56(sp)
ffffffe000203578:	03013403          	ld	s0,48(sp)
ffffffe00020357c:	04010113          	addi	sp,sp,64
ffffffe000203580:	00008067          	ret

ffffffe000203584 <setup_vm_final>:


void setup_vm_final(){
ffffffe000203584:	fe010113          	addi	sp,sp,-32
ffffffe000203588:	00113c23          	sd	ra,24(sp)
ffffffe00020358c:	00813823          	sd	s0,16(sp)
ffffffe000203590:	02010413          	addi	s0,sp,32
    memset(swapper_pg_dir, 0x0, PGSIZE);
ffffffe000203594:	00001637          	lui	a2,0x1
ffffffe000203598:	00000593          	li	a1,0
ffffffe00020359c:	0000a517          	auipc	a0,0xa
ffffffe0002035a0:	a6450513          	addi	a0,a0,-1436 # ffffffe00020d000 <swapper_pg_dir>
ffffffe0002035a4:	568010ef          	jal	ffffffe000204b0c <memset>
    /**
     * stext -> represents the start of the text address;
     * etext -> represents the end of the text address;
     * create_mapping(uint64_t *pgtbl, uint64_t va, uint64_t pa, uint64_t sz, uint64_t perm)
    */
    Log(RED "We enter the part of the setup_vm_final" CLEAR);
ffffffe0002035a8:	00002697          	auipc	a3,0x2
ffffffe0002035ac:	5a868693          	addi	a3,a3,1448 # ffffffe000205b50 <__func__.1>
ffffffe0002035b0:	04e00613          	li	a2,78
ffffffe0002035b4:	00002597          	auipc	a1,0x2
ffffffe0002035b8:	35c58593          	addi	a1,a1,860 # ffffffe000205910 <__func__.0+0x18>
ffffffe0002035bc:	00002517          	auipc	a0,0x2
ffffffe0002035c0:	3d450513          	addi	a0,a0,980 # ffffffe000205990 <__func__.0+0x98>
ffffffe0002035c4:	428010ef          	jal	ffffffe0002049ec <printk>
    create_mapping((uint64_t*)swapper_pg_dir,(uint64_t)(_stext),(uint64_t)(_stext-PA2VA_OFFSET),(uint64_t)(_etext-_stext),0xb);
ffffffe0002035c8:	ffffd597          	auipc	a1,0xffffd
ffffffe0002035cc:	a3858593          	addi	a1,a1,-1480 # ffffffe000200000 <_skernel>
ffffffe0002035d0:	ffffd717          	auipc	a4,0xffffd
ffffffe0002035d4:	a3070713          	addi	a4,a4,-1488 # ffffffe000200000 <_skernel>
ffffffe0002035d8:	04100793          	li	a5,65
ffffffe0002035dc:	01f79793          	slli	a5,a5,0x1f
ffffffe0002035e0:	00f707b3          	add	a5,a4,a5
ffffffe0002035e4:	00078613          	mv	a2,a5
ffffffe0002035e8:	00001717          	auipc	a4,0x1
ffffffe0002035ec:	60070713          	addi	a4,a4,1536 # ffffffe000204be8 <_etext>
ffffffe0002035f0:	ffffd797          	auipc	a5,0xffffd
ffffffe0002035f4:	a1078793          	addi	a5,a5,-1520 # ffffffe000200000 <_skernel>
ffffffe0002035f8:	40f707b3          	sub	a5,a4,a5
ffffffe0002035fc:	00b00713          	li	a4,11
ffffffe000203600:	00078693          	mv	a3,a5
ffffffe000203604:	0000a517          	auipc	a0,0xa
ffffffe000203608:	9fc50513          	addi	a0,a0,-1540 # ffffffe00020d000 <swapper_pg_dir>
ffffffe00020360c:	158000ef          	jal	ffffffe000203764 <create_mapping>
    // mapping kernel rodata -|-|R|V
    create_mapping((uint64_t*)swapper_pg_dir,(uint64_t)(_srodata),(uint64_t)(_srodata-PA2VA_OFFSET),(uint64_t)(_erodata-_srodata),0x3);
ffffffe000203610:	00002597          	auipc	a1,0x2
ffffffe000203614:	9f058593          	addi	a1,a1,-1552 # ffffffe000205000 <__func__.2>
ffffffe000203618:	00002717          	auipc	a4,0x2
ffffffe00020361c:	9e870713          	addi	a4,a4,-1560 # ffffffe000205000 <__func__.2>
ffffffe000203620:	04100793          	li	a5,65
ffffffe000203624:	01f79793          	slli	a5,a5,0x1f
ffffffe000203628:	00f707b3          	add	a5,a4,a5
ffffffe00020362c:	00078613          	mv	a2,a5
ffffffe000203630:	00002717          	auipc	a4,0x2
ffffffe000203634:	5f870713          	addi	a4,a4,1528 # ffffffe000205c28 <_erodata>
ffffffe000203638:	00002797          	auipc	a5,0x2
ffffffe00020363c:	9c878793          	addi	a5,a5,-1592 # ffffffe000205000 <__func__.2>
ffffffe000203640:	40f707b3          	sub	a5,a4,a5
ffffffe000203644:	00300713          	li	a4,3
ffffffe000203648:	00078693          	mv	a3,a5
ffffffe00020364c:	0000a517          	auipc	a0,0xa
ffffffe000203650:	9b450513          	addi	a0,a0,-1612 # ffffffe00020d000 <swapper_pg_dir>
ffffffe000203654:	110000ef          	jal	ffffffe000203764 <create_mapping>

    // mapping other memory -|W|R|V
    create_mapping((uint64_t*)swapper_pg_dir,(uint64_t)(_sdata),(uint64_t)(_sdata-PA2VA_OFFSET),(PHY_END+PA2VA_OFFSET-(uint64_t)_sdata),0x7);
ffffffe000203658:	00004597          	auipc	a1,0x4
ffffffe00020365c:	9a858593          	addi	a1,a1,-1624 # ffffffe000207000 <TIMECLOCK>
ffffffe000203660:	00004717          	auipc	a4,0x4
ffffffe000203664:	9a070713          	addi	a4,a4,-1632 # ffffffe000207000 <TIMECLOCK>
ffffffe000203668:	04100793          	li	a5,65
ffffffe00020366c:	01f79793          	slli	a5,a5,0x1f
ffffffe000203670:	00f707b3          	add	a5,a4,a5
ffffffe000203674:	00078613          	mv	a2,a5
ffffffe000203678:	00004797          	auipc	a5,0x4
ffffffe00020367c:	98878793          	addi	a5,a5,-1656 # ffffffe000207000 <TIMECLOCK>
ffffffe000203680:	c0100713          	li	a4,-1023
ffffffe000203684:	01b71713          	slli	a4,a4,0x1b
ffffffe000203688:	40f707b3          	sub	a5,a4,a5
ffffffe00020368c:	00700713          	li	a4,7
ffffffe000203690:	00078693          	mv	a3,a5
ffffffe000203694:	0000a517          	auipc	a0,0xa
ffffffe000203698:	96c50513          	addi	a0,a0,-1684 # ffffffe00020d000 <swapper_pg_dir>
ffffffe00020369c:	0c8000ef          	jal	ffffffe000203764 <create_mapping>

    create_mapping((uint64_t*)swapper_pg_dir,(uint64_t)_sramdisk,(uint64_t)(_sramdisk-PA2VA_OFFSET),(uint64_t)(_eramdisk-_sramdisk),0xf);
ffffffe0002036a0:	00005597          	auipc	a1,0x5
ffffffe0002036a4:	96058593          	addi	a1,a1,-1696 # ffffffe000208000 <_sramdisk>
ffffffe0002036a8:	00005717          	auipc	a4,0x5
ffffffe0002036ac:	95870713          	addi	a4,a4,-1704 # ffffffe000208000 <_sramdisk>
ffffffe0002036b0:	04100793          	li	a5,65
ffffffe0002036b4:	01f79793          	slli	a5,a5,0x1f
ffffffe0002036b8:	00f707b3          	add	a5,a4,a5
ffffffe0002036bc:	00078613          	mv	a2,a5
ffffffe0002036c0:	00006717          	auipc	a4,0x6
ffffffe0002036c4:	6b070713          	addi	a4,a4,1712 # ffffffe000209d70 <_eramdisk>
ffffffe0002036c8:	00005797          	auipc	a5,0x5
ffffffe0002036cc:	93878793          	addi	a5,a5,-1736 # ffffffe000208000 <_sramdisk>
ffffffe0002036d0:	40f707b3          	sub	a5,a4,a5
ffffffe0002036d4:	00f00713          	li	a4,15
ffffffe0002036d8:	00078693          	mv	a3,a5
ffffffe0002036dc:	0000a517          	auipc	a0,0xa
ffffffe0002036e0:	92450513          	addi	a0,a0,-1756 # ffffffe00020d000 <swapper_pg_dir>
ffffffe0002036e4:	080000ef          	jal	ffffffe000203764 <create_mapping>
    // set satp with swapper_pg_dir
    uint64_t temp = 0x8000000000000000 | (((uint64_t)swapper_pg_dir-PA2VA_OFFSET)>>12);
ffffffe0002036e8:	0000a717          	auipc	a4,0xa
ffffffe0002036ec:	91870713          	addi	a4,a4,-1768 # ffffffe00020d000 <swapper_pg_dir>
ffffffe0002036f0:	04100793          	li	a5,65
ffffffe0002036f4:	01f79793          	slli	a5,a5,0x1f
ffffffe0002036f8:	00f707b3          	add	a5,a4,a5
ffffffe0002036fc:	00c7d713          	srli	a4,a5,0xc
ffffffe000203700:	fff00793          	li	a5,-1
ffffffe000203704:	03f79793          	slli	a5,a5,0x3f
ffffffe000203708:	00f767b3          	or	a5,a4,a5
ffffffe00020370c:	fef43423          	sd	a5,-24(s0)
    csr_write(satp,temp);
ffffffe000203710:	fe843783          	ld	a5,-24(s0)
ffffffe000203714:	fef43023          	sd	a5,-32(s0)
ffffffe000203718:	fe043783          	ld	a5,-32(s0)
ffffffe00020371c:	18079073          	csrw	satp,a5
    // YOUR CODE HERE

    debug_ptr = 0;
ffffffe000203720:	00004797          	auipc	a5,0x4
ffffffe000203724:	8f878793          	addi	a5,a5,-1800 # ffffffe000207018 <debug_ptr>
ffffffe000203728:	0007b023          	sd	zero,0(a5)

    // flush TLB
    asm volatile("sfence.vma zero, zero");
ffffffe00020372c:	12000073          	sfence.vma
    Log(RED "We go out of the part of the setup_vm_final" CLEAR);
ffffffe000203730:	00002697          	auipc	a3,0x2
ffffffe000203734:	42068693          	addi	a3,a3,1056 # ffffffe000205b50 <__func__.1>
ffffffe000203738:	06000613          	li	a2,96
ffffffe00020373c:	00002597          	auipc	a1,0x2
ffffffe000203740:	1d458593          	addi	a1,a1,468 # ffffffe000205910 <__func__.0+0x18>
ffffffe000203744:	00002517          	auipc	a0,0x2
ffffffe000203748:	29450513          	addi	a0,a0,660 # ffffffe0002059d8 <__func__.0+0xe0>
ffffffe00020374c:	2a0010ef          	jal	ffffffe0002049ec <printk>
    
    return;
ffffffe000203750:	00000013          	nop
}
ffffffe000203754:	01813083          	ld	ra,24(sp)
ffffffe000203758:	01013403          	ld	s0,16(sp)
ffffffe00020375c:	02010113          	addi	sp,sp,32
ffffffe000203760:	00008067          	ret

ffffffe000203764 <create_mapping>:
     * perm 为映射的权限（即页表项的低 8 位）
     * 
     * 创建多级页表的时候可以使用 kalloc() 来获取一页作为页表目录
     * 可以使用 V bit 来判断页表项是否存在
    **/
void create_mapping(uint64_t *pgtbl, uint64_t va, uint64_t pa, uint64_t sz, uint64_t perm) {
ffffffe000203764:	f5010113          	addi	sp,sp,-176
ffffffe000203768:	0a113423          	sd	ra,168(sp)
ffffffe00020376c:	0a813023          	sd	s0,160(sp)
ffffffe000203770:	0b010413          	addi	s0,sp,176
ffffffe000203774:	f8a43c23          	sd	a0,-104(s0)
ffffffe000203778:	f8b43823          	sd	a1,-112(s0)
ffffffe00020377c:	f8c43423          	sd	a2,-120(s0)
ffffffe000203780:	f8d43023          	sd	a3,-128(s0)
ffffffe000203784:	f6e43c23          	sd	a4,-136(s0)
    // The purpose is to map all the part from the physical address to the virtual address;
    uint64_t n = (sz+PGSIZE-1)/PGSIZE;
ffffffe000203788:	f8043703          	ld	a4,-128(s0)
ffffffe00020378c:	000017b7          	lui	a5,0x1
ffffffe000203790:	fff78793          	addi	a5,a5,-1 # fff <PGSIZE-0x1>
ffffffe000203794:	00f707b3          	add	a5,a4,a5
ffffffe000203798:	00c7d793          	srli	a5,a5,0xc
ffffffe00020379c:	fcf43823          	sd	a5,-48(s0)
    Log(GREEN "root : %016lx, [%016lx,%016lx) -> [%016lx,%016lx),perm = %lx",(uint64_t*)pgtbl,PGROUNDDOWN(pa),PGROUNDDOWN(pa+n*PGSIZE),PGROUNDDOWN(va),PGROUNDDOWN(va+n*PGSIZE),perm,CLEAR);
ffffffe0002037a0:	f8843703          	ld	a4,-120(s0)
ffffffe0002037a4:	fffff7b7          	lui	a5,0xfffff
ffffffe0002037a8:	00f776b3          	and	a3,a4,a5
ffffffe0002037ac:	fd043783          	ld	a5,-48(s0)
ffffffe0002037b0:	00c79713          	slli	a4,a5,0xc
ffffffe0002037b4:	f8843783          	ld	a5,-120(s0)
ffffffe0002037b8:	00f70733          	add	a4,a4,a5
ffffffe0002037bc:	fffff7b7          	lui	a5,0xfffff
ffffffe0002037c0:	00f77633          	and	a2,a4,a5
ffffffe0002037c4:	f9043703          	ld	a4,-112(s0)
ffffffe0002037c8:	fffff7b7          	lui	a5,0xfffff
ffffffe0002037cc:	00f775b3          	and	a1,a4,a5
ffffffe0002037d0:	fd043783          	ld	a5,-48(s0)
ffffffe0002037d4:	00c79713          	slli	a4,a5,0xc
ffffffe0002037d8:	f9043783          	ld	a5,-112(s0)
ffffffe0002037dc:	00f70733          	add	a4,a4,a5
ffffffe0002037e0:	fffff7b7          	lui	a5,0xfffff
ffffffe0002037e4:	00f777b3          	and	a5,a4,a5
ffffffe0002037e8:	00002717          	auipc	a4,0x2
ffffffe0002037ec:	2a070713          	addi	a4,a4,672 # ffffffe000205a88 <__func__.0+0x190>
ffffffe0002037f0:	00e13823          	sd	a4,16(sp)
ffffffe0002037f4:	f7843703          	ld	a4,-136(s0)
ffffffe0002037f8:	00e13423          	sd	a4,8(sp)
ffffffe0002037fc:	00f13023          	sd	a5,0(sp)
ffffffe000203800:	00058893          	mv	a7,a1
ffffffe000203804:	00060813          	mv	a6,a2
ffffffe000203808:	00068793          	mv	a5,a3
ffffffe00020380c:	f9843703          	ld	a4,-104(s0)
ffffffe000203810:	00002697          	auipc	a3,0x2
ffffffe000203814:	35068693          	addi	a3,a3,848 # ffffffe000205b60 <__func__.0>
ffffffe000203818:	07400613          	li	a2,116
ffffffe00020381c:	00002597          	auipc	a1,0x2
ffffffe000203820:	0f458593          	addi	a1,a1,244 # ffffffe000205910 <__func__.0+0x18>
ffffffe000203824:	00002517          	auipc	a0,0x2
ffffffe000203828:	20450513          	addi	a0,a0,516 # ffffffe000205a28 <__func__.0+0x130>
ffffffe00020382c:	1c0010ef          	jal	ffffffe0002049ec <printk>
    for(int i=0;i<n;i++){
ffffffe000203830:	fe042623          	sw	zero,-20(s0)
ffffffe000203834:	27c0006f          	j	ffffffe000203ab0 <create_mapping+0x34c>
        // we need to set for the 3-levels page table;
        uint64_t VPN[3];
        VPN[2] = (va>>30)&0x1ff;
ffffffe000203838:	f9043783          	ld	a5,-112(s0)
ffffffe00020383c:	01e7d793          	srli	a5,a5,0x1e
ffffffe000203840:	1ff7f793          	andi	a5,a5,511
ffffffe000203844:	faf43c23          	sd	a5,-72(s0)
        VPN[1] = (va>>21)&0x1ff;
ffffffe000203848:	f9043783          	ld	a5,-112(s0)
ffffffe00020384c:	0157d793          	srli	a5,a5,0x15
ffffffe000203850:	1ff7f793          	andi	a5,a5,511
ffffffe000203854:	faf43823          	sd	a5,-80(s0)
        VPN[0] = (va>>12)&0x1ff;
ffffffe000203858:	f9043783          	ld	a5,-112(s0)
ffffffe00020385c:	00c7d793          	srli	a5,a5,0xc
ffffffe000203860:	1ff7f793          	andi	a5,a5,511
ffffffe000203864:	faf43423          	sd	a5,-88(s0)
        uint64_t *ptr = pgtbl;
ffffffe000203868:	f9843783          	ld	a5,-104(s0)
ffffffe00020386c:	fef43023          	sd	a5,-32(s0)
        if(debug_ptr==0)
ffffffe000203870:	00003797          	auipc	a5,0x3
ffffffe000203874:	7a878793          	addi	a5,a5,1960 # ffffffe000207018 <debug_ptr>
ffffffe000203878:	0007b783          	ld	a5,0(a5)
ffffffe00020387c:	02079863          	bnez	a5,ffffffe0002038ac <create_mapping+0x148>
            Log(YELLOW "[COW] root address is  : %016lx",ptr,CLEAR);
ffffffe000203880:	00002797          	auipc	a5,0x2
ffffffe000203884:	20878793          	addi	a5,a5,520 # ffffffe000205a88 <__func__.0+0x190>
ffffffe000203888:	fe043703          	ld	a4,-32(s0)
ffffffe00020388c:	00002697          	auipc	a3,0x2
ffffffe000203890:	2d468693          	addi	a3,a3,724 # ffffffe000205b60 <__func__.0>
ffffffe000203894:	07d00613          	li	a2,125
ffffffe000203898:	00002597          	auipc	a1,0x2
ffffffe00020389c:	07858593          	addi	a1,a1,120 # ffffffe000205910 <__func__.0+0x18>
ffffffe0002038a0:	00002517          	auipc	a0,0x2
ffffffe0002038a4:	1f050513          	addi	a0,a0,496 # ffffffe000205a90 <__func__.0+0x198>
ffffffe0002038a8:	144010ef          	jal	ffffffe0002049ec <printk>
        for(int j=2;j>0;j--){
ffffffe0002038ac:	00200793          	li	a5,2
ffffffe0002038b0:	fcf42e23          	sw	a5,-36(s0)
ffffffe0002038b4:	1440006f          	j	ffffffe0002039f8 <create_mapping+0x294>
            uint64_t temp = ptr[(VPN[j])];
ffffffe0002038b8:	fdc42783          	lw	a5,-36(s0)
ffffffe0002038bc:	00379793          	slli	a5,a5,0x3
ffffffe0002038c0:	ff078793          	addi	a5,a5,-16
ffffffe0002038c4:	008787b3          	add	a5,a5,s0
ffffffe0002038c8:	fb87b783          	ld	a5,-72(a5)
ffffffe0002038cc:	00379793          	slli	a5,a5,0x3
ffffffe0002038d0:	fe043703          	ld	a4,-32(s0)
ffffffe0002038d4:	00f707b3          	add	a5,a4,a5
ffffffe0002038d8:	0007b783          	ld	a5,0(a5)
ffffffe0002038dc:	fcf43423          	sd	a5,-56(s0)
            if((temp&0x1)==0x0){
ffffffe0002038e0:	fc843783          	ld	a5,-56(s0)
ffffffe0002038e4:	0017f793          	andi	a5,a5,1
ffffffe0002038e8:	0c079463          	bnez	a5,ffffffe0002039b0 <create_mapping+0x24c>
                uint64_t new_Ptr = (uint64_t)kalloc();
ffffffe0002038ec:	9bcfd0ef          	jal	ffffffe000200aa8 <kalloc>
ffffffe0002038f0:	00050793          	mv	a5,a0
ffffffe0002038f4:	fcf43023          	sd	a5,-64(s0)
                // mark for the v bit 
                ptr[VPN[j]] = (((new_Ptr-PA2VA_OFFSET)>>12&0xfffffffffff)<<10)|0x1; 
ffffffe0002038f8:	fc043703          	ld	a4,-64(s0)
ffffffe0002038fc:	04100793          	li	a5,65
ffffffe000203900:	01f79793          	slli	a5,a5,0x1f
ffffffe000203904:	00f707b3          	add	a5,a4,a5
ffffffe000203908:	00c7d793          	srli	a5,a5,0xc
ffffffe00020390c:	00a79713          	slli	a4,a5,0xa
ffffffe000203910:	fff007b7          	lui	a5,0xfff00
ffffffe000203914:	00a7d793          	srli	a5,a5,0xa
ffffffe000203918:	00f77733          	and	a4,a4,a5
ffffffe00020391c:	fdc42783          	lw	a5,-36(s0)
ffffffe000203920:	00379793          	slli	a5,a5,0x3
ffffffe000203924:	ff078793          	addi	a5,a5,-16 # ffffffffffeffff0 <VM_END+0xffeffff0>
ffffffe000203928:	008787b3          	add	a5,a5,s0
ffffffe00020392c:	fb87b783          	ld	a5,-72(a5)
ffffffe000203930:	00379793          	slli	a5,a5,0x3
ffffffe000203934:	fe043683          	ld	a3,-32(s0)
ffffffe000203938:	00f687b3          	add	a5,a3,a5
ffffffe00020393c:	00176713          	ori	a4,a4,1
ffffffe000203940:	00e7b023          	sd	a4,0(a5)
                // Log(YELLOW "PageTable address %d is %016lx",j,new_Ptr,CLEAR);
                // Log(BLUE "THE PHYSICAL PageTable address %d is %016lx",j,new_Ptr-PA2VA_OFFSET,CLEAR);
                if(debug_ptr==0)
ffffffe000203944:	00003797          	auipc	a5,0x3
ffffffe000203948:	6d478793          	addi	a5,a5,1748 # ffffffe000207018 <debug_ptr>
ffffffe00020394c:	0007b783          	ld	a5,0(a5)
ffffffe000203950:	04079a63          	bnez	a5,ffffffe0002039a4 <create_mapping+0x240>
                    Log(YELLOW "[COW] ptr[VPN[%d]] : %016lx",j,ptr[VPN[j]],CLEAR);
ffffffe000203954:	fdc42783          	lw	a5,-36(s0)
ffffffe000203958:	00379793          	slli	a5,a5,0x3
ffffffe00020395c:	ff078793          	addi	a5,a5,-16
ffffffe000203960:	008787b3          	add	a5,a5,s0
ffffffe000203964:	fb87b783          	ld	a5,-72(a5)
ffffffe000203968:	00379793          	slli	a5,a5,0x3
ffffffe00020396c:	fe043703          	ld	a4,-32(s0)
ffffffe000203970:	00f707b3          	add	a5,a4,a5
ffffffe000203974:	0007b783          	ld	a5,0(a5)
ffffffe000203978:	fdc42703          	lw	a4,-36(s0)
ffffffe00020397c:	00002817          	auipc	a6,0x2
ffffffe000203980:	10c80813          	addi	a6,a6,268 # ffffffe000205a88 <__func__.0+0x190>
ffffffe000203984:	00002697          	auipc	a3,0x2
ffffffe000203988:	1dc68693          	addi	a3,a3,476 # ffffffe000205b60 <__func__.0>
ffffffe00020398c:	08700613          	li	a2,135
ffffffe000203990:	00002597          	auipc	a1,0x2
ffffffe000203994:	f8058593          	addi	a1,a1,-128 # ffffffe000205910 <__func__.0+0x18>
ffffffe000203998:	00002517          	auipc	a0,0x2
ffffffe00020399c:	13850513          	addi	a0,a0,312 # ffffffe000205ad0 <__func__.0+0x1d8>
ffffffe0002039a0:	04c010ef          	jal	ffffffe0002049ec <printk>

                ptr = (uint64_t *)new_Ptr;
ffffffe0002039a4:	fc043783          	ld	a5,-64(s0)
ffffffe0002039a8:	fef43023          	sd	a5,-32(s0)
ffffffe0002039ac:	0400006f          	j	ffffffe0002039ec <create_mapping+0x288>
            }else{
                ptr = (uint64_t *)(((ptr[VPN[j]]>>10)<<12)+PA2VA_OFFSET);
ffffffe0002039b0:	fdc42783          	lw	a5,-36(s0)
ffffffe0002039b4:	00379793          	slli	a5,a5,0x3
ffffffe0002039b8:	ff078793          	addi	a5,a5,-16
ffffffe0002039bc:	008787b3          	add	a5,a5,s0
ffffffe0002039c0:	fb87b783          	ld	a5,-72(a5)
ffffffe0002039c4:	00379793          	slli	a5,a5,0x3
ffffffe0002039c8:	fe043703          	ld	a4,-32(s0)
ffffffe0002039cc:	00f707b3          	add	a5,a4,a5
ffffffe0002039d0:	0007b783          	ld	a5,0(a5)
ffffffe0002039d4:	00a7d793          	srli	a5,a5,0xa
ffffffe0002039d8:	00c79713          	slli	a4,a5,0xc
ffffffe0002039dc:	fbf00793          	li	a5,-65
ffffffe0002039e0:	01f79793          	slli	a5,a5,0x1f
ffffffe0002039e4:	00f707b3          	add	a5,a4,a5
ffffffe0002039e8:	fef43023          	sd	a5,-32(s0)
        for(int j=2;j>0;j--){
ffffffe0002039ec:	fdc42783          	lw	a5,-36(s0)
ffffffe0002039f0:	fff7879b          	addiw	a5,a5,-1
ffffffe0002039f4:	fcf42e23          	sw	a5,-36(s0)
ffffffe0002039f8:	fdc42783          	lw	a5,-36(s0)
ffffffe0002039fc:	0007879b          	sext.w	a5,a5
ffffffe000203a00:	eaf04ce3          	bgtz	a5,ffffffe0002038b8 <create_mapping+0x154>
            }
        }

        ptr[VPN[0]] = ((pa>>12)&0xfffffffffff)<<10 | perm;
ffffffe000203a04:	f8843783          	ld	a5,-120(s0)
ffffffe000203a08:	00c7d793          	srli	a5,a5,0xc
ffffffe000203a0c:	00a79713          	slli	a4,a5,0xa
ffffffe000203a10:	fff007b7          	lui	a5,0xfff00
ffffffe000203a14:	00a7d793          	srli	a5,a5,0xa
ffffffe000203a18:	00f776b3          	and	a3,a4,a5
ffffffe000203a1c:	fa843783          	ld	a5,-88(s0)
ffffffe000203a20:	00379793          	slli	a5,a5,0x3
ffffffe000203a24:	fe043703          	ld	a4,-32(s0)
ffffffe000203a28:	00f707b3          	add	a5,a4,a5
ffffffe000203a2c:	f7843703          	ld	a4,-136(s0)
ffffffe000203a30:	00e6e733          	or	a4,a3,a4
ffffffe000203a34:	00e7b023          	sd	a4,0(a5) # fffffffffff00000 <VM_END+0xfff00000>
        if(debug_ptr==0)
ffffffe000203a38:	00003797          	auipc	a5,0x3
ffffffe000203a3c:	5e078793          	addi	a5,a5,1504 # ffffffe000207018 <debug_ptr>
ffffffe000203a40:	0007b783          	ld	a5,0(a5)
ffffffe000203a44:	04079063          	bnez	a5,ffffffe000203a84 <create_mapping+0x320>
            Log(YELLOW "[COW] ptr[VPN[0]] : %016lx",ptr[VPN[0]],CLEAR);
ffffffe000203a48:	fa843783          	ld	a5,-88(s0)
ffffffe000203a4c:	00379793          	slli	a5,a5,0x3
ffffffe000203a50:	fe043703          	ld	a4,-32(s0)
ffffffe000203a54:	00f707b3          	add	a5,a4,a5
ffffffe000203a58:	0007b703          	ld	a4,0(a5)
ffffffe000203a5c:	00002797          	auipc	a5,0x2
ffffffe000203a60:	02c78793          	addi	a5,a5,44 # ffffffe000205a88 <__func__.0+0x190>
ffffffe000203a64:	00002697          	auipc	a3,0x2
ffffffe000203a68:	0fc68693          	addi	a3,a3,252 # ffffffe000205b60 <__func__.0>
ffffffe000203a6c:	09100613          	li	a2,145
ffffffe000203a70:	00002597          	auipc	a1,0x2
ffffffe000203a74:	ea058593          	addi	a1,a1,-352 # ffffffe000205910 <__func__.0+0x18>
ffffffe000203a78:	00002517          	auipc	a0,0x2
ffffffe000203a7c:	09050513          	addi	a0,a0,144 # ffffffe000205b08 <__func__.0+0x210>
ffffffe000203a80:	76d000ef          	jal	ffffffe0002049ec <printk>
        pa+=PGSIZE;
ffffffe000203a84:	f8843703          	ld	a4,-120(s0)
ffffffe000203a88:	000017b7          	lui	a5,0x1
ffffffe000203a8c:	00f707b3          	add	a5,a4,a5
ffffffe000203a90:	f8f43423          	sd	a5,-120(s0)
        va+=PGSIZE;
ffffffe000203a94:	f9043703          	ld	a4,-112(s0)
ffffffe000203a98:	000017b7          	lui	a5,0x1
ffffffe000203a9c:	00f707b3          	add	a5,a4,a5
ffffffe000203aa0:	f8f43823          	sd	a5,-112(s0)
    for(int i=0;i<n;i++){
ffffffe000203aa4:	fec42783          	lw	a5,-20(s0)
ffffffe000203aa8:	0017879b          	addiw	a5,a5,1 # 1001 <PGSIZE+0x1>
ffffffe000203aac:	fef42623          	sw	a5,-20(s0)
ffffffe000203ab0:	fec42783          	lw	a5,-20(s0)
ffffffe000203ab4:	fd043703          	ld	a4,-48(s0)
ffffffe000203ab8:	d8e7e0e3          	bltu	a5,a4,ffffffe000203838 <create_mapping+0xd4>
    }

ffffffe000203abc:	00000013          	nop
ffffffe000203ac0:	00000013          	nop
ffffffe000203ac4:	0a813083          	ld	ra,168(sp)
ffffffe000203ac8:	0a013403          	ld	s0,160(sp)
ffffffe000203acc:	0b010113          	addi	sp,sp,176
ffffffe000203ad0:	00008067          	ret

ffffffe000203ad4 <start_kernel>:
#include "defs.h"
#include "proc.h"

extern void test();

int start_kernel() {
ffffffe000203ad4:	ff010113          	addi	sp,sp,-16
ffffffe000203ad8:	00113423          	sd	ra,8(sp)
ffffffe000203adc:	00813023          	sd	s0,0(sp)
ffffffe000203ae0:	01010413          	addi	s0,sp,16
    printk("2024");
ffffffe000203ae4:	00002517          	auipc	a0,0x2
ffffffe000203ae8:	08c50513          	addi	a0,a0,140 # ffffffe000205b70 <__func__.0+0x10>
ffffffe000203aec:	701000ef          	jal	ffffffe0002049ec <printk>
    printk(" ZJU Operating System\n");
ffffffe000203af0:	00002517          	auipc	a0,0x2
ffffffe000203af4:	08850513          	addi	a0,a0,136 # ffffffe000205b78 <__func__.0+0x18>
ffffffe000203af8:	6f5000ef          	jal	ffffffe0002049ec <printk>
    
    schedule();
ffffffe000203afc:	ee5fd0ef          	jal	ffffffe0002019e0 <schedule>
    test();
ffffffe000203b00:	01c000ef          	jal	ffffffe000203b1c <test>
    return 0;
ffffffe000203b04:	00000793          	li	a5,0
}
ffffffe000203b08:	00078513          	mv	a0,a5
ffffffe000203b0c:	00813083          	ld	ra,8(sp)
ffffffe000203b10:	00013403          	ld	s0,0(sp)
ffffffe000203b14:	01010113          	addi	sp,sp,16
ffffffe000203b18:	00008067          	ret

ffffffe000203b1c <test>:
#include "printk.h"
#include "stdint.h"
#include "sbi.h"
void test() {
ffffffe000203b1c:	fe010113          	addi	sp,sp,-32
ffffffe000203b20:	00113c23          	sd	ra,24(sp)
ffffffe000203b24:	00813823          	sd	s0,16(sp)
ffffffe000203b28:	02010413          	addi	s0,sp,32
    // sbi_ecall(0x4442434E, 0x2, 0x32, 0, 0, 0, 0, 0);
    // printk("\n");
    // Test for the colorful format debugger console;
    Log(RED " This is a test for log" CLEAR);
ffffffe000203b2c:	00001697          	auipc	a3,0x1
ffffffe000203b30:	4e468693          	addi	a3,a3,1252 # ffffffe000205010 <__func__.0>
ffffffe000203b34:	00800613          	li	a2,8
ffffffe000203b38:	00002597          	auipc	a1,0x2
ffffffe000203b3c:	05858593          	addi	a1,a1,88 # ffffffe000205b90 <__func__.0+0x30>
ffffffe000203b40:	00002517          	auipc	a0,0x2
ffffffe000203b44:	05850513          	addi	a0,a0,88 # ffffffe000205b98 <__func__.0+0x38>
ffffffe000203b48:	6a5000ef          	jal	ffffffe0002049ec <printk>
    int i = 0;
ffffffe000203b4c:	fe042623          	sw	zero,-20(s0)
    while(1);
ffffffe000203b50:	00000013          	nop
ffffffe000203b54:	ffdff06f          	j	ffffffe000203b50 <test+0x34>

ffffffe000203b58 <putc>:
// credit: 45gfg9 <45gfg9@45gfg9.net>

#include "printk.h"
#include "sbi.h"

int putc(int c) {
ffffffe000203b58:	fe010113          	addi	sp,sp,-32
ffffffe000203b5c:	00113c23          	sd	ra,24(sp)
ffffffe000203b60:	00813823          	sd	s0,16(sp)
ffffffe000203b64:	02010413          	addi	s0,sp,32
ffffffe000203b68:	00050793          	mv	a5,a0
ffffffe000203b6c:	fef42623          	sw	a5,-20(s0)
    sbi_debug_console_write_byte(c);
ffffffe000203b70:	fec42783          	lw	a5,-20(s0)
ffffffe000203b74:	0ff7f793          	zext.b	a5,a5
ffffffe000203b78:	00078513          	mv	a0,a5
ffffffe000203b7c:	b00fe0ef          	jal	ffffffe000201e7c <sbi_debug_console_write_byte>
    return (char)c;
ffffffe000203b80:	fec42783          	lw	a5,-20(s0)
ffffffe000203b84:	0ff7f793          	zext.b	a5,a5
ffffffe000203b88:	0007879b          	sext.w	a5,a5
}
ffffffe000203b8c:	00078513          	mv	a0,a5
ffffffe000203b90:	01813083          	ld	ra,24(sp)
ffffffe000203b94:	01013403          	ld	s0,16(sp)
ffffffe000203b98:	02010113          	addi	sp,sp,32
ffffffe000203b9c:	00008067          	ret

ffffffe000203ba0 <isspace>:
    bool sign;
    int width;
    int prec;
};

int isspace(int c) {
ffffffe000203ba0:	fe010113          	addi	sp,sp,-32
ffffffe000203ba4:	00813c23          	sd	s0,24(sp)
ffffffe000203ba8:	02010413          	addi	s0,sp,32
ffffffe000203bac:	00050793          	mv	a5,a0
ffffffe000203bb0:	fef42623          	sw	a5,-20(s0)
    return c == ' ' || (c >= '\t' && c <= '\r');
ffffffe000203bb4:	fec42783          	lw	a5,-20(s0)
ffffffe000203bb8:	0007871b          	sext.w	a4,a5
ffffffe000203bbc:	02000793          	li	a5,32
ffffffe000203bc0:	02f70263          	beq	a4,a5,ffffffe000203be4 <isspace+0x44>
ffffffe000203bc4:	fec42783          	lw	a5,-20(s0)
ffffffe000203bc8:	0007871b          	sext.w	a4,a5
ffffffe000203bcc:	00800793          	li	a5,8
ffffffe000203bd0:	00e7de63          	bge	a5,a4,ffffffe000203bec <isspace+0x4c>
ffffffe000203bd4:	fec42783          	lw	a5,-20(s0)
ffffffe000203bd8:	0007871b          	sext.w	a4,a5
ffffffe000203bdc:	00d00793          	li	a5,13
ffffffe000203be0:	00e7c663          	blt	a5,a4,ffffffe000203bec <isspace+0x4c>
ffffffe000203be4:	00100793          	li	a5,1
ffffffe000203be8:	0080006f          	j	ffffffe000203bf0 <isspace+0x50>
ffffffe000203bec:	00000793          	li	a5,0
}
ffffffe000203bf0:	00078513          	mv	a0,a5
ffffffe000203bf4:	01813403          	ld	s0,24(sp)
ffffffe000203bf8:	02010113          	addi	sp,sp,32
ffffffe000203bfc:	00008067          	ret

ffffffe000203c00 <strtol>:

long strtol(const char *restrict nptr, char **restrict endptr, int base) {
ffffffe000203c00:	fb010113          	addi	sp,sp,-80
ffffffe000203c04:	04113423          	sd	ra,72(sp)
ffffffe000203c08:	04813023          	sd	s0,64(sp)
ffffffe000203c0c:	05010413          	addi	s0,sp,80
ffffffe000203c10:	fca43423          	sd	a0,-56(s0)
ffffffe000203c14:	fcb43023          	sd	a1,-64(s0)
ffffffe000203c18:	00060793          	mv	a5,a2
ffffffe000203c1c:	faf42e23          	sw	a5,-68(s0)
    long ret = 0;
ffffffe000203c20:	fe043423          	sd	zero,-24(s0)
    bool neg = false;
ffffffe000203c24:	fe0403a3          	sb	zero,-25(s0)
    const char *p = nptr;
ffffffe000203c28:	fc843783          	ld	a5,-56(s0)
ffffffe000203c2c:	fcf43c23          	sd	a5,-40(s0)

    while (isspace(*p)) {
ffffffe000203c30:	0100006f          	j	ffffffe000203c40 <strtol+0x40>
        p++;
ffffffe000203c34:	fd843783          	ld	a5,-40(s0)
ffffffe000203c38:	00178793          	addi	a5,a5,1
ffffffe000203c3c:	fcf43c23          	sd	a5,-40(s0)
    while (isspace(*p)) {
ffffffe000203c40:	fd843783          	ld	a5,-40(s0)
ffffffe000203c44:	0007c783          	lbu	a5,0(a5)
ffffffe000203c48:	0007879b          	sext.w	a5,a5
ffffffe000203c4c:	00078513          	mv	a0,a5
ffffffe000203c50:	f51ff0ef          	jal	ffffffe000203ba0 <isspace>
ffffffe000203c54:	00050793          	mv	a5,a0
ffffffe000203c58:	fc079ee3          	bnez	a5,ffffffe000203c34 <strtol+0x34>
    }

    if (*p == '-') {
ffffffe000203c5c:	fd843783          	ld	a5,-40(s0)
ffffffe000203c60:	0007c783          	lbu	a5,0(a5)
ffffffe000203c64:	00078713          	mv	a4,a5
ffffffe000203c68:	02d00793          	li	a5,45
ffffffe000203c6c:	00f71e63          	bne	a4,a5,ffffffe000203c88 <strtol+0x88>
        neg = true;
ffffffe000203c70:	00100793          	li	a5,1
ffffffe000203c74:	fef403a3          	sb	a5,-25(s0)
        p++;
ffffffe000203c78:	fd843783          	ld	a5,-40(s0)
ffffffe000203c7c:	00178793          	addi	a5,a5,1
ffffffe000203c80:	fcf43c23          	sd	a5,-40(s0)
ffffffe000203c84:	0240006f          	j	ffffffe000203ca8 <strtol+0xa8>
    } else if (*p == '+') {
ffffffe000203c88:	fd843783          	ld	a5,-40(s0)
ffffffe000203c8c:	0007c783          	lbu	a5,0(a5)
ffffffe000203c90:	00078713          	mv	a4,a5
ffffffe000203c94:	02b00793          	li	a5,43
ffffffe000203c98:	00f71863          	bne	a4,a5,ffffffe000203ca8 <strtol+0xa8>
        p++;
ffffffe000203c9c:	fd843783          	ld	a5,-40(s0)
ffffffe000203ca0:	00178793          	addi	a5,a5,1
ffffffe000203ca4:	fcf43c23          	sd	a5,-40(s0)
    }

    if (base == 0) {
ffffffe000203ca8:	fbc42783          	lw	a5,-68(s0)
ffffffe000203cac:	0007879b          	sext.w	a5,a5
ffffffe000203cb0:	06079c63          	bnez	a5,ffffffe000203d28 <strtol+0x128>
        if (*p == '0') {
ffffffe000203cb4:	fd843783          	ld	a5,-40(s0)
ffffffe000203cb8:	0007c783          	lbu	a5,0(a5)
ffffffe000203cbc:	00078713          	mv	a4,a5
ffffffe000203cc0:	03000793          	li	a5,48
ffffffe000203cc4:	04f71e63          	bne	a4,a5,ffffffe000203d20 <strtol+0x120>
            p++;
ffffffe000203cc8:	fd843783          	ld	a5,-40(s0)
ffffffe000203ccc:	00178793          	addi	a5,a5,1
ffffffe000203cd0:	fcf43c23          	sd	a5,-40(s0)
            if (*p == 'x' || *p == 'X') {
ffffffe000203cd4:	fd843783          	ld	a5,-40(s0)
ffffffe000203cd8:	0007c783          	lbu	a5,0(a5)
ffffffe000203cdc:	00078713          	mv	a4,a5
ffffffe000203ce0:	07800793          	li	a5,120
ffffffe000203ce4:	00f70c63          	beq	a4,a5,ffffffe000203cfc <strtol+0xfc>
ffffffe000203ce8:	fd843783          	ld	a5,-40(s0)
ffffffe000203cec:	0007c783          	lbu	a5,0(a5)
ffffffe000203cf0:	00078713          	mv	a4,a5
ffffffe000203cf4:	05800793          	li	a5,88
ffffffe000203cf8:	00f71e63          	bne	a4,a5,ffffffe000203d14 <strtol+0x114>
                base = 16;
ffffffe000203cfc:	01000793          	li	a5,16
ffffffe000203d00:	faf42e23          	sw	a5,-68(s0)
                p++;
ffffffe000203d04:	fd843783          	ld	a5,-40(s0)
ffffffe000203d08:	00178793          	addi	a5,a5,1
ffffffe000203d0c:	fcf43c23          	sd	a5,-40(s0)
ffffffe000203d10:	0180006f          	j	ffffffe000203d28 <strtol+0x128>
            } else {
                base = 8;
ffffffe000203d14:	00800793          	li	a5,8
ffffffe000203d18:	faf42e23          	sw	a5,-68(s0)
ffffffe000203d1c:	00c0006f          	j	ffffffe000203d28 <strtol+0x128>
            }
        } else {
            base = 10;
ffffffe000203d20:	00a00793          	li	a5,10
ffffffe000203d24:	faf42e23          	sw	a5,-68(s0)
        }
    }

    while (1) {
        int digit;
        if (*p >= '0' && *p <= '9') {
ffffffe000203d28:	fd843783          	ld	a5,-40(s0)
ffffffe000203d2c:	0007c783          	lbu	a5,0(a5)
ffffffe000203d30:	00078713          	mv	a4,a5
ffffffe000203d34:	02f00793          	li	a5,47
ffffffe000203d38:	02e7f863          	bgeu	a5,a4,ffffffe000203d68 <strtol+0x168>
ffffffe000203d3c:	fd843783          	ld	a5,-40(s0)
ffffffe000203d40:	0007c783          	lbu	a5,0(a5)
ffffffe000203d44:	00078713          	mv	a4,a5
ffffffe000203d48:	03900793          	li	a5,57
ffffffe000203d4c:	00e7ee63          	bltu	a5,a4,ffffffe000203d68 <strtol+0x168>
            digit = *p - '0';
ffffffe000203d50:	fd843783          	ld	a5,-40(s0)
ffffffe000203d54:	0007c783          	lbu	a5,0(a5)
ffffffe000203d58:	0007879b          	sext.w	a5,a5
ffffffe000203d5c:	fd07879b          	addiw	a5,a5,-48
ffffffe000203d60:	fcf42a23          	sw	a5,-44(s0)
ffffffe000203d64:	0800006f          	j	ffffffe000203de4 <strtol+0x1e4>
        } else if (*p >= 'a' && *p <= 'z') {
ffffffe000203d68:	fd843783          	ld	a5,-40(s0)
ffffffe000203d6c:	0007c783          	lbu	a5,0(a5)
ffffffe000203d70:	00078713          	mv	a4,a5
ffffffe000203d74:	06000793          	li	a5,96
ffffffe000203d78:	02e7f863          	bgeu	a5,a4,ffffffe000203da8 <strtol+0x1a8>
ffffffe000203d7c:	fd843783          	ld	a5,-40(s0)
ffffffe000203d80:	0007c783          	lbu	a5,0(a5)
ffffffe000203d84:	00078713          	mv	a4,a5
ffffffe000203d88:	07a00793          	li	a5,122
ffffffe000203d8c:	00e7ee63          	bltu	a5,a4,ffffffe000203da8 <strtol+0x1a8>
            digit = *p - ('a' - 10);
ffffffe000203d90:	fd843783          	ld	a5,-40(s0)
ffffffe000203d94:	0007c783          	lbu	a5,0(a5)
ffffffe000203d98:	0007879b          	sext.w	a5,a5
ffffffe000203d9c:	fa97879b          	addiw	a5,a5,-87
ffffffe000203da0:	fcf42a23          	sw	a5,-44(s0)
ffffffe000203da4:	0400006f          	j	ffffffe000203de4 <strtol+0x1e4>
        } else if (*p >= 'A' && *p <= 'Z') {
ffffffe000203da8:	fd843783          	ld	a5,-40(s0)
ffffffe000203dac:	0007c783          	lbu	a5,0(a5)
ffffffe000203db0:	00078713          	mv	a4,a5
ffffffe000203db4:	04000793          	li	a5,64
ffffffe000203db8:	06e7f863          	bgeu	a5,a4,ffffffe000203e28 <strtol+0x228>
ffffffe000203dbc:	fd843783          	ld	a5,-40(s0)
ffffffe000203dc0:	0007c783          	lbu	a5,0(a5)
ffffffe000203dc4:	00078713          	mv	a4,a5
ffffffe000203dc8:	05a00793          	li	a5,90
ffffffe000203dcc:	04e7ee63          	bltu	a5,a4,ffffffe000203e28 <strtol+0x228>
            digit = *p - ('A' - 10);
ffffffe000203dd0:	fd843783          	ld	a5,-40(s0)
ffffffe000203dd4:	0007c783          	lbu	a5,0(a5)
ffffffe000203dd8:	0007879b          	sext.w	a5,a5
ffffffe000203ddc:	fc97879b          	addiw	a5,a5,-55
ffffffe000203de0:	fcf42a23          	sw	a5,-44(s0)
        } else {
            break;
        }

        if (digit >= base) {
ffffffe000203de4:	fd442783          	lw	a5,-44(s0)
ffffffe000203de8:	00078713          	mv	a4,a5
ffffffe000203dec:	fbc42783          	lw	a5,-68(s0)
ffffffe000203df0:	0007071b          	sext.w	a4,a4
ffffffe000203df4:	0007879b          	sext.w	a5,a5
ffffffe000203df8:	02f75663          	bge	a4,a5,ffffffe000203e24 <strtol+0x224>
            break;
        }

        ret = ret * base + digit;
ffffffe000203dfc:	fbc42703          	lw	a4,-68(s0)
ffffffe000203e00:	fe843783          	ld	a5,-24(s0)
ffffffe000203e04:	02f70733          	mul	a4,a4,a5
ffffffe000203e08:	fd442783          	lw	a5,-44(s0)
ffffffe000203e0c:	00f707b3          	add	a5,a4,a5
ffffffe000203e10:	fef43423          	sd	a5,-24(s0)
        p++;
ffffffe000203e14:	fd843783          	ld	a5,-40(s0)
ffffffe000203e18:	00178793          	addi	a5,a5,1
ffffffe000203e1c:	fcf43c23          	sd	a5,-40(s0)
    while (1) {
ffffffe000203e20:	f09ff06f          	j	ffffffe000203d28 <strtol+0x128>
            break;
ffffffe000203e24:	00000013          	nop
    }

    if (endptr) {
ffffffe000203e28:	fc043783          	ld	a5,-64(s0)
ffffffe000203e2c:	00078863          	beqz	a5,ffffffe000203e3c <strtol+0x23c>
        *endptr = (char *)p;
ffffffe000203e30:	fc043783          	ld	a5,-64(s0)
ffffffe000203e34:	fd843703          	ld	a4,-40(s0)
ffffffe000203e38:	00e7b023          	sd	a4,0(a5)
    }

    return neg ? -ret : ret;
ffffffe000203e3c:	fe744783          	lbu	a5,-25(s0)
ffffffe000203e40:	0ff7f793          	zext.b	a5,a5
ffffffe000203e44:	00078863          	beqz	a5,ffffffe000203e54 <strtol+0x254>
ffffffe000203e48:	fe843783          	ld	a5,-24(s0)
ffffffe000203e4c:	40f007b3          	neg	a5,a5
ffffffe000203e50:	0080006f          	j	ffffffe000203e58 <strtol+0x258>
ffffffe000203e54:	fe843783          	ld	a5,-24(s0)
}
ffffffe000203e58:	00078513          	mv	a0,a5
ffffffe000203e5c:	04813083          	ld	ra,72(sp)
ffffffe000203e60:	04013403          	ld	s0,64(sp)
ffffffe000203e64:	05010113          	addi	sp,sp,80
ffffffe000203e68:	00008067          	ret

ffffffe000203e6c <puts_wo_nl>:

// puts without newline
static int puts_wo_nl(int (*putch)(int), const char *s) {
ffffffe000203e6c:	fd010113          	addi	sp,sp,-48
ffffffe000203e70:	02113423          	sd	ra,40(sp)
ffffffe000203e74:	02813023          	sd	s0,32(sp)
ffffffe000203e78:	03010413          	addi	s0,sp,48
ffffffe000203e7c:	fca43c23          	sd	a0,-40(s0)
ffffffe000203e80:	fcb43823          	sd	a1,-48(s0)
    if (!s) {
ffffffe000203e84:	fd043783          	ld	a5,-48(s0)
ffffffe000203e88:	00079863          	bnez	a5,ffffffe000203e98 <puts_wo_nl+0x2c>
        s = "(null)";
ffffffe000203e8c:	00002797          	auipc	a5,0x2
ffffffe000203e90:	d4478793          	addi	a5,a5,-700 # ffffffe000205bd0 <__func__.0+0x70>
ffffffe000203e94:	fcf43823          	sd	a5,-48(s0)
    }
    const char *p = s;
ffffffe000203e98:	fd043783          	ld	a5,-48(s0)
ffffffe000203e9c:	fef43423          	sd	a5,-24(s0)
    while (*p) {
ffffffe000203ea0:	0240006f          	j	ffffffe000203ec4 <puts_wo_nl+0x58>
        putch(*p++);
ffffffe000203ea4:	fe843783          	ld	a5,-24(s0)
ffffffe000203ea8:	00178713          	addi	a4,a5,1
ffffffe000203eac:	fee43423          	sd	a4,-24(s0)
ffffffe000203eb0:	0007c783          	lbu	a5,0(a5)
ffffffe000203eb4:	0007871b          	sext.w	a4,a5
ffffffe000203eb8:	fd843783          	ld	a5,-40(s0)
ffffffe000203ebc:	00070513          	mv	a0,a4
ffffffe000203ec0:	000780e7          	jalr	a5
    while (*p) {
ffffffe000203ec4:	fe843783          	ld	a5,-24(s0)
ffffffe000203ec8:	0007c783          	lbu	a5,0(a5)
ffffffe000203ecc:	fc079ce3          	bnez	a5,ffffffe000203ea4 <puts_wo_nl+0x38>
    }
    return p - s;
ffffffe000203ed0:	fe843703          	ld	a4,-24(s0)
ffffffe000203ed4:	fd043783          	ld	a5,-48(s0)
ffffffe000203ed8:	40f707b3          	sub	a5,a4,a5
ffffffe000203edc:	0007879b          	sext.w	a5,a5
}
ffffffe000203ee0:	00078513          	mv	a0,a5
ffffffe000203ee4:	02813083          	ld	ra,40(sp)
ffffffe000203ee8:	02013403          	ld	s0,32(sp)
ffffffe000203eec:	03010113          	addi	sp,sp,48
ffffffe000203ef0:	00008067          	ret

ffffffe000203ef4 <print_dec_int>:

static int print_dec_int(int (*putch)(int), unsigned long num, bool is_signed, struct fmt_flags *flags) {
ffffffe000203ef4:	f9010113          	addi	sp,sp,-112
ffffffe000203ef8:	06113423          	sd	ra,104(sp)
ffffffe000203efc:	06813023          	sd	s0,96(sp)
ffffffe000203f00:	07010413          	addi	s0,sp,112
ffffffe000203f04:	faa43423          	sd	a0,-88(s0)
ffffffe000203f08:	fab43023          	sd	a1,-96(s0)
ffffffe000203f0c:	00060793          	mv	a5,a2
ffffffe000203f10:	f8d43823          	sd	a3,-112(s0)
ffffffe000203f14:	f8f40fa3          	sb	a5,-97(s0)
    if (is_signed && num == 0x8000000000000000UL) {
ffffffe000203f18:	f9f44783          	lbu	a5,-97(s0)
ffffffe000203f1c:	0ff7f793          	zext.b	a5,a5
ffffffe000203f20:	02078663          	beqz	a5,ffffffe000203f4c <print_dec_int+0x58>
ffffffe000203f24:	fa043703          	ld	a4,-96(s0)
ffffffe000203f28:	fff00793          	li	a5,-1
ffffffe000203f2c:	03f79793          	slli	a5,a5,0x3f
ffffffe000203f30:	00f71e63          	bne	a4,a5,ffffffe000203f4c <print_dec_int+0x58>
        // special case for 0x8000000000000000
        return puts_wo_nl(putch, "-9223372036854775808");
ffffffe000203f34:	00002597          	auipc	a1,0x2
ffffffe000203f38:	ca458593          	addi	a1,a1,-860 # ffffffe000205bd8 <__func__.0+0x78>
ffffffe000203f3c:	fa843503          	ld	a0,-88(s0)
ffffffe000203f40:	f2dff0ef          	jal	ffffffe000203e6c <puts_wo_nl>
ffffffe000203f44:	00050793          	mv	a5,a0
ffffffe000203f48:	2a00006f          	j	ffffffe0002041e8 <print_dec_int+0x2f4>
    }

    if (flags->prec == 0 && num == 0) {
ffffffe000203f4c:	f9043783          	ld	a5,-112(s0)
ffffffe000203f50:	00c7a783          	lw	a5,12(a5)
ffffffe000203f54:	00079a63          	bnez	a5,ffffffe000203f68 <print_dec_int+0x74>
ffffffe000203f58:	fa043783          	ld	a5,-96(s0)
ffffffe000203f5c:	00079663          	bnez	a5,ffffffe000203f68 <print_dec_int+0x74>
        return 0;
ffffffe000203f60:	00000793          	li	a5,0
ffffffe000203f64:	2840006f          	j	ffffffe0002041e8 <print_dec_int+0x2f4>
    }

    bool neg = false;
ffffffe000203f68:	fe0407a3          	sb	zero,-17(s0)

    if (is_signed && (long)num < 0) {
ffffffe000203f6c:	f9f44783          	lbu	a5,-97(s0)
ffffffe000203f70:	0ff7f793          	zext.b	a5,a5
ffffffe000203f74:	02078063          	beqz	a5,ffffffe000203f94 <print_dec_int+0xa0>
ffffffe000203f78:	fa043783          	ld	a5,-96(s0)
ffffffe000203f7c:	0007dc63          	bgez	a5,ffffffe000203f94 <print_dec_int+0xa0>
        neg = true;
ffffffe000203f80:	00100793          	li	a5,1
ffffffe000203f84:	fef407a3          	sb	a5,-17(s0)
        num = -num;
ffffffe000203f88:	fa043783          	ld	a5,-96(s0)
ffffffe000203f8c:	40f007b3          	neg	a5,a5
ffffffe000203f90:	faf43023          	sd	a5,-96(s0)
    }

    char buf[20];
    int decdigits = 0;
ffffffe000203f94:	fe042423          	sw	zero,-24(s0)

    bool has_sign_char = is_signed && (neg || flags->sign || flags->spaceflag);
ffffffe000203f98:	f9f44783          	lbu	a5,-97(s0)
ffffffe000203f9c:	0ff7f793          	zext.b	a5,a5
ffffffe000203fa0:	02078863          	beqz	a5,ffffffe000203fd0 <print_dec_int+0xdc>
ffffffe000203fa4:	fef44783          	lbu	a5,-17(s0)
ffffffe000203fa8:	0ff7f793          	zext.b	a5,a5
ffffffe000203fac:	00079e63          	bnez	a5,ffffffe000203fc8 <print_dec_int+0xd4>
ffffffe000203fb0:	f9043783          	ld	a5,-112(s0)
ffffffe000203fb4:	0057c783          	lbu	a5,5(a5)
ffffffe000203fb8:	00079863          	bnez	a5,ffffffe000203fc8 <print_dec_int+0xd4>
ffffffe000203fbc:	f9043783          	ld	a5,-112(s0)
ffffffe000203fc0:	0047c783          	lbu	a5,4(a5)
ffffffe000203fc4:	00078663          	beqz	a5,ffffffe000203fd0 <print_dec_int+0xdc>
ffffffe000203fc8:	00100793          	li	a5,1
ffffffe000203fcc:	0080006f          	j	ffffffe000203fd4 <print_dec_int+0xe0>
ffffffe000203fd0:	00000793          	li	a5,0
ffffffe000203fd4:	fcf40ba3          	sb	a5,-41(s0)
ffffffe000203fd8:	fd744783          	lbu	a5,-41(s0)
ffffffe000203fdc:	0017f793          	andi	a5,a5,1
ffffffe000203fe0:	fcf40ba3          	sb	a5,-41(s0)

    do {
        buf[decdigits++] = num % 10 + '0';
ffffffe000203fe4:	fa043703          	ld	a4,-96(s0)
ffffffe000203fe8:	00a00793          	li	a5,10
ffffffe000203fec:	02f777b3          	remu	a5,a4,a5
ffffffe000203ff0:	0ff7f713          	zext.b	a4,a5
ffffffe000203ff4:	fe842783          	lw	a5,-24(s0)
ffffffe000203ff8:	0017869b          	addiw	a3,a5,1
ffffffe000203ffc:	fed42423          	sw	a3,-24(s0)
ffffffe000204000:	0307071b          	addiw	a4,a4,48
ffffffe000204004:	0ff77713          	zext.b	a4,a4
ffffffe000204008:	ff078793          	addi	a5,a5,-16
ffffffe00020400c:	008787b3          	add	a5,a5,s0
ffffffe000204010:	fce78423          	sb	a4,-56(a5)
        num /= 10;
ffffffe000204014:	fa043703          	ld	a4,-96(s0)
ffffffe000204018:	00a00793          	li	a5,10
ffffffe00020401c:	02f757b3          	divu	a5,a4,a5
ffffffe000204020:	faf43023          	sd	a5,-96(s0)
    } while (num);
ffffffe000204024:	fa043783          	ld	a5,-96(s0)
ffffffe000204028:	fa079ee3          	bnez	a5,ffffffe000203fe4 <print_dec_int+0xf0>

    if (flags->prec == -1 && flags->zeroflag) {
ffffffe00020402c:	f9043783          	ld	a5,-112(s0)
ffffffe000204030:	00c7a783          	lw	a5,12(a5)
ffffffe000204034:	00078713          	mv	a4,a5
ffffffe000204038:	fff00793          	li	a5,-1
ffffffe00020403c:	02f71063          	bne	a4,a5,ffffffe00020405c <print_dec_int+0x168>
ffffffe000204040:	f9043783          	ld	a5,-112(s0)
ffffffe000204044:	0037c783          	lbu	a5,3(a5)
ffffffe000204048:	00078a63          	beqz	a5,ffffffe00020405c <print_dec_int+0x168>
        flags->prec = flags->width;
ffffffe00020404c:	f9043783          	ld	a5,-112(s0)
ffffffe000204050:	0087a703          	lw	a4,8(a5)
ffffffe000204054:	f9043783          	ld	a5,-112(s0)
ffffffe000204058:	00e7a623          	sw	a4,12(a5)
    }

    int written = 0;
ffffffe00020405c:	fe042223          	sw	zero,-28(s0)

    for (int i = flags->width - __MAX(decdigits, flags->prec) - has_sign_char; i > 0; i--) {
ffffffe000204060:	f9043783          	ld	a5,-112(s0)
ffffffe000204064:	0087a703          	lw	a4,8(a5)
ffffffe000204068:	fe842783          	lw	a5,-24(s0)
ffffffe00020406c:	fcf42823          	sw	a5,-48(s0)
ffffffe000204070:	f9043783          	ld	a5,-112(s0)
ffffffe000204074:	00c7a783          	lw	a5,12(a5)
ffffffe000204078:	fcf42623          	sw	a5,-52(s0)
ffffffe00020407c:	fd042783          	lw	a5,-48(s0)
ffffffe000204080:	00078593          	mv	a1,a5
ffffffe000204084:	fcc42783          	lw	a5,-52(s0)
ffffffe000204088:	00078613          	mv	a2,a5
ffffffe00020408c:	0006069b          	sext.w	a3,a2
ffffffe000204090:	0005879b          	sext.w	a5,a1
ffffffe000204094:	00f6d463          	bge	a3,a5,ffffffe00020409c <print_dec_int+0x1a8>
ffffffe000204098:	00058613          	mv	a2,a1
ffffffe00020409c:	0006079b          	sext.w	a5,a2
ffffffe0002040a0:	40f707bb          	subw	a5,a4,a5
ffffffe0002040a4:	0007871b          	sext.w	a4,a5
ffffffe0002040a8:	fd744783          	lbu	a5,-41(s0)
ffffffe0002040ac:	0007879b          	sext.w	a5,a5
ffffffe0002040b0:	40f707bb          	subw	a5,a4,a5
ffffffe0002040b4:	fef42023          	sw	a5,-32(s0)
ffffffe0002040b8:	0280006f          	j	ffffffe0002040e0 <print_dec_int+0x1ec>
        putch(' ');
ffffffe0002040bc:	fa843783          	ld	a5,-88(s0)
ffffffe0002040c0:	02000513          	li	a0,32
ffffffe0002040c4:	000780e7          	jalr	a5
        ++written;
ffffffe0002040c8:	fe442783          	lw	a5,-28(s0)
ffffffe0002040cc:	0017879b          	addiw	a5,a5,1
ffffffe0002040d0:	fef42223          	sw	a5,-28(s0)
    for (int i = flags->width - __MAX(decdigits, flags->prec) - has_sign_char; i > 0; i--) {
ffffffe0002040d4:	fe042783          	lw	a5,-32(s0)
ffffffe0002040d8:	fff7879b          	addiw	a5,a5,-1
ffffffe0002040dc:	fef42023          	sw	a5,-32(s0)
ffffffe0002040e0:	fe042783          	lw	a5,-32(s0)
ffffffe0002040e4:	0007879b          	sext.w	a5,a5
ffffffe0002040e8:	fcf04ae3          	bgtz	a5,ffffffe0002040bc <print_dec_int+0x1c8>
    }

    if (has_sign_char) {
ffffffe0002040ec:	fd744783          	lbu	a5,-41(s0)
ffffffe0002040f0:	0ff7f793          	zext.b	a5,a5
ffffffe0002040f4:	04078463          	beqz	a5,ffffffe00020413c <print_dec_int+0x248>
        putch(neg ? '-' : flags->sign ? '+' : ' ');
ffffffe0002040f8:	fef44783          	lbu	a5,-17(s0)
ffffffe0002040fc:	0ff7f793          	zext.b	a5,a5
ffffffe000204100:	00078663          	beqz	a5,ffffffe00020410c <print_dec_int+0x218>
ffffffe000204104:	02d00793          	li	a5,45
ffffffe000204108:	01c0006f          	j	ffffffe000204124 <print_dec_int+0x230>
ffffffe00020410c:	f9043783          	ld	a5,-112(s0)
ffffffe000204110:	0057c783          	lbu	a5,5(a5)
ffffffe000204114:	00078663          	beqz	a5,ffffffe000204120 <print_dec_int+0x22c>
ffffffe000204118:	02b00793          	li	a5,43
ffffffe00020411c:	0080006f          	j	ffffffe000204124 <print_dec_int+0x230>
ffffffe000204120:	02000793          	li	a5,32
ffffffe000204124:	fa843703          	ld	a4,-88(s0)
ffffffe000204128:	00078513          	mv	a0,a5
ffffffe00020412c:	000700e7          	jalr	a4
        ++written;
ffffffe000204130:	fe442783          	lw	a5,-28(s0)
ffffffe000204134:	0017879b          	addiw	a5,a5,1
ffffffe000204138:	fef42223          	sw	a5,-28(s0)
    }

    for (int i = decdigits; i < flags->prec - has_sign_char; i++) {
ffffffe00020413c:	fe842783          	lw	a5,-24(s0)
ffffffe000204140:	fcf42e23          	sw	a5,-36(s0)
ffffffe000204144:	0280006f          	j	ffffffe00020416c <print_dec_int+0x278>
        putch('0');
ffffffe000204148:	fa843783          	ld	a5,-88(s0)
ffffffe00020414c:	03000513          	li	a0,48
ffffffe000204150:	000780e7          	jalr	a5
        ++written;
ffffffe000204154:	fe442783          	lw	a5,-28(s0)
ffffffe000204158:	0017879b          	addiw	a5,a5,1
ffffffe00020415c:	fef42223          	sw	a5,-28(s0)
    for (int i = decdigits; i < flags->prec - has_sign_char; i++) {
ffffffe000204160:	fdc42783          	lw	a5,-36(s0)
ffffffe000204164:	0017879b          	addiw	a5,a5,1
ffffffe000204168:	fcf42e23          	sw	a5,-36(s0)
ffffffe00020416c:	f9043783          	ld	a5,-112(s0)
ffffffe000204170:	00c7a703          	lw	a4,12(a5)
ffffffe000204174:	fd744783          	lbu	a5,-41(s0)
ffffffe000204178:	0007879b          	sext.w	a5,a5
ffffffe00020417c:	40f707bb          	subw	a5,a4,a5
ffffffe000204180:	0007871b          	sext.w	a4,a5
ffffffe000204184:	fdc42783          	lw	a5,-36(s0)
ffffffe000204188:	0007879b          	sext.w	a5,a5
ffffffe00020418c:	fae7cee3          	blt	a5,a4,ffffffe000204148 <print_dec_int+0x254>
    }

    for (int i = decdigits - 1; i >= 0; i--) {
ffffffe000204190:	fe842783          	lw	a5,-24(s0)
ffffffe000204194:	fff7879b          	addiw	a5,a5,-1
ffffffe000204198:	fcf42c23          	sw	a5,-40(s0)
ffffffe00020419c:	03c0006f          	j	ffffffe0002041d8 <print_dec_int+0x2e4>
        putch(buf[i]);
ffffffe0002041a0:	fd842783          	lw	a5,-40(s0)
ffffffe0002041a4:	ff078793          	addi	a5,a5,-16
ffffffe0002041a8:	008787b3          	add	a5,a5,s0
ffffffe0002041ac:	fc87c783          	lbu	a5,-56(a5)
ffffffe0002041b0:	0007871b          	sext.w	a4,a5
ffffffe0002041b4:	fa843783          	ld	a5,-88(s0)
ffffffe0002041b8:	00070513          	mv	a0,a4
ffffffe0002041bc:	000780e7          	jalr	a5
        ++written;
ffffffe0002041c0:	fe442783          	lw	a5,-28(s0)
ffffffe0002041c4:	0017879b          	addiw	a5,a5,1
ffffffe0002041c8:	fef42223          	sw	a5,-28(s0)
    for (int i = decdigits - 1; i >= 0; i--) {
ffffffe0002041cc:	fd842783          	lw	a5,-40(s0)
ffffffe0002041d0:	fff7879b          	addiw	a5,a5,-1
ffffffe0002041d4:	fcf42c23          	sw	a5,-40(s0)
ffffffe0002041d8:	fd842783          	lw	a5,-40(s0)
ffffffe0002041dc:	0007879b          	sext.w	a5,a5
ffffffe0002041e0:	fc07d0e3          	bgez	a5,ffffffe0002041a0 <print_dec_int+0x2ac>
    }

    return written;
ffffffe0002041e4:	fe442783          	lw	a5,-28(s0)
}
ffffffe0002041e8:	00078513          	mv	a0,a5
ffffffe0002041ec:	06813083          	ld	ra,104(sp)
ffffffe0002041f0:	06013403          	ld	s0,96(sp)
ffffffe0002041f4:	07010113          	addi	sp,sp,112
ffffffe0002041f8:	00008067          	ret

ffffffe0002041fc <vprintfmt>:

int vprintfmt(int (*putch)(int), const char *fmt, va_list vl) {
ffffffe0002041fc:	f4010113          	addi	sp,sp,-192
ffffffe000204200:	0a113c23          	sd	ra,184(sp)
ffffffe000204204:	0a813823          	sd	s0,176(sp)
ffffffe000204208:	0c010413          	addi	s0,sp,192
ffffffe00020420c:	f4a43c23          	sd	a0,-168(s0)
ffffffe000204210:	f4b43823          	sd	a1,-176(s0)
ffffffe000204214:	f4c43423          	sd	a2,-184(s0)
    static const char lowerxdigits[] = "0123456789abcdef";
    static const char upperxdigits[] = "0123456789ABCDEF";

    struct fmt_flags flags = {};
ffffffe000204218:	f8043023          	sd	zero,-128(s0)
ffffffe00020421c:	f8043423          	sd	zero,-120(s0)

    int written = 0;
ffffffe000204220:	fe042623          	sw	zero,-20(s0)

    for (; *fmt; fmt++) {
ffffffe000204224:	7a40006f          	j	ffffffe0002049c8 <vprintfmt+0x7cc>
        if (flags.in_format) {
ffffffe000204228:	f8044783          	lbu	a5,-128(s0)
ffffffe00020422c:	72078e63          	beqz	a5,ffffffe000204968 <vprintfmt+0x76c>
            if (*fmt == '#') {
ffffffe000204230:	f5043783          	ld	a5,-176(s0)
ffffffe000204234:	0007c783          	lbu	a5,0(a5)
ffffffe000204238:	00078713          	mv	a4,a5
ffffffe00020423c:	02300793          	li	a5,35
ffffffe000204240:	00f71863          	bne	a4,a5,ffffffe000204250 <vprintfmt+0x54>
                flags.sharpflag = true;
ffffffe000204244:	00100793          	li	a5,1
ffffffe000204248:	f8f40123          	sb	a5,-126(s0)
ffffffe00020424c:	7700006f          	j	ffffffe0002049bc <vprintfmt+0x7c0>
            } else if (*fmt == '0') {
ffffffe000204250:	f5043783          	ld	a5,-176(s0)
ffffffe000204254:	0007c783          	lbu	a5,0(a5)
ffffffe000204258:	00078713          	mv	a4,a5
ffffffe00020425c:	03000793          	li	a5,48
ffffffe000204260:	00f71863          	bne	a4,a5,ffffffe000204270 <vprintfmt+0x74>
                flags.zeroflag = true;
ffffffe000204264:	00100793          	li	a5,1
ffffffe000204268:	f8f401a3          	sb	a5,-125(s0)
ffffffe00020426c:	7500006f          	j	ffffffe0002049bc <vprintfmt+0x7c0>
            } else if (*fmt == 'l' || *fmt == 'z' || *fmt == 't' || *fmt == 'j') {
ffffffe000204270:	f5043783          	ld	a5,-176(s0)
ffffffe000204274:	0007c783          	lbu	a5,0(a5)
ffffffe000204278:	00078713          	mv	a4,a5
ffffffe00020427c:	06c00793          	li	a5,108
ffffffe000204280:	04f70063          	beq	a4,a5,ffffffe0002042c0 <vprintfmt+0xc4>
ffffffe000204284:	f5043783          	ld	a5,-176(s0)
ffffffe000204288:	0007c783          	lbu	a5,0(a5)
ffffffe00020428c:	00078713          	mv	a4,a5
ffffffe000204290:	07a00793          	li	a5,122
ffffffe000204294:	02f70663          	beq	a4,a5,ffffffe0002042c0 <vprintfmt+0xc4>
ffffffe000204298:	f5043783          	ld	a5,-176(s0)
ffffffe00020429c:	0007c783          	lbu	a5,0(a5)
ffffffe0002042a0:	00078713          	mv	a4,a5
ffffffe0002042a4:	07400793          	li	a5,116
ffffffe0002042a8:	00f70c63          	beq	a4,a5,ffffffe0002042c0 <vprintfmt+0xc4>
ffffffe0002042ac:	f5043783          	ld	a5,-176(s0)
ffffffe0002042b0:	0007c783          	lbu	a5,0(a5)
ffffffe0002042b4:	00078713          	mv	a4,a5
ffffffe0002042b8:	06a00793          	li	a5,106
ffffffe0002042bc:	00f71863          	bne	a4,a5,ffffffe0002042cc <vprintfmt+0xd0>
                // l: long, z: size_t, t: ptrdiff_t, j: intmax_t
                flags.longflag = true;
ffffffe0002042c0:	00100793          	li	a5,1
ffffffe0002042c4:	f8f400a3          	sb	a5,-127(s0)
ffffffe0002042c8:	6f40006f          	j	ffffffe0002049bc <vprintfmt+0x7c0>
            } else if (*fmt == '+') {
ffffffe0002042cc:	f5043783          	ld	a5,-176(s0)
ffffffe0002042d0:	0007c783          	lbu	a5,0(a5)
ffffffe0002042d4:	00078713          	mv	a4,a5
ffffffe0002042d8:	02b00793          	li	a5,43
ffffffe0002042dc:	00f71863          	bne	a4,a5,ffffffe0002042ec <vprintfmt+0xf0>
                flags.sign = true;
ffffffe0002042e0:	00100793          	li	a5,1
ffffffe0002042e4:	f8f402a3          	sb	a5,-123(s0)
ffffffe0002042e8:	6d40006f          	j	ffffffe0002049bc <vprintfmt+0x7c0>
            } else if (*fmt == ' ') {
ffffffe0002042ec:	f5043783          	ld	a5,-176(s0)
ffffffe0002042f0:	0007c783          	lbu	a5,0(a5)
ffffffe0002042f4:	00078713          	mv	a4,a5
ffffffe0002042f8:	02000793          	li	a5,32
ffffffe0002042fc:	00f71863          	bne	a4,a5,ffffffe00020430c <vprintfmt+0x110>
                flags.spaceflag = true;
ffffffe000204300:	00100793          	li	a5,1
ffffffe000204304:	f8f40223          	sb	a5,-124(s0)
ffffffe000204308:	6b40006f          	j	ffffffe0002049bc <vprintfmt+0x7c0>
            } else if (*fmt == '*') {
ffffffe00020430c:	f5043783          	ld	a5,-176(s0)
ffffffe000204310:	0007c783          	lbu	a5,0(a5)
ffffffe000204314:	00078713          	mv	a4,a5
ffffffe000204318:	02a00793          	li	a5,42
ffffffe00020431c:	00f71e63          	bne	a4,a5,ffffffe000204338 <vprintfmt+0x13c>
                flags.width = va_arg(vl, int);
ffffffe000204320:	f4843783          	ld	a5,-184(s0)
ffffffe000204324:	00878713          	addi	a4,a5,8
ffffffe000204328:	f4e43423          	sd	a4,-184(s0)
ffffffe00020432c:	0007a783          	lw	a5,0(a5)
ffffffe000204330:	f8f42423          	sw	a5,-120(s0)
ffffffe000204334:	6880006f          	j	ffffffe0002049bc <vprintfmt+0x7c0>
            } else if (*fmt >= '1' && *fmt <= '9') {
ffffffe000204338:	f5043783          	ld	a5,-176(s0)
ffffffe00020433c:	0007c783          	lbu	a5,0(a5)
ffffffe000204340:	00078713          	mv	a4,a5
ffffffe000204344:	03000793          	li	a5,48
ffffffe000204348:	04e7f663          	bgeu	a5,a4,ffffffe000204394 <vprintfmt+0x198>
ffffffe00020434c:	f5043783          	ld	a5,-176(s0)
ffffffe000204350:	0007c783          	lbu	a5,0(a5)
ffffffe000204354:	00078713          	mv	a4,a5
ffffffe000204358:	03900793          	li	a5,57
ffffffe00020435c:	02e7ec63          	bltu	a5,a4,ffffffe000204394 <vprintfmt+0x198>
                flags.width = strtol(fmt, (char **)&fmt, 10);
ffffffe000204360:	f5043783          	ld	a5,-176(s0)
ffffffe000204364:	f5040713          	addi	a4,s0,-176
ffffffe000204368:	00a00613          	li	a2,10
ffffffe00020436c:	00070593          	mv	a1,a4
ffffffe000204370:	00078513          	mv	a0,a5
ffffffe000204374:	88dff0ef          	jal	ffffffe000203c00 <strtol>
ffffffe000204378:	00050793          	mv	a5,a0
ffffffe00020437c:	0007879b          	sext.w	a5,a5
ffffffe000204380:	f8f42423          	sw	a5,-120(s0)
                fmt--;
ffffffe000204384:	f5043783          	ld	a5,-176(s0)
ffffffe000204388:	fff78793          	addi	a5,a5,-1
ffffffe00020438c:	f4f43823          	sd	a5,-176(s0)
ffffffe000204390:	62c0006f          	j	ffffffe0002049bc <vprintfmt+0x7c0>
            } else if (*fmt == '.') {
ffffffe000204394:	f5043783          	ld	a5,-176(s0)
ffffffe000204398:	0007c783          	lbu	a5,0(a5)
ffffffe00020439c:	00078713          	mv	a4,a5
ffffffe0002043a0:	02e00793          	li	a5,46
ffffffe0002043a4:	06f71863          	bne	a4,a5,ffffffe000204414 <vprintfmt+0x218>
                fmt++;
ffffffe0002043a8:	f5043783          	ld	a5,-176(s0)
ffffffe0002043ac:	00178793          	addi	a5,a5,1
ffffffe0002043b0:	f4f43823          	sd	a5,-176(s0)
                if (*fmt == '*') {
ffffffe0002043b4:	f5043783          	ld	a5,-176(s0)
ffffffe0002043b8:	0007c783          	lbu	a5,0(a5)
ffffffe0002043bc:	00078713          	mv	a4,a5
ffffffe0002043c0:	02a00793          	li	a5,42
ffffffe0002043c4:	00f71e63          	bne	a4,a5,ffffffe0002043e0 <vprintfmt+0x1e4>
                    flags.prec = va_arg(vl, int);
ffffffe0002043c8:	f4843783          	ld	a5,-184(s0)
ffffffe0002043cc:	00878713          	addi	a4,a5,8
ffffffe0002043d0:	f4e43423          	sd	a4,-184(s0)
ffffffe0002043d4:	0007a783          	lw	a5,0(a5)
ffffffe0002043d8:	f8f42623          	sw	a5,-116(s0)
ffffffe0002043dc:	5e00006f          	j	ffffffe0002049bc <vprintfmt+0x7c0>
                } else {
                    flags.prec = strtol(fmt, (char **)&fmt, 10);
ffffffe0002043e0:	f5043783          	ld	a5,-176(s0)
ffffffe0002043e4:	f5040713          	addi	a4,s0,-176
ffffffe0002043e8:	00a00613          	li	a2,10
ffffffe0002043ec:	00070593          	mv	a1,a4
ffffffe0002043f0:	00078513          	mv	a0,a5
ffffffe0002043f4:	80dff0ef          	jal	ffffffe000203c00 <strtol>
ffffffe0002043f8:	00050793          	mv	a5,a0
ffffffe0002043fc:	0007879b          	sext.w	a5,a5
ffffffe000204400:	f8f42623          	sw	a5,-116(s0)
                    fmt--;
ffffffe000204404:	f5043783          	ld	a5,-176(s0)
ffffffe000204408:	fff78793          	addi	a5,a5,-1
ffffffe00020440c:	f4f43823          	sd	a5,-176(s0)
ffffffe000204410:	5ac0006f          	j	ffffffe0002049bc <vprintfmt+0x7c0>
                }
            } else if (*fmt == 'x' || *fmt == 'X' || *fmt == 'p') {
ffffffe000204414:	f5043783          	ld	a5,-176(s0)
ffffffe000204418:	0007c783          	lbu	a5,0(a5)
ffffffe00020441c:	00078713          	mv	a4,a5
ffffffe000204420:	07800793          	li	a5,120
ffffffe000204424:	02f70663          	beq	a4,a5,ffffffe000204450 <vprintfmt+0x254>
ffffffe000204428:	f5043783          	ld	a5,-176(s0)
ffffffe00020442c:	0007c783          	lbu	a5,0(a5)
ffffffe000204430:	00078713          	mv	a4,a5
ffffffe000204434:	05800793          	li	a5,88
ffffffe000204438:	00f70c63          	beq	a4,a5,ffffffe000204450 <vprintfmt+0x254>
ffffffe00020443c:	f5043783          	ld	a5,-176(s0)
ffffffe000204440:	0007c783          	lbu	a5,0(a5)
ffffffe000204444:	00078713          	mv	a4,a5
ffffffe000204448:	07000793          	li	a5,112
ffffffe00020444c:	30f71263          	bne	a4,a5,ffffffe000204750 <vprintfmt+0x554>
                bool is_long = *fmt == 'p' || flags.longflag;
ffffffe000204450:	f5043783          	ld	a5,-176(s0)
ffffffe000204454:	0007c783          	lbu	a5,0(a5)
ffffffe000204458:	00078713          	mv	a4,a5
ffffffe00020445c:	07000793          	li	a5,112
ffffffe000204460:	00f70663          	beq	a4,a5,ffffffe00020446c <vprintfmt+0x270>
ffffffe000204464:	f8144783          	lbu	a5,-127(s0)
ffffffe000204468:	00078663          	beqz	a5,ffffffe000204474 <vprintfmt+0x278>
ffffffe00020446c:	00100793          	li	a5,1
ffffffe000204470:	0080006f          	j	ffffffe000204478 <vprintfmt+0x27c>
ffffffe000204474:	00000793          	li	a5,0
ffffffe000204478:	faf403a3          	sb	a5,-89(s0)
ffffffe00020447c:	fa744783          	lbu	a5,-89(s0)
ffffffe000204480:	0017f793          	andi	a5,a5,1
ffffffe000204484:	faf403a3          	sb	a5,-89(s0)

                unsigned long num = is_long ? va_arg(vl, unsigned long) : va_arg(vl, unsigned int);
ffffffe000204488:	fa744783          	lbu	a5,-89(s0)
ffffffe00020448c:	0ff7f793          	zext.b	a5,a5
ffffffe000204490:	00078c63          	beqz	a5,ffffffe0002044a8 <vprintfmt+0x2ac>
ffffffe000204494:	f4843783          	ld	a5,-184(s0)
ffffffe000204498:	00878713          	addi	a4,a5,8
ffffffe00020449c:	f4e43423          	sd	a4,-184(s0)
ffffffe0002044a0:	0007b783          	ld	a5,0(a5)
ffffffe0002044a4:	01c0006f          	j	ffffffe0002044c0 <vprintfmt+0x2c4>
ffffffe0002044a8:	f4843783          	ld	a5,-184(s0)
ffffffe0002044ac:	00878713          	addi	a4,a5,8
ffffffe0002044b0:	f4e43423          	sd	a4,-184(s0)
ffffffe0002044b4:	0007a783          	lw	a5,0(a5)
ffffffe0002044b8:	02079793          	slli	a5,a5,0x20
ffffffe0002044bc:	0207d793          	srli	a5,a5,0x20
ffffffe0002044c0:	fef43023          	sd	a5,-32(s0)

                if (flags.prec == 0 && num == 0 && *fmt != 'p') {
ffffffe0002044c4:	f8c42783          	lw	a5,-116(s0)
ffffffe0002044c8:	02079463          	bnez	a5,ffffffe0002044f0 <vprintfmt+0x2f4>
ffffffe0002044cc:	fe043783          	ld	a5,-32(s0)
ffffffe0002044d0:	02079063          	bnez	a5,ffffffe0002044f0 <vprintfmt+0x2f4>
ffffffe0002044d4:	f5043783          	ld	a5,-176(s0)
ffffffe0002044d8:	0007c783          	lbu	a5,0(a5)
ffffffe0002044dc:	00078713          	mv	a4,a5
ffffffe0002044e0:	07000793          	li	a5,112
ffffffe0002044e4:	00f70663          	beq	a4,a5,ffffffe0002044f0 <vprintfmt+0x2f4>
                    flags.in_format = false;
ffffffe0002044e8:	f8040023          	sb	zero,-128(s0)
ffffffe0002044ec:	4d00006f          	j	ffffffe0002049bc <vprintfmt+0x7c0>
                    continue;
                }

                // 0x prefix for pointers, or, if # flag is set and non-zero
                bool prefix = *fmt == 'p' || (flags.sharpflag && num != 0);
ffffffe0002044f0:	f5043783          	ld	a5,-176(s0)
ffffffe0002044f4:	0007c783          	lbu	a5,0(a5)
ffffffe0002044f8:	00078713          	mv	a4,a5
ffffffe0002044fc:	07000793          	li	a5,112
ffffffe000204500:	00f70a63          	beq	a4,a5,ffffffe000204514 <vprintfmt+0x318>
ffffffe000204504:	f8244783          	lbu	a5,-126(s0)
ffffffe000204508:	00078a63          	beqz	a5,ffffffe00020451c <vprintfmt+0x320>
ffffffe00020450c:	fe043783          	ld	a5,-32(s0)
ffffffe000204510:	00078663          	beqz	a5,ffffffe00020451c <vprintfmt+0x320>
ffffffe000204514:	00100793          	li	a5,1
ffffffe000204518:	0080006f          	j	ffffffe000204520 <vprintfmt+0x324>
ffffffe00020451c:	00000793          	li	a5,0
ffffffe000204520:	faf40323          	sb	a5,-90(s0)
ffffffe000204524:	fa644783          	lbu	a5,-90(s0)
ffffffe000204528:	0017f793          	andi	a5,a5,1
ffffffe00020452c:	faf40323          	sb	a5,-90(s0)

                int hexdigits = 0;
ffffffe000204530:	fc042e23          	sw	zero,-36(s0)
                const char *xdigits = *fmt == 'X' ? upperxdigits : lowerxdigits;
ffffffe000204534:	f5043783          	ld	a5,-176(s0)
ffffffe000204538:	0007c783          	lbu	a5,0(a5)
ffffffe00020453c:	00078713          	mv	a4,a5
ffffffe000204540:	05800793          	li	a5,88
ffffffe000204544:	00f71863          	bne	a4,a5,ffffffe000204554 <vprintfmt+0x358>
ffffffe000204548:	00001797          	auipc	a5,0x1
ffffffe00020454c:	6a878793          	addi	a5,a5,1704 # ffffffe000205bf0 <upperxdigits.1>
ffffffe000204550:	00c0006f          	j	ffffffe00020455c <vprintfmt+0x360>
ffffffe000204554:	00001797          	auipc	a5,0x1
ffffffe000204558:	6b478793          	addi	a5,a5,1716 # ffffffe000205c08 <lowerxdigits.0>
ffffffe00020455c:	f8f43c23          	sd	a5,-104(s0)
                char buf[2 * sizeof(unsigned long)];

                do {
                    buf[hexdigits++] = xdigits[num & 0xf];
ffffffe000204560:	fe043783          	ld	a5,-32(s0)
ffffffe000204564:	00f7f793          	andi	a5,a5,15
ffffffe000204568:	f9843703          	ld	a4,-104(s0)
ffffffe00020456c:	00f70733          	add	a4,a4,a5
ffffffe000204570:	fdc42783          	lw	a5,-36(s0)
ffffffe000204574:	0017869b          	addiw	a3,a5,1
ffffffe000204578:	fcd42e23          	sw	a3,-36(s0)
ffffffe00020457c:	00074703          	lbu	a4,0(a4)
ffffffe000204580:	ff078793          	addi	a5,a5,-16
ffffffe000204584:	008787b3          	add	a5,a5,s0
ffffffe000204588:	f8e78023          	sb	a4,-128(a5)
                    num >>= 4;
ffffffe00020458c:	fe043783          	ld	a5,-32(s0)
ffffffe000204590:	0047d793          	srli	a5,a5,0x4
ffffffe000204594:	fef43023          	sd	a5,-32(s0)
                } while (num);
ffffffe000204598:	fe043783          	ld	a5,-32(s0)
ffffffe00020459c:	fc0792e3          	bnez	a5,ffffffe000204560 <vprintfmt+0x364>

                if (flags.prec == -1 && flags.zeroflag) {
ffffffe0002045a0:	f8c42783          	lw	a5,-116(s0)
ffffffe0002045a4:	00078713          	mv	a4,a5
ffffffe0002045a8:	fff00793          	li	a5,-1
ffffffe0002045ac:	02f71663          	bne	a4,a5,ffffffe0002045d8 <vprintfmt+0x3dc>
ffffffe0002045b0:	f8344783          	lbu	a5,-125(s0)
ffffffe0002045b4:	02078263          	beqz	a5,ffffffe0002045d8 <vprintfmt+0x3dc>
                    flags.prec = flags.width - 2 * prefix;
ffffffe0002045b8:	f8842703          	lw	a4,-120(s0)
ffffffe0002045bc:	fa644783          	lbu	a5,-90(s0)
ffffffe0002045c0:	0007879b          	sext.w	a5,a5
ffffffe0002045c4:	0017979b          	slliw	a5,a5,0x1
ffffffe0002045c8:	0007879b          	sext.w	a5,a5
ffffffe0002045cc:	40f707bb          	subw	a5,a4,a5
ffffffe0002045d0:	0007879b          	sext.w	a5,a5
ffffffe0002045d4:	f8f42623          	sw	a5,-116(s0)
                }

                for (int i = flags.width - 2 * prefix - __MAX(hexdigits, flags.prec); i > 0; i--) {
ffffffe0002045d8:	f8842703          	lw	a4,-120(s0)
ffffffe0002045dc:	fa644783          	lbu	a5,-90(s0)
ffffffe0002045e0:	0007879b          	sext.w	a5,a5
ffffffe0002045e4:	0017979b          	slliw	a5,a5,0x1
ffffffe0002045e8:	0007879b          	sext.w	a5,a5
ffffffe0002045ec:	40f707bb          	subw	a5,a4,a5
ffffffe0002045f0:	0007871b          	sext.w	a4,a5
ffffffe0002045f4:	fdc42783          	lw	a5,-36(s0)
ffffffe0002045f8:	f8f42a23          	sw	a5,-108(s0)
ffffffe0002045fc:	f8c42783          	lw	a5,-116(s0)
ffffffe000204600:	f8f42823          	sw	a5,-112(s0)
ffffffe000204604:	f9442783          	lw	a5,-108(s0)
ffffffe000204608:	00078593          	mv	a1,a5
ffffffe00020460c:	f9042783          	lw	a5,-112(s0)
ffffffe000204610:	00078613          	mv	a2,a5
ffffffe000204614:	0006069b          	sext.w	a3,a2
ffffffe000204618:	0005879b          	sext.w	a5,a1
ffffffe00020461c:	00f6d463          	bge	a3,a5,ffffffe000204624 <vprintfmt+0x428>
ffffffe000204620:	00058613          	mv	a2,a1
ffffffe000204624:	0006079b          	sext.w	a5,a2
ffffffe000204628:	40f707bb          	subw	a5,a4,a5
ffffffe00020462c:	fcf42c23          	sw	a5,-40(s0)
ffffffe000204630:	0280006f          	j	ffffffe000204658 <vprintfmt+0x45c>
                    putch(' ');
ffffffe000204634:	f5843783          	ld	a5,-168(s0)
ffffffe000204638:	02000513          	li	a0,32
ffffffe00020463c:	000780e7          	jalr	a5
                    ++written;
ffffffe000204640:	fec42783          	lw	a5,-20(s0)
ffffffe000204644:	0017879b          	addiw	a5,a5,1
ffffffe000204648:	fef42623          	sw	a5,-20(s0)
                for (int i = flags.width - 2 * prefix - __MAX(hexdigits, flags.prec); i > 0; i--) {
ffffffe00020464c:	fd842783          	lw	a5,-40(s0)
ffffffe000204650:	fff7879b          	addiw	a5,a5,-1
ffffffe000204654:	fcf42c23          	sw	a5,-40(s0)
ffffffe000204658:	fd842783          	lw	a5,-40(s0)
ffffffe00020465c:	0007879b          	sext.w	a5,a5
ffffffe000204660:	fcf04ae3          	bgtz	a5,ffffffe000204634 <vprintfmt+0x438>
                }

                if (prefix) {
ffffffe000204664:	fa644783          	lbu	a5,-90(s0)
ffffffe000204668:	0ff7f793          	zext.b	a5,a5
ffffffe00020466c:	04078463          	beqz	a5,ffffffe0002046b4 <vprintfmt+0x4b8>
                    putch('0');
ffffffe000204670:	f5843783          	ld	a5,-168(s0)
ffffffe000204674:	03000513          	li	a0,48
ffffffe000204678:	000780e7          	jalr	a5
                    putch(*fmt == 'X' ? 'X' : 'x');
ffffffe00020467c:	f5043783          	ld	a5,-176(s0)
ffffffe000204680:	0007c783          	lbu	a5,0(a5)
ffffffe000204684:	00078713          	mv	a4,a5
ffffffe000204688:	05800793          	li	a5,88
ffffffe00020468c:	00f71663          	bne	a4,a5,ffffffe000204698 <vprintfmt+0x49c>
ffffffe000204690:	05800793          	li	a5,88
ffffffe000204694:	0080006f          	j	ffffffe00020469c <vprintfmt+0x4a0>
ffffffe000204698:	07800793          	li	a5,120
ffffffe00020469c:	f5843703          	ld	a4,-168(s0)
ffffffe0002046a0:	00078513          	mv	a0,a5
ffffffe0002046a4:	000700e7          	jalr	a4
                    written += 2;
ffffffe0002046a8:	fec42783          	lw	a5,-20(s0)
ffffffe0002046ac:	0027879b          	addiw	a5,a5,2
ffffffe0002046b0:	fef42623          	sw	a5,-20(s0)
                }

                for (int i = hexdigits; i < flags.prec; i++) {
ffffffe0002046b4:	fdc42783          	lw	a5,-36(s0)
ffffffe0002046b8:	fcf42a23          	sw	a5,-44(s0)
ffffffe0002046bc:	0280006f          	j	ffffffe0002046e4 <vprintfmt+0x4e8>
                    putch('0');
ffffffe0002046c0:	f5843783          	ld	a5,-168(s0)
ffffffe0002046c4:	03000513          	li	a0,48
ffffffe0002046c8:	000780e7          	jalr	a5
                    ++written;
ffffffe0002046cc:	fec42783          	lw	a5,-20(s0)
ffffffe0002046d0:	0017879b          	addiw	a5,a5,1
ffffffe0002046d4:	fef42623          	sw	a5,-20(s0)
                for (int i = hexdigits; i < flags.prec; i++) {
ffffffe0002046d8:	fd442783          	lw	a5,-44(s0)
ffffffe0002046dc:	0017879b          	addiw	a5,a5,1
ffffffe0002046e0:	fcf42a23          	sw	a5,-44(s0)
ffffffe0002046e4:	f8c42703          	lw	a4,-116(s0)
ffffffe0002046e8:	fd442783          	lw	a5,-44(s0)
ffffffe0002046ec:	0007879b          	sext.w	a5,a5
ffffffe0002046f0:	fce7c8e3          	blt	a5,a4,ffffffe0002046c0 <vprintfmt+0x4c4>
                }

                for (int i = hexdigits - 1; i >= 0; i--) {
ffffffe0002046f4:	fdc42783          	lw	a5,-36(s0)
ffffffe0002046f8:	fff7879b          	addiw	a5,a5,-1
ffffffe0002046fc:	fcf42823          	sw	a5,-48(s0)
ffffffe000204700:	03c0006f          	j	ffffffe00020473c <vprintfmt+0x540>
                    putch(buf[i]);
ffffffe000204704:	fd042783          	lw	a5,-48(s0)
ffffffe000204708:	ff078793          	addi	a5,a5,-16
ffffffe00020470c:	008787b3          	add	a5,a5,s0
ffffffe000204710:	f807c783          	lbu	a5,-128(a5)
ffffffe000204714:	0007871b          	sext.w	a4,a5
ffffffe000204718:	f5843783          	ld	a5,-168(s0)
ffffffe00020471c:	00070513          	mv	a0,a4
ffffffe000204720:	000780e7          	jalr	a5
                    ++written;
ffffffe000204724:	fec42783          	lw	a5,-20(s0)
ffffffe000204728:	0017879b          	addiw	a5,a5,1
ffffffe00020472c:	fef42623          	sw	a5,-20(s0)
                for (int i = hexdigits - 1; i >= 0; i--) {
ffffffe000204730:	fd042783          	lw	a5,-48(s0)
ffffffe000204734:	fff7879b          	addiw	a5,a5,-1
ffffffe000204738:	fcf42823          	sw	a5,-48(s0)
ffffffe00020473c:	fd042783          	lw	a5,-48(s0)
ffffffe000204740:	0007879b          	sext.w	a5,a5
ffffffe000204744:	fc07d0e3          	bgez	a5,ffffffe000204704 <vprintfmt+0x508>
                }

                flags.in_format = false;
ffffffe000204748:	f8040023          	sb	zero,-128(s0)
            } else if (*fmt == 'x' || *fmt == 'X' || *fmt == 'p') {
ffffffe00020474c:	2700006f          	j	ffffffe0002049bc <vprintfmt+0x7c0>
            } else if (*fmt == 'd' || *fmt == 'i' || *fmt == 'u') {
ffffffe000204750:	f5043783          	ld	a5,-176(s0)
ffffffe000204754:	0007c783          	lbu	a5,0(a5)
ffffffe000204758:	00078713          	mv	a4,a5
ffffffe00020475c:	06400793          	li	a5,100
ffffffe000204760:	02f70663          	beq	a4,a5,ffffffe00020478c <vprintfmt+0x590>
ffffffe000204764:	f5043783          	ld	a5,-176(s0)
ffffffe000204768:	0007c783          	lbu	a5,0(a5)
ffffffe00020476c:	00078713          	mv	a4,a5
ffffffe000204770:	06900793          	li	a5,105
ffffffe000204774:	00f70c63          	beq	a4,a5,ffffffe00020478c <vprintfmt+0x590>
ffffffe000204778:	f5043783          	ld	a5,-176(s0)
ffffffe00020477c:	0007c783          	lbu	a5,0(a5)
ffffffe000204780:	00078713          	mv	a4,a5
ffffffe000204784:	07500793          	li	a5,117
ffffffe000204788:	08f71063          	bne	a4,a5,ffffffe000204808 <vprintfmt+0x60c>
                long num = flags.longflag ? va_arg(vl, long) : va_arg(vl, int);
ffffffe00020478c:	f8144783          	lbu	a5,-127(s0)
ffffffe000204790:	00078c63          	beqz	a5,ffffffe0002047a8 <vprintfmt+0x5ac>
ffffffe000204794:	f4843783          	ld	a5,-184(s0)
ffffffe000204798:	00878713          	addi	a4,a5,8
ffffffe00020479c:	f4e43423          	sd	a4,-184(s0)
ffffffe0002047a0:	0007b783          	ld	a5,0(a5)
ffffffe0002047a4:	0140006f          	j	ffffffe0002047b8 <vprintfmt+0x5bc>
ffffffe0002047a8:	f4843783          	ld	a5,-184(s0)
ffffffe0002047ac:	00878713          	addi	a4,a5,8
ffffffe0002047b0:	f4e43423          	sd	a4,-184(s0)
ffffffe0002047b4:	0007a783          	lw	a5,0(a5)
ffffffe0002047b8:	faf43423          	sd	a5,-88(s0)

                written += print_dec_int(putch, num, *fmt != 'u', &flags);
ffffffe0002047bc:	fa843583          	ld	a1,-88(s0)
ffffffe0002047c0:	f5043783          	ld	a5,-176(s0)
ffffffe0002047c4:	0007c783          	lbu	a5,0(a5)
ffffffe0002047c8:	0007871b          	sext.w	a4,a5
ffffffe0002047cc:	07500793          	li	a5,117
ffffffe0002047d0:	40f707b3          	sub	a5,a4,a5
ffffffe0002047d4:	00f037b3          	snez	a5,a5
ffffffe0002047d8:	0ff7f793          	zext.b	a5,a5
ffffffe0002047dc:	f8040713          	addi	a4,s0,-128
ffffffe0002047e0:	00070693          	mv	a3,a4
ffffffe0002047e4:	00078613          	mv	a2,a5
ffffffe0002047e8:	f5843503          	ld	a0,-168(s0)
ffffffe0002047ec:	f08ff0ef          	jal	ffffffe000203ef4 <print_dec_int>
ffffffe0002047f0:	00050793          	mv	a5,a0
ffffffe0002047f4:	fec42703          	lw	a4,-20(s0)
ffffffe0002047f8:	00f707bb          	addw	a5,a4,a5
ffffffe0002047fc:	fef42623          	sw	a5,-20(s0)
                flags.in_format = false;
ffffffe000204800:	f8040023          	sb	zero,-128(s0)
            } else if (*fmt == 'd' || *fmt == 'i' || *fmt == 'u') {
ffffffe000204804:	1b80006f          	j	ffffffe0002049bc <vprintfmt+0x7c0>
            } else if (*fmt == 'n') {
ffffffe000204808:	f5043783          	ld	a5,-176(s0)
ffffffe00020480c:	0007c783          	lbu	a5,0(a5)
ffffffe000204810:	00078713          	mv	a4,a5
ffffffe000204814:	06e00793          	li	a5,110
ffffffe000204818:	04f71c63          	bne	a4,a5,ffffffe000204870 <vprintfmt+0x674>
                if (flags.longflag) {
ffffffe00020481c:	f8144783          	lbu	a5,-127(s0)
ffffffe000204820:	02078463          	beqz	a5,ffffffe000204848 <vprintfmt+0x64c>
                    long *n = va_arg(vl, long *);
ffffffe000204824:	f4843783          	ld	a5,-184(s0)
ffffffe000204828:	00878713          	addi	a4,a5,8
ffffffe00020482c:	f4e43423          	sd	a4,-184(s0)
ffffffe000204830:	0007b783          	ld	a5,0(a5)
ffffffe000204834:	faf43823          	sd	a5,-80(s0)
                    *n = written;
ffffffe000204838:	fec42703          	lw	a4,-20(s0)
ffffffe00020483c:	fb043783          	ld	a5,-80(s0)
ffffffe000204840:	00e7b023          	sd	a4,0(a5)
ffffffe000204844:	0240006f          	j	ffffffe000204868 <vprintfmt+0x66c>
                } else {
                    int *n = va_arg(vl, int *);
ffffffe000204848:	f4843783          	ld	a5,-184(s0)
ffffffe00020484c:	00878713          	addi	a4,a5,8
ffffffe000204850:	f4e43423          	sd	a4,-184(s0)
ffffffe000204854:	0007b783          	ld	a5,0(a5)
ffffffe000204858:	faf43c23          	sd	a5,-72(s0)
                    *n = written;
ffffffe00020485c:	fb843783          	ld	a5,-72(s0)
ffffffe000204860:	fec42703          	lw	a4,-20(s0)
ffffffe000204864:	00e7a023          	sw	a4,0(a5)
                }
                flags.in_format = false;
ffffffe000204868:	f8040023          	sb	zero,-128(s0)
ffffffe00020486c:	1500006f          	j	ffffffe0002049bc <vprintfmt+0x7c0>
            } else if (*fmt == 's') {
ffffffe000204870:	f5043783          	ld	a5,-176(s0)
ffffffe000204874:	0007c783          	lbu	a5,0(a5)
ffffffe000204878:	00078713          	mv	a4,a5
ffffffe00020487c:	07300793          	li	a5,115
ffffffe000204880:	02f71e63          	bne	a4,a5,ffffffe0002048bc <vprintfmt+0x6c0>
                const char *s = va_arg(vl, const char *);
ffffffe000204884:	f4843783          	ld	a5,-184(s0)
ffffffe000204888:	00878713          	addi	a4,a5,8
ffffffe00020488c:	f4e43423          	sd	a4,-184(s0)
ffffffe000204890:	0007b783          	ld	a5,0(a5)
ffffffe000204894:	fcf43023          	sd	a5,-64(s0)
                written += puts_wo_nl(putch, s);
ffffffe000204898:	fc043583          	ld	a1,-64(s0)
ffffffe00020489c:	f5843503          	ld	a0,-168(s0)
ffffffe0002048a0:	dccff0ef          	jal	ffffffe000203e6c <puts_wo_nl>
ffffffe0002048a4:	00050793          	mv	a5,a0
ffffffe0002048a8:	fec42703          	lw	a4,-20(s0)
ffffffe0002048ac:	00f707bb          	addw	a5,a4,a5
ffffffe0002048b0:	fef42623          	sw	a5,-20(s0)
                flags.in_format = false;
ffffffe0002048b4:	f8040023          	sb	zero,-128(s0)
ffffffe0002048b8:	1040006f          	j	ffffffe0002049bc <vprintfmt+0x7c0>
            } else if (*fmt == 'c') {
ffffffe0002048bc:	f5043783          	ld	a5,-176(s0)
ffffffe0002048c0:	0007c783          	lbu	a5,0(a5)
ffffffe0002048c4:	00078713          	mv	a4,a5
ffffffe0002048c8:	06300793          	li	a5,99
ffffffe0002048cc:	02f71e63          	bne	a4,a5,ffffffe000204908 <vprintfmt+0x70c>
                int ch = va_arg(vl, int);
ffffffe0002048d0:	f4843783          	ld	a5,-184(s0)
ffffffe0002048d4:	00878713          	addi	a4,a5,8
ffffffe0002048d8:	f4e43423          	sd	a4,-184(s0)
ffffffe0002048dc:	0007a783          	lw	a5,0(a5)
ffffffe0002048e0:	fcf42623          	sw	a5,-52(s0)
                putch(ch);
ffffffe0002048e4:	fcc42703          	lw	a4,-52(s0)
ffffffe0002048e8:	f5843783          	ld	a5,-168(s0)
ffffffe0002048ec:	00070513          	mv	a0,a4
ffffffe0002048f0:	000780e7          	jalr	a5
                ++written;
ffffffe0002048f4:	fec42783          	lw	a5,-20(s0)
ffffffe0002048f8:	0017879b          	addiw	a5,a5,1
ffffffe0002048fc:	fef42623          	sw	a5,-20(s0)
                flags.in_format = false;
ffffffe000204900:	f8040023          	sb	zero,-128(s0)
ffffffe000204904:	0b80006f          	j	ffffffe0002049bc <vprintfmt+0x7c0>
            } else if (*fmt == '%') {
ffffffe000204908:	f5043783          	ld	a5,-176(s0)
ffffffe00020490c:	0007c783          	lbu	a5,0(a5)
ffffffe000204910:	00078713          	mv	a4,a5
ffffffe000204914:	02500793          	li	a5,37
ffffffe000204918:	02f71263          	bne	a4,a5,ffffffe00020493c <vprintfmt+0x740>
                putch('%');
ffffffe00020491c:	f5843783          	ld	a5,-168(s0)
ffffffe000204920:	02500513          	li	a0,37
ffffffe000204924:	000780e7          	jalr	a5
                ++written;
ffffffe000204928:	fec42783          	lw	a5,-20(s0)
ffffffe00020492c:	0017879b          	addiw	a5,a5,1
ffffffe000204930:	fef42623          	sw	a5,-20(s0)
                flags.in_format = false;
ffffffe000204934:	f8040023          	sb	zero,-128(s0)
ffffffe000204938:	0840006f          	j	ffffffe0002049bc <vprintfmt+0x7c0>
            } else {
                putch(*fmt);
ffffffe00020493c:	f5043783          	ld	a5,-176(s0)
ffffffe000204940:	0007c783          	lbu	a5,0(a5)
ffffffe000204944:	0007871b          	sext.w	a4,a5
ffffffe000204948:	f5843783          	ld	a5,-168(s0)
ffffffe00020494c:	00070513          	mv	a0,a4
ffffffe000204950:	000780e7          	jalr	a5
                ++written;
ffffffe000204954:	fec42783          	lw	a5,-20(s0)
ffffffe000204958:	0017879b          	addiw	a5,a5,1
ffffffe00020495c:	fef42623          	sw	a5,-20(s0)
                flags.in_format = false;
ffffffe000204960:	f8040023          	sb	zero,-128(s0)
ffffffe000204964:	0580006f          	j	ffffffe0002049bc <vprintfmt+0x7c0>
            }
        } else if (*fmt == '%') {
ffffffe000204968:	f5043783          	ld	a5,-176(s0)
ffffffe00020496c:	0007c783          	lbu	a5,0(a5)
ffffffe000204970:	00078713          	mv	a4,a5
ffffffe000204974:	02500793          	li	a5,37
ffffffe000204978:	02f71063          	bne	a4,a5,ffffffe000204998 <vprintfmt+0x79c>
            flags = (struct fmt_flags) {.in_format = true, .prec = -1};
ffffffe00020497c:	f8043023          	sd	zero,-128(s0)
ffffffe000204980:	f8043423          	sd	zero,-120(s0)
ffffffe000204984:	00100793          	li	a5,1
ffffffe000204988:	f8f40023          	sb	a5,-128(s0)
ffffffe00020498c:	fff00793          	li	a5,-1
ffffffe000204990:	f8f42623          	sw	a5,-116(s0)
ffffffe000204994:	0280006f          	j	ffffffe0002049bc <vprintfmt+0x7c0>
        } else {
            putch(*fmt);
ffffffe000204998:	f5043783          	ld	a5,-176(s0)
ffffffe00020499c:	0007c783          	lbu	a5,0(a5)
ffffffe0002049a0:	0007871b          	sext.w	a4,a5
ffffffe0002049a4:	f5843783          	ld	a5,-168(s0)
ffffffe0002049a8:	00070513          	mv	a0,a4
ffffffe0002049ac:	000780e7          	jalr	a5
            ++written;
ffffffe0002049b0:	fec42783          	lw	a5,-20(s0)
ffffffe0002049b4:	0017879b          	addiw	a5,a5,1
ffffffe0002049b8:	fef42623          	sw	a5,-20(s0)
    for (; *fmt; fmt++) {
ffffffe0002049bc:	f5043783          	ld	a5,-176(s0)
ffffffe0002049c0:	00178793          	addi	a5,a5,1
ffffffe0002049c4:	f4f43823          	sd	a5,-176(s0)
ffffffe0002049c8:	f5043783          	ld	a5,-176(s0)
ffffffe0002049cc:	0007c783          	lbu	a5,0(a5)
ffffffe0002049d0:	84079ce3          	bnez	a5,ffffffe000204228 <vprintfmt+0x2c>
        }
    }

    return written;
ffffffe0002049d4:	fec42783          	lw	a5,-20(s0)
}
ffffffe0002049d8:	00078513          	mv	a0,a5
ffffffe0002049dc:	0b813083          	ld	ra,184(sp)
ffffffe0002049e0:	0b013403          	ld	s0,176(sp)
ffffffe0002049e4:	0c010113          	addi	sp,sp,192
ffffffe0002049e8:	00008067          	ret

ffffffe0002049ec <printk>:

int printk(const char* s, ...) {
ffffffe0002049ec:	f9010113          	addi	sp,sp,-112
ffffffe0002049f0:	02113423          	sd	ra,40(sp)
ffffffe0002049f4:	02813023          	sd	s0,32(sp)
ffffffe0002049f8:	03010413          	addi	s0,sp,48
ffffffe0002049fc:	fca43c23          	sd	a0,-40(s0)
ffffffe000204a00:	00b43423          	sd	a1,8(s0)
ffffffe000204a04:	00c43823          	sd	a2,16(s0)
ffffffe000204a08:	00d43c23          	sd	a3,24(s0)
ffffffe000204a0c:	02e43023          	sd	a4,32(s0)
ffffffe000204a10:	02f43423          	sd	a5,40(s0)
ffffffe000204a14:	03043823          	sd	a6,48(s0)
ffffffe000204a18:	03143c23          	sd	a7,56(s0)
    int res = 0;
ffffffe000204a1c:	fe042623          	sw	zero,-20(s0)
    va_list vl;
    va_start(vl, s);
ffffffe000204a20:	04040793          	addi	a5,s0,64
ffffffe000204a24:	fcf43823          	sd	a5,-48(s0)
ffffffe000204a28:	fd043783          	ld	a5,-48(s0)
ffffffe000204a2c:	fc878793          	addi	a5,a5,-56
ffffffe000204a30:	fef43023          	sd	a5,-32(s0)
    res = vprintfmt(putc, s, vl);
ffffffe000204a34:	fe043783          	ld	a5,-32(s0)
ffffffe000204a38:	00078613          	mv	a2,a5
ffffffe000204a3c:	fd843583          	ld	a1,-40(s0)
ffffffe000204a40:	fffff517          	auipc	a0,0xfffff
ffffffe000204a44:	11850513          	addi	a0,a0,280 # ffffffe000203b58 <putc>
ffffffe000204a48:	fb4ff0ef          	jal	ffffffe0002041fc <vprintfmt>
ffffffe000204a4c:	00050793          	mv	a5,a0
ffffffe000204a50:	fef42623          	sw	a5,-20(s0)
    va_end(vl);
    return res;
ffffffe000204a54:	fec42783          	lw	a5,-20(s0)
}
ffffffe000204a58:	00078513          	mv	a0,a5
ffffffe000204a5c:	02813083          	ld	ra,40(sp)
ffffffe000204a60:	02013403          	ld	s0,32(sp)
ffffffe000204a64:	07010113          	addi	sp,sp,112
ffffffe000204a68:	00008067          	ret

ffffffe000204a6c <srand>:
#include "stdint.h"
#include "stdlib.h"

static uint64_t seed;

void srand(unsigned s) {
ffffffe000204a6c:	fe010113          	addi	sp,sp,-32
ffffffe000204a70:	00813c23          	sd	s0,24(sp)
ffffffe000204a74:	02010413          	addi	s0,sp,32
ffffffe000204a78:	00050793          	mv	a5,a0
ffffffe000204a7c:	fef42623          	sw	a5,-20(s0)
    seed = s - 1;
ffffffe000204a80:	fec42783          	lw	a5,-20(s0)
ffffffe000204a84:	fff7879b          	addiw	a5,a5,-1
ffffffe000204a88:	0007879b          	sext.w	a5,a5
ffffffe000204a8c:	02079713          	slli	a4,a5,0x20
ffffffe000204a90:	02075713          	srli	a4,a4,0x20
ffffffe000204a94:	00006797          	auipc	a5,0x6
ffffffe000204a98:	58478793          	addi	a5,a5,1412 # ffffffe00020b018 <seed>
ffffffe000204a9c:	00e7b023          	sd	a4,0(a5)
}
ffffffe000204aa0:	00000013          	nop
ffffffe000204aa4:	01813403          	ld	s0,24(sp)
ffffffe000204aa8:	02010113          	addi	sp,sp,32
ffffffe000204aac:	00008067          	ret

ffffffe000204ab0 <rand>:

int rand(void) {
ffffffe000204ab0:	ff010113          	addi	sp,sp,-16
ffffffe000204ab4:	00813423          	sd	s0,8(sp)
ffffffe000204ab8:	01010413          	addi	s0,sp,16
    seed = 6364136223846793005ULL * seed + 1;
ffffffe000204abc:	00006797          	auipc	a5,0x6
ffffffe000204ac0:	55c78793          	addi	a5,a5,1372 # ffffffe00020b018 <seed>
ffffffe000204ac4:	0007b703          	ld	a4,0(a5)
ffffffe000204ac8:	00001797          	auipc	a5,0x1
ffffffe000204acc:	15878793          	addi	a5,a5,344 # ffffffe000205c20 <lowerxdigits.0+0x18>
ffffffe000204ad0:	0007b783          	ld	a5,0(a5)
ffffffe000204ad4:	02f707b3          	mul	a5,a4,a5
ffffffe000204ad8:	00178713          	addi	a4,a5,1
ffffffe000204adc:	00006797          	auipc	a5,0x6
ffffffe000204ae0:	53c78793          	addi	a5,a5,1340 # ffffffe00020b018 <seed>
ffffffe000204ae4:	00e7b023          	sd	a4,0(a5)
    return seed >> 33;
ffffffe000204ae8:	00006797          	auipc	a5,0x6
ffffffe000204aec:	53078793          	addi	a5,a5,1328 # ffffffe00020b018 <seed>
ffffffe000204af0:	0007b783          	ld	a5,0(a5)
ffffffe000204af4:	0217d793          	srli	a5,a5,0x21
ffffffe000204af8:	0007879b          	sext.w	a5,a5
}
ffffffe000204afc:	00078513          	mv	a0,a5
ffffffe000204b00:	00813403          	ld	s0,8(sp)
ffffffe000204b04:	01010113          	addi	sp,sp,16
ffffffe000204b08:	00008067          	ret

ffffffe000204b0c <memset>:
#include "string.h"
#include "stdint.h"

void *memset(void *dest, int c, uint64_t n) {
ffffffe000204b0c:	fc010113          	addi	sp,sp,-64
ffffffe000204b10:	02813c23          	sd	s0,56(sp)
ffffffe000204b14:	04010413          	addi	s0,sp,64
ffffffe000204b18:	fca43c23          	sd	a0,-40(s0)
ffffffe000204b1c:	00058793          	mv	a5,a1
ffffffe000204b20:	fcc43423          	sd	a2,-56(s0)
ffffffe000204b24:	fcf42a23          	sw	a5,-44(s0)
    char *s = (char *)dest;
ffffffe000204b28:	fd843783          	ld	a5,-40(s0)
ffffffe000204b2c:	fef43023          	sd	a5,-32(s0)
    for (uint64_t i = 0; i < n; ++i) {
ffffffe000204b30:	fe043423          	sd	zero,-24(s0)
ffffffe000204b34:	0280006f          	j	ffffffe000204b5c <memset+0x50>
        s[i] = c;
ffffffe000204b38:	fe043703          	ld	a4,-32(s0)
ffffffe000204b3c:	fe843783          	ld	a5,-24(s0)
ffffffe000204b40:	00f707b3          	add	a5,a4,a5
ffffffe000204b44:	fd442703          	lw	a4,-44(s0)
ffffffe000204b48:	0ff77713          	zext.b	a4,a4
ffffffe000204b4c:	00e78023          	sb	a4,0(a5)
    for (uint64_t i = 0; i < n; ++i) {
ffffffe000204b50:	fe843783          	ld	a5,-24(s0)
ffffffe000204b54:	00178793          	addi	a5,a5,1
ffffffe000204b58:	fef43423          	sd	a5,-24(s0)
ffffffe000204b5c:	fe843703          	ld	a4,-24(s0)
ffffffe000204b60:	fc843783          	ld	a5,-56(s0)
ffffffe000204b64:	fcf76ae3          	bltu	a4,a5,ffffffe000204b38 <memset+0x2c>
    }
    return dest;
ffffffe000204b68:	fd843783          	ld	a5,-40(s0)
}
ffffffe000204b6c:	00078513          	mv	a0,a5
ffffffe000204b70:	03813403          	ld	s0,56(sp)
ffffffe000204b74:	04010113          	addi	sp,sp,64
ffffffe000204b78:	00008067          	ret

ffffffe000204b7c <memcpy>:

void *memcpy(void *dest, void *source,uint64_t n){
ffffffe000204b7c:	fc010113          	addi	sp,sp,-64
ffffffe000204b80:	02813c23          	sd	s0,56(sp)
ffffffe000204b84:	04010413          	addi	s0,sp,64
ffffffe000204b88:	fca43c23          	sd	a0,-40(s0)
ffffffe000204b8c:	fcb43823          	sd	a1,-48(s0)
ffffffe000204b90:	fcc43423          	sd	a2,-56(s0)
    for(int i=0;i<n;i++){
ffffffe000204b94:	fe042623          	sw	zero,-20(s0)
ffffffe000204b98:	0300006f          	j	ffffffe000204bc8 <memcpy+0x4c>
        ((char*)dest)[i] = ((char*)source)[i];
ffffffe000204b9c:	fec42783          	lw	a5,-20(s0)
ffffffe000204ba0:	fd043703          	ld	a4,-48(s0)
ffffffe000204ba4:	00f70733          	add	a4,a4,a5
ffffffe000204ba8:	fec42783          	lw	a5,-20(s0)
ffffffe000204bac:	fd843683          	ld	a3,-40(s0)
ffffffe000204bb0:	00f687b3          	add	a5,a3,a5
ffffffe000204bb4:	00074703          	lbu	a4,0(a4)
ffffffe000204bb8:	00e78023          	sb	a4,0(a5)
    for(int i=0;i<n;i++){
ffffffe000204bbc:	fec42783          	lw	a5,-20(s0)
ffffffe000204bc0:	0017879b          	addiw	a5,a5,1
ffffffe000204bc4:	fef42623          	sw	a5,-20(s0)
ffffffe000204bc8:	fec42783          	lw	a5,-20(s0)
ffffffe000204bcc:	fc843703          	ld	a4,-56(s0)
ffffffe000204bd0:	fce7e6e3          	bltu	a5,a4,ffffffe000204b9c <memcpy+0x20>
    }
    return dest;
ffffffe000204bd4:	fd843783          	ld	a5,-40(s0)
ffffffe000204bd8:	00078513          	mv	a0,a5
ffffffe000204bdc:	03813403          	ld	s0,56(sp)
ffffffe000204be0:	04010113          	addi	sp,sp,64
ffffffe000204be4:	00008067          	ret
