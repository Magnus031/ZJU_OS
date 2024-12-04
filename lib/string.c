#include "string.h"
#include "stdint.h"

void *memset(void *dest, int c, uint64_t n) {
    char *s = (char *)dest;
    for (uint64_t i = 0; i < n; ++i) {
        s[i] = c;
    }
    return dest;
}

void *memcpy(void *dest, void *source,uint64_t n){
    for(int i=0;i<n;i++){
        ((char*)dest)[i] = ((char*)source)[i];
    }
    return dest;
}