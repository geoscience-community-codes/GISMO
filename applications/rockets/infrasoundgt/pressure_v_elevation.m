% Section 2.8 of https://www.ohio.edu/mechanical/thermo/Intro/Chapt.1_6/Chapter2b.html
close all

T0 = 0 + 273; % kelvin, temperature at sea level
a = -0.00651; % Kelvin/m, a is lapse rate
P0 = 101000; % Pa, standard atmosphere pressure
g = 9.81; %m/s-2
R = 287; %J/kg.Kelvin gas constant for air

count=1;
z = 0:3000; % height
T = T0 + a * z;
P = P0 * power(T/T0, -g/(R*a) );

subplot(3,1,1),plot(z, T-273); ylabel('Temperature (C)');
subplot(3,1,2),plot(z, P); ylabel('Pressure (Pa)');


z=z(1)+0.5:z(end)-0.5;
subplot(3,1,3),plot(z,diff(P));
xlabel('Altitude (m)')
ylabel('Pressure gradient (Pa/m)')



