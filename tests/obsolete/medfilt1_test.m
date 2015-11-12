fs = 100;
t = 0:1/fs:1;
x = sin(2 * pi * t * 3) + 0.25 * sin(2 * pi * t*40);
y = medfilt1(x,10);
figure,clf
plot(t,x,t,y),grid on
xlabel 'Time (s)',ylabel Signal
legend('Original','Filtered')
legend boxoff

