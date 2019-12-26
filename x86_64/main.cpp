#include <fstream>
#include <iostream>
#include <iomanip>
#include <stdio.h>

#include "fun.h"

using namespace std;

int get4bytes(char *dataptr){
	int ret = 0;
	for(int i = 0; i < 4; ++i){
		ret *= 256;
		ret += *(unsigned char*)dataptr;
		dataptr -= 1;
	}
	return ret;
}

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

	int width = get4bytes(bmpptr+21);
	int height = get4bytes(bmpptr+25);
	int bytesPerRow = ((int)size-54) / height;

	cout<<"Width:  "<<setw(4)<<width<<endl;
	cout<<"Height: "<<setw(4)<<height<<endl;
	cout<<"Bytes per row: "<<setw(4)<<bytesPerRow<<endl;

	fun(bmpptr+54, width, height, bytesPerRow, 16, 32, 0.1);

	ofstream outputbmp("./output.bmp", ios::out | ios::binary | ios::trunc);
	if(!outputbmp.is_open()){
		cout<<"Couldn't open output bitmap!"<<endl;
		exit(EXIT_FAILURE);
	}

	outputbmp.write(bmpptr, size);
	outputbmp.close();

	return 0;
}
