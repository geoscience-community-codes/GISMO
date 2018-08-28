clear all
close all
%% Falcon 9 full thrust
thrust = 7.607e6; % N
m_initial = 549054; % kg, mass of fully laden Falcon 9
burntime = 162; % s
m_1ststage_empty = 22200; % kg
m_2ndstage_full = 115000; % kg
m_payload = 1700; % kg
m_lost = m_initial - m_1ststage_empty - m_2ndstage_full - m_payload;
k = m_lost / burntime; % kg/s
g = 9.8055; %m/s
b = 0.4 * k; % drag constant, kg/s
v(1)=0;
a(1)=0;
d(1)=0;
m(1)=m_initial;
g(1) = 9.8055; % m/s^2
R=6.371e6; %m
f(1)=60; % Hz
c(1)=340; % speed of sound, m/s
for t=1:burntime
    g(t+1) = g(1) * R^2/(d(t) + R)^2;
    m(t+1) = m(t) - k;
    drag = b * v(t);
    a(t+1) = (thrust - drag) / mean([m(t)  m(t+1)]) - mean([g(t) g(t+1)]) ;
    v(t+1) = v(t) + a(t);
    c(t+1) = max([c(1) - d(t)/500 * 2  300]); % based on tables of elevation, pressure, temperature & c
    f(t+1) = f(1) * c(t+1) / (c(t+1) + v(t+1) );
    d(t+1) = d(t) + mean([v(t) v(t+1)]);
end
figure
t=0:burntime;
subplot(2,2,1),plot(t,a);
xlabel('time (s)'); ylabel('acceleration (m/s^2)')
subplot(2,2,2),plot(t,v/1000);
xlabel('time (s)'); ylabel('velocity (km/s)')
subplot(2,2,3),plot(t,d/1000);
xlabel('time (s)'); ylabel('altitude (km)')
subplot(2,2,4),plot(t,f);
xlabel('time (s)'); ylabel('Doppler-shifted frequency (Hz)'); set(gca, 'YLim', [0 f(1)]);