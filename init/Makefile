C_SRC       = $(sort $(wildcard *.c))
# 存放的是 将 $(C_SRC)中的内容 .c 替换成 .o 文件
OBJ		    = $(patsubst %.c,%.o,$(C_SRC))


# 执行编译 $(OBJ) 中的.o文件
all:$(OBJ)
	
%.o:%.c
	${GCC}  ${CFLAG} -c $<
	
clean:
	$(shell rm *.o 2>/dev/null)
