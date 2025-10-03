NAME = server

ASM = $(NAME).s

OBJ = $(NAME).o

all:
	as -g -o $(OBJ) $(ASM)
	ld -g -o $(NAME) $(OBJ)
	gdb ./$(NAME)

clean:
	rm $(OBJ)

fclean: clean
	rm $(NAME)
