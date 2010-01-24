function c = integrate(c)

%INTEGRATE   integrates each trace.
%
% C = INTEGRATE(C) integrates each trace. Prior to integrating, the trend
% and mean of each trace is removed. Depending on the application, it is
% recommended that users also consider applying a gentle high pass filter
% to remove unwanted low frequencies that can dominate the integrated
% waveforms.

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks

c.W = detrend(c.W);
c.W = demean(c.W);
c.W = integrate(c.W);