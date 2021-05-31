#include <stdio.h>
#include "f.h"

int main(int argc, char *argv[])
{
	int x = 10;
	int y = 10;
	
	int output = f(x, y);
	printf("%d\n", output);
	
	return 0;
}
