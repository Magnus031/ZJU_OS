export
CROSS	:=	riscv64-linux-gnu-
GCC		:=	$(CROSS)gcc
LD		:=	$(CROSS)ld
OBJCOPY	:=	$(CROSS)objcopy
OBJDUMP	:=	$(CROSS)objdump
TEST_SCHED := 0

ISA		:=	rv64imafd
ABI		:=	lp64

INCLUDE =  -I $(shell pwd)/arch/riscv/include -I $(shell pwd)/include -I$(shell pwd)/user
CF		:=	-march=$(ISA) -mabi=$(ABI) -mcmodel=medany -fno-builtin -fno-pie -ffunction-sections -fdata-sections -nostartfiles -nostdlib -nostdinc -static -lgcc -Wl,--nmagic -Wl,--gc-sections -g -O0
CFLAG	:=	$(CF) $(INCLUDE) -DTEST_SCHED=$(TEST_SCHED) 

.PHONY:all run debug clean
all: clean
	$(MAKE) -C lib all
	$(MAKE) -C init all
	$(MAKE) -C user all
	$(MAKE) -C arch/riscv all
	@echo -e '\n'Build Finished OK

run: all
	@echo Launch qemu...
	@qemu-system-riscv64 -nographic -machine virt -kernel vmlinux -bios default 

debug: all
	@echo Launch qemu for debug...
	@qemu-system-riscv64 -nographic -machine virt -kernel vmlinux -bios default -S -s

clean:
	$(MAKE) -C lib clean
	$(MAKE) -C init clean
	$(MAKE) -C user clean
	$(MAKE) -C arch/riscv clean
	$(shell test -f vmlinux && rm vmlinux)
	$(shell test -f vmlinux.asm && rm vmlinux.asm)
	$(shell test -f System.map && rm System.map)
	@echo -e '\n'Clean Finished