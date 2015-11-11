%% Main function to generate tests
function tests = amplitude_spectrum_test()
tests = functiontests(localfunctions);
end

%% Test Functions
function testFunctionOne(testCase)
samp=100;
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
end

%% Optional file fixtures  
function setupOnce(testCase)  % do not change function name
% set a new path, for example
end

function teardownOnce(testCase)  % do not change function name
% change back to original path, for example
end

%% Optional fresh fixtures  
function setup(testCase)  % do not change function name
% open a figure, for example
close all
end

function teardown(testCase)  % do not change function name
% close figure, for example
close all
end
