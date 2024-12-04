# 包含我们所有 .c 文件（其实只有 printk.c
SRC = $(sort $(wildcard *.c))
# 
OBJ = $(patsubst %.c,%.o, $(SRC))

all:$(OBJ)

%.o:%.c
	${GCC} ${CFLAG} -c $<

clean: 
	$(shell rm -f *.o)
