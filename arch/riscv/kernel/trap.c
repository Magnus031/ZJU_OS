#include "stdint.h"
#include "trap.h"
#include "printk.h"
#include "sbi.h"
#include "clock.h"
#include "proc.h"
#include "mm.h"
#include "defs.h"
#include "string.h"
#include "syscall.h"

extern void create_mapping(uint64_t *pgtbl, uint64_t va, uint64_t pa, uint64_t sz, uint64_t perm);
extern long write(unsigned int fd,const char* buf,size_t count);
extern long get_pid();
extern struct task_struct* current;
extern char _sramdisk[],_eramdisk[];
extern uint64_t tasks_number;
uint64_t checkValid(uint64_t address,uint64_t* pgd);


void trap_handler(uint64_t scause, uint64_t sepc, struct pt_regs *regs){
    // 通过 `scause` 判断 trap 类型
    // 如果是 interrupt 判断是否是 timer interrupt
    // 如果是 timer interrupt 则打印输出相关信息，并通过 `clock_set_next_event()` 设置下一次时钟中断
    // `clock_set_next_event()` 见 4.3.4 节
    // 其他 interrupt / exception 可以直接忽略，推荐打印出来供以后调试
    // 通过查阅手册，我们得知 scause 寄存器在最高位置1表示的是trap，后面跟着的Exception Code表示的是trap的类型;
    // 判断 scause = 0x5
    //Log(YELLOW "scause: %lx\n",scause,CLEAR);
    
    if((scause >> 63)==0x1){
        // We distinguish if it is a trap;
        uint64_t cause_code = scause & 0x7FFFFFFFFFFFFFFF;
        //printk("exception_code: %lx\n",cause_code);
        if(cause_code == 5){
            // Indicate that it is the time_interrupt;
            //printk("[S] Supervisor Mode Timer Interrupt\n");
            clock_set_next_event();
            do_timer();
        }else{
            //printk("You have run across another interrupt;\n");
        }
    }else{
        //printk("Not the time interrupt\n");
        //Log(RED "Now you set for the ecall" CLEAR);
        uint64_t cause_code = scause & 0x7FFFFFFFFFFFFFFF;
        //Log(GREEN "the cause_code is %lx",cause_code,CLEAR);
        switch(cause_code){
            case 0x8 : // system call from the User mode;
                uint64_t syscall_number = regs->a7;
                Log(BLUE "the syscall_number is %lx",syscall_number,CLEAR);
                switch(syscall_number){
                    // write()
                    case 64:
                        regs->a0 = write(regs->a0,(const char*)regs->a1,regs->a2);
                    break;
                    // getpid()
                    case 172:
                        regs->a0 = get_pid();
                    break;
                    // fork() (actually the clone)
                    case 220:
                        //regs->a0 = do_cow_fork(regs); 
                        regs->a0 = do_fork(regs);
                    break;
                    default:
                    break; 
                }
            //sepc+=4;
            regs->sepc+=4;
            break;
            case 0xc:
            case 0xd:
            case 0xf:
            Log(RED "[S] Unhandled Exception: scause = %lx, sepc = %lx , stval = %lx",regs->scause,regs->sepc,regs->stval,CLEAR);
            do_page_fault(regs);
            break;
        }
    }
}

/**
 * the function to deal with the page fault;
 * Exception : 
 *  12 Instruction Page Fault;
 *  13 Load Page Fault;
 *  15 Store/AMO Page Fault
 * 
 * 
*/
void do_page_fault(struct pt_regs *regs){
    Log(BLUE "WE HAVE ENTERED INTO THE DEAL_PG_FAULT DEAL WITH PART" CLEAR);
    uint64_t fault_address = regs->stval;
    Log(YELLOW "fault_address: %016lx",regs->stval,CLEAR);
    struct vm_area_struct* ptr = find_vma(&current->mm,fault_address);
    if(ptr == NULL){
        Log(RED "ERROR! YOU HAVE FOUND THE ERROR EREA!" CLEAR);
        untrapped_handler(regs);
    }
    Log(PURPLE "We have found the VMA : [%016lx, %016lx]",PGROUNDDOWN(ptr->vm_start),PGROUNDDOWN(ptr->vm_end),CLEAR);
    /**
     *  determine whether it is a ANON area;
     *  If it is an ANON area : 
     *      we need to alloc a PAGE in the memory
     *      create mapping from the page to the memory in the PageTable;
     *  If it is not an ANON area: 
     *      we need to do additionally action -> Load the data from the elf file;
     * 
     * */
    

    /**
     * In the PTE -> the flags: 
     * U X W R V
     * 
    */
    
    uint64_t FLAG = ptr->vm_flags;
    if(((regs->scause==0xc)&&!(FLAG&VM_EXEC))||((regs->scause==0xd)&&!(FLAG&VM_READ))||((regs->scause==0xf)&&!(FLAG&VM_WRITE))){
        untrapped_handler(regs);
    }

    uint64_t flag = FLAG&0x1;
    
    // The ANON area;
    // Allocate a PAGE
    char* VA = (char*)alloc_page();
    memset(VA,0,sizeof(uint64_t));
    // 在 elf 需要映射到的内存上的 VA 地址上的报错位置;
    uint64_t VMA_VA = regs->stval;
    uint64_t flag_cow = checkValid(VMA_VA,current->pgd);

    if(flag_cow==0){
        // get the page offset;
        uint64_t perm = 0x11;
        // Now we set for the perm;
        perm |= FLAG&0xe;
        create_mapping(current->pgd,VMA_VA,(uint64_t)VA-PA2VA_OFFSET,PGSIZE,perm);
        
        
        // NOT ANON area;
        if(flag!=1){
            uint64_t elf_offset = ptr->vm_pgoff;
            // 表示的是在 elf 文件中的开始位置
            uint64_t VM_VA = ptr->vm_start;
            uint64_t start_elf_va = (uint64_t)(_sramdisk+ptr->vm_pgoff);
            uint64_t offset = 0; 
            uint64_t end_elf_va = (uint64_t)(_sramdisk+ptr->vm_pgoff+ptr->vm_filesz);
            uint64_t start_copy = VMA_VA;
            // now we consider the case for that 
            /**
             * 1. start_elf_va and VMA_VA is in the same page;
             * we need to copy the first part of the elf segment;
            */  
            if(PGROUNDUP(start_elf_va)==PGROUNDUP(VMA_VA - VM_VA + start_elf_va)){
                // update the start_copy address from VMA_VA to start_elf_va;
                start_copy = start_elf_va;
                offset = VM_VA&0xFFF;
            }else{
                // from the sepecific paged start copy;
                // vm->start 表示的是 elf 文件中的segment 开始的部分需要在内存中映射的VA地址;
                // 我们接下来要求的是在 elf文件中的 segment 需要开始复制的开始地址;
                start_copy = start_elf_va + PGROUNDDOWN(VMA_VA) - VM_VA; 
            }

            /**
             * The following we consider for the end of the elf_file;
             * 1. start_copy+PGSIZE < end_elf_va; 整段复制
             * 2. start_copy < end_elf_va < start_copy+PGSIZE; 复制前面一部分
             * 3. start_copy > end_elf_va; 不需要处理 
            */
            if(end_elf_va>=start_copy&&end_elf_va<=start_copy+PGSIZE){
                memcpy((void*)(VA+offset),(void*)(start_copy),end_elf_va-start_copy-offset);
            }else if(end_elf_va>start_copy+PGSIZE){
                memcpy((void*)(VA+offset),(void*)(start_copy),PGSIZE-offset);
            }
        }   
    }else{
        uint64_t f = 0;
        /**
         * here we add the logical for dealing with the cow-fork;
         * 
        */
        printk("we start to cow _ in the page fault deal with\n");
        uint64_t p = 0x0;
        uint64_t VPN[3];
        VPN[2] = (VMA_VA>>30)&0x1ff;
        VPN[1] = (VMA_VA>>21)&0x1ff;
        VPN[0] = (VMA_VA>>12)&0x1ff;
        uint64_t* ptrp = current->pgd;
        for(int j=2;j>0;j--){
            ptrp = (uint64_t*) (((ptrp[VPN[j]]>>10)<<12) + PA2VA_OFFSET);
        }
        printk("ptrp = %016lx\n",ptrp[VPN[0]]);
        uint64_t number = get_page_refcnt(((ptrp[VPN[0]]>>10)<<12)+PA2VA_OFFSET);
        uint64_t f_write = ptrp[VPN[0]]&0x4;
            f = (regs->scause==15)&&((FLAG&VM_WRITE)==4)&&(f_write==0);
        printk("f: %d\n",f);
        if(f==1){
            /**
             * 1. we will copy for this cow 
             * 2. we will recreate the mapping 
             * 3. distinguish with the number;
             * */ 

            if(number==1){
                ptrp[VPN[0]] |= 0x4;
                // save for one copy time;
                printk("COW number is 1,we directly change the PTE_WRITE to 1\n");
            }else{
                // recreate the mapping
                put_page(((ptrp[VPN[0]]>>10)<<12)+PA2VA_OFFSET);
                printk("the number of virtual address : %016lx is %d\n",((ptrp[VPN[0]]>>10)<<12)+PA2VA_OFFSET,get_page_refcnt(((ptrp[VPN[0]]>>10)<<12)+PA2VA_OFFSET));
                char* VA_Address = (char*)alloc_page();
                memset(VA_Address,0,PGSIZE);
                memcpy((void*) VA_Address,(void*)PGROUNDDOWN(VMA_VA),PGSIZE);
                uint64_t VA_perm = ptrp[VPN[0]] & 0x1f;
                VA_perm |= 0x4;
                Log(YELLOW "COW: THE New VA_perm is %016lx",VA_perm,CLEAR);
                asm volatile("sfence.vma zero, zero");
                create_mapping(current->pgd,VMA_VA,(uint64_t)VA_Address-PA2VA_OFFSET,PGSIZE,VA_perm);
                printk("COW number is 2, and we create the mapping\n");
            }
            return ;
        }else{
            untrapped_handler(regs);
        }   
        
    }
}

/**
 * This function is to handler those problem that has no permission or accessing the invalid memory;
*/
void untrapped_handler(struct pt_regs *regs){
    Log(RED "YOU HAVE ENTERED THE ERROR AREA! sepc = %lx, scause = %lx, stval = %lx",regs->sepc,regs->scause,regs->stval,CLEAR);
    // we set for stopping.
    Log(BLUE "YOU CAN'T EXECUTE AGAIN" CLEAR);
    while(1);
}