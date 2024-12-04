#include "syscall.h"
#include "proc.h"
#include "printk.h"
#include "mm.h"
#include "defs.h"
#include "string.h"

extern struct task_struct* current;
extern struct task_struct* task[NR_TASKS];
extern int tasks_number;
extern void __ret_from_fork();
extern uint64_t swapper_pg_dir[512] __attribute__((__aligned__(0x1000)));
extern void create_mapping(uint64_t *pgtbl, uint64_t va, uint64_t pa, uint64_t sz, uint64_t perm);

long write(unsigned int fd,const char* buf,size_t count){
    if(fd!=STDOUT){
        Log(RED "sys_write: fd != STDOUT\n" CLEAR);
        return -1;
    }
    if(count<=0){
        Log(RED "sys_write: count<=0\n" CLEAR);
        return -1;
    }
    long cnt = printk("%s",buf);
    return cnt;
}

long get_pid(){
    return current->pid;
}

/**
 * in this funciton, our purpose is to confirm whether this address's content is valid;
 * 
 * @param address the address waiting for confirmed whether it is valid;
 * @param pgd the page table root address;
*/
uint64_t checkValid(uint64_t address,uint64_t* pgd){
    uint64_t VPN[3];
    VPN[2] = (address>>30)&0x1ff;
    VPN[1] = (address>>21)&0x1ff;
    VPN[0] = (address>>12)&0x1ff;
    uint64_t* ptr = pgd;
    //printk("root pg address : %016lx\n");
    for(int i=2;i>0;i--){
        // v-bit is 0;
        //printk("ptr[VPN[%d]] : %016lx\n",i,ptr[VPN[i]]);
        uint64_t f = ptr[VPN[i]]&0x1;
        if(f==0)
             return 0;
        // the ptr records for the next page table address;
        // printk("PTE %d is %016lx\n",i,ptr[VPN[i]],CLEAR);
        ptr = (uint64_t*)(((ptr[VPN[i]]>>10)<<12) + PA2VA_OFFSET);
        // printk("page table address is %016lx\n",ptr);
    }

    //printk("ptr[VPN[0]] : %016lx\n",ptr[VPN[0]]);
    uint64_t flag = ptr[VPN[0]]&0x1;
    // printk("flag : %d\n",flag);
    if(flag==0)
        return 0;
    return 1;
}




/**
 * used to achieve the system call -> fork;
 * @param regs the parent process's registers information
 * @return if we fork the child process successfully, return child pid. Otherwise, return -1;
 * 
*/
long do_fork(struct pt_regs* regs){
    /**
     * 1. copy for the kernel stack of the parent process;
     *    including the `task_struct` information, but for some changes
     * 2. create a new page-table used for the child process's creating mapping;
     * 3. traversal parents' VMA and its page-table
     * 4. add the process into the schedule queue;
     * 5. deal with parents' process return value;
    */
    // create a new child process;
    printk("\n");
    struct task_struct* child = (struct task_struct*)alloc_page();
    // adding into the schedule queue;
    // we do the deep copy first for the child process;
    int index = -1;
    //memset((void*)child,0,PGSIZE);
    memcpy((void*)child,(void*)current,PGSIZE);
    for(int i=0;i<NR_TASKS;i++){
        if(task[i]==NULL){
            index = i;
            tasks_number = index;
            break;
        }
    }
    if(index==-1){
        printk("the array is full!\n");
        return -1;
    }
    task[tasks_number] = child;
    child->pid = tasks_number;
    child->thread.ra = (uint64_t)__ret_from_fork;

    /***********************************
     *     
     *    ****************  -> high address
     *    *              * 
     *    *              * 
     *    *     *****    *  -> child_regs              
     *    *     *****    * 
     *    *     *****    * 
     *    *     *****    *  -> child_regs->sp  stack top;
     *    *              * 
     *    *              * 
     *    *              * 
     *    ****************  ->  low address            
    */


    // its turn to the regs 
    uint64_t offset = (uint64_t)regs-PGROUNDDOWN((uint64_t)regs);
    struct pt_regs* child_regs = (struct pt_regs*) ((uint64_t)child+offset);
    child->thread.sp = (uint64_t)child_regs;
    //child->thread.sscratch = regs->sscratch;
    // create a new page table for the child process;
    child->pgd = (uint64_t*)alloc_page();
    // first copy for the kernel page table 
    // for(int i=0;i<PGSIZE/8;i++)
    //     child->pgd[i] = swapper_pg_dir[i];
    memset((void*)child->pgd,0,PGSIZE);
    memcpy((void*)child->pgd,(void*)swapper_pg_dir,PGSIZE);
    // we start to do mapping for the VMA valid area;
    //child->mm = *(struct mm_struct*)alloc_page();
    // memset(&child->mm,0,PGSIZE);
    //child->mm.mmap = NULL;
    // if fork successfully, the child process return value is 0
    child_regs->a0 = 0;
    child_regs->sp = child_regs->sp - (uint64_t)current + (uint64_t)task[tasks_number];  
    child_regs->sepc = regs->sepc + 4;
    struct vm_area_struct* start_area = current->mm.mmap;
    for(;start_area!=NULL;){
        // add the vma into the vma_list;
        do_mmap(&child->mm,start_area->vm_start,(start_area->vm_end-start_area->vm_start),start_area->vm_pgoff,start_area->vm_filesz,start_area->vm_flags);
        Log(RED "WE FIND THE FIRST PART [%016lx,%016lx)",start_area->vm_start,start_area->vm_end,CLEAR);
        uint64_t page_start = PGROUNDDOWN(start_area->vm_start);
        while(page_start<start_area->vm_end){
            uint64_t fg = checkValid(page_start,current->pgd);
            printk("%d\n",fg);
            if(fg==0x1){
                /**
                 * if the page is valid,we need to do the mapping ;
                 * 1. memcpy the content;
                 * 2. do the page_table mapping;
                 * 
                 * vma perm : XWRA
                 * page_table_perm: UXWRV;
                 * 
                 * */ 
                Log(RED"We have entered the valid part [%016lx,%016lx);",page_start,page_start+PGSIZE,CLEAR);
                uint64_t* add_page = (uint64_t*)alloc_page();
                memset((void*)add_page,0,PGSIZE);
                memcpy((void*)add_page,(void*)page_start,PGSIZE);
                uint64_t perm = 0x11|(start_area->vm_flags&0b1110);
                create_mapping(child->pgd,page_start,(uint64_t)add_page-PA2VA_OFFSET,PGSIZE,perm);
            }
            page_start+=PGSIZE;
        }
        start_area = start_area->vm_next;
    }
    Log(RED "pid:%d is fork from the pid: %d",tasks_number,current->pid,CLEAR);
    return child->pid;
    
}


long do_cow_fork(struct pt_regs* regs){
    printk("COW : ENTER!\n");
    /**
     * @todo do_cow_fork
     * 1. 我们还是要为子进程复制一份父进程的内核栈
     * 2. 我们要为子进程创建页表pgd 
     * 3. 但是父和子的页表映射的是同一块物理地址 -> 都保证了只读;
     * 4. 只有当需要写的时候，才会报 page_fault
     * 
    */
    // we create a new child process;
    struct task_struct* child = (struct task_struct*)alloc_page();
    memset((void*)child,0,PGSIZE);
    memcpy((void*)child,(void*)current,PGSIZE);
    int idx = -1;
    for(int i=0;i<NR_TASKS;i++){
        // find the process 
        if(task[i]==NULL){
            tasks_number = i;
            idx = tasks_number;
            break;
        }
    }
    if(idx == -1){
        printk("WE CREATE the PROCESS DEFEATED!\n");
        return -1;
    }
    task[tasks_number] = child;
    child->pid = tasks_number;

    /***********************************
     *     
     *    ****************  -> high address
     *    *              * 
     *    *              * 
     *    *     *****    *  -> child_regs              
     *    *     *****    * 
     *    *     *****    * 
     *    *     *****    *  -> child_regs->sp  stack top;
     *    *              * 
     *    *              * 
     *    *              * 
     *    ****************  ->  low address            
    */

    // Now we do the copy for the child process;
    uint64_t offset = (uint64_t) regs - PGROUNDDOWN((uint64_t)regs);
    struct pt_regs* child_regs = (struct pt_regs*)((uint64_t)child+offset);
    // 和 parent process 一样，在 thread.sp 中保存了当前的内核栈开始的位置;
    child->thread.sp = (uint64_t)child_regs;
    // change the return address of the child process;
    child->thread.ra = (uint64_t)__ret_from_fork;
    // child->thread.sscratch = regs->sscratch;
    // 需要更改栈顶 sp 的位置;
    child_regs ->sp = child_regs->sp + (uint64_t)task[tasks_number] - (uint64_t)current;
    child_regs ->a0 = 0;
    child_regs ->sepc += 4;

    // create the page_table;
    child->pgd = (uint64_t*) alloc_page();
    /**
     *  the reference count ++;
     *  now we need to let the PTE read-only and copy for the PTE; 
     *  so that the child process can share the memory with the parent process;
     * 
     * 
     *  find the valid area and set the area's PTE to PTE_W = 0;
     */
    struct vm_area_struct* start_area = current->mm.mmap;
    for(;start_area!=NULL;start_area = start_area->vm_next){
        uint64_t VA = PGROUNDDOWN(start_area->vm_start);
        uint64_t VA_END = start_area->vm_end;
        while(VA<VA_END){
            uint64_t f_check = checkValid(VA,current->pgd);
            if(f_check==1){
                uint64_t VPN[3];
                VPN[2] = (VA>>30)&0x1ff;
                VPN[1] = (VA>>21)&0x1ff;
                VPN[0] = (VA>>12)&0x1ff;
                uint64_t* ptr = current->pgd;
                for(int j=2;j>0;j--){
                    ptr = (uint64_t*) (((ptr[VPN[j]]>>10)<<12) + PA2VA_OFFSET);
                }
                ptr[VPN[0]] = ptr[VPN[0]]&0xfffffffffffffffb;
                // VA reference + 1;
                // create PTE for child process; and point to the same physical address;
                uint64_t PA = (ptr[VPN[0]]>>10)<<12 + (VA&0xfff);
                get_page(PA+PA2VA_OFFSET);
                printk("the number of virtual address : %016lx is %d",PA+PA2VA_OFFSET,get_page_refcnt(PA+PA2VA_OFFSET));
                create_mapping(child->pgd,VA,PA,PGSIZE,ptr[VPN[0]]&0x1f);
            }
            VA+=PGSIZE;
        }
    }
    // refresh the TLB;
    asm volatile("sfence.vma zero, zero");
    Log(RED "pid:%d is fork from the pid: %d",tasks_number,current->pid,CLEAR);
    return child->pid;
}