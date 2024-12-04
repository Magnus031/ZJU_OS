#include "printk.h"
#include "stdint.h"
#include "sbi.h"
void test() {
    // sbi_ecall(0x4442434E, 0x2, 0x32, 0, 0, 0, 0, 0);
    // printk("\n");
    // Test for the colorful format debugger console;
    Log(RED " This is a test for log" CLEAR);
    int i = 0;
    while(1);
    // while (1) {
    //     if ((++i) % 100000000 == 0) {
    //         printk("kernel is running!\n");
    //         i = 0;
    //     }
    // }
}