function speed_versus_pressure()
% from Marchetti & Yasur 2013 GRL
% compute Mach number (M) as a function of overpressure (P0)
speed_of_sound = 348.8; % m/sec
gamma  = 1.4; % heat capacity for dry air
r = 1400; %m
ambient_pressure = 1e5; % Pascals
overpressure = logspace(0,5);
underpressure = sort(-overpressure);
overpressure = [underpressure overpressure];
%P0=ambient_pressure*10.^(-0.9:0.001:0.9);
%M=sqrt( (gamma+1)/(2*gamma) * (P0/ambient_pressure - 1) + 1);
M=sqrt( (gamma+1)/(2*gamma) * overpressure/ambient_pressure + 1);
close all
figure
subplot(3,1,1)
loglog(overpressure,M);
xlabel('Overpressure (Pa)')
ylabel('Mach number');

p=1000; % Pa
p_reduced = p * r;
r1 = 10:1:r;
p1 = p_reduced./r1;
subplot(3,1,2),semilogy(r1,p1);
xlabel('Distance (m)')
ylabel('Overpressure (Pa)')

M1=sqrt( (gamma+1)/(2*gamma) * p1/ambient_pressure + 1);
subplot(3,1,3),semilogy(r1,M1);
xlabel('Distance (m)')
ylabel('Mach number')
disp(sprintf('At array: Mach number = %.3f, mean speed = %.1f',M1(end),1.6+M1(end)*speed_of_sound))
disp(sprintf('Along raypath: Mean Mach number = %.3f, mean speed = %.1f',mean(M1),1.6+mean(M1*speed_of_sound)))
