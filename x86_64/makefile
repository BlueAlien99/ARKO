CC = gcc -std=c++11 -no-pie -g
CFLAGS = -Wall -pedantic -Wextra -m64
INC := -lstdc++ -Iinclude/ -lallegro -lallegro_memfile -lallegro_image

all: main.o fun.o
	$(CC) $(CFLAGS) main.o fun.o -o Run $(INC)

main.o: main.cpp
	$(CC) $(CFLAGS) -c main.cpp -o main.o $(INC)

fun.o: fun.s
	nasm -F dwarf -f elf64 fun.s -o fun.o

clean:
	rm -f *.o Run
