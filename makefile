CC=gcc
CFLAGS=-m64 -Wall
LDFLAGS=-L/usr/local/lib -lallegro -lallegro_image
INCLUDE=-I. -I/usr/local/include/allegro5

all:	main.o f.o
	$(CC) $(CFLAGS) main.o f.o -o fun $(INCLUDE) $(LDFLAGS)
	
main.o:
	$(CC) $(CFLAGS) -c main.c -o main.o
	
f.o:	f.asm
	nasm -f elf64 f.asm -o f.o
	
clean:
	rm -f *.o
