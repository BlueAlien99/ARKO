#include <fstream>
#include <iostream>
#include <stdio.h>

#include "fun.h"

using namespace std;

int main(int argc, char *argv[]){
	ifstream inputbmp("./bitmap.bmp", ios::in | ios::binary);
	if(!inputbmp.is_open()){
		cout<<"Couldn't open input bitmap!"<<endl;
		exit(EXIT_FAILURE);
	}

	inputbmp.seekg(0, ios::end);
	streampos size = inputbmp.tellg();

	char *bmpptr = new char[size];
	if(bmpptr == nullptr){
		cout<<"Couldn't allocate memory!"<<endl;
		exit(EXIT_FAILURE);
	}

	inputbmp.seekg(0, ios::beg);
	inputbmp.read(bmpptr, size);
	inputbmp.close();

	fun(NULL, 0, 0, 16, 32, 0.1);

	ofstream outputbmp("./output.bmp", ios::out | ios::binary | ios::trunc);
	if(!outputbmp.is_open()){
		cout<<"Couldn't open output bitmap!"<<endl;
		exit(EXIT_FAILURE);
	}

	outputbmp.write(bmpptr, size);
	outputbmp.close();

	return 0;
}
