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
b = 0.001 * k; % drag constant, kg/s
vy(1)=0;
vx(1)=0;
v(1)=0;
ay(1)=0;
ax(1)=0;
a(1)=0;
dy(1)=0;
dx(1)=0;
d(1)=0;
m(1)=m_initial;
g(1) = 9.8055; % m/s^2
R=6.371e6; %m
f(1)=60; % Hz
c(1)=340; % speed of sound, m/s
theta(1)=0;
for t=1:burntime
    theta(t+1)=min([t 80]); % thrust angle gradually increases from 0-80 degrees from the vertical
    theta(t+1)=27;
    g(t+1) = g(1) * R^2 /  (dy(t) + R)^2;
    m(t+1) = m(t) - k;
    drag = b * v(t) * exp(-dy(t)/8000);
    cos(deg2rad(theta(t+1)));
    thrust - drag;
    mean([m(t:t+1)]);
    mean([g(t:t+1)]);
    disp(drag)
    ay(t+1) = cos(deg2rad(theta(t+1))) * (thrust - drag) / mean([m(t:t+1)]) - mean([g(t:t+1)]) ;
    ax(t+1) = sin(deg2rad(theta(t+1))) * (thrust - drag) ;
    vy(t+1) = vy(t) + mean([ay(t) ay(t+1)]);
    vx(t+1) = vx(t) + mean([ax(t) ax(t+1)]);
    dy(t+1) = dy(t) + mean([vy(t) vy(t+1)]);
    dx(t+1) = dx(t) + mean([vx(t) vx(t+1)]);
    a(t+1) = sqrt(ay(t+1)^2 + ax(t+1)^2);
    v(t+1) = sqrt(vy(t+1)^2 + vx(t+1)^2);
    d(t+1) = sqrt(dy(t+1)^2 + dx(t+1)^2);
    
    % now compute doppler shifted frequency - for this need to know velocity along the
    % angle from launchpad to rocket
    c(t+1) = max([c(1) - d(t)/500 * 2  300]); % based on tables of elevation, pressure, temperature & c
    alpha(t+1) = atan(dy(t+1)/dx(t+1));
    phi(t+1) = atan(vy(t+1)/vx(t+1));
    vaway(t+1) = cos(alpha(t+1)-phi(t+1)) * v(t+1);
    f(t+1) = f(1) - vaway(t+1) / c(t+1);    
end
figure(1)
t=0:burntime;
subplot(2,2,1),plot(t,a);
xlabel('time (s)'); ylabel('acceleration (m/s^2)')
subplot(2,2,2),plot(t,v/1000);
xlabel('time (s)'); ylabel('speed (km/s)')
subplot(2,2,3),plot(t,d/1000);
xlabel('time (s)'); ylabel('distance travelled (km)')
subplot(2,2,4),plot(t,f);
xlabel('time (s)'); ylabel('Doppler-shifted frequency (Hz)')

figure(2)
subplot(3,2,1),plot(t,ax);
xlabel('time (s)'); ylabel('horizontal acceleration (m/s^2)')
subplot(3,2,2),plot(t,ay);
xlabel('time (s)'); ylabel('vertical acceleration (m/s^2)')
subplot(3,2,3),plot(t,vx);
xlabel('time (s)'); ylabel('horizontal speed (m/s)')
subplot(3,2,4),plot(t,vy);
xlabel('time (s)'); ylabel('vertical speed (m/s)')
subplot(3,2,5),plot(t,dx);
xlabel('time (s)'); ylabel('horizontal distance (m)')
subplot(3,2,6),plot(t,dy);
xlabel('time (s)'); ylabel('vertical distance (m)')

figure(3)
subplot(3,2,1),plot(t,90-theta);
xlabel('time (s)'); ylabel('thrust angle')
subplot(3,2,2),plot(t,rad2deg(phi));
xlabel('time (s)'); ylabel('velocity angle')
subplot(3,2,3),plot(t,rad2deg(alpha));
xlabel('time (s)'); ylabel('position angle')
subplot(3,2,4),plot(dx,dy);
xlabel('Horizontal distance'); ylabel('Height'); axis equal;
subplot(3,2,5),plot(t,c);
xlabel('time (s)'); ylabel('Speed of sound (m/s)')
subplot(3,2,6),plot(t,f);
xlabel('time (s)'); ylabel('Doppler-shifted Frequency (Hz)')

