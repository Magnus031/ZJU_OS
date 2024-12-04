.extern start_kernel
.extern mm_init
.extern setup_vm
.extern task_init
.extern setup_vm_final
    .section .text.init
    .globl _start
_start:
    # ------------------
    # - your code here -
    # ------------------
    # 将 CPU 的 Program Counter 移动到内存中 bootloader 的起始地址
    la sp , boot_stack_top

    # set for the virtual memory
    call setup_vm
    call relocate

    # 调用 mm_init 函数来初始化内存管理系统;
    call mm_init
    # 分配最终的虚拟地址
    call setup_vm_final
    call task_init

    # (previous) initialize stack 初始化栈
    # set stvec = _trap 开始处理_trap部分 存入发生_trap的状态信息
    la t0 , _traps 
    csrw stvec , t0

    # set sie[STIE] = 1 说明可以进行响应对应的中断状态
    li t0, 0x20
    csrs sie,t0

    # 设置第一次时钟中断
    rdtime a0
    li t1 , 10000000
    add a0, a0, t1 
    # call sbi_set_timer(a0) a0 表示的是我们需要设置中断的时间
    call sbi_set_timer

    # sstatus[SIE] = 1
    # li t0, 0x2
    # csrs sstatus, t0

    # call start_kernel
    # 跳转到 start_kernel 函数 
    jal start_kernel 
    # 进行循环直到start_kernel停机返回
    j .



relocate:
    # relocate is used to set for satp register;
    # set ra = ra + PA2VA_OFFSET
    # set sp = sp + PA2VA_OFFSET (If you have set the sp before)

    ###################### 
    #   YOUR CODE HERE   #
    ######################

    # set for the PA2VA_OFFSET = VM_START - PHY_START;
    li t1, 0xffffffdf80000000

    add ra,ra,t1
    add sp,sp,t1


    # need a fence to ensure the new translations are in use
    # everytime we change the page table we all need to flush the TLB cache;
    # otherwise, it will use the old mapping in the TLB cache 
    # especially, nowtime we have nooooot set the ASID correctly
    # it will cause some awful influences;
    
    sfence.vma zero, zero

    # set satp with early_pgtbl

    ###################### 
    #   YOUR CODE HERE   #
    ######################
    # here is the part for set the satp register;

    # 1. Mode 0111 sv39
    # 2. ASID defualt -> 0000000
    # 3. PPN from the early_ptb
    # satp pointer to the first page table

    la t2, early_pgtbl
    srl t2, t2, 12
    li  t3, 0x8000000000000000
    or  t2, t2, t3
    csrw satp, t2

    ret

    


    .section .bss.stack
    .globl boot_stack
boot_stack:
    # We define the first Size is 4KB
    .space 4096 # <-- change to your stack size 

    .globl boot_stack_top
boot_stack_top: