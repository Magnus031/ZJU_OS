#include "mm.h"
#include "defs.h"
#include "proc.h"
#include "stdlib.h"
#include "printk.h"
// 我们引入ELF文件
#include "elf.h"
#include "string.h"

extern void __dummy();
extern void __switch_to(struct task_struct* prev, struct task_struct* next);

struct task_struct *idle;           // idle process
struct task_struct *current;        // 指向当前运行线程的 task_struct
struct task_struct *task[NR_TASKS]; // 线程数组，所有的线程都保存在此

//  申明并使用外部变量;
extern uint64_t swapper_pg_dir[512] __attribute__((__aligned__(0x1000)));
//  我们需要将uapp 所在的页面映射到每个进程中去
extern void create_mapping(uint64_t *pgtbl, uint64_t va, uint64_t pa, uint64_t sz, uint64_t perm);

extern char _sramdisk[],_eramdisk[];

// used to record the current process number in the stack; 
uint64_t tasks_number = 1;

/**
 * @todo VMA init 
 * we do init of the VMA task.
 * @param task the process waited for initing
 * 
 * For Segment part 
 * [phdr->p_vaddr ] -> offset phdr->p_offset 
 *  
 * For user stack [USER_END-PGSIZE,USER_END] VM_READ|VM_WRITE 
 * 
*/
static uint64_t VMA_init(struct task_struct* task){
    // from the `_sramdisk` is the address of elf life
    Elf64_Ehdr *ehdr = (Elf64_Ehdr *)_sramdisk;
    // get the programs headers
    Elf64_Phdr *phdrs = (Elf64_Phdr *)(_sramdisk+ehdr->e_phoff);
    for(int i=0;i<ehdr->e_phnum;i++){
        Elf64_Phdr *phdr = phdrs + i;
        if(phdr->p_type == PT_LOAD){
            uint64_t VA = phdr->p_vaddr;
            uint64_t offset = phdr->p_offset;
            uint64_t page_offset = VA&0xFFF;
            uint64_t file_size = phdr->p_filesz;
            uint64_t memory_size = phdr->p_memsz;
            uint64_t flags = phdr->p_flags;
            // phdr->flags R W X -> x w r p
            uint64_t perm = ((phdr->p_flags&0x2)<<1)|((phdr->p_flags&0x4)>>1)|((phdr->p_flags&0x1)<<3);

            // set the valid virtual memory space for them.
            Log(BLUE"We have created the valid VMA mmap [%016lx,%016lx),perm = %d",PGROUNDDOWN(VA),PGROUNDDOWN(VA+memory_size),perm,CLEAR);
            do_mmap(&task->mm,VA,memory_size,offset,file_size,perm);

        }
    }
    // set for the user stack for them;
    /* flags : ->  */
    do_mmap(&task->mm,USER_END-PGSIZE,PGSIZE,0,0,0x7);
    // store 
    task->thread.sepc = ehdr->e_entry;
    return 0;
}


/**
 * @param task the program which need to load into the memory
*/
static uint64_t load_program(struct task_struct* task){
    // from the `_sramdisk` is the address of elf file
    Elf64_Ehdr *ehdr = (Elf64_Ehdr *)_sramdisk;
    // get the programs headers 
    Elf64_Phdr *phdrs = (Elf64_Phdr *)(_sramdisk + ehdr->e_phoff);
    for (int i = 0; i < ehdr->e_phnum; ++i) {
        Elf64_Phdr *phdr = phdrs + i;
        // we just need to deal with the PT_LOAD part;
        if (phdr->p_type == PT_LOAD) {
            // alloc space and copy content
            // do mapping
            // code...
            // used to find the progrem content;
            // the start address in the virtual address
            uint64_t VA = phdr->p_vaddr;
            uint64_t page_offset = VA&0xFFF;
            uint64_t file_size = phdr->p_filesz;
            // in order to supplement 0;
            uint64_t memory_size = phdr->p_memsz;
            uint64_t offset = phdr->p_offset;
            // the physical address
            char* PVA = (char*)alloc_pages((memory_size-1+PGSIZE)/PGSIZE);
            char* content = (char*)(_sramdisk+offset);
            // copy for the content;
            for(int i =0;i<memory_size;i++){
                    if(i<file_size)
                        PVA[page_offset+i] = content[i];
                    else 
                        PVA[page_offset+i] = 0x0;
            }
            //memset(PA+phdr->p_filesz,0,memory_size-file_size);
            uint64_t perm = 0x0;
            // 权限 U & V
            perm |= 1<<4|1<<0;
            // for R
            perm |= (phdr->p_flags&0x4) >>1;
            // for W 
            perm |= (phdr->p_flags&0x2) <<1;
            // for X execute
            perm |= (phdr->p_flags&0x1) <<3;

            create_mapping(task->pgd,VA,(uint64_t)PVA-PA2VA_OFFSET,memory_size,perm);
        }
    }
    uint64_t user_stack = (uint64_t)alloc_page();
    create_mapping(task->pgd,USER_END-PGSIZE,user_stack-PA2VA_OFFSET,PGSIZE,0x17);
    task->thread.sepc = ehdr->e_entry;
}


/**
 * Here we consider the case that page fault;
 * 1. the demanding page is not existed;
 * -> check for the try for let the page accessed validly;
 *     1. you have no permission to get the page in the VMA table;
 *     2. the address Bad address, is not in the virtual address we set
 * terminated the process;
 * 
*/
/**
 * @todo Lab5: we consider the demanding paging way;
 * Only the time that we need to execute this process, that we start loading the page into the memory;
 * 
 * in the task_init we do no create mapping. only when the process is executed that we do page mapping for them.
 * 
 * 
 *  - sepc -> store the PC where the instructions happened the traps;
 *  - stval -> store the VA, which page is not paging valid;
*/
/**
 * @todo here we modify the task_init's logic;
 * in Lab3-4 we have not used the alloc and creating maps in the task_init period;
 * - The reason that ,we do this is to use the demanding paging avoiding the case that cause page waste;
 * - so at this part,we directly set the VMA for data/text and user stack; 
 * 
 * 
*/
void task_init() {
    srand(2024);

    // 1. 调用 kalloc() 为 idle 分配一个物理页
    // 2. 设置 state 为 TASK_RUNNING;
    // 3. 由于 idle 不参与调度，可以将其 counter / priority 设置为 0
    // 4. 设置 idle 的 pid 为 0
    // 5. 将 current 和 task[0] 指向 idle

    /* YOUR CODE HERE */
    // Part one we need to init the idle process;
    // initial part;
    Log(PURPLE "the number of tasks is %d",tasks_number,CLEAR);
    Log(RED "We start to task_init" CLEAR);
    idle = (struct task_struct*)kalloc(); // 分配一个物理页面; idle 是指一个闲置的进程;
    idle->state = TASK_RUNNING;
    idle->counter = 0;
    idle->priority = 0;
    idle->pid = 0;
    for(int i =0;i<12;i++)
        idle->thread.s[i] = 0;

    current = idle;
    task[0] = idle;
    //Log(RED "Finish the init" CLEAR);

    // 1. 参考 idle 的设置，为 task[1] ~ task[NR_TASKS - 1] 进行初始化
    // 2. 其中每个线程的 state 为 TASK_RUNNING, 此外，counter 和 priority 进行如下赋值：
    //     - counter  = 0;
    //     - priority = rand() 产生的随机数（控制范围在 [PRIORITY_MIN, PRIORITY_MAX] 之间）
    // 3. 为 task[1] ~ task[NR_TASKS - 1] 设置 thread_struct 中的 ra 和 sp
    //     - ra 设置为 __dummy（见 4.2.2）的地址
    //     - sp 设置为该线程申请的物理页的高地址
    for(int i=1;i<=tasks_number;i++){
        /**
         * here we only init the first process.
         * and make other process as NULL, because they are waiting for initialization;
        */
        task[i] = (struct task_struct*)kalloc();
        task[i]->state = TASK_RUNNING;
        task[i]->counter = 0;
        int random_number = (rand()%(PRIORITY_MAX-PRIORITY_MIN+1))+PRIORITY_MIN;
        task[i]->priority = random_number;
        task[i]->pid = i;
        //Log(GREEN "%d %d", i,random_number ,CLEAR);
        task[i]->thread.ra = (uint64_t)__dummy;
        // 这里的 sp 表示的是我们申请了一个页的高地址，也就是 页的开头;
        task[i]->thread.sp = (uint64_t)task[i] + PGSIZE;
        for(int j=0;j<12;j++)
            task[i]->thread.s[j] = 0;     
        /**
         * The initial status :
         *    SPIE = 1 5-bit
         *    SPP = 0 8-bit
         *    SUM = 1 18-bit 
         * */ 
        task[i]->thread.sepc = USER_START;
        task[i]->thread.sscratch = USER_END;
        task[i]->thread.sstatus = 0x40020;   
        // copy for the page table
        task[i]->pgd = (uint64_t*)alloc_page();
        Log(RED "task[1]->pgd: %016lx",task[i]->pgd,CLEAR);
        for(int j=0;j<PGSIZE/8;j++)
            task[i]->pgd[j] = swapper_pg_dir[j];
        /**
         * @todo this part is for load binary into the memory
        */

        // // 将 `app` 所在的页面映射到每个进程的页表中;
        // uint64_t app_size = _eramdisk-_sramdisk;
        // char* uappAddress = (char*)alloc_pages((app_size-1+PGSIZE)/PGSIZE);
        // for(int j=0;j<app_size;j++){
        //     uappAddress[j] = _sramdisk[j];
        // }
        // create_mapping(task[i]->pgd,USER_START,(uint64_t)uappAddress-PA2VA_OFFSET,app_size,0x1F);

        // // set for the user Stack;
        // uint64_t user_stack = (uint64_t)alloc_page();
        // create_mapping(task[i]->pgd,USER_END-PGSIZE,user_stack-PA2VA_OFFSET,PGSIZE,0x17);

        /**
         * @todo
         * this part is for load the program into the memory using elf file;
        */

        //Log(GREEN "i : %d,counter: %lu,priority: %lu",i,task[i]->counter,task[i]->priority,CLEAR);
        //load_program(task[i]);

        /**
         * @todo
         * we change the method for demand-paging
         * 
        */
       task[i]->mm = *(struct mm_struct*)alloc_page();
       memset(&task[i]->mm,0,sizeof(struct mm_struct));
       task[i]->mm.mmap = NULL;
       VMA_init(task[i]);
    }
    //Log(PURPLE "Finish the assign" CLEAR);
    /* YOUR CODE HERE */
    printk("...task_init done!\n");

    //test_switch();
}

#if TEST_SCHED
#define MAX_OUTPUT ((NR_TASKS - 1) * 10)
char tasks_output[MAX_OUTPUT];
int tasks_output_index = 0;
char expected_output[] = "2222222222111111133334222222222211111113";
#include "sbi.h"
#endif

// 简单占用CPU运行的空任务
void dummy() {
    // 大数取模;
    uint64_t MOD = 1000000007;
    uint64_t auto_inc_local_var = 0;
    // 表明是否有新的线程进入，有新的线程进入 说明last_counter = -1;
    int last_counter = -1;
    while (1) {
        // 如果这个线程是第一次接受调度/他的时间片段被改变了，那么我们就需要重新给任务进行调度
        if ((last_counter == -1 || current->counter != last_counter) && current->counter > 0) {
            if (current->counter == 1) {
                --(current->counter);   // forced the counter to be zero if this thread is going to be scheduled
            }                           // in case that the new counter is also 1, leading the information not printed.
            last_counter = current->counter;
            auto_inc_local_var = (auto_inc_local_var + 1) % MOD;
            printk("[PID = %d] is running. auto_inc_local_var = %d\n", current->pid, auto_inc_local_var);
            #if TEST_SCHED
            tasks_output[tasks_output_index++] = current->pid + '0';
            if (tasks_output_index == MAX_OUTPUT) {
                for (int i = 0; i < MAX_OUTPUT; ++i) {
                    if (tasks_output[i] != expected_output[i]) {
                        printk("\033[31mTest failed!\033[0m\n");
                        printk("\033[31m    Expected: %s\033[0m\n", expected_output);
                        printk("\033[31m    Got:      %s\033[0m\n", tasks_output);
                        sbi_system_reset(SBI_SRST_RESET_TYPE_SHUTDOWN, SBI_SRST_RESET_REASON_NONE);
                    }
                }
                printk("\033[32mTest passed!\033[0m\n");
                printk("\033[32m    Output: %s\033[0m\n", expected_output);
                sbi_system_reset(SBI_SRST_RESET_TYPE_SHUTDOWN, SBI_SRST_RESET_REASON_NONE);
            }
            #endif
        }
    }
}

/**
 * @brief use to distinguish whether 2 threads are the same
 * 
*/
void switch_to(struct task_struct* next) {
    // YOUR CODE HERE
    // If next is the same with current thread we do no handler;
    if(next == current)
        return ; 
    
    //Log(RED "priority: %d",next->priority,CLEAR);
    struct task_struct* prev = current;
    current = next; 

    // uint64_t pc;
    // asm volatile ("mv %0, ra" : "=r"(pc));
    // Log(BLUE "Switching from PID = %d, PC = %lx to PID = %d\n", prev->pid, pc, next->pid, CLEAR);

    // Log(RED "2" CLEAR);

    // call __switch_to 函数的目的是切换线程;
    __switch_to(prev,next);

    // Log(RED "1" CLEAR);

    // asm volatile ("mv %0, ra" : "=r"(pc));
    // Log(BLUE "Switching from PID = %d, PC = %lx to PID = %d\n", prev->pid, pc, next->pid, CLEAR);
}

void test_switch(){
    current = task[1];
    Log(RED "Before switching : current pid : %d\n",current->pid);

    switch_to(task[2]);

    Log(RED "After switching : current pid : %d\n",current->pid);

}

void do_timer(){
    //Log(PURPLE "current pid: %lu ",current->pid,CLEAR);
    if(current==idle||current->counter == 0)
        schedule();
    else{
        // 如果对当前线程的运行剩余时间为1，则完成调度;
        if(--current->counter==0)
            schedule();
        else 
            return ;
    }

}

void schedule(){
    // 上面的task_init已经为各个线程赋予了优先级;
    // 找到最大的time-counter;
    int max = 0;
    int next = 0; // the index of the next thread;
    int flag = 0; // flag 为 1 只要出现了全0 那就是 0;
    for(int i=1;i<=tasks_number;i++){
        if(task[i]->counter==0)
            continue;
        if(!flag&&task[i]->counter>0)
            flag = 1;
        // Log(PURPLE "i : %d, counter: %d",i,task[i]->counter,CLEAR);
        // Log(GREEN "max : %d",max,CLEAR);
        // Log(GREEN "next : %d",next,CLEAR);
        if((task[i]->counter)>max){
            max = task[i]->counter;
            next = i;
        }
    }
    // Log(GREEN "shedule next: %d",next,CLEAR);
    // Log(RED " flag : %d",flag,CLEAR);
    if(!flag){
        for(int i=1;i<=tasks_number;i++){
            task[i]->counter = task[i]->priority;
            printk("SET [PID = %d PRIORITY = %d COUNTER = %d]\n",i,task[i]->priority,task[i]->counter);
        }
        schedule();
    }else{
        Log(RED "switch to [PID = %lx PRIORITY = %lx COUNTER = %lx] ",task[next]->pid,task[next]->priority,task[next]->counter,CLEAR);
        switch_to(task[next]);
    }
}


/**
 * The function to find whether the sepcific VA is in the VMA
 * 
 * @param mm -> the memory manager need be find;
 * @param addr -> the va waited for seeking
 * @return return the found struct else return null;
*/
struct vm_area_struct *find_vma(struct mm_struct *mm, uint64_t addr){
    struct vm_area_struct* ptr = mm->mmap;
    for(;ptr!=NULL;ptr = ptr->vm_next){
        if(addr>=ptr->vm_start&&addr<=ptr->vm_end){
            return ptr;
        }
    }
    return NULL;
}



/*
* @mm       : current thread's mm_struct
* @addr     : the suggested va to map
* @len      : memory size to map
* @vm_pgoff : phdr->p_offset
* @vm_filesz: phdr->p_filesz
* @flags    : flags for the new VMA
*
* @return   : start va
* we choose to add the nodes in the header of the linked-list;
*/
uint64_t do_mmap(struct mm_struct *mm, uint64_t addr, uint64_t len, uint64_t vm_pgoff, uint64_t vm_filesz, uint64_t flags){
    struct vm_area_struct* temp = (struct vm_area_struct*)alloc_page();
    //memset(temp,0,sizeof(struct vm_area_struct));
    // initial the vm_area_struct
    temp->vm_start = addr;
    temp->vm_end = addr+len;
    temp->vm_prev = NULL;
    temp->vm_next = NULL;
    temp->vm_flags = flags;
    temp->vm_filesz = vm_filesz;
    temp->vm_pgoff = vm_pgoff;
    if(mm->mmap==NULL){
        mm->mmap = temp;
    }else{
        struct vm_area_struct *ptr = mm->mmap;
        temp->vm_next = ptr;
        ptr->vm_prev = temp;
        mm->mmap = temp;
    }
    temp->vm_mm = mm;
    return temp->vm_start;
}

