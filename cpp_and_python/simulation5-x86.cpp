#include <iostream>
#include <fstream>
#include <cmath>

using namespace std;

int main(){
	double vx, vy;
	double rho;

	cout<<"\nvy: ";
	cin>>vy;
	cout<<"\nvx: ";
	cin>>vx;
	cout<<"\nrho: ";
	cin>>rho;

	double initvy = -vy;
	double g = 9.81;
	double dt = 0.0078125;	// 1/128 s
	double s = 0;
	double h = 0;
	double tau = 0.0625;	// 1/16 s
	bool freefall = true;
	int i = 0;

	ofstream outfile("data.txt");

	while(i < 2048){
		++i;
		//outfile<<s<<" "<<h<<'\t'<<vx<<" "<<vy<<endl;
		outfile<<s<<" "<<h<<endl;
		if(freefall){
			s = s + vx*dt;
			double x = vy*dt;
			double y = g*dt;
			double vxt = rho*vx*vx*dt;
			double vyt = rho*vy*vy*dt;
			h = h+x;
			vx = vx-vxt;
			if(h > 0){
				if(vy < 0){
					vy = vy-y+vyt;
				} else{
					vy = vy-y-vyt;
				}
			}
			else{
				if(vy < initvy){
					vy = initvy;
				}
				freefall = 0;
				h = 0;
			}
		}
		else{
			s = s + vx*tau;
			vy = vy * (-1);
			freefall = true;
		}
	}

	outfile.close();
}
