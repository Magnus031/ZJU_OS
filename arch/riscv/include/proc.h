#ifndef __PROC_H__
#define __PROC_H__

#include "stdint.h"

#if TEST_SCHED
//#define NR_TASKS (1 + 4)    // 测试时线程数量
#define NR_TASKS ( 1 + 8 )
#else
#define NR_TASKS (1 + 8)   // 用于控制最大线程数量（idle 线程 + 31 内核线程）
#endif

#define TASK_RUNNING 0      // 为了简化实验，所有的线程都只有一种状态

#define PRIORITY_MIN 1 // 最小优先级 1 
#define PRIORITY_MAX 10 // 最大优先级 10 



/**
 * VMA virtual memory area 虚拟内存区域 数据结构
 * 我们用链表实现 
 * 同时要实现两个 
 * 1. for each traversal 
 * 2. add / delete;
 * */
struct vm_area_struct {
    struct mm_struct *vm_mm;    // 所属的 mm_struct
    uint64_t vm_start;          // VMA 对应的用户态虚拟地址的开始
    uint64_t vm_end;            // VMA 对应的用户态虚拟地址的结束
    struct vm_area_struct *vm_next, *vm_prev;   // 链表指针
    uint64_t vm_flags;          // VMA 对应的 flags
    // struct file *vm_file;    // 对应的文件（目前还没实现，而且我们只有一个 uapp 所以暂不需要）
    uint64_t vm_pgoff;          // 如果对应了一个文件，那么这块 VMA 起始地址对应的文件内容相对文件起始位置的偏移量
    uint64_t vm_filesz;         // 对应的文件内容的长度
};
/** mm_struct 
 *  memory_manager 
*/
struct mm_struct {
    struct vm_area_struct *mmap;
};


/* 线程状态段数据结构 */
// 这个数据结构保存了线程在上下文切换时的关键寄存器状态
struct thread_struct {
    uint64_t ra; // (offset 8) Return Address 
    uint64_t sp; // (offset 8) Stack Pointer 栈指针的位置
    uint64_t s[12]; // (offset 8*12) s0 - s11 寄存器的值
    /**
      * sepc -> represents the current PC which run across the interruption;
      * sstatus -> represents the state of the Process before content-switch;
      *     1. SPIE and SIE : 
      *         - When it is in the user mode, the SIE = 1 represents that it can be trapped;
      *             when the trap happened, SPIE(Supervisor previous Interruption Enabled) will store the SIE 
      *             now, and the SIE will turn 0;
      *         - After finish the interruption, it SIE will get back to SPIE's value.(It can return to can be interruption)
      *      2. SPP : 
      *           indicates the privilege level of the process before be interrupted. 
      *           when a trap is taken, SPP is set to 0 if the trap originated from user mode.
      *               if an SRET instruction is executed to reture from the trap handler,the priviledge level will set to User mode
      *                   if the SPP bit is 0.
      *           when a trap is taken, SPP is set to 1 if the trap originated from s mode.       
      *      3.SUM  :  也就是修饰的是S模式下是否能够修饰user page.
      *            When Sum = 0,S-mode memory accesses to pages that are accessible by U-mode will fault. 
      * 
      * 
      */             
    uint64_t sepc; // store the pc that
    uint64_t sstatus;
    uint64_t sscratch; // The sscratch register is to avoid overwriting user registers before saving them.
};

/* 线程数据结构 */
struct task_struct {
    uint64_t state;     // (offset 8)线程状态
    uint64_t counter;   // (offset 8)运行剩余时间
    uint64_t priority;  // (offset 8)运行优先级 1 最低 10 最高
    uint64_t pid;       // (offset 8)线程 id

    struct thread_struct thread;
    uint64_t *pgd; // used for store the page table for the user space;
    struct mm_struct mm;
};

/*used to load elf into the memory*/
static uint64_t load_program(struct task_struct* task);

/**
 * @todo lab5 
 * VMA init
 * 
*/
static uint64_t VMA_init(struct task_struct* task);

/* 线程初始化，创建 NR_TASKS 个线程 */
void task_init();

/* 在时钟中断处理中被调用，用于判断是否需要进行调度 */
void do_timer();

/* 调度程序，选择出下一个运行的线程 */
void schedule();

/* 线程切换入口函数 */
void switch_to(struct task_struct *next);

/* dummy funciton: 一个循环程序，循环输出自己的 pid 以及一个自增的局部变量 */
void dummy();

/* test switch */
void test_switch();

/*
* @mm       : current thread's mm_struct
* @addr     : the va to look up
*
* @return   : the VMA if found or NULL if not found
*/
struct vm_area_struct *find_vma(struct mm_struct *mm, uint64_t addr);



/*
* @mm       : current thread's mm_struct
* @addr     : the suggested va to map
* @len      : memory size to map
* @vm_pgoff : phdr->p_offset
* @vm_filesz: phdr->p_filesz
* @flags    : flags for the new VMA
*
* @return   : start va
*/
uint64_t do_mmap(struct mm_struct *mm, uint64_t addr, uint64_t len, uint64_t vm_pgoff, uint64_t vm_filesz, uint64_t flags);



#endif
