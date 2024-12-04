#include "stdint.h"
#include "sbi.h"
#include "defs.h"
#include "stddef.h"
#include "printk.h"
#include "mm.h"
#include "string.h"
/* early_pgtbl: 用于 setup_vm 进行 1GiB 的映射 
 * early_pgtbl -> 一个页表
*/
uint64_t early_pgtbl[512] __attribute__((__aligned__(0x1000)));
/* swapper_pg_dir: kernel pagetable 根目录，在 setup_vm_final 进行映射 */
uint64_t swapper_pg_dir[512] __attribute__((__aligned__(0x1000)));
void create_mapping(uint64_t *pgtbl, uint64_t va, uint64_t pa, uint64_t sz, uint64_t perm);

// call the .text / .rotate / .other memory part
extern char _stext[],_etext[];
extern char _srodata[],_erodata[];
extern char _sdata[],_edata[];
extern char _sramdisk[],_eramdisk[];

uint64_t debug_ptr = 1;
/**
 * The purpose for this function is to set 2 mapping
 * 1. The equal value mapping PA==VA
 * 2. The direct mapping area PA + PV2VA_OFFSET == VA
 * 
*/
void setup_vm() {
    /* 
     * 1. 由于是进行 1GiB 的映射，这里不需要使用多级页表 
     * 2. 将 va 的 64bit 作为如下划分： | high bit | 9 bit | 30 bit |
     *     high bit 可以忽略
     *     中间 9 bit 作为 early_pgtbl 的 index
     *     低 30 bit 作为页内偏移，这里注意到 30 = 9 + 9 + 12，即我们只使用根页表，根页表的每个 entry 都对应 1GiB 的区域
     * 3. Page Table Entry 的权限 V | R | W | X 位设置为 1
    **/
   
    // page table entry
    /**
     * Sv39 Mode 
     * | Reserved bit | PPN[2] | PPN[1] | PPN[0] | RSW | D | A | G | U | X | W | R | V | 
     * 
     * 
    */
    // The first equal value mapping PA == VA 
    Log(RED "We enter the part of the setup_vm" CLEAR);
    uint64_t PA = PHY_START;
    // The first step to map;
    uint64_t virtualMemory_ = PA;
    // index 9 bits
    uint64_t index = (virtualMemory_>>30)&0x1ff;
    uint64_t PPN = (PA>>30)&0x1ff;
    // set for early_pagetable PNN;
    early_pgtbl[index] = (PPN)<<28;
    // set for the priority;
    early_pgtbl[index] = early_pgtbl[index] | 0xf;  // X | W | R | V |
    // The second value mapping PA + Offset == VA;

    uint64_t virtualMemory = VM_START;
    index = (VM_START>>30)&0x1ff;
    early_pgtbl[index] = (PPN)<<28 | 0xf;

    Log(RED "Over the set_vm" CLEAR);
}


void setup_vm_final(){
    memset(swapper_pg_dir, 0x0, PGSIZE);

    // No OpenSBI mapping required
    // mapping kernel text X|-|R|V 
    /**
     * stext -> represents the start of the text address;
     * etext -> represents the end of the text address;
     * create_mapping(uint64_t *pgtbl, uint64_t va, uint64_t pa, uint64_t sz, uint64_t perm)
    */
    Log(RED "We enter the part of the setup_vm_final" CLEAR);
    create_mapping((uint64_t*)swapper_pg_dir,(uint64_t)(_stext),(uint64_t)(_stext-PA2VA_OFFSET),(uint64_t)(_etext-_stext),0xb);
    // mapping kernel rodata -|-|R|V
    create_mapping((uint64_t*)swapper_pg_dir,(uint64_t)(_srodata),(uint64_t)(_srodata-PA2VA_OFFSET),(uint64_t)(_erodata-_srodata),0x3);

    // mapping other memory -|W|R|V
    create_mapping((uint64_t*)swapper_pg_dir,(uint64_t)(_sdata),(uint64_t)(_sdata-PA2VA_OFFSET),(PHY_END+PA2VA_OFFSET-(uint64_t)_sdata),0x7);

    create_mapping((uint64_t*)swapper_pg_dir,(uint64_t)_sramdisk,(uint64_t)(_sramdisk-PA2VA_OFFSET),(uint64_t)(_eramdisk-_sramdisk),0xf);
    // set satp with swapper_pg_dir
    uint64_t temp = 0x8000000000000000 | (((uint64_t)swapper_pg_dir-PA2VA_OFFSET)>>12);
    csr_write(satp,temp);
    // YOUR CODE HERE

    debug_ptr = 0;

    // flush TLB
    asm volatile("sfence.vma zero, zero");
    Log(RED "We go out of the part of the setup_vm_final" CLEAR);
    
    return;
}


/* 创建多级页表映射关系 */
/* 不要修改该接口的参数和返回值 */
/*
     * pgtbl 为根页表的基地址
     * va, pa 为需要映射的虚拟地址、物理地址
     * sz 为映射的大小，单位为字节
     * perm 为映射的权限（即页表项的低 8 位）
     * 
     * 创建多级页表的时候可以使用 kalloc() 来获取一页作为页表目录
     * 可以使用 V bit 来判断页表项是否存在
    **/
void create_mapping(uint64_t *pgtbl, uint64_t va, uint64_t pa, uint64_t sz, uint64_t perm) {
    // The purpose is to map all the part from the physical address to the virtual address;
    uint64_t n = (sz+PGSIZE-1)/PGSIZE;
    Log(GREEN "root : %016lx, [%016lx,%016lx) -> [%016lx,%016lx),perm = %lx",(uint64_t*)pgtbl,PGROUNDDOWN(pa),PGROUNDDOWN(pa+n*PGSIZE),PGROUNDDOWN(va),PGROUNDDOWN(va+n*PGSIZE),perm,CLEAR);
    for(int i=0;i<n;i++){
        // we need to set for the 3-levels page table;
        uint64_t VPN[3];
        VPN[2] = (va>>30)&0x1ff;
        VPN[1] = (va>>21)&0x1ff;
        VPN[0] = (va>>12)&0x1ff;
        uint64_t *ptr = pgtbl;
        if(debug_ptr==0)
            Log(YELLOW "[COW] root address is  : %016lx",ptr,CLEAR);
        for(int j=2;j>0;j--){
            uint64_t temp = ptr[(VPN[j])];
            if((temp&0x1)==0x0){
                uint64_t new_Ptr = (uint64_t)kalloc();
                // mark for the v bit 
                ptr[VPN[j]] = (((new_Ptr-PA2VA_OFFSET)>>12&0xfffffffffff)<<10)|0x1; 
                // Log(YELLOW "PageTable address %d is %016lx",j,new_Ptr,CLEAR);
                // Log(BLUE "THE PHYSICAL PageTable address %d is %016lx",j,new_Ptr-PA2VA_OFFSET,CLEAR);
                if(debug_ptr==0)
                    Log(YELLOW "[COW] ptr[VPN[%d]] : %016lx",j,ptr[VPN[j]],CLEAR);

                ptr = (uint64_t *)new_Ptr;
            }else{
                ptr = (uint64_t *)(((ptr[VPN[j]]>>10)<<12)+PA2VA_OFFSET);
            }
        }

        ptr[VPN[0]] = ((pa>>12)&0xfffffffffff)<<10 | perm;
        if(debug_ptr==0)
            Log(YELLOW "[COW] ptr[VPN[0]] : %016lx",ptr[VPN[0]],CLEAR);
        pa+=PGSIZE;
        va+=PGSIZE;
    }

}