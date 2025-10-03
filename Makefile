NAME = server

ASM = $(NAME).s

OBJ = $(NAME).o

all:
	as -o $(OBJ) $(ASM)
	ld -o $(NAME) $(OBJ)

gdb:
	as -g -o $(OBJ) $(ASM)
	ld -g -o $(NAME) $(OBJ)
	gdb ./$(NAME)

run: all
	./$(NAME)

clean:
	rm $(OBJ)

fclean: clean
	rm $(NAME)
