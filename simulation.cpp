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
	double dt = 0.001;
	double s = 0;
	double h = 0;
	double hmax = pow(vy, 2)/(2*g);
	double tau = 0.1;
	double hstop = 0.01;
	double vmax = vy;
	bool freefall = true;

	ofstream outfile("data.txt");

	while(hmax > hstop){
		if(freefall){
			double hnew = h + vy*dt;
			s = s + vx*dt;
			if(hnew < 0){
				freefall = false;
				h = 0;
			}
			else {
				vy = vy - g*dt;
				h = hnew;
			}
		}
		else{
			s = s + vx*tau;
			vmax = vmax*rho;
			vy = vmax;
			freefall = true;
			hmax = pow(vmax, 2)/(2*g);
		}
		outfile<<h<<" "<<s<<endl;
	}
	cout<<"Stopped at "<<hmax;

	outfile.close();
}
