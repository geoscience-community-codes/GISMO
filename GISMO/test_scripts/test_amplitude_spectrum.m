function test_amplitude_spectrum()
fsamp=100;
fsignal = 2; % 2Hz signal
t=0:1/fsamp:60; % 60s of data, 100Hz sampling rate
size(t)
y=20*sin(2 * pi * fsignal * t) + randn(size(t)); % bury a sinusoid signal in normally-distributed noise
figure
subplot(2,1,1),plot(t,y)
w=waveform;
w=set(w,'data',y,'freq',fsamp);
subplot(2,1,2), plot(w)
[A, phi, f] = amplitude_spectrum(w);
figure
plot(f,A)
set(gca,'XLim',[0 3])