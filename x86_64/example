#include <stdio.h> 		// angle brackets include looks for file 'stdio.h' 
#include <string.h>		//	in all the possible directories (including 
#include <stdlib.h>		//	this file directory or system directories)

#include "x86_function.h" 	// quotation include looks for 'x86_function.h' ONLY in the  
				//	working directory and relative 
				//	directories (for example "../another_file.h")

int main(int argc, char *argv[])
{
	char *pText = (char *) 0;
	if (argc < 2)				// check if text is provided
	{
		printf("Not enough arguments.\n"
			"Run program as \"%s <some alphanumeric text>\"\n"
			"Thanks ;-)", argv[0]);
		return -1;
	}
	
	pText = malloc(strlen(argv[1]) + 1);	// alloc mamory for copy of our text
	if (pText == NULL)
	{
		printf("Memory allocation failed.");
		return -1;
	}
	
	strcpy(pText, argv[1]);			// copy text
	
	x86_function(pText);			// call assembler procedure
	
	printf("Original text & modified text:\n"
		"%s\n"
		"%s\n"
		"Bye! ;-)\n", argv[1], pText);
	
	free(pText);				// free allocated memory
	
	return 0;
}

