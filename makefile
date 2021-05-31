CC=gcc
CFLAGS=-m64 -Wall

all:	main.o f.o
	$(CC) $(CFLAGS) main.o f.o -o fun
	
main.o:	main.c
	$(CC) $(CFLAGS) -c main.c -o main.o
	
f.o:	f.asm
	nasm -f elf64 f.asm -o f.o
	
clean:
	rm -f *.o
