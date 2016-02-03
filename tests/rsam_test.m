%TEST Test the RSAM class
close all
echo on

%% Load data
file = '/Users/thompsong/Dropbox/MVOnetwork/SEISMICDATA/RSAM_1/%station%year.DAT';
sta = {'MLGT';'MRYT'};
chan = 'SHZ';
snum = datenum(1995,8,1);
enum = datenum(1999,12,31,23,59,59);
s = rsam.load('file', file, 'snum', snum, 'enum', enum, 'sta', sta, 'chan', chan);

%% Plot the raw 1-minute data
figure
s.plot();

%% Subset for a 9-day period in 1996 (banded tremor)
s2 = s.subset(datenum(1996,7,30), datenum(1996,8,8));
figure
s2.plot()

%% Smooth in 10-minute bins
tic;
ss = s2.smooth(10);
toc % reports elapsed time in seconds - smoothing is slow
figure
ss.plot('linestyle','-');

%% Resample at 10-minutes instead - compare speed
tic;
ss = s2.resample(10);
toc % reports elapsed time in seconds - smoothing is slow
figure
ss.plot('linestyle','-');

%% Ratio MLGT by MRYT
[r,errflag] = ss(1).divide(ss(2));
if errflag==false
    figure
    r.plot('yaxisType','logarithmic','linestyle','-')
end

%% Subtract MRYT from MLGT
[r,errflag] = ss(1).subtract(ss(2));
if errflag==false
    figure
    r.plot('linestyle','-')
end

%% duration amplitude
[lambda, r2] = duration_amplitude(s2, 'exponential')

echo off