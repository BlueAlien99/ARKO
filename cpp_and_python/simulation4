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

	double g = 9.81;
	double dt = 0.0078125;	// 1/128 s
	double s = 0;
	double h = 0;
	//double hmax = pow(vy, 2)/(2*g);
	double tau = 0.0625;	// 1/16 s
	//double hstop = 0.03;
	double vmax = vy;
	bool freefall = true;
	int i = 0;

	ofstream outfile("data.txt");

	while(i < 1024){
		++i;
		outfile<<s<<" "<<h<<endl;
		if(freefall){
			s = s + vx*dt;
			double x = vy*dt;
			double y = g*dt;
			h = h+x;
			vy = vy-y;
			if(h <= 0){
				freefall = 0;
				h = 0;
			}
		}
		else{
			s = s + vx*tau;
			vmax = vmax*rho;
			vy = vmax;
			freefall = true;
			//hmax = pow(vmax, 2)/(2*g);
		}
	}

	outfile.close();
}
