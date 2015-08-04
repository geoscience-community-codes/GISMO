function w = demean (w)
%DEMEAN remove offset voltage from signal
%   waveform = demean(waveform)
%   Removes the mean signal from the waveform object
%
%   Input Arguments
%       WAVEFORM: a waveform object   N-DIMENSIONAL

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

m = mean(w);
w = w - m;
