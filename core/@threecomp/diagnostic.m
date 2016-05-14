function diagnostic(threecomp)

%DIAGNOSTIC check for accurate behavior of threecomp object.
% DIAGNOSTIC(THREECOMP) runs a series of diagnostics to ensure that threecomp
% object is workign properly. This function is intended for debugging and
% not general use.



% GET TEST DATA
load('private/demo_waveforms');
orientationList = 360*rand(size(w,1),6);
triggerList = get(w,'START') + 180/86400;
%triggerList = datenum('2010/01/01') * ones(size(w));


% TEST THREECOMP CONSTRUCTOR
TC = threecomp(); disp(TC);
TC = threecomp(w); disp(TC);
TC = threecomp(w,backAzimuth,triggerList,orientationList);  disp(TC);
TC = threecomp(w,triggerList,backAzimuth);  disp(TC);
TC = threecomp(w,triggerList);  disp(TC);
TC = threecomp(w,backAzimuth);  disp(TC);


% DISPLAY OBJECT AND PROPERTIES
disp(TC);
NSCL = get(TC,'NSCL')


% GET PARTICLE MOTION COEFFICIENTS
TC = particlemotion(TC,5,15);
for n = 1:numel(TC)
    plotpm(TC(n))
    set(gcf,'Position',[500 0 400 400]);
end


% TEST PARTICLE MOTION VALUES
% Adjust Z,N,E amplitudes and fZ,fN,fE frequencies to create test signal
% If fZ = fN = fE then signal will be highly rectilinear

Z = 1;      fZ = 5;
N = 0;      fN = 3;
E = 1;      fE = 2;
%
L = 1000;
S1 = Z*sin([1:L]'/fZ) .* hanning(L) + 0.1*rand(L,1)-0.05;
S2 = N*sin([1:L]'/fN) .* hanning(L) + 0.1*rand(L,1)-0.05;
S3 = E*sin([1:L]'/fE) .* hanning(L) + 0.1*rand(L,1)-0.05;
w = waveform;
w(1) = waveform('TEST','HHZ',100,datenum('2010/1/1'),S1);
w(2) = waveform('TEST','HHN',100,datenum('2010/1/1'),S2);
w(3) = waveform('TEST','HHE',100,datenum('2010/1/1'),S3);
tc = threecomp(w,135)
tc = particlemotion(tc);

%subplot(2,1,1); plot(tc.rectilinearity,'o'); ylim([0 1]); grid on;
%subplot(2,1,2); plot(tc.planarity,'o'); ylim([0 1]); grid on;




