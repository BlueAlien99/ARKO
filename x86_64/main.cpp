#include <fstream>
#include <iostream>
#include <iomanip>
#include <limits>
#include <stdio.h>
#include <stdlib.h>

#include <allegro5/allegro.h>
#include <allegro5/allegro_memfile.h>
#include <allegro5/allegro_image.h>

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

int main(){
	ALLEGRO_DISPLAY *display = NULL;
	ALLEGRO_EVENT_QUEUE *event_queue = NULL;
	ALLEGRO_FILE *bitmap_file = NULL;
	ALLEGRO_BITMAP *bitmap = NULL;

	if(!al_init()){
		cout<<"Failed to initialize allegro!"<<endl;
		return -1;
	}

	if(!al_init_image_addon()){
		cout<<"Failed to initialize image addon!"<<endl;
		return -1;
	}

	if(!al_install_mouse()){
		cout<<"Failed to initialize the mouse!"<<endl;
		return -1;
	}

	ifstream inputbmp("./bitmap.bmp", ios::in | ios::binary);
	if(!inputbmp.is_open()){
		cout<<"Couldn't open input bitmap!"<<endl;
		return -1;
	}

	inputbmp.seekg(0, ios::end);
	streampos size = inputbmp.tellg();

	char *plainbmpptr = new char[size];
	char *bmpptr = new char[size];
	if(plainbmpptr == nullptr || bmpptr == nullptr){
		cout<<"Couldn't allocate memory!"<<endl;
		return -1;
	}

	inputbmp.seekg(0, ios::beg);
	inputbmp.read(plainbmpptr, size);
	inputbmp.close();

	int width = get4bytes(plainbmpptr+21);
	int height = get4bytes(plainbmpptr+25);
	int bytesPerRow = ((int)size-54) / height;

	cout<<"Width:  "<<setw(4)<<width<<endl;
	cout<<"Height: "<<setw(4)<<height<<endl;
	cout<<"Bytes per row: "<<setw(4)<<bytesPerRow<<endl;

	display = al_create_display(width, height);
	if(!display){
		cout<<"Failed to create display!"<<endl;
		return -1;
	}

	event_queue = al_create_event_queue();
	if(!event_queue){
		cout<<"Failed to create event queue!"<<endl;
		al_destroy_display(display);
		return -1;
	}

	al_register_event_source(event_queue, al_get_display_event_source(display));
	al_register_event_source(event_queue, al_get_mouse_event_source());

	memcpy(bmpptr, plainbmpptr, size);

	int i = 1;
	double K = 0.1;
	bool draw = true;

	while(true){

		if(draw){

			bitmap_file = al_open_memfile(bmpptr, size, "r");
			bitmap = al_load_bitmap_f(bitmap_file, ".bmp");
			if(bitmap == NULL){
				cout<<"Failed to load bitmap!"<<endl;
				al_destroy_display(display);
				al_destroy_event_queue(event_queue);
				return -1;
			}

			al_draw_bitmap(bitmap, 0, 0, 0);
			al_flip_display();
			draw = false;
			++i;
		}

		ALLEGRO_EVENT ev;
		al_wait_for_event(event_queue, &ev);

		if(ev.type == ALLEGRO_EVENT_DISPLAY_CLOSE){
			break;
		}
		else if(ev.type == ALLEGRO_EVENT_MOUSE_BUTTON_DOWN && ev.mouse.button == 1){
			cout<<"mouse btn LEFT down at "<<endl;
			cout<<"x: "<<ev.mouse.x<<endl;
			cout<<"y: "<<ev.mouse.y<<endl;
			draw = true;
		}
		else if(ev.type == ALLEGRO_EVENT_MOUSE_BUTTON_DOWN && ev.mouse.button == 3){
			string newK;
			cout<<"Current K value = "<<K<<endl;
			cout<<"Enter new K value: ";
			cin>>newK;
			cin.ignore(numeric_limits<streamsize>::max(), '\n');
			try{
				K = stod(newK);
				cout<<"New K value = "<<K<<endl;
				draw = true;
			} catch(...){
				cout<<"Couldn't change K value!"<<endl;
			}
		}


		if(draw){

			memcpy(bmpptr, plainbmpptr, size);

			fun(bmpptr+54, width, height, bytesPerRow, 16, 32, K);

			al_destroy_bitmap(bitmap);
			al_fclose(bitmap_file);
		}


	}

	al_destroy_bitmap(bitmap);
	al_fclose(bitmap_file);
	al_destroy_display(display);
	al_destroy_event_queue(event_queue);

	ofstream outputbmp("./output.bmp", ios::out | ios::binary | ios::trunc);
	if(!outputbmp.is_open()){
		cout<<"Couldn't open output bitmap!"<<endl;
		return -1;
	}

	outputbmp.write(bmpptr, size);
	outputbmp.close();

	delete[] plainbmpptr;
	delete[] bmpptr;

	return 0;
}
