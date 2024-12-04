#ifndef __MM_H__
#define __MM_H__

#include "stdint.h"

struct run {
    struct run *next;
};

void mm_init();

void *kalloc();
void kfree(void *);

/**
 * buddy struct is used to record an interface with the memory manager 
*/
struct buddy {
  // the size of memory for managing
  uint64_t size;
  // used to record the situation about allocating the memory;
  uint64_t *bitmap; 
  // 因为要共享页面，我们给每一个页增加一个引用计数;
  uint64_t *ref_cnt;
};

void buddy_init();
uint64_t buddy_alloc(uint64_t);
void buddy_free(uint64_t);

// 增加计数;
uint64_t get_page(void*);
// 减少计数;
void put_page(void*);
// 获取计数;
uint64_t get_page_refcnt(void*);

void *alloc_pages(uint64_t);
void *alloc_page();
void free_pages(void *);

void page_ref_inc(uint64_t pfn);
void page_ref_dec(uint64_t pfn);

#endif